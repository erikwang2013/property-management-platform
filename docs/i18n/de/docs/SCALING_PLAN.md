# Skalierungsplan (Scaling Plan)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

Die aktuelle Bereitstellung ist Einzelmaschinen-docker-compose (MySQL/Redis/Elasticsearch auf derselben Maschine wie die Anwendung, siehe `admin/docker-compose.yml`), ohne HA. Dieses Dokument beschreibt die Risiken und vorhandenen Abschwächungen und gibt den horizontalen Skalierungspfad, Datenmengen-Auslöser und Übungsempfehlungen an. Die Betriebsbaseline (Backup/Wiederherstellung, Monitoring-Alarme, Protokollrotation) finden Sie in [OPS_RUNBOOK.md](OPS_RUNBOOK.md).

---

## 1. Aktuelle Bereitstellung und Risiken

### 1.1 Ist-Zustand

| Komponente | Version | Beschreibung |
|------|------|------|
| MySQL | 8.0.36 | Einzelinstanz, Daten persistent im Host-Volume |
| Redis | 7.2-alpine | Einzelinstanz, Cache/Queue/Lock |
| Elasticsearch | 8.12.0 | Einzelknoten, scout-Volltextsuche |
| nginx + webman | — | admin (8787) und service (8788) Mehrprozess auf derselben Maschine |
| Prometheus + Grafana | — | Monitoring-Alarme, gleiche Maschine |

### 1.2 Risikoliste

| Risiko | Auswirkung | Wahrscheinlichkeit | Folge |
|------|------|------|------|
| Single Point of Failure (Ausfall einer Middleware) | Ganze Seite nicht erreichbar | Niedrig | Hoch |
| Host-Disk-/RAM-/CPU-Konkurrenz | Slow Queries, ES-Hänger, OOM | Mittel (steigt mit Datenwachstum) | Mittel |
| MySQL-Einzelinstanz irreparabel beschädigt | Datenverlust | Sehr niedrig | Sehr hoch |
| Kein Disaster-Recovery-Rechenzentrum | Rechenzentrumsausfall = Totalverlust | Sehr niedrig | Sehr hoch |
| Backup/Wiederherstellung nicht geübt | Wiederherstellung mit Zeitüberschreitung oder Fehlschlag | Mittel | Hoch |

## 2. Vorhandene Abschwächungen (umgesetzt)

- **Backup**: Ein-Klick-Backupskript `scripts/backup.sh` (liest Verbindung aus `admin/.env`, standardmäßig mysqldump im Container), tägliches Vollbackup per crontab, Standard-Aufbewahrung 7 Tage (`--keep-days=30` konfigurierbar); Wiederherstellungsübung und RPO/RTO-Erläuterung siehe OPS_RUNBOOK §1 und RECOVERY_RUNBOOK.
- **Monitoring-Alarme**: Prometheus + Grafana + `deploy/monitoring/alerts.yml`, abdeckt AppDown / MysqlDown / RedisDown / ElasticsearchDown / QueueBacklog, siehe OPS_RUNBOOK §3.
- **Protokollrotation**: Container-Protokolle `max-size 10m`, Host-Protokolle per logrotate täglich rotiert und 30 Tage aufbewahrt, siehe OPS_RUNBOOK §4.
- **Anwendungsebene**: webman Mehrprozess-Dauerbetrieb, Queue-Aufgaben entkoppeln zeitintensive Vorgänge, `/health`-Health-Check.

Fazit: Die obigen Abschwächungen decken „Ausfall wiederherstellbar" ab, **nicht „Ausfall ohne Unterbrechung"**. Wenn Geschäftsunterbrechungen nicht akzeptabel sind, ist die horizontale Skalierung aus §3 erforderlich.

## 3. Horizontaler Skalierungspfad (nach Priorität)

Skalierungsprinzip: erst vertikal (mehr CPU/RAM/Disk), dann horizontal (Komponenten trennen); erst Middleware, dann Anwendung; jeder Schritt einzeln rückrollbar.

### 3.1 MySQL Master-Slave + Halbsynchron (erste Priorität)

- Architektur: Master (bestehende Instanz) → Slave (neue Maschine), halbsynchrone Replikation aktivieren (`rpl_semi_sync_master_enabled=1`).
- Lese-Skalierung: Anwendung auf Master-Slave-Trennung konfigurieren (`config/database.php` unterstützt Lesen/Schreiben-Trennung, dann aktivieren; sonst zunächst nur Master-Slave-HA).
- Backup-Migration: Backupskript auf den Slave umstellen, um den Master nicht durch Backups zu belasten.
- Version: Der Slave muss mit der Hauptversion des Masters übereinstimmen (aktuell 8.0.36).
- Upgrade-Bedingung: Master-CPU dauerhaft >70%, Verbindungen nahe max_connections, sprunghafter Anstieg gescannter Zeilen im Slow-Query-Log.

### 3.2 Redis Sentinel oder Cluster (zweite Priorität)

- Sentinel (3 Knoten): bei moderatem Kapazitätsbedarf; Umschaltung in Sekunden; Client muss den `sentinel`-Modus unterstützen.
- Cluster (≥3 Master 3 Slave): wenn Cache-Menge > Einzelmaschinen-RAM oder Schreibparallelität steigt.
- Hinweis: Queue und verteilte Locks hängen von Redis ab; beim Topologiewechsel muss `config/redis.php` mit angepasst und das Verhalten von Locks/Queues unter Failover verifiziert werden.

### 3.3 Elasticsearch auf eigenem Knoten

- Einzelknoten-ES hat keine Repliken; bei Indexschaden ist die Suche unbenutzbar. Mindestens auf eine separate Maschine + 1 Replikat migrieren.
- Bei Datenwachstum Indizes nach Geschäftsdomäne aufteilen, unnötige Indexrepliken abschalten, um Ressourcen zu begrenzen.
- Upgrade-Bedingung: Heap-Nutzung >70% dauerhaft, Schreib-Ablehnungen (`es_rejected_executions` steigend), Abfrage-P95 über 1s.

### 3.4 Anwendungs-Mehrfachrepliken + Load Balancing (zuletzt)

- admin/service jeweils 2+ Repliken, davor nginx-Load-Balancing (round robin oder least_conn).
- Voraussetzung: zustandslos (Session in Redis, keine lokale Dateischreibabhängigkeit; dieses System mit JWT + Redis-Session erfüllt das im Wesentlichen).
- Danach verdoppelt sich die Verarbeitungskapazität mit der Replikatanzahl; dann zurück zu den Middleware-Engpässen aus §3.1-3.3.

## 4. Datenwachstums-Auslöser und Empfehlungen

| Auslöser | Schwellenwert-Empfehlung | Pflichtaktion |
|--------|----------|----------|
| Datenbankgesamtmenge | > 50 GB oder Einzeltabelle > 50 Mio. Zeilen | Master-Slave-Aufteilung + Archivierung historischer Rechnungs-/Protokolltabellen |
| Slow Queries | > 10 Slow Queries/Tag oder einzelne > 2s | Indizes ergänzen, Tabellen aufteilen, N+1 prüfen |
| MySQL-Verbindungen | dauerhaft > 80% max_connections | Verbindungspool + Master-Slave |
| Redis-Speicher | > 70% und weiter wachsend | Abgelaufene Keys aufräumen → Sentinel → Cluster |
| ES-Heap | > 70% oder Schreib-Ablehnungen | Eigener Knoten + Replikate + Indexaufteilung |
| CPU | Einzelkern dauerhaft > 80% und Queue-Stau | Anwendungs-Mehrfachrepliken → Middleware-Aufteilung |
| Disk | > 80% | Backups/Protokolle aufräumen, kalte Daten archivieren |

Empfehlung: Die obige Tabelle monatlich prüfen (Daten aus den Grafana-Panels); überschreitet ein Punkt zwei Wochen in Folge die Schwelle, die entsprechende Skalierung starten.

## 5. Skalierungsübungsempfehlungen

- **Vierteljährlich**: Wiederherstellungsübung (siehe OPS_RUNBOOK §1.3), RPO/RTO-Zielerreichung verifizieren.
- **Jährlich**: Master-Slave-Umschaltübung (auf neuer Maschine üben, Produktions-Master nicht anfassen): Slave aufbauen → aufholen lassen → umschalten → Lesen/Schreiben beider Enden verifizieren → zurückschalten.
- **Nach der ersten Skalierung**: mit `scripts/loadtest` die drei Pfade (Anmeldung/Liste/Suche) lasttesten und P95-Zielerreichung bestätigen (Referenz `docs/PERFORMANCE_REPORT_2026-08-16.md`).
- **Übungsprotokoll**: jede Übung im Änderungsprotokoll (CHANGELOG.md) festhalten, inkl.: Zeitpunkt, Übungspunkt, Ergebnis, offene Punkte.

## 6. Upgrade-Pfad-Schnellübersicht

```
Einzelmaschine (Ist-Zustand)
  ├─ MySQL Master-Slave halbsynchron   ← erste Priorität
  ├─ Redis Sentinel/Cluster            ← zweite Priorität
  ├─ ES eigener Knoten+Replikate        ← dritte Priorität
  └─ Anwendungs-Mehrfachrepliken+LB     ← zuletzt
        ↓
Mehrmaschinen-Bereitstellung (kein SPOF; Ausfallunterbrechung akzeptabel → Minuten-Unterbrechung akzeptabel → Sekunden-Umschaltung)
```

> Beim aktuellen Geschäftsvolumen ist keine Skalierung nötig; dieses Dokument dient dazu, bei „veränderten Datenmengen-/Ausfallanforderungen" direkt danach zu handeln, statt vor Ort zu entscheiden.
