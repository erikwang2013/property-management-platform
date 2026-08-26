# Handbuch für die Datenbank-Wiederherstellungsübung (Recovery Runbook)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> Gültig für: property-management-platform (admin-Seite + service-Seite, MySQL 8.0)
> In Verbindung mit [OPS_RUNBOOK.md](OPS_RUNBOOK.md) Abschnitt 1 lesen: Backuperstellung, crontab, RPO/RTO siehe OPS_RUNBOOK; dieses Dokument behandelt nur „wie wiederherstellen, wie verifizieren".

## 0. Ziel

- **Übungsziel: eine vollständige Wiederherstellungsübung in 30 Minuten abschließen** (Wiederherstellung + Validierung), mindestens vierteljährlich.
- Mit dem neuesten Backup kann jederzeit in eine leere Datenbank oder zu einem bestimmten Zeitpunkt wiederhergestellt werden.

Voraussetzungen:

- Backup-Datei verfügbar: `scripts/backup.sh` läuft per cron (siehe OPS_RUNBOOK 1.2).
- Die Zielumgebung für die Wiederherstellung (Übungsmaschine oder Produktion) ist zur Produktion gleichartig: dasselbe docker-compose, gleiche MySQL-8.0-Version.
- Vor der Wiederherstellung bestätigen: `gzip -t <Backupdatei>` besteht; freier Speicherplatz ≥ 2× Backup-Größe.

## 1. Szenario A: Wiederherstellung in eine leere Datenbank (am häufigsten, Standard-Übungsszenario)

Ziel: Das Backup in eine komplett neue leere Datenbank importieren und die Datenverfügbarkeit verifizieren.

```bash
cd /path/to/property-management-platform

# 1) Neuestes Backup auswählen
ls -lt backups/backup_*.sql.gz | head

# 2) Integritätsprüfung (bei Fehlschlag älteres Backup verwenden)
gzip -t backups/backup_20260816_020000.sql.gz && echo OK

# 3) Sicherstellen, dass der Zielcontainer läuft
docker compose -f admin/docker-compose.yml ps mysql

# 4) Leere Datenbank anlegen (Übungsdatenbank mit _drill-Suffix, um versehentliches Überschreiben von Produktionsdaten zu vermeiden)
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot -e "CREATE DATABASE IF NOT EXISTS property_management_drill DEFAULT CHARACTER SET utf8mb4;"'

# 5) Importieren (-T deaktiviert TTY, nicht-interaktiv; gemessen ca. 1-5 Minuten)
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot --default-character-set=utf8mb4 property_management_drill' \
  < backups/backup_20260816_020000.sql.gz
```

> Hinweis zu Zugangsdaten: `MYSQL_PWD` aus `DB_PASSWORD` in `admin/.env`; in der Produktion darf das Passwort nicht im Klartext in der Shell-Historie erscheinen — stattdessen `--env-file admin/.env` oder Umgebungsvariablen-Injektion verwenden. Die Beispiele dieses Handbuchs sind Übungsumgebungs-Werte.

## 2. Szenario B: Wiederherstellung zu einem bestimmten Zeitpunkt (binlog-Replay)

Voraussetzung: MySQL 8 aktiviert binlog standardmäßig (`log_bin=ON`); die Inkremente nach dem Backup-Zeitpunkt liegen alle im binlog. Datenverlust ≤ letztes Backup + binlog-Aufbewahrungszeitraum (Standard `binlog_expire_logs_seconds=2592000`, 30 Tage).

Vorgehen: Vollwiederherstellung → binlog-Startpunkt finden → mit `mysqlbinlog` bis zum Zielzeitpunkt replayen.

```bash
# 1) binlog-Aktivierung bestätigen, Logdateien auflisten
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot -e "SHOW VARIABLES LIKE \"log_bin\"; SHOW BINARY LOGS;"'

# 2) Vollwiederherstellung (wie Szenario A Schritte 4-5, in leere Datenbank)

# 3) binlog-Startpunkt des Backups finden: im Backup aufgezeichnete Position (bei --master-data=2)
#    Dieses Skript nutzt kein --master-data; als Startpunkt dient die „Backup-Startzeit", Abweichung innerhalb der Backup-Dauer.
#    binlog bis zum Zielzeitpunkt replayen (Beispiel: Wiederherstellung bis 2026-08-16 10:30:00)
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysqlbinlog --stop-datetime="2026-08-16 10:30:00" /var/lib/mysql/binlog.000012 | mysql -uroot property_management_drill'
```

Wichtige Punkte:

- Der binlog liegt im Container unter `/var/lib/mysql/binlog.0000NN`; aus der Ausgabe von `SHOW BINARY LOGS` zuordnen.
- Nur den binlog „nach der Backup-Startzeit" replayen; nach dem Replay sofort verifizieren (siehe Abschnitt 3) und bestätigen, dass `max(updated_at)` den Erwartungen entspricht.
- Wiederherstellung nach Fehlbedienung mit Sekundengenauigkeit: zuerst die Fehlbedienungs-Anweisung lokalisieren `mysqlbinlog /var/lib/mysql/binlog.0000NN | grep -n "Fehlbedienungs-Schlüsselwort"`, dann über `--stop-datetime` oder `--stop-position` entscheiden.

## 3. Datenkonsistenzvalidierung (nach der Wiederherstellung Pflicht)

| Prüfpunkt | Befehl | Bestehenskriterium |
|---|---|---|
| Integrität der Backup-Datei | `gzip -t <Backup>` | keine Fehler |
| Zeilenzahl der Schlüsseltabellen | `SELECT COUNT(*) FROM erik_admin_user;` | stimmt mit den vor dem Backup erfassten Zeilenzahlen überein |
| Stichprobe der Geschäftstabellen | `SELECT COUNT(*) FROM erik_owner;`、`erik_tenant`、`erik_fee_bill`、`erik_repair_order` | mindestens drei mit plausibler Größenordnung (nicht 0 und identisch mit dem Stand vor dem Backup) |
| Verschlüsselte Felder entschlüsselbar | einen Datensatz mit encryptable-Feldern abfragen (z. B. `erik_owner` Personalausweis/Telefonnummer) | Wert korrekt, keine decrypt-Fehler in den Anwendungsprotokollen |
| Geschäfts-Smoke-Test | Anmeldung und Listen-Schnittstelle je 1× | 200 / normale Rückgabe |

Beispiel für das Stichprobenskript (Übungsumgebung):

```bash
docker compose -f admin/docker-compose.yml exec -T -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot property_management_drill -e "
    SELECT (SELECT COUNT(*) FROM erik_admin_user) AS users,
           (SELECT COUNT(*) FROM erik_owner) AS owners,
           (SELECT COUNT(*) FROM erik_tenant) AS tenants,
           (SELECT COUNT(*) FROM erik_fee_bill) AS fee_bills,
           (SELECT COUNT(*) FROM erik_repair_order) AS repair_orders;"'
```

> Zeilenzahl-Konsistenz: vor dem Backup mit derselben SQL eine Baseline aufzeichnen, nach der Wiederherstellung vergleichen; die Baseline bei der Übung ins Übungsprotokoll schreiben.

## 4. 30-Minuten-Übungszeitplan

| Zeit | Aktion | Verantwortlich |
|---|---|---|
| 0-5 min | Backup auswählen、`gzip -t`、leere Datenbank anlegen、Baseline-Zeilenzahlen aufzeichnen | Betrieb |
| 5-15 min | Szenario-A-Wiederherstellung und Import | Betrieb |
| 15-25 min | Konsistenzvalidierung aus Abschnitt 3 + Geschäfts-Smoke | Betrieb + Fachbereich |
| 25-30 min | Ergebnisse protokollieren、Übungsdatenbank aufräumen（`DROP DATABASE property_management_drill`）、gemessenes RTO in OPS_RUNBOOK 1.4 aktualisieren | Betrieb |

## 5. Fehlerbehandlung

| Symptom | Behandlung |
|---|---|
| `gzip -t` fehlgeschlagen | Backup beschädigt, älteres Backup verwenden, größeres RPO akzeptieren und den Backup-cron prüfen |
| Importfehler (Zeichensatz/Berechtigungen) | sicherstellen, dass `--default-character-set=utf8mb4` und der Zeichensatz der leeren Datenbank übereinstimmen; sicherstellen, dass der Benutzer Tabellen anlegen darf |
| Zeilenzahl weicht von der Baseline ab | Übung sofort stoppen, prüfen ob falsche Datenbank/falsche Datei importiert wurde; im Produktionswiederherstellungsfall weiter untersuchen und die Anwendung zurücksetzen |
| Daten nach binlog-Replay weiterhin fehlen | prüfen, ob `--stop-datetime` später als die Backup-Startzeit liegt; sicherstellen, dass das Replay mit dem ersten binlog nach dem Backup beginnt |

## 6. Übungsprotokollvorlage

```text
日期: 2026-08-16
恢复目标: 空库（场景 A）/ 时间点（场景 B）
备份文件: backups/backup_20260816_020000.sql.gz
基线行数: erik_admin_user=1, erik_owner=42, erik_fee_bill=128
恢复耗时: XX 分钟    验证耗时: XX 分钟    总计: XX 分钟（目标 ≤ 30）
结果: 通过 / 失败（附失败原因与处理）
```
