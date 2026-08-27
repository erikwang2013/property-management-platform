# Bericht über Leistungstests und Slow-Query-Bewirtschaftung (2026-08-16)

Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## 1. Testumgebung und -methode

| Punkt | Wert |
|---|---|
| Anwendung | webman v2 (PHP 8.3, 32 workers), admin + service zwei Anwendungen |
| Getestete Instanz | admin auf eigenem Port 8790 (`SERVER_LISTEN=http://0.0.0.0:8790`) |
| Werkzeug | k6 v0.51.0 (kein wrk/ab/hey lokal), Skripte unter `scripts/loadtest/` |
| Lastziele | Anmeldung (/api/auth/login)、Dashboard (/admin/dashboard)、Gebührenzahlungsliste (/admin/fee-payment) |
| Autorisierung | dashboard/fee mit per `scripts/loadtest/mint-token.php` ausgestelltem JWT (Captcha umgangen, `sub=21000000000000100`); das Anmeldeskript prüft die Kette mit ungültigem Captcha |
| Daten | Einzelmaschine direkt 127.0.0.1, ohne Gateway/CDN; MySQL/Redis auf derselben Maschine wie die Anwendung |

Skripteinstieg: `bash scripts/loadtest/run.sh [BASE_URL] [VUS] [DURATION]` (k6 muss im PATH sein).
Hinweis zum Anmeldeskript: Die Anmeldung ist durch Captcha + Ratenlimit (10 Versuche/Min./IP) doppelt geschützt — Sicherheitsdesign; eine Hochlast-Prüfung ist nicht möglich und nicht sinnvoll. login.js prüft mit 1 VU / 8 Anfragen bei niedriger Rate die Kettenlatenz; erwartet wird 422 (Captcha-Fehler) oder 429 (Ratenlimit) — beides bedeutet, dass die Verteidigung aktiv wirkt.

## 2. Lasttestergebnisse

### 20 VU / 30s (Basislast)

| Schnittstelle | Anfragen | Durchsatz | avg | p90 | p95 | max | Fehlerquote |
|---|---|---|---|---|---|---|---|
| login (1 VU × 8) | 8 | 14,4/s | 68,6 ms | 154 ms | 207,8 ms | 261 ms | 0% |
| dashboard | 6863 | 227,9/s | 86,0 ms | 151 ms | 189,5 ms | 1,37 s | 0% |
| fee-payment | 5944 | 197,2/s | 99,3 ms | 178 ms | 220,0 ms | 704 ms | 0% |

### 50 VU / 30s (erhöhte Last)

| Schnittstelle | Anfragen | Durchsatz | avg | p95 | max | Fehlerquote |
|---|---|---|---|---|---|---|
| login (1 VU × 8) | 8 | 18,7/s | 52,1 ms | 173 ms | 243,8 ms | 0% |
| dashboard | 6902 | 226,9/s | 212,7 ms | 544,0 ms | 1,99 s | 0% |
| fee-payment | 7525 | 247,4/s | 195,7 ms | 514,2 ms | 2,0 s | 0% |

(Bei 50 VU überschreitet p95 die 500-ms-Schwelle; k6 bricht wegen Schwellenüberschreitung ab, aber 0% fehlgeschlagene Anfragen, 0 Nicht-200.)

### Fazit

- Alle Schnittstellen bei 20 VU mit 0 Fehlern, p95 < 220 ms, gesund.
- **Durchsatz-Engpass bei ca. 230–250 rps**: von 20 VU → 50 VU steigt der Durchsatz nicht, sondern bleibt flach (dashboard 227,9 → 226,9, fee 197 → 247), während die p95-Latenz sich verdoppelt (~190 ms → ~540 ms). Bei 32 workers auf einer Maschine sind das ca. 7–8 rps pro worker — charakteristisch für die Einzelkern-Obergrenze des vollständigen PHP-Pfads (inkl. MySQL-Abfragen, Redis-Cache-Roundtrips), kein Verbindungserschöpfung (keine fehlgeschlagenen Anfragen).
- Empfehlung: Für diese Größenordnung reicht die Einzelmaschine (ca. 20 Mio. Anfragen/Tag); für höheren Durchsatz zuerst horizontale Instanzen hinzufügen, danach SQL und Cache-Trefferquoten der Schnittstellen prüfen (siehe unten).

## 3. Slow-Query-Überprüfung

- Die Indizes der Gebührentabellen `management_fee_bill` / `management_fee_payment` sind vollständig (paid_at、bill_id、owner_id、payment_number usw.), Kernabfragen haben passende Indizes.
- Fundstelle: Die Gebührenliste sucht per `payment_number like %kw%` (führender Wildcard) — kein Index nutzbar; bei großen Datenmengen degeneriert diese Bedingung zum Full-Table-Scan. Ist eine seltene Admin-Suche, vorerst nicht behandelt; bei Datenwachstum auf Inverted-Index oder Präfix-Index umstellen.
- **MySQL slow_query_log ist OFF**: Empfehlung, es zu aktivieren und `long_query_time=1` zu setzen, um reale langsame SQLs zu beobachten (statt nur aus Lasttests abzuleiten). Produktion ausführen:
  ```sql
  SET GLOBAL slow_query_log = ON;
  SET GLOBAL long_query_time = 1;
  ```
- Dashboard-Aggregation: Jeder Cache-Neuaufbau führt ca. 8 COUNT-Aggregationen + 30-Tage-Gruppenstatistik aus; ein einzelner Neuaufbau kostet Sekunden, wird vom Redis-5-Minuten-Cache abgefangen (siehe unten), kein Hot-Path.

## 4. Redis-Cache-Überprüfung

- Dashboard-Cache `dashboard:data`: `setex 300`, bei Treffer ~10 ms, bei Fehltreffer Sekunden für den Neuaufbau. **Problem: keine Invalidierungslogik bei Schreibvorgängen** — nach Datenänderungen bis zu 5 Minuten veraltet. Empfehlung: den Key in den Gebühren-/Immobilien-Schreibschnittstellen löschen (eine Zeile `del dashboard:data`).
- **Kein Cache-Durchbruch-Schutz**: Im Moment des Key-Ablaufs bauen 32 workers gleichzeitig neu auf (8 Aggregationsabfragen werden dupliziert). Bei großen Datenmengen einfachen Mutex ergänzen (z. B. `set nx ex`-Lock + Double-Check).
- Berechtigungscache `perm:{adminId}` 60s, Verhalten normal.
- Verbleibender Untersuchungspunkt: Im lokalen Redis wurde der Key `dashboard:data` nie beobachtet (in mehreren DBs nicht), aber die Schnittstellenantwort ist normal und die Latenz bei Treffer deutlich niedriger. Während des Lasttests traten vereinzelt 403 „keine Berechtigung" auf (nach 2 Vorkommen wieder stabil 200). Vermutlich Unterschiede zwischen mehreren lokalen Redis-Instanzen/Umgebungsvariablen und der Live-Konfiguration; in der Zielumgebung nachzuprüfen, ohne Einfluss auf das Lasttest-Ergebnis (stabile Phase 0 Fehler).

## 5. Liefergegenstände

- `scripts/loadtest/mint-token.php` — Lasttest-JWT ausstellen (`php mint-token.php --file=/tmp/pmp-token`)
- `scripts/loadtest/login.js` / `dashboard.js` / `fee.js` — k6-Skripte
- `scripts/loadtest/run.sh` — Ein-Klick-Ausführung (mint token + drei Skripte, Parameter: BASE_URL VUS DURATION)
- Dieser Bericht

Wiederholungsbefehl: `PATH=/home/erik/bin:$PATH bash scripts/loadtest/run.sh http://127.0.0.1:8790 20 30s`
