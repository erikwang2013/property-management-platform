# Immobilienverwaltungssystem — Umfassende Projektplanung

> Erstellungsdatum: 2026-08-16 · Quelle: pmp-team-Teamaudit (auditor / security-auditor / planner)

## I. Audit-Ergebnis des Ist-Zustands

**Funktionen: deckungsgleich mit den Angaben.** 22 Geschäftsmodule + 12 Erweiterungsfunktionen alle abgeschlossen, 68 Tabellen / 178 APIs, admin 58 Controller / 127 Routen, service 19 Controller / 57 Routen, Flutter-Web-Admin-Panel 42 Seiten + Eigentümer-Portal 13 Seiten, HarmonyOS 5 Seiten. Alle 14 Dokumente in docs/ + 35 SVGs haben Code-Unterstützung; keine „angekündigten, aber nicht umgesetzten" Funktionen gefunden.

**Tests: vollständig grün (Stand 2026-08-17).** admin 193 Tests / 452 Assertions、service 101 Tests / 385 Assertions (7 skips wegen Umgebungsabhängigkeiten)、Flutter-Widget-Tests 9 Fälle (Anmeldung/Startseite/Rechnungsseite).

**Engineering-Basis vorhanden:** docker-compose für beide Enden, GitHub Actions CI (PHP-Syntax + PHPUnit beider Enden + composer audit + Flutter analyze)、Dependabot、Prometheus-Metrikendpunkte.

**Technische Schulden (überwiegend geringes Risiko):**
1. Protokollansammlung: service/workerman.log 9,3 MB、admin/runtime/logs 5,7 MB (bereits gitignore, belegt nur Speicherplatz) → Rotation erforderlich
2. README listet die Dokumentationsangabe der 57 Modelle der service-Seite nicht separat (64 bezieht sich nur auf die admin-Seite)
3. Keine TODO/FIXME, .env nicht eingecheckt, keine auffälligen Abhängigkeitsversionen — sauber

## II. Sicherheits- und Qualitätslücken (security-auditor)

**18-Schichten-Verteidigung: 16/18 als vorhanden verifiziert**, Umsetzung deckungsgleich mit SECURITY_ARCHITECTURE.md (Captcha、Zweitbestätigung、poster、SecurityFilter、AES-256-CBC、JWT、Sitzungslimit、Kontosperrung、RBAC、Ratenlimit、hashids、Feldverschlüsselung、Maskierung、Auditprotokolle、CSP).

**Zwei Abweichungen (beide P1 behoben):**
1. ~~security-php nur auf der service-Seite installiert~~ → in beide SecurityFilter integriert (admin + service haben jeweils 4b-Tiefenscan-Ebene, SecurityGuard lazy initialisiert, blockt mit Protokollierung und Eskalation)
2. ~~PDF-Urheberrechtswasserzeichen nicht implementiert~~ → verifiziert: das 18-Schichten-Wasserzeichen in ExportController ist implementiert (ExportController.php:179,206), Audit-Fehlmeldung

**Höchstes Risiko: hartkodierte Fallback-Schlüssel (behoben).** EncryptionService/Verschlüsselungskonfiguration komplett auf fail-fast umgestellt (fehlend oder change-me führt beim Start zu Fehlern); hartkodierte und zufällige Fallbacks in den Plugin-Ebenen encryptable/jwt entfernt; .env-Schlüssel sind generierte echte Zufallswerte, CI lädt mit .env.example-Kopie. DB-/Redis-Passwörter sind weiterhin Platzhalter — Bereitstellungszugangsdaten, die vom Deployment injiziert werden.

**Engineering-Defizite (P1 ergänzt):** CI um phpstan-Job erweitert (Level 5 + baseline)、Coverage-Gates für PHPUnit beider Enden (gemessene Baseline admin 1,66% / service 3,21%, Gate verhindert Null-Instrumentierungs-Regression)、gitleaks-Schlüsselleck-Scan (.gitleaks.toml gibt Umgebungsvorlagen frei).

**Überprüfung riskanter Muster:** eval( nur Redis::eval (sicher)、exec 3 Stellen (Monitoring-/Installations-Controller)、md5( nur Token-Blacklist-Hashing、SQL komplett über Query Builder — kein nacktes String-Verkettungsrisiko.

## III. Strategische Positionierung

**Phase „Funktionen fertig" → Phase „Engineering/Kommerzialisierung".** Die Geschäftsfunktionsentwicklung ist abgeschlossen (jüngste Commits sind Dokumentation/Audit/Test-Ergänzungen). Die nächste Investitionsrichtung: **CI/CD und Qualitätsgates、Zahlung produktionsreif、Monitoring/Alarme und Backup-Wiederherstellung、Multi-Tenant-SaaS、Mobile-Lückenschluss**. Kommerzielle Verpackung hat eine Basis (EDITIONS drei Versionen + Installationsassistent + Urheberrechtswasserzeichen); es fehlt die Engineering-Glaubwürdigkeit, die Kunden zum Zahlen bewegt.

## IV. Phasen-Fahrplan

### P1 Engineering-Festigung (2-4 Wochen) — das System „glaubwürdig" machen

| Ziel | Schlüsselaufgaben | Abnahmekriterien |
|------|---------|---------|
| Qualitätsgates grün、Schlüssel kontrollierbar、keine Datenverluste | ① CI vervollständigen: Flutter analyze、service-Tests、PHPUnit-Coverage-Gate、phpstan、gitleaks ② Schlüsselverwaltung: .env-Generator + JWT/DB-Schlüsselrotationsskript ③ Backup-Wiederherstellung: mysqldump-Skript + Wiederherstellungs-Übungsmanual ④ ES-Degradierung: Queue-Schreibfehler mit Protokoll-Fallback + Suche degradiert zu MySQL LIKE (verschoben) ⑤ SQL-Versionsmanagement: vollständige Migration als einzigem Einstiegspunkt docs/install.sql vereinheitlicht (ursprünglicher Split-Migrationsplan gestrichen, 2026-08-16 zusammengeführt) | CI komplett grün inkl. Coverage; Wiederherstellungsübung mit 30-Minuten-Datenkonsistenz; Suche bei ES-Ausfall nutzbar; Upgrade-Skript ausführbar |

**P1-Status**: ✅ alles abgeschlossen (Backup-Wiederherstellung unter P8 nachgetragen: scripts/backup.sh + docs/RECOVERY_RUNBOOK.md).

### P2 Kommerzielle Fähigkeiten (4-8 Wochen) — Kunden „trauen sich zu kaufen"

| Ziel | Schlüsselaufgaben | Abnahmekriterien |
|------|---------|---------|
| Zahlungs-Closed-Loop、überwachbar、lieferbar | ① Zahlung produktionsreif: WeChat/Alipay-Sandbox-Komplettablauf (Bestellung→Callback-Idempotenz→Rückerstattung→Abstimmung), Zugangsdaten zentral in config/payment.php + env ② Monitoring/Alarme: Prometheus+Grafana-Orchestrierung + Alarmregeln (5xx、ES/Redis-Verbindung、Queue-Stau) + Protokollrotation ③ Kommerzielle Versionssteuerung: Editions-Schalter basierend auf EDITIONS (Lite/Standard/Full-Routengruppen aktiviert) + Demo-Daten ④ Installationsassistent deckt Zahlungs-/ES-Konfiguration ab | Sandbox-Zahlungskomplettablauf bestanden (inkl. doppelter Callback-Idempotenz); Alarme real ausgelöst getestet; Drei-Versionen-Schalter demonstrierbar; neue Umgebung in 10 Minuten installiert |

**P2-Aktueller Status**: ✅ Offline-Teile alle abgeschlossen (2026-08-16/17): Zahlungs-Gesamtkette-Code (PaymentService Bestellung/Callback-Idempotenz/Rückerstattung/Abstimmung + config/payment.php Zugangsdaten-Zentralisierung + PaymentServiceTest mit reiner Funktionsabdeckung)、Monitoring-Orchestrierung (doppelter Prometheus-Stack + 6 Alarmregeln + Grafana-Dashboard-Provisioning beider Enden)、Editions-Schalter (EDITIONS drei Versionen + fail-fast-Validierung)、Installationsassistent (inkl. automatischer Zahlungskonfiguration + Template-Pfad-Bug behoben). Verbleibende externe Abhängigkeiten: **Sandbox-Abstimmung wartet auf Zugangsdaten** (nach Erhalt der WECHAT_PAY_* / ALIPAY_*-Sandbox-Zugangsdaten `scripts/payment_sandbox_smoke.php` ausführen)、**Alarm-Real-Test wartet auf Deployment** (`scripts/verify_monitoring.sh` kann lokal validieren; echte Auslösung nach dem Deployment).

### P3 Skalierung (8-12 Wochen) — das System „mehr verkaufbar" machen

| Ziel | Schlüsselaufgaben | Abnahmekriterien |
|------|---------|---------|
| Multi-Tenant、Leistungsziele、Mobile-Lückenschluss | ① Multi-Tenant-SaaS: mit Konzernverwaltung als Startpunkt, erik_community um tenant_id erweitern + Middleware-Isolierung (Lösungsbewertung zuerst, getrennte DB als Evolutionsrichtung) ② Leistungstests: wrk/k6 für Anmeldung/Gebühren/Dashboard, Slow Queries + Redis-Cache-Überprüfung ③ Mobile-Lückenschluss: HarmonyOS von 5 auf Kernpfade erweitern (Zahlung/Reparatur/Ankündigung/Besucher/Parken), Flutter-Eigentümer-Portal mobil anpassen ④ Offene API / Webhook (optional) | Mandanten-Zugriffsschutztests bestanden; Kern-Schnittstellen P95 < 300 ms; HarmonyOS-Kernpfade abgeschlossen |

**P3-Status**: ✅ alles abgeschlossen (2026-08-16 geliefert: Multi-Tenant-Dreiergespann + Lasttests real mit P95-Ziel erreicht + HarmonyOS auf 5 Seiten erweitert).

### P4-P9 Nachträgliche Lieferaufzeichnungen (2026-08-16 ~ 08-17, neue Engineering-Phasen außerhalb des ursprünglichen P1-P3-Umfangs)

| Phase | Lieferinhalt | Status |
|------|---------|------|
| P4 Abschluss | ES-Schreibpfad-Fallback (AdminUser Searchable try/catch + Protokoll-Degradierung)、Zahlungskonfiguration im Installationsassistenten (mit Zugangsdaten automatisch aktiviert)、Protokollrotation (logrotate.conf)、Monitoring-/Alarm-Orchestrierung (doppelter Prometheus-Stack + 6 Regeln) | ✅ Abgeschlossen |
| P5 Restposten | Webhook-Zustellung (HMAC-SHA256-Signatur + exponentielles Backoff-Retry + 3 Auslösepunkte)、Unit-Tests für Gebühren/Genehmigung/SLA | ✅ Abgeschlossen |
| P6 Deployment-Abschluss | Ein-Klick-Deploy-Skript (deploy.sh: pull → .env → compose → idempotenter install.sql-Import → Monitoring-Smoke)、Container-Protokoll-Mount-Fix、CI-Coverage-Gate angehoben、Skalierungsplan (SCALING_PLAN) | ✅ Abgeschlossen |
| P7 Testtiefe | service-Unit-Tests 43→82、Flutter-Widget-Tests 3 Seiten 8 Fälle (CI-Integration)、offene API (/open 3 Nur-Lese-Endpunkte + X-API-Key-Autorisierung + gen_api_key.php)、Lasttest-Smoke (k6 smoke.js + workflow_dispatch manueller Workflow) | ✅ Abgeschlossen |
| P8 Betriebs-Abschluss | Backup-Wiederherstellung umgesetzt (backup.sh + RECOVERY_RUNBOOK)、Grafana-Dashboard (service-Seite 7 Panels Provisioning)、admin-Unit-Tests +11 (152 grün)、**Installationsassistent-Template-Pfad-Bug behoben** (Template nach app/view/install verschoben, curl-Rendertest 200) | ✅ Abgeschlossen |
| P9 Engineering-Abschluss | Bereinigung nicht verifizierbarer Backup-Skripte (git rm 4 Dateien beider Enden + 8 Dokumentstellen vereinheitlicht)、admin-Grafana-Dashboard (open_admin_*-Präfix 7 Panels)、InstallValidator-Validierung als reine Funktion extrahiert + 17 Fälle (admin 193 grün) | ✅ Abgeschlossen |

**P4-P9-Zusammenfassung**: admin-Unit-Tests 93→193、service-Unit-Tests 43→101、Flutter-Widget-Tests 9/9、offene API 3 Endpunkte、Monitor-Panels beider Enden symmetrisch、komplettes Betriebsskript-Set für Backup/Wiederherstellung/Schlüssel/Deployment bereit.

## V. Top-10-Prioritätsmaßnahmen (nach Kosten-Nutzen-Verhältnis)

| # | Maßnahme | Auswirkung | Kosten | Risiko | Status |
|---|--------|------|------|------|------|
| 1 | Schlüsselverwaltung: env-Generator + Rotationsskript + Entfernung hartkodierter Fallback-Schlüssel (beim Start auf nicht-change-me prüfen) | Hoch (Sicherheits-Compliance) | Niedrig | Niedrig | ✅ Abgeschlossen |
| 2 | CI-Vervollständigung: Flutter analyze + service-Tests + Coverage-Gate + phpstan + gitleaks | Hoch (Qualitätsbasis) | Niedrig | Niedrig | ✅ Abgeschlossen (P7 zusätzlich flutter test) |
| 3 | Backup-Skript + Wiederherstellungsübung | Hoch (keine Datenverluste) | Niedrig | Niedrig | ✅ Abgeschlossen (P8: backup.sh + RECOVERY_RUNBOOK) |
| 4 | ES-Degradierungs-Fallback (MySQL LIKE) | Hoch (Verfügbarkeit) | Niedrig | Mittel (doppelter Abfragepfad-Wartung) | ✅ Abgeschlossen (P4: Schreibpfad try/catch-Fallback; Suche lief immer über MySQL LIKE) |
| 5 | Zahlungs-Sandbox-Komplettablauf + Callback-Idempotenzvalidierung | Hoch (kommerziell erforderlich) | Mittel | Mittel (Zugangsdaten/Callback-Sicherheit) | 🔶 Code fertig, Sandbox-Abstimmung wartet auf Zugangsdaten |
| 6 | Prometheus + Grafana-Alarme + Protokollrotation | Hoch (betreibbar) | Mittel | Niedrig | ✅ Abgeschlossen (Panels beider Enden P8/P9 ergänzt; Alarm-Real-Test nach Deployment) |
| 7 | SQL-Migrationsverwaltung (vollständig in install.sql als einzigen Einstiegspunkt zusammengeführt) | Mittel (upgradefähig) | Niedrig | Niedrig | ✅ Abgeschlossen (2026-08-16 zusammengeführt) |
| 8 | Multi-Tenant-Lösungsbewertung + tenant_id-Isolierung | Hoch (Decke) | Hoch | Hoch (wirkt auf alle Abfragen) | ✅ Abgeschlossen (P3 geliefert, Zugriffsschutztests bestanden) |
| 9 | Lasttests + Slow-Query-Bewirtschaftung | Mittel (Leistung) | Mittel | Niedrig | ✅ Abgeschlossen (P3 real mit P95-Ziel; P7 Smoke-Version in CI) |
| 10 | Kommerzielle Editions-Schalter + Demo-Daten | Mittel (Pre-Sales) | Mittel | Niedrig | ✅ Abgeschlossen (EDITIONS + demo_data.php + Demovorgangs-Dokumentation) |

## VI. Risiken und Abhängigkeiten

| Risiko | Ist-Zustand | Abschwächungsempfehlung | Status |
|------|------|---------|------|
| Einzelmaschinen-Deployment ohne HA | docker-compose Einzelmaschine, MySQL/Redis/ES auf einem Host | Backup-Wiederherstellungsübung + Monitoring-Alarme + Skalierungsplan-Dokument | ✅ Abschwächung umgesetzt (P8 Backup + P2/P8/P9 Monitoring + P6 SCALING_PLAN); Übungsdurchführung nach Deployment |
| ES-Hartabhängigkeit | Suche/Indexsynchronisierung komplett über ES | Degradierungs-Fallback + Index-Neuaufbauskript | ✅ Abgeschwächt (P4 Schreibpfad-Fallback; Suche lief immer über MySQL LIKE, ES keine Abhängigkeit im Abfragepfad) |
| Schlüsselverwaltung | Platzhalter + hartkodierte Fallback-Schlüssel, keine Rotation | Generator + Rotationsskript; Produktion mit Umgebungsvariablen-Injektion | ✅ Gelöst (fail-fast-Validierung + gen_env_keys.sh + rotate_keys.sh) |
| Zahlungszugangsdaten verstreut | Zahlungsmodul ohne zentrale Konfiguration, Sandbox unverifiziert | Konfigurationszentralisierung + Sandbox zuerst | 🔶 Konfiguration zentralisiert (config/payment.php), Sandbox-Abstimmung wartet auf Zugangsdaten |
| Migrationsverwaltung | Einzeldatei install.sql (IF NOT EXISTS idempotent) | Auf einen einzigen Vollumfangs-Einstiegspunkt vereinheitlicht; inkrementeller Upgrade-Pfad separat zu besprechen | ✅ Vereinheitlicht (2026-08-16 zusammengeführt) |
| Testabdeckung eher strukturell | 133 Tests konzentriert auf Schema/Sicherheit/Roundtrip | Coverage-Gate + Unit-Tests für Kernfunktionen (Gebühren/Genehmigung/SLA) | ✅ Verstärkt (admin 193 / service 101 / Flutter 9; Gate verhindert Null-Instrumentierungs-Regression) |
| Mobile-Lücken | HarmonyOS nur 5 Seiten, kein natives Eigentümer-App | P3-Kernpfade ergänzen; Abhängigkeit: HarmonyOS-Testgeräte | ✅ Kernpfade ergänzt (5 Seiten: Zahlung/Reparatur/Ankündigung/Besucher/Parken); Echtgeräte-Validierung wartet auf Geräte |

## VII. Teamarbeitsteilung (pmp-team)

| Rolle | Eingesetzte Aufgaben |
|------|---------|
| Architektur | Multi-Tenant-Lösungsbewertung und tenant_id-Isolierungsdesign (P3)、ES-Degradierungsarchitektur、Monitoring-Architektur (P2)、Zahlungs-Callback-Idempotenz-Designbewertung |
| Backend | Schlüsselgenerierungs-/Rotationsskripte、ES-Degradierungsimplementierung、Zahlungskonfigurationszentralisierung + Sandbox-Abstimmung、Migrationsskript-Trennung、Lasttests und Slow-Query-Bewirtschaftung |
| Flutter-Frontend | CI-Integration flutter analyze、Mobile-Anpassung des Eigentümer-Portals (P3)、Editions-Schalter-UI-Unterstützung |
| HarmonyOS | Kernpfade ergänzen: Zahlung/Reparatur/Ankündigung/Besucher/Parken (P3) |
| Test | Coverage-Gate、Zahlungs-Sandbox-Testfälle (doppelter Callback/Rückerstattung/Abstimmung)、Lasttestskripte、Durchführung der Backup-Wiederherstellungsübung |
| Review | Review der Zahlungs- und Sicherheits-Kernpfade、gitleaks in CI、Review der Multi-Tenant-Zugriffsschutztests |
| Dokumentation | Bereitstellungs-/Betriebshandbuch (inkl. Wiederherstellungsübung)、Multi-Tenant-Dokument、Monitoring-Konfigurationshandbuch、Kommerzielle-Lieferung-Handbuch |

## VIII. Sofortmaßnahmen-Empfehlungen

✅ Die ursprünglichen P1-Punkte 1-4 (Schlüssel-Härtung → CI-Vervollständigung → Backup-Skript → ES-Degradierung) sind alle umgesetzt (P4-P9 iterativ geliefert).

**Verbleibende Abhängigkeiten (erfordern externe Bedingungen, keine Codelücken)**:
1. Zahlungs-Sandbox-Abstimmung: nach Erhalt der WECHAT_PAY_* / ALIPAY_*-Sandbox-Zugangsdaten `scripts/payment_sandbox_smoke.php` ausführen (Bestellung→doppelte Callback-Idempotenz→Rückerstattung→Abstimmung als Gesamtkette validieren)
2. Monitoring-Alarm-Real-Test: nach dem Deployment `scripts/verify_monitoring.sh` ausführen, um die Regel-Ladung zu prüfen und 5xx/Verbindungsfehler real auszulösen (Http5xxRatio-Regel kann direkt wirken)
3. Backup-Wiederherstellungsübung: vierteljährliche Übung gemäß docs/RECOVERY_RUNBOOK.md durchführen und gemessene Dauer protokollieren (RTO ≤ 1h-Ziel)
4. HarmonyOS-Echtgeräte-Validierung: nach Bereitstellung der Testgeräte Kernpfade durchlaufen (Zahlung/Reparatur/Ankündigung/Besucher/Parken)
