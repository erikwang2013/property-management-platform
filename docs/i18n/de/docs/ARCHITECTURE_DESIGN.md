# Architekturdesign-Dokument (Architecture Design)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## 1. Systemarchitektur-Überblick

Das Immobilienverwaltungssystem verwendet eine Schichtenarchitektur mit „zwei Backends + mehreren Frontends". Das Admin-Panel (admin) und das Eigentümer-Geschäftssystem (service) sind zwei unabhängige webman-v2-Projekte, die über eine gemeinsame MySQL-Datenbank zusammenarbeiten. Das Frontend umfasst Flutter Web (PC-Admin-Stil) und HarmonyOS-Mobilanwendungen.

### Designziele

- **Unabhängige Bereitstellung**: admin und service werden jeweils separat gestartet/gestoppt, separat skaliert und verwalten eigene Schlüssel
- **Gemeinsame Daten**: gemeinsame Nutzung derselben MySQL-Datenbank, keine Datensynchronisationsprobleme
- **Einheitliche Standards**: beide Projekte folgen denselben Codestandards, Konfigurationsstilen und Sicherheitsrichtlinien
- **PC-orientiertes Web-Frontend**: Flutter Web ist im Desktop-Admin-Stil gestaltet (Sidebar + Topbar + Inhaltsbereich)

## 2. Schichtenarchitektur

```
┌─────────────────────────────────────────────────────────────┐
│                    Routing-Ebene (Route Layer)                │
│   config/route.php — URL → Controller-Zuordnung + Middleware  │
├─────────────────────────────────────────────────────────────┤
│                 Middleware-Ebene (Middleware Layer)           │
│   SecurityFilter → RateLimit → ApiVersion → Auth → Permission │
├─────────────────────────────────────────────────────────────┤
│                 Controller-Ebene (Controller Layer)           │
│   BaseController → Anfragevalidierung → ID-Kodierung →        │
│   Geschäftslogik → Antwortformatierung                        │
├─────────────────────────────────────────────────────────────┤
│                   Service-Ebene (Service Layer)               │
│   HashidsService | SnowflakeService | EncryptionService       │
├─────────────────────────────────────────────────────────────┤
│                   Model-Ebene (Model Layer)                   │
│   Eloquent ORM + encryptable automatische Ver-/Entschlüsselung│
│   + scout ES-Synchronisierung                                 │
├─────────────────────────────────────────────────────────────┤
│                   Treiber-Ebene (Driver Layer)                │
│   MySQL PDO | Elasticsearch HTTP | Redis                      │
└─────────────────────────────────────────────────────────────┘
```

## 3. Middleware-Ausführungskette

### Admin-Panel (admin)
```
Cors → SecurityFilter(Methodenprüfung→405) → RateLimit(Ratenlimit)
  → AdminAuth(JWT-Validierung) → AdminPermission(RBAC-Autorisierung)
    → OperationLog(Aktionsprotokoll) → Controller
```

### Geschäftssystem (service)
```
Cors → SecurityFilter(Methodenprüfung→405) → RateLimit(Ratenlimit)
  → ApiVersion(Versionsprüfung) → Controller      # /api/* öffentliche Schnittstellen
  → ServiceAuth(JWT-Eigentümerauthentifizierung) → Controller  # /service/* geschützte Schnittstellen
```

### Globale Middleware-Übersicht

| Middleware | Position | Aufgabe |
|--------|------|------|
| Cors | Global an erster Stelle | CORS-Header-Verarbeitung |
| SecurityFilter | Global | HTTP-Methoden-Whitelist, Blockierung von XSS/SQL-Injection/Pfadtraversal/Befehlsinjektion/CSRF, IP-Blacklist |
| RateLimit | Global | Redis-Sliding-Window-Ratenbegrenzung (Lua atomar), Standard 60 Anfragen/Minute |
| ApiVersion | /api-Routen | Prüfung des Anfrageheaders API-Version, Injektion der Versionsnummer |
| AdminAuth | /admin-Routen | JWT-Token-Validierung, Injektion von adminId |
| AdminPermission | /admin-Routen | RBAC-method.path-Berechtigungsprüfung (Redis 60s Cache) |
| OperationLog | /admin-Routen | Automatische Protokollierung von POST/PUT/DELETE-Aktionen (inkl. Quellenerkennung) |
| ServiceAuth | /service-Routen | JWT-Token-Validierung, Injektion von ownerId |

## 4. Vollständiger ID-Lebenszyklus

```
Generierung: SnowflakeService::generate()
      datacenter_id(5bit) + worker_id(5bit) + timestamp(41bit) + sequence(12bit)
      → BIGINT(18) z. B.: 1750123456789

Speicherung: MySQL management_*-Tabellen
      id BIGINT UNSIGNED NOT NULL (kein Auto-Inkrement)
      sensible Felder mit encryptable cast → AES-256-CBC-verschlüsselt gespeichert

Übertragung: HashidsService::encode(bigint) → Hashids-String z. B.: aB3xK9mW2pQ7rT5v
      Alle ID-Felder in API-Anfragen/-Antworten verwenden einheitlich Hashids

Dekodierung: HashidsService::decode(hashid) → BIGINT
      Ungültige Hashids lösen InvalidArgumentException aus
```

## 5. Datenverschlüsselung nach Ebenen

### Übertragungsebene (encryption)
- AES-256-CBC-Verschlüsselung
- Der Client verschlüsselt sensible Daten vor dem Senden, der Server entschlüsselt nach dem Empfang
- Eigener Schlüssel `ENCRYPTION_KEY`

### Speicherebene (encryptable)
- Automatische Ver-/Entschlüsselung über den `$casts`-Mechanismus des Models
- Sensible Felder: phone, email, id_card, emergency_contact, emergency_phone
- Eigener Schlüssel `ENCRYPTABLE_KEY`
- Beim Schreiben automatisch als Chiffrat verschlüsselt, beim Lesen automatisch als Klartext entschlüsselt

### Anzeigebene (Maskierung)
- Telefonnummer: `138****1234`
- E-Mail: `a***@example.com`
- Personalausweis: `********`
- Excel/PDF-Export automatisch maskiert

## 6. Authentifizierung und Berechtigungen

### JWT-Authentifizierung
- Algorithmus: HS256
- access_token: 2 Stunden gültig
- refresh_token: 14 Tage gültig
- Parallelitätslimit: maximal 3 gültige Tokens pro Benutzer; bei Überschreitung wird das älteste Token auf die Blacklist gesetzt
- Kontosperrung: 5 fehlgeschlagene Anmeldeversuche in Folge sperren für 15 Minuten

### RBAC-Berechtigungsmodell
- Benutzer → Rolle → Berechtigung (viele-zu-viele)
- Berechtigungstypen: type=1 (Menü) / type=2 (Schaltfläche) / type=3 (API)
- Berechtigungskennung: `{method}.{path}` z. B.: `get.admin/user`
- Superadministrator-Kennung: `*` (überspringt alle Berechtigungsprüfungen)
- Berechtigungsbaum: selbstreferenzierender parent_id, unbegrenzte Hierarchie

## 7. Verteidigung in der Tiefe (18 Schichten)

```
Schicht 1   Klick-Captcha        → Pflicht-Mensch-Prüfung bei Anmeldung/Registrierung
Schicht 2   Passwortbestätigung  → Sensible Aktionen (Löschen/Zahlung/Vertragsende) erfordern Passwort
Schicht 3   poster-Zufallsprüfung → Zufälliges Captcha bei häufigen sensiblen Aktionen
Schicht 4   security-php         → Automatischer Sicherheitsscan im Anfragezyklus
Schicht 5   SecurityFilter       → Blockierung von XSS/SQL-Injection/Pfadtraversal/Befehlsinjektion/CSRF
Schicht 6   Übertragungssicherheit → HTTPS + AES-256-CBC
Schicht 7   JWT-Authentifizierung → HS256, 2h Ablauf + Refresh-Token
Schicht 8   Parallelitätskontrolle → Maximal 3 Tokens pro Benutzer, darüber Blacklist
Schicht 9   Kontosperrung        → 5 Fehlversuche in Folge sperren für 15 Minuten
Schicht 10  RBAC-Autorisierung   → Berechtigungskontrolle mit method.path-Granularität
Schicht 11  Ratenbegrenzung      → Redis Sliding Window, Lua atomar
Schicht 12  ID-Schutz            → Hashids-Kodierung, echte ID nicht ableitbar
Schicht 13  Anfragekörper-Verschlüsselung → AES-256-CBC für sensible Felder
Schicht 14  Speicherverschlüsselung → encryptable DB-Feldverschlüsselung
Schicht 15  Anzeige-Maskierung   → Telefonnummer/E-Mail/Personalausweis maskiert
Schicht 16  Audit-Rückverfolgung → OperationLog vollständige Protokollierung (inkl. automatischer Quellenerkennung)
Schicht 17  HTTP-Header-Schutz   → CSP + X-Permitted-Cross-Domain-Policies
Schicht 18  Ausgangsschutz       → PDF-Urheberrechtswasserzeichen (nicht entfernbar) + Excel-Maskierung sensibler Daten
```

## 8. Ratenbegrenzungsstrategie

Basiert auf dem Redis-Sorted-Set-Sliding-Window-Algorithmus, atomar per Lua-Skript:

| Schnittstelle | Limit |
|------|------|
| Standard | 60 Anfragen/Minute/IP/Route |
| POST /api/auth/login | 10 Anfragen/Minute |
| POST /api/auth/register | 5 Anfragen/Minute |

Bei Überschreitung wird 429 + `X-RateLimit-Limit/Remaining/Reset/Retry-After` zurückgegeben.

## 9. API-Versionsstrategie

- Die Version wird über den Anfrageheader `API-Version` gesteuert (Standard `v1`), nicht über die URL
- Nicht unterstützte Versionen führen zu 400
- Controller sind nach Version organisiert: `app/api/{version}/controller/`
- Eine neue Version erfordert nur das Anlegen des Verzeichnisses und die Registrierung in der `ApiVersion`-Middleware

## 10. Bereitstellungsarchitektur

```
┌─────────────────────────────────────┐
│            CloudFlare DNS + CDN      │
└────────────────┬────────────────────┘
                 │
┌────────────────▼────────────────────┐
│          Nginx (:443)                │
│    Reverse Proxy + Gzip + SSL-Terminierung
│    Statische Dateien: Flutter Web build/
└──────┬──────────────────┬───────────┘
       │                  │
┌──────▼──────┐    ┌──────▼──────┐
│ admin webman│    │service webman│
│ :8787       │    │ :8788       │
│ Admin-API   │    │ Eigentümer-API│
└──────┬──────┘    └──────┬──────┘
       │                  │
       └────────┬─────────┘
                │
┌───────────────┼───────────────────┐
│               │                   │
┌▼──────┐  ┌────▼───┐  ┌──────────▼┐
│MySQL  │  │ Redis  │  │Elasticsearch│
│:3306  │  │ :6379  │  │ :9200      │
└───────┘  └────────┘  └────────────┘
```

### Docker-Compose-Dienste

| Dienst | Image | Beschreibung |
|------|------|------|
| nginx | nginx:alpine | Reverse Proxy + statische Dateien |
| admin | Dockerfile-Build | PHP 8.3 + OPcache |
| service | Dockerfile-Build | PHP 8.3 + OPcache |
| mysql | mysql:8.0 | Datenvolumen persistent |
| redis | redis:7-alpine | Cache/Ratenlimit/Session |
| elasticsearch | elasticsearch:8.x | Volltextsuche |

## 11. Internationalisierungsdesign (i18n)

### Struktur der Sprachdateien

Das System unterstützt Vereinfachtes Chinesisch (zh_CN) und Englisch (en), Standard ist Chinesisch.

**PHP-Backend:**
```
resource/translations/
├── zh_CN/
│   └── messages.php    # Chinesisches Sprachpaket (42+ Übersetzungsschlüssel)
└── en/
    └── messages.php    # Englisches Sprachpaket
```

Angetrieben von symfony/translation, konfiguriert in `config/translation.php`:
- `locale`: `zh_CN`
- `fallback_locale`: `['zh_CN', 'en']`
- `path`: `resource/translations`

Im Controller wird die Übersetzung über `$this->__('key')` abgerufen:
```php
return $this->success([], $this->__('create_success'));
return $this->fail($this->__('community.name_required'), 422);
```

Die Methode `__()` ruft intern die globale Funktion `trans()` von webman auf; bei fehlender Übersetzung wird der Schlüssel selbst zurückgegeben.

**Flutter Web:**
```
apps/flutter/lib/i18n/
└── messages.dart       # AppTranslations extends GetX Translations
```

Verwendet GetX `Translations` mit 101 Übersetzungsschlüsseln. Nutzung über die `.tr`-Erweiterung:
```dart
Text('login_btn'.tr)   // Chinesisch: "登 录", Englisch: "Login"
Text('phone_hint'.tr)  // "请输入手机号" / "Enter phone number"
```

Sprachumschaltung:
```dart
Get.updateLocale(Locale('zh', 'CN'));  // Auf Chinesisch umschalten
Get.updateLocale(Locale('en', 'US'));  // Auf Englisch umschalten
```

### Kategorien der Übersetzungsschlüssel

| Kategorie | PHP-Schlüsselbeispiele | Flutter-Schlüsselbeispiele |
|------|-----------|---------------|
| Allgemein | `success`, `fail`, `not_found` | `confirm`, `cancel`, `save` |
| Authentifizierung | `auth.login_success`, `auth.*` | `login_btn`, `phone_hint` |
| Wohnanlage | `community.name_required` | - |
| Gebühren | `fee.bill_not_found`, `fee.*` | `fee_management`, `bill_status` |
| Reparatur | `repair.not_found`, `repair.*` | `repair_submit`, `urgency_normal` |
| Beschwerde | `complaint.submit_success` | `complaint_type`, `type_complaint` |
| Persönlich | - | `profile`, `change_password` |

**HarmonyOS:** verwendet `resources/base/element/string.json` + `resources/en_US/element/string.json` Ressourcenqualifizierer (wird bei der Erstellung des HarmonyOS-Projekts umgesetzt).

## 12. Teststrategie

### TDD-Testablauf

Das Projekt folgt dem TDD-Ablauf (Testgetriebene Entwicklung): Rot → Grün → Refactoring.

```
ROT: Zuerst Tests schreiben, Fehlschlag beobachten
  ↓
GRÜN: Minimale Codeänderung, damit die Tests bestehen
  ↓
REFACTOR: Code bereinigen, Tests grün halten
```

### Testabdeckung

| Ebene | Testframework | Testinhalte |
|----|---------|---------|
| Basisdienste | PHPUnit | Snowflake-ID-Generierung, Hashids-Kodierung/-Dekodierung, Antwortformat |
| Datenbank | PHPUnit + PDO | Schemavalidierung (BIGINT-Primärschlüssel, kein Auto-Inkrement, management_-Präfix) |
| Internationalisierung | PHPUnit | Existenz der Übersetzungsdateien, Konsistenz der chinesischen/englischen Schlüssel |
| API-Endpunkte | PHPUnit | Health-Check, Antwortformat |
| Middleware | Integrationstests | JWT-Authentifizierung, Ratenlimit, Berechtigungen |

### Tests ausführen

```bash
cd admin && php vendor/bin/phpunit    # Admin: 60 Tests, 164 Assertions
cd service && php vendor/bin/phpunit  # Service: 18 Tests, 45 Assertions, 100% bestanden
```

## 13. Frontend-Architektur

### Flutter Web (PC-Desktop-Stil)

```
apps/flutter/lib/
├── main.dart                    # Einstiegspunkt, initialisiert ApiService + AuthService
├── app.dart                     # GetMaterialApp, Routentabelle + Theme + i18n
├── config/
│   ├── api_config.dart          # API-Endpunktkonstanten (zeigt auf service :8788)
│   └── theme.dart               # Material-3-Theme (Ant-Design-Farbpalette)
├── services/
│   ├── api_service.dart         # Dio-Singleton + JWT-Interceptor + automatische 401-Aktualisierung
│   ├── auth_service.dart        # Anmeldung/Abmeldung/Token-Persistenz
│   └── storage_service.dart     # shared_preferences-Wrapper
├── i18n/
│   └── messages.dart            # GetX Translations (101 Schlüssel, zh_CN/en)
├── pages/
│   ├── login/                   # PC-Startseite (zentrierte Card + Formularvalidierung)
│   ├── home/                    # Dashboard (4 StatCards + Ankündigungsliste)
│   ├── fee/                     # Rechnungsliste / Details / Zahlungsdialog
│   ├── repair/                  # Reparaturliste / Einreichen / Details + Bewertung
│   └── profile/                 # Persönliche Daten / Passwort ändern / Abmelden
└── widgets/
    └── stat_card.dart           # Statistik-Kartenkomponente (Icon + Titel + Wert)
```

### HarmonyOS Mobile

```
apps/harmonyos/entry/src/main/ets/
├── services/
│   ├── ApiService.ets           # @ohos.net.http-Wrapper, Bearer Token
│   └── AuthService.ets          # Anmeldung/Abmeldung (Preference-Persistenz)
├── model/
│   └── Models.ets               # TypeScript-Schnittstellendefinitionen
├── pages/
│   ├── LoginPage.ets            # Anmeldung mit Telefonnummer + Passwort
│   └── HomePage.ets             # Dashboard (Statistik-Karten + Ankündigungsliste)
└── resources/
    ├── base/element/string.json # Chinesische Ressourcen
    └── en_US/element/string.json# Englische Ressourcen
```

### Technologieauswahl

| Ebene | Flutter Web | HarmonyOS |
|----|------------|-----------|
| Zustandsverwaltung | GetX | @State + @Prop |
| HTTP | Dio + JWT-Interceptor | @ohos.net.http |
| Persistenz | shared_preferences | @ohos.data.preferences |
| Diagramme | fl_chart | Web-Komponente + ECharts |
| Internationalisierung | GetX Translations | Ressourcenqualifizierer |
| Routing | GetX named routes | router.pushUrl/replaceUrl |

## 14. Architektur der Erweiterungsfunktionen

### Benachrichtigungszentrum
Nachrichtenvorlage → Benachrichtigungserstellung → Versand über mehrere Kanäle (In-App/SMS/E-Mail/Push)

### Genehmigungsworkflow
Konfiguration des Genehmigungstyps → Einreichung der Instanz → Schrittfluss (bestätigen/ablehnen) → Benachrichtigung des nächsten Genehmigers

### Zahlungsablauf
Zahlungsauftrag erstellen → Drittanbieter-Zahlung → asynchroner Callback → Rechnungsstatus aktualisieren → Zahlungsprotokoll erfassen

### Eigentümer-Abstimmung
Abstimmung veröffentlichen → Eigentümer stimmen ab (flächengewichtet) → Echtzeit-Auszählung → Ergebnisstatistik

### Automatische SLA-Eskalation
SLA-Regelabgleich → regelmäßige Zeitüberschreitungsprüfung → automatische Eskalation → Strafprotokoll

### Intelligente Zahlungserinnerung
Mahnstrategie-Abgleich → Überfälligkeitserkennung → automatische Erstellung von Mahnaufgaben → Ausführung der Mahnaktion

### Inspektionsverwaltung
Aufgabenverteilung → GPS-Check-in auf dem Handy → Foto-Upload → Anomalie-Markierung → Abschlussstatistik

### Konzernverwaltung
Konzern → Wohnanlagen-Verknüpfung → Datenaggregation über Wohnanlagen hinweg (Immobilien/Eigentümer/Gebühren/Reparaturen)

## 15. API-Dokumentation

Verwendet `hg/apidoc` zur automatischen Generierung der Schnittstellendokumentation aus Controller-Annotationen, gruppiert nach Funktion.

**Admin-Panel** (`http://localhost:8787/apidoc`): 10 Gruppen — 57 Controller mit Annotationen (Base/Docs/Install ohne Gruppe)

| Gruppe | Anzahl | Controller |
|------|------|--------|
| `common` | 2 | Auth, Captcha |
| `dashboard` | 3 | Dashboard, Metrics, Health |
| `export` | 1 | Export |
| `import` | 1 | Import |
| `upload` | 1 | Upload |
| `system` | 6 | User, Role, Permission, Config, Log, Profile |
| `property-core` | 12 | Community, Building, Unit, RoomType, Room, Owner, Tenant, FeeType, FeeBill, FeePayment, Repair, Announcement |
| `property-aux` | 9 | Parking(3), Equipment(2), Complaint, Visitor, Contract, Finance |
| `property-adv` | 11 | Activity(2), Patrol(2), Cleaning(2), Green(2), Energy(2), Staff |
| `extensions` | 11 | Notification, Approval, Payment, Vote, Sla, Collection, Inspection, Mall, Face, Group, Knowledge |

**Geschäftssystem** (`http://localhost:8788/apidoc`): 9 Gruppen — 17 Controller mit Annotationen

| Gruppe | Anzahl | Controller |
|------|------|--------|
| `public` | 2 | Auth, Captcha |
| `home` | 2 | Home, Room |
| `fee` | 1 | Fee |
| `repair` | 1 | Repair |
| `feedback` | 2 | Complaint, Announcement |
| `parking` | 2 | Parking, Visitor |
| `activity` | 1 | Activity |
| `profile` | 1 | Profile |
| `extensions` | 5 | Notification, Vote, Mall, Knowledge, Face |

### Annotationsstandards

```php
/**
 * 小区列表
 * @Apidoc\Method("GET")
 * @Apidoc\Url("/admin/community")
 * @Apidoc\Group("property-core")
 * @Apidoc\Sort(1)
 * @Apidoc\Param("keyword", type="string", require=false, desc="搜索关键词")
 * @Apidoc\Param(ref="pagination")
 * @Apidoc\Returned("id", type="string", desc="hashid")
 */
```

### Gemeinsame Definitionsblöcke

| Blockname | Inhalt |
|------|------|
| `pagination` | page/page_size Paginierungsparameter |
| `searchParams` | keyword/status Suchfilter |
| `dateRange` | start_date/end_date Datumsbereich |
| `passwordConfirm` | password Passwortbestätigung |

## 16. Einheitliches Antwortformat

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

| code | Bedeutung |
|------|------|
| 0 | Erfolg |
| 400 | Parameterfehler |
| 401 | Nicht authentifiziert |
| 403 | Keine Berechtigung |
| 404 | Nicht vorhanden |
| 422 | Validierung fehlgeschlagen |
| 429 | Zu viele Anfragen |
| 500 | Serverfehler |
