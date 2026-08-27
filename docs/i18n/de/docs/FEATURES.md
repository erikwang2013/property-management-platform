# Funktionsdokument (Features)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## Funktionsliste

| Nr. | Modul | Charge | Admin-Panel | Eigentümer-Portal | Datenbanktabellen |
|------|------|---------|---------|--------|--------|
| 1 | Wohnanlagenverwaltung | 1. Charge | CRUD + Suche/Paginierung | Gebundene Wohnanlage ansehen | management_community |
| 2 | Gebäudeverwaltung | 1. Charge | CRUD + Filter nach Wohnanlage | - | management_building |
| 3 | Einheitenverwaltung | 1. Charge | CRUD + Filter nach Gebäude | - | management_unit |
| 4 | Wohntypverwaltung | 1. Charge | CRUD | - | management_room_type |
| 5 | Immobilienverwaltung | 1. Charge | CRUD + Immobilienbaum + Massenbindung von Eigentümern | Meine Immobilien Liste/Details | management_room |
| 6 | Eigentümerverwaltung | 1. Charge | CRUD + Massenimport/Aktivieren-Deaktivieren/Löschen | Registrierung/Anmeldung/Persönliche Daten | management_owner, management_room_owner |
| 7 | Mieterverwaltung | 1. Charge | CRUD + Filter nach Immobilie | - | management_tenant |
| 8 | Gebührenverwaltung | 1. Charge | Gebührenarten-CRUD + Rechnungsverwaltung + Seriengenerierung + Offline-Zahlungseingang | Rechnungsabfrage + Online-Zahlung + Gebührenstatistik | management_fee_type, management_fee_bill, management_fee_payment |
| 9 | Reparaturverwaltung | 1. Charge | Reparaturliste + Auftragszuweisung + Fortschrittsupdate | Reparatur einreichen + Fortschritt ansehen + Bewerten | management_repair_order, management_repair_progress |
| 10 | Ankündigungen | 1. Charge | CRUD + Veröffentlichen/Anpinnen | Ankündigungsliste/Details | management_announcement |
| 11 | Parkplatzverwaltung | 2. Charge | Parkplatz-/Fahrzeugverwaltung + Parkprotokoll | Meine Parkplätze/Fahrzeuge + Parkprotokoll | management_parking_space, management_parking_vehicle, management_parking_record |
| 12 | Geräteverwaltung | 2. Charge | Gerätebuch + Wartungsprotokolle | - | management_equipment, management_equipment_maintenance |
| 13 | Beschwerde & Vorschlag | 2. Charge | Beschwerdeliste + Bearbeitung + Nachbesuch | Beschwerde einreichen + Fortschritt ansehen + Bewerten | management_complaint |
| 14 | Besucherverwaltung | 2. Charge | Besuchergenehmigung + Protokollabfrage | Besuchertermin + Zugangscode | management_visitor |
| 15 | Vertragsverwaltung | 2. Charge | CRUD + Statusverwaltung | - | management_contract |
| 16 | Finanzverwaltung | 2. Charge | Einnahmen-Ausgaben-Verwaltung + Statistikberichte | - | management_finance_income, management_finance_expense |
| 17 | Sicherheitspatrouille | 3. Charge | Patrouillenrouten + Patrouillenprotokolle | - | management_security_patrol, management_patrol_record |
| 18 | Reinigungsverwaltung | 3. Charge | Reinigungsbereiche + Reinigungsprotokolle | - | management_cleaning_area, management_cleaning_record |
| 19 | Grünanlagenverwaltung | 3. Charge | Grünbereiche + Pflegeprotokolle | - | management_green_area, management_green_maintenance |
| 20 | Community-Aktivitäten | 3. Charge | Aktivitätsverwaltung + Anmeldungen ansehen | Aktivitätsliste + Anmeldung | management_community_activity, management_activity_signup |
| 21 | Energieverbrauchsverwaltung | 3. Charge | Zählerverwaltung + Ableseprotokolle | - | management_energy_meter, management_energy_record |
| 22 | Mitarbeiterverwaltung | 3. Charge | CRUD + Statusverwaltung | - | management_staff |

## Erweiterungsfunktionen (4. Charge — 12 Module)

| Nr. | Modul | Admin-Panel | Eigentümer-Portal | Datenbanktabellen |
|------|------|---------|--------|--------|
| 23 | Benachrichtigungen | Vorlagen-CRUD + manueller Versand + Liste | Meine Nachrichten + als gelesen markieren | management_notification_template, management_notification |
| 24 | Genehmigungsworkflow | Genehmigungstypen + Instanzen + Schrittfluss | - | management_approval_type, management_approval, management_approval_record |
| 25 | Zahlungsintegration | Auftragsverwaltung + Rückerstattung + WeChat/Alipay-Callbacks | - | management_payment_order |
| 26 | Eigentümer-Abstimmung | Abstimmungs-CRUD + Optionen + flächengewichtete Statistik | Abstimmungsliste + Abstimmung + flächengewichtet | management_vote, management_vote_option, management_vote_record |
| 27 | Automatische SLA-Eskalation | Regelkonfiguration + Zeitüberschreitungsprüfung + Strafen | - | management_sla_rule, management_sla_record |
| 28 | Intelligente Zahlungserinnerung | Strategiekonfiguration + Überfälligkeitsabgleich + Verzugszuschlag | - | management_collection_strategy, management_collection_record |
| 29 | Mobile Inspektion | Aufgabenverteilung + GPS-Check-in + Fotos | - | management_inspection_task, management_inspection_checkpoint |
| 30 | Community-Shop | Kategorien/Produkte/Bestellungen/Lieferung | Produkte ansehen + Bestellen + Meine Bestellungen | management_mall_category, management_mall_product, management_mall_order |
| 31 | Gesichtserkennung | Prüfungsverwaltung | Gesicht registrieren + Authentifizierungsstatus | management_face_info |
| 32 | Konzernverwaltung | Konzern-CRUD + Wohnanlagen-Verknüpfung + übergreifende Zusammenfassung | - | management_group, management_group_community |
| 33 | Intelligente Fragen & Antworten | Wissensdatenbank + Gesprächsverlauf + Statistik | Fragen stellen + Schlüsselwortabgleich | management_knowledge_base, management_chat_record |
| - | Daten-Dashboard | Echtzeit-Visualisierung der Immobiliendaten im Vollbild | - | (nutzt bestehende Datenschnittstellen) |

## Admin-Panel-Module (bereits vorhanden)

| Modul | Funktion |
|------|------|
| Dashboard | Echtzeit-Statistik/Trend/Verteilung/Protokolle (Redis 5m Cache) |
| Benutzerverwaltung | Admin-Benutzer-CRUD + Massenlöschung/Aktivierung-Deaktivierung + Excel-Import |
| Rollen & Berechtigungen | CRUD + Berechtigungsbaum + RBAC-method.path-Autorisierung |
| Systemkonfiguration | Schlüssel-Wert-CRUD |
| Betriebsaudit | Protokollabfrage + automatische Erkennung von 8 Plattform-Quellen |
| Dateiverwaltung | Upload + Excel/PDF-Export (sensible Daten maskiert) |
| Sicherheitsverwaltung | 18-Schichten-Verteidigung in der Tiefe + security.txt |
| Betriebsüberwachung | Health-Check + Prometheus-Metriken + API-Dokumentation |
| Internationalisierung | Zweisprachig Chinesisch/Englisch, PHP symfony/translation + Flutter GetX Translations + HarmonyOS-Ressourcenqualifizierer |
| API-Dokumentation | Automatisch generiert mit `hg/apidoc`, admin 10 Gruppen + service 9 Gruppen, nach Funktionsmodul organisiert |

## Funktionsübergreifende Eigenschaften

### ID-Verschlüsselte Übertragung
Die ID-Felder in allen API-Anfragen und -Antworten werden mit `erikwang2013/hashids` kodiert/dekodiert. Der Client erhält einen Hashids-String (z. B. `aB3xK9mW2pQ7rT5v`), das Backend dekodiert ihn zu BIGINT für die Verarbeitung.

### Schutz sensibler Daten
- API-Übertragungsebene: `erikwang2013/encryption` — AES-256-CBC
- Datenbankspeicherebene: `erikwang2013/encryptable` — automatische Ver-/Entschlüsselung über Eloquent Model casts
- Frontend-Anzeigebene: Telefonnummer 138****1234, E-Mail a***@e.com

### Betriebsaudit
Alle POST/PUT/DELETE-Aktionen im Admin-Panel werden automatisch protokolliert, inkl. Benutzer, IP, Pfad, Parameter (maskiert), Aktionszeitpunkt und Quelle (web/ios/android/harmonyos/windows/macos/linux/ipados).

### Berechtigungskontrolle
- Admin-Panel: RBAC-method.path-Granularitätsprüfung, Superadministrator `*` überspringt die Prüfung
- Eigentümer-Portal: JWT-Bearer-Token-Authentifizierung, Eigentümer können nur auf eigene Daten zugreifen

### Sicherheitsschutz
18-Schichten-Verteidigung in der Tiefe: Captcha → Passwortbestätigung → Zufallsprüfung → Sicherheitsscan → Angriffsblockierung → Übertragungsverschlüsselung → JWT → Sitzungskontrolle → Kontosperrung → RBAC → Ratenlimit → ID-Schutz → Anfrageverschlüsselung → Speicherverschlüsselung → Anzeige-Maskierung → Audit → CSP → Urheberrechtswasserzeichen

### Exportfunktionen
- Excel: PhpSpreadsheet, blauer Kopf mit weißer Schrift + eingefrorene erste Zeile + Auto-Filter + Maskierung sensibler Daten
- PDF: Dompdf A4 quer, Kopfzeile mit Copyright + nicht entfernbares Copyright-Wasserzeichen in der Fußzeile
- Export von Panel-Visualisierungsdaten als PDF

### Suchmaschine
- `erikwang2013/webman-scout` treibt Elasticsearch
- Automatische Indexsynchronisierung (automatische Übertragung bei Hinzufügen/Ändern/Löschen)
- Indexpräfix `management_`, identisch mit dem Datenbank-Tabellenpräfix

### Internationalisierung (i18n)
- **PHP-Backend**: symfony/translation — `resource/translations/{zh_CN,en}/messages.php`, 42 Übersetzungsschlüssel, im Controller über die Methode `__()` abgerufen
- **Flutter Web**: GetX `Translations` — `lib/i18n/messages.dart`, 101 Übersetzungsschlüssel, auf Seiten über die `.tr`-Erweiterung genutzt
- **HarmonyOS**: `resources/{base,en_US}/element/string.json` Ressourcenqualifizierer
- **Standardsprache**: Vereinfachtes Chinesisch (zh_CN), Fallback-Sprache Englisch (en)
- **Anfrageheader**: `Accept-Language` steuert die Antwortsprache

### Testabdeckung
- **Testframework**: PHPUnit 12.x
- **TDD-Ablauf**: Rot → Grün → Refactoring, erst Test, dann Code
- **Admin-Panel**: 60 Tests, 164 Assertions, abdeckt Basisdienste, Umgebungskonfiguration, Sicherheitsvalidierung
- **Geschäftssystem**: 18 Tests, 45 Assertions, 100% Erfolgsquote
- **Gesamt**: 78 Tests, 209 Assertions
- **Abdeckung**: Eindeutigkeit der Snowflake-ID-Generierung, Hashids-Kodierungs-/Dekodierungs-Roundtrip, einheitliches Antwortformat, Schema-Validierung der 64 Tabellen, Konsistenz der chinesischen/englischen Übersetzungsschlüssel
- **Flutter**: flutter analyze ohne Befunde
- **API-Dokumentation**: `hg/apidoc` automatisch generiert, admin (10 Gruppen) + service (9 Gruppen), nach Funktionsmodul organisiert
