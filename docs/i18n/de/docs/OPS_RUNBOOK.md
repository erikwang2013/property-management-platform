# Betriebshandbuch (OPS Runbook)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> Gültig für: property-management-platform (admin-Seite + service-Seite, PHP 8.3 webman)

## 1. Datenbank-Backup und -Wiederherstellung

Die admin-Seite und die service-Seite nutzen dieselbe MySQL-Instanz und dieselbe Datenbank `property_management`; ein Backup genügt. Einheitlicher Einstiegspunkt:

| Datenbank | Backup-Skript | Beschreibung |
|---|---|---|
| `property_management` | `scripts/backup.sh` | Liest die Verbindung aus `admin/.env` (Container-Name mit `--container=` überschreibbar), standardmäßig mysqldump im Container |

Ausgabe: `backups/backup_YYYYMMDD_HHMMSS.sql.gz`, standardmäßig werden die letzten 7 Tage behalten (`--keep-days=` einstellbar).

### 1.1 Vollständiges Backup

```bash
cd /path/to/property-management-platform
bash scripts/backup.sh
```

### 1.2 Geplante Aufgabe (crontab)

```cron
# Täglich um 02:00 vollständiges Backup
0 2 * * * cd /path/to/property-management-platform && bash scripts/backup.sh >> /var/log/pmp-backup.log 2>&1
```

Produktionsempfehlung: Backup-Verzeichnis auf eine separate Festplatte/Offsite-Speicher mounten und regelmäßig die Integrität der Backup-Dateien stichprobenartig prüfen (`gzip -t`).

### 1.3 Wiederherstellungsübung (mindestens vierteljährlich)

1. Neuestes Backup auswählen: `ls -t backups/backup_*.sql.gz`
2. Wiederherstellung in **separater Umgebung** (oder temporärer Datenbank) durchführen: siehe [RECOVERY_RUNBOOK.md](RECOVERY_RUNBOOK.md) Szenario A (Wiederherstellung in leere Datenbank) und Szenario B (Point-in-Time-Wiederherstellung).
3. Verifizieren:
   - Zeilenzahl-Vergleich: `SELECT COUNT(*) FROM erik_user;` muss mit den vor dem Backup erfassten Werten übereinstimmen
   - Verschlüsselte Felder sind normal entschlüsselbar: einen Datensatz mit encryptable-Feldern abfragen — Wert korrekt, keine decrypt-Fehler im Protokoll
   - Geschäfts-Smoke-Test: Anmeldung, Listen-Schnittstellen funktionieren normal
4. Dauer und Ergebnis der Übung protokollieren (für die RTO-Bewertung).

> Das vollständige Übungshandbuch (Wiederherstellung in leere Datenbank / Point-in-Time / Konsistenzvalidierung / 30-Minuten-Übungszeitplan) finden Sie in [RECOVERY_RUNBOOK.md](RECOVERY_RUNBOOK.md).

### 1.4 RPO / RTO-Erläuterung

- **RPO (maximaler Datenverlust)**: durch die Backup-Häufigkeit bestimmt. Tägliches Vollbackup → RPO ≤ 24 Stunden, d. h. höchstens die Daten des letzten Tages gehen verloren. Für ein kleineres RPO die Backup-Häufigkeit erhöhen (z. B. 2-mal täglich) oder binlog-Inkrement-Backups aktivieren.
- **RTO (Wiederherstellungszeit)**: hängt von Datenbankgröße und Wiederherstellungsgeschwindigkeit ab, Ziel ≤ 1 Stunde (Wiederherstellung + Validierung + Dienstneustart). Nach jeder Übung den real gemessenen Wert aktualisieren.
- Notfall bei fehlgeschlagener Wiederherstellung: zuerst den Anwendungscode zurücksetzen, dann mit dem neuesten verfügbaren Backup erneut versuchen; bei beschädigtem Backup ein älteres Backup verwenden und ein größeres RPO akzeptieren.

## 2. Schlüsselverwaltung

Das Projekt hängt von 5 Schlüsseln ab, alle in `.env` (admin und service jeweils unabhängig, nicht dasselbe Set teilen):

| Variable | Länge | Zweck |
|---|---|---|
| `ENCRYPTION_KEY` | 32 Bytes | API-Übertragungsverschlüsselung (config/encryption.php) |
| `ENCRYPTABLE_KEY` | 32 Bytes | Verschlüsselung sensibler Datenbankfelder (encryptable-Plugin, **nicht mit ENCRYPTION_KEY teilen**) |
| `JWT_SECRET_KEY` | 64+ Zeichen | JWT-Signatur |
| `HASHIDS_SALT` | — | ID-Ver-/Entschlüsselung |
| `HASHIDS_ALT_SALT` | — | Reserve für ID-Ver-/Entschlüsselung |

### 2.1 Schlüssel generieren

```bash
# Gibt 5 KEY=VALUE auf stdout aus, direkt an .env anhängbar
php scripts/gen_env_keys.php

# Direkt in .env schreiben: vorhandene Schlüssel werden nicht überschrieben, nur fehlende ergänzt
php scripts/gen_env_keys.php --file=.env
```

> Wenn ein Schlüssel in .env noch der `change-me`-Platzhalter ist, die Zeile zuerst löschen und dann ausführen (der Platzhalter gilt als „vorhanden" und wird nicht überschrieben).

### 2.2 Schlüsselrotation (encryptable)

```bash
bash scripts/rotate_keys.sh            # Standardmäßig auf .env im aktuellen Verzeichnis
bash scripts/rotate_keys.sh /path/to/service/.env
```

Das Skript erledigt automatisch: .env sichern → neuen `ENCRYPTABLE_KEY` generieren → alten Key an `ENCRYPTION_PREVIOUS_KEYS` anhängen (kommagetrennt, zuletzt rotierter zuerst) → neuen Key schreiben. Danach manuell wie angezeigt: Dienst neu starten → Entschlüsselung verifizieren → nach Bestätigung die Sicherung löschen.

**Hinweis zu `ENCRYPTION_PREVIOUS_KEYS`**: Beim Entschlüsseln versucht encryptable zuerst den aktuellen `ENCRYPTABLE_KEY`, bei Fehlschlag werden die historischen Keys in Listenreihenfolge nacheinander probiert. Daher muss der alte Key **vor dem Wirksamwerden des neuen Keys** in diese Liste aufgenommen werden, sonst sind Altdaten nach dem Neustart nicht entschlüsselbar (Daten gehen nicht verloren, Rollback der .env stellt alles wieder her). Die Liste wächst nur; vor dem Entfernen historischer Keys muss bestätigt sein, dass alle Altdaten neu verschlüsselt wurden.

**Keine automatische Datenmigration**: Nach der Rotation bleiben Altdaten mit dem alten Key verschlüsselt und sind normal les-/schreibbar. Zum Neuschreiben der Bestandsdaten mit dem neuen Key wird separat eine Datenmigrationsaufgabe ausgeführt (tabellenweise lesen → Schreiben löst Neuverschlüsselung aus).

### 2.3 Fail-fast-Startvalidierung

Folgende Konfigurationen werden beim Dienststart geprüft; bei **fehlenden oder noch als `change-me`-Platzhalter vorhandenen** Schlüsseln wird direkt eine `RuntimeException` geworfen und der Start verweigert (verhindert den Produktionsstart mit Platzhalterschlüsseln):

| Konfiguration | Geprüfter Schlüssel |
|---|---|
| `service/config/encryption.php` | `ENCRYPTION_KEY` |
| `service/config/encryptable.php`、`service/config/plugin/erikwang2013/encryptable/app.php` | `ENCRYPTABLE_KEY` |
| `service/config/jwt.php`、`service/config/plugin/erikwang2013/jwt/jwt.php` | `JWT_SECRET_KEY` |

Beispiel für Startfehler: `ENCRYPTABLE_KEY 未配置或仍为占位符，请在 .env 中配置 32 字节随机密钥`.

**Checkliste für den Alltag**:

1. Neue Umgebung bereitstellen: `cp .env.example .env` → `change-me`-Platzhalterzeilen löschen → `php scripts/gen_env_keys.php --file=.env` → Dienst starten und sicherstellen, dass keine Schlüsselfehler auftreten.
2. Routinemäßige Rotation: nach 2.2 ausführen, vierteljährlich genügt (kein Pflichtzyklus; bei Leck sofort rotieren).
3. `.env.bak.*`-Sicherungen enthalten Klartextschlüssel und sind wie Datenbank-Backups zu behandeln (Berechtigung 600, Offsite-Ablage).

## 3. Monitoring-Alarme (Prometheus + Grafana)

Orchestriert in `admin/docker-compose.yml` (drei neue Dienste prometheus / grafana / redis-exporter), alle Konfigurationen unter `admin/deploy/monitoring/`:

```bash
cd admin
docker compose up -d prometheus grafana redis-exporter
# Prometheus: http://host:9090   Grafana: http://host:3000
# Erste Grafana-Anmeldung: admin / ${GRAFANA_ADMIN_PASSWORD} (Standard: change-me-grafana-password)
```

- **Datenquelle**: Grafana konfiguriert beim Start automatisch die Prometheus-Datenquelle (Provisioning); Panels werden in der UI erstellt.
- **Alarmregeln**: `deploy/monitoring/alerts.yml`, abdeckt:
  - `AppDown` (Anwendung nicht erreichbar, entspricht 5xx auf der ganzen Seite) — critical
  - `MysqlDown` / `RedisDown` (Erkennungsfehler auf Anwendungsseite) — critical
  - `ElasticsearchDown` (ES-nativer `/ _prometheus/metrics`-Abruf fehlgeschlagen) + `ElasticsearchHealthYellow` (Cluster nicht grün) — critical/warning
  - `QueueBacklog` (scout-Suchwarteschlange `queues:scout_*` Stau >100 Einträge für 10 Minuten) — warning
- **ES-Passwort-Injektion**: prometheus liest `ELASTIC_PASSWORD` über compose `secrets` (Docker Compose ≥ 2.24 erforderlich); die Konfigurationsdatei schreibt das Passwort nicht fest; ohne Einstellung wird der change-me-Platzhalter verwendet, ES-Abruf-401 löst ElasticsearchDown aus.
- **Regeln neu laden**: nach Änderungen an alerts.yml `curl -X POST localhost:9090/-/reload` (prometheus benötigt `--web.enable-lifecycle`; wenn nicht gesetzt, Container neu starten).
- **Lokale Validierung**: `bash scripts/verify_monitoring.sh` — prüft die YAML-Syntax der Alarmregeln auf admin/service-Seite, ruft `/metrics` beider Enden per curl ab (admin:8787 / service:8788) und prüft die Regel-Ladung von Prometheus (9090/9091); wenn Anwendung/Prometheus nicht laufen, wird der jeweilige Punkt mit SKIP gemeldet und mit exit 0 beendet.

**Status**: admin und service haben beide einen `/metrics`-Endpunkt (MetricsController, ohne Authentifizierung). Die MetricsCollector-Middleware zählt real nach `code="all"|"5xx"` (admin gibt `open_admin_http_requests_total` aus, service `property_service_http_requests_total`); die `Http5xxRatio`-Regel (5xx-Anteil >5% für 10 Minuten) in beiden alerts.yml kann direkt wirken. **Alarm-Real-Test steht nach dem Deployment aus**: Die Regeln sind bereit, wurden aber in der echten Deployment-Umgebung noch nicht ausgelöst verifiziert (abhängig von `verify_monitoring.sh` und dem Prometheus-Go-Live).

## 4. Protokollrotation

- **Container-Protokolle**: alle Dienste in compose haben `json-file` + `max-size 10m / max-file 3` konfiguriert, keine weitere Behandlung nötig.
- **Host-Anwendungsprotokolle** (`runtime/*.log`、`service/workerman.log`): `admin/deploy/logrotate/pmp-app` verwenden:

```bash
sudo cp admin/deploy/logrotate/pmp-app /etc/logrotate.d/pmp-app
# Pfade in der Datei an den tatsächlichen Bereitstellungspfad anpassen; copytruncate ermöglicht Rotation ohne webman-Neustart
sudo logrotate -d /etc/logrotate.d/pmp-app   # Testlauf prüfen
```

Standardmäßig tägliche Rotation, 30 Tage Aufbewahrung, gzip-Kompression.

## 5. Lasttest-Smoke nach dem Deployment

Nach dem Deployment mit k6 einen Smoke-Test der Anmeldekette und der Erreichbarkeit wichtiger Geschäftsschnittstellen durchführen (niedrige Rate, kein Leistungstest). Skript: `scripts/loadtest/smoke.js` (Standard 2 VU、30s, Anmeldung + dashboard, alle unterstützen die Umgebungsvariablen `BASE_URL`/`VUS`/`DURATION`/`TOKEN`).

### 5.1 Lokaler Smoke

```bash
cd /path/to/property-management-platform/scripts/loadtest

# Nur Anmeldekette prüfen (kein Token nötig; 422-Captcha-Fehler/429-Ratenlimit gelten als aktive Verteidigung, also erreichbar)
k6 run -e BASE_URL=http://127.0.0.1:8790 smoke.js

# Mit authentifizierten Geschäftsschnittstellen: auf dem Deployment-Server Test-JWT ausstellen (abhängig von admin/.env und vendor) und übergeben
TOKEN=$(php mint-token.php)
k6 run -e BASE_URL=https://admin.example.com -e TOKEN="$TOKEN" smoke.js

# Eigene Parallelität/Dauer
k6 run -e BASE_URL=https://admin.example.com -e TOKEN="$TOKEN" -e VUS=5 -e DURATION=60s smoke.js
```

Für den vollständigen Lasttest (login + dashboard + fee, drei Skripte) weiterhin `bash scripts/loadtest/run.sh [BASE_URL] [VUS] [DURATION]` verwenden.

### 5.2 CI-Smoke (GitHub Actions manuell ausgelöst)

Auf der Actions-Seite des Repositories → **Loadtest Smoke** → **Run workflow**:

| Eingabe | Pflicht | Beschreibung |
|---|---|---|
| `target_url` | Ja | Adresse der Testumgebung, z. B. `https://admin.example.com` |
| `duration` | Nein | Smoke-Dauer, Standard `30s` |
| `token` | Nein | Lasttest-JWT; leer lassen = nur Anmeldekette prüfen |

Token abrufen (im Wurzelverzeichnis des Repos auf dem Deployment-Server ausführen, benötigt `admin/.env` und `admin/vendor/`):

```bash
php scripts/loadtest/mint-token.php
```

> Hinweis: Das Token ist ein lasttestspezifisches JWT (Standard: erik-Administratorkonto) und erscheint im Klartext in den Workflow-Protokollen — ein dediziertes Lasttest-Konto verwenden; falls in der Produktion nicht exponiert werden soll, den lokalen Smoke aus 5.1 verwenden.
