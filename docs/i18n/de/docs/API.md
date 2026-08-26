# API-Referenz (API Reference)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## Überblick

- Die Admin-Panel API läuft auf `http://localhost:8787`
- Die Geschäftssystem-API läuft auf `http://localhost:8788`
- Einheitliches Antwortformat: `{"code": 0, "message": "success", "data": {...}}`
- Alle ID-Felder werden mit hashids kodiert übertragen
- Die API-Version wird über den Anfrageheader `API-Version` gesteuert (Standard `v1`)
- Die Sprache wird über den Anfrageheader `Accept-Language` gesteuert (`zh-CN` / `en-US`, Standard `zh-CN`)

### Online-API-Dokumentation

Nach dem Start des Dienstes ist die automatisch generierte interaktive Dokumentation von `hg/apidoc` erreichbar:

| Ende | Adresse | Gruppenzahl |
|----|------|--------|
| Admin-Panel | `http://localhost:8787/apidoc` | 10 Gruppen (common/dashboard/system/property-core/property-aux/property-adv/extensions/export/import/upload) |
| Eigentümer-Portal | `http://localhost:8788/apidoc` | 9 Gruppen (öffentliche Schnittstellen/Startseite/Gebühren/Reparatur/Feedback/Parken/Aktivitäten/Profil/Erweiterungen) |

---

## Admin-Panel API (admin :8787)

### Öffentliche Schnittstellen — ohne Authentifizierung

#### POST /api/captcha/generate
Klick-Captcha abrufen.

Anfrageparameter: keine

Antwort:
```json
{
  "code": 0,
  "data": {
    "key": "captcha_key_string",
    "image": "base64_encoded_png",
    "extra": { "targets": ["树", "鸟", "花"] }
  }
}
```

#### POST /api/captcha/verify
Klick-Captcha prüfen.

Anfrageparameter:
| Parameter | Typ | Beschreibung |
|------|------|------|
| key | string | Captcha-Key, von generate zurückgegeben |
| clicks | array | Klickkoordinaten [{x, y}, ...] |

Antwort:
```json
{
  "code": 0,
  "data": { "valid": true }
}
```

Bei fehlgeschlagener Prüfung ist `code` 422 und `data.valid` ist `false`.

#### POST /api/auth/login
Administrator-Anmeldung.

Anfrageparameter:
| Parameter | Typ | Beschreibung |
|------|------|------|
| username | string | Benutzername |
| password | string | Passwort |
| captcha_key | string | Captcha-Key |
| clicks | array | Klickkoordinaten [{x, y}, ...] |

Antwort:
```json
{
  "code": 0,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "user": { "id": "aB3xK9mW...", "username": "admin", "real_name": "管理员" }
  }
}
```

#### POST /api/auth/refresh
Token aktualisieren.

Anfrageparameter:
| Parameter | Typ | Beschreibung |
|------|------|------|
| refresh_token | string | Aktualisierungstoken |

Antwort:
```json
{
  "code": 0,
  "data": { "access_token": "eyJ..." }
}
```

#### GET /health
Health-Check.

#### GET /metrics
Prometheus-Überwachungsmetriken.

#### GET /api/docs
OpenAPI-Dokumentation.

---

### Admin-Schnittstellen — Authentifizierung erforderlich (Bearer Token)

Alle Schnittstellen haben das Präfix `/admin` und erfordern den Header `Authorization: Bearer {access_token}`.

#### Dashboard

**GET /admin/dashboard**
Dashboard-Statistikdaten abrufen.

#### Administrator-Benutzerverwaltung

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/user | Benutzerliste (?keyword=&status=&page=&page_size=) |
| POST | /admin/user | Benutzer erstellen |
| GET | /admin/user/{hashid} | Benutzerdetails |
| PUT | /admin/user/{hashid} | Benutzer aktualisieren |
| DELETE | /admin/user/{hashid} | Benutzer löschen (Passwortbestätigung erforderlich) |
| POST | /admin/user/batch/destroy | Massenlöschung |
| POST | /admin/user/batch/status | Massenaktivierung/-deaktivierung |
| POST | /admin/import/users | Benutzer per Excel importieren |

#### Rollen- und Berechtigungsverwaltung

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/role | Rollenliste |
| POST | /admin/role | Rolle erstellen |
| GET | /admin/role/{hashid} | Rollendetails |
| PUT | /admin/role/{hashid} | Rolle aktualisieren |
| DELETE | /admin/role/{hashid} | Rolle löschen |
| GET | /admin/permission | Berechtigungsliste (Baumstruktur) |
| POST | /admin/permission | Berechtigung erstellen |
| PUT | /admin/permission/{hashid} | Berechtigung aktualisieren |
| DELETE | /admin/permission/{hashid} | Berechtigung löschen |

#### Systemkonfiguration

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/config | Konfigurationsliste (?group=) |
| POST | /admin/config | Konfiguration erstellen |
| PUT | /admin/config/{hashid} | Konfiguration aktualisieren |
| DELETE | /admin/config/{hashid} | Konfiguration löschen |

#### Betriebsprotokoll

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/log | Protokollliste (?user_id=&action=&method=&source=&start_date=&end_date=) |

#### Persönliches Zentrum

| Methode | Pfad | Beschreibung |
|------|------|------|
| PUT | /admin/profile | Persönliche Daten ändern |
| PUT | /admin/profile/password | Passwort ändern |
| POST | /admin/profile/logout | Abmelden |

#### Export

| Methode | Pfad | Beschreibung |
|------|------|------|
| POST | /admin/export/excel | Excel exportieren ({ table, columns, conditions, title }) |
| POST | /admin/export/pdf | PDF exportieren ({ type, title, data }) |

---

### Immobilienverwaltung — Admin-Schnittstellen

#### Wohnanlagenverwaltung

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/community | Liste (?keyword=&status=) |
| POST | /admin/community | Erstellen |
| GET | /admin/community/{hashid} | Details |
| PUT | /admin/community/{hashid} | Aktualisieren |
| DELETE | /admin/community/{hashid} | Löschen (Passwort erforderlich) |

#### Gebäudeverwaltung

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/building | Liste (?community_id=&keyword=) |
| POST | /admin/building | Erstellen |
| GET | /admin/building/{hashid} | Details |
| PUT | /admin/building/{hashid} | Aktualisieren |
| DELETE | /admin/building/{hashid} | Löschen |

#### Einheitenverwaltung

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/unit | Liste (?building_id=) |
| POST | /admin/unit | Erstellen |
| GET | /admin/unit/{hashid} | Details |
| PUT | /admin/unit/{hashid} | Aktualisieren |
| DELETE | /admin/unit/{hashid} | Löschen |

#### Wohntypverwaltung

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/room-type | Liste |
| POST | /admin/room-type | Erstellen |
| GET | /admin/room-type/{hashid} | Details |
| PUT | /admin/room-type/{hashid} | Aktualisieren |
| DELETE | /admin/room-type/{hashid} | Löschen |

#### Immobilienverwaltung

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/room | Liste (?community_id=&building_id=&unit_id=&status=) |
| POST | /admin/room | Erstellen |
| GET | /admin/room/{hashid} | Details |
| PUT | /admin/room/{hashid} | Aktualisieren |
| DELETE | /admin/room/{hashid} | Löschen |
| GET | /admin/room/tree | Immobilienbaum (Wohnanlage→Gebäude→Einheit→Immobilie) |

#### Eigentümerverwaltung

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/owner | Liste (?keyword=&status=) |
| POST | /admin/owner | Erstellen |
| GET | /admin/owner/{hashid} | Details (inkl. gebundener Immobilien) |
| PUT | /admin/owner/{hashid} | Aktualisieren |
| DELETE | /admin/owner/{hashid} | Löschen (Passwort erforderlich) |
| POST | /admin/owner/batch/import | Massenimport per Excel |
| POST | /admin/owner/batch/destroy | Massenlöschung |

#### Mieterverwaltung

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/tenant | Liste (?room_id=&status=) |
| POST | /admin/tenant | Erstellen |
| GET | /admin/tenant/{hashid} | Details |
| PUT | /admin/tenant/{hashid} | Aktualisieren |
| DELETE | /admin/tenant/{hashid} | Löschen |

#### Gebührenart

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/fee-type | Liste |
| POST | /admin/fee-type | Erstellen |
| GET | /admin/fee-type/{hashid} | Details |
| PUT | /admin/fee-type/{hashid} | Aktualisieren |
| DELETE | /admin/fee-type/{hashid} | Löschen |

#### Rechnungsverwaltung

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/fee-bill | Liste (?community_id=&status=&due_date_start=&due_date_end=) |
| POST | /admin/fee-bill | Rechnung erstellen |
| GET | /admin/fee-bill/{hashid} | Details |
| PUT | /admin/fee-bill/{hashid} | Aktualisieren |
| DELETE | /admin/fee-bill/{hashid} | Löschen |
| POST | /admin/fee-bill/batch/generate | Rechnungen in Serie erzeugen |

#### Zahlungshistorie

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/fee-payment | Liste (?bill_id=&payment_method=&date_start=&date_end=) |
| POST | /admin/fee-payment/offline | Offline-Zahlungseingang erfassen |

#### Reparaturverwaltung

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/repair | Liste (?status=&category=) |
| POST | /admin/repair | Erstellen |
| GET | /admin/repair/{hashid} | Details (inkl. Fortschrittsprotokoll) |
| PUT | /admin/repair/{hashid} | Aktualisieren |
| DELETE | /admin/repair/{hashid} | Löschen |
| PUT | /admin/repair/{id}/assign | Auftrag zuweisen ({ staff_id }) |
| POST | /admin/repair/{id}/progress | Fortschritt aktualisieren ({ status_to, remark }) |

#### Ankündigungsverwaltung

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/announcement | Liste (?community_id=&category=&is_published=) |
| POST | /admin/announcement | Erstellen |
| GET | /admin/announcement/{hashid} | Details |
| PUT | /admin/announcement/{hashid} | Aktualisieren |
| DELETE | /admin/announcement/{hashid} | Löschen |

#### Parkplatzverwaltung

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/parking-space | Liste (?community_id=) |
| POST | /admin/parking-space | Parkplatz erstellen |
| PUT | /admin/parking-space/{hashid} | Aktualisieren |
| DELETE | /admin/parking-space/{hashid} | Löschen |
| GET | /admin/parking-vehicle | Liste (?owner_id=&space_id=) |
| POST | /admin/parking-vehicle | Fahrzeug erstellen |
| PUT | /admin/parking-vehicle/{hashid} | Aktualisieren |
| DELETE | /admin/parking-vehicle/{hashid} | Löschen |
| GET | /admin/parking-record | Parkprotokoll (?vehicle_id=&date_start=&date_end=) |

#### Geräteverwaltung

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/equipment | Liste (?community_id=&category=&status=) |
| POST | /admin/equipment | Erstellen |
| PUT | /admin/equipment/{hashid} | Aktualisieren |
| DELETE | /admin/equipment/{hashid} | Löschen |
| GET | /admin/equipment-maintenance | Wartungsprotokoll (?equipment_id=) |
| POST | /admin/equipment-maintenance | Wartung erfassen |

#### Beschwerdebearbeitung

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/complaint | Liste (?type=&status=) |
| GET | /admin/complaint/{hashid} | Details |
| PUT | /admin/complaint/{id}/handle | Bearbeiten ({ handler_remark }) |
| POST | /admin/complaint/{id}/visit | Nachbesuch ({ visitor_remark }) |

#### Besuchergenehmigung

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/visitor | Liste (?status=) |
| PUT | /admin/visitor/{id}/approve | Genehmigen |

#### Vertragsverwaltung

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/contract | Liste (?contract_type=&status=) |
| POST | /admin/contract | Erstellen |
| PUT | /admin/contract/{hashid} | Aktualisieren |
| DELETE | /admin/contract/{hashid} | Löschen |

#### Finanzverwaltung

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/finance-income | Einnahmenliste (?income_type=&date_start=&date_end=) |
| POST | /admin/finance-income | Einnahme erfassen |
| GET | /admin/finance-expense | Ausgabenliste |
| POST | /admin/finance-expense | Ausgabe erfassen |
| GET | /admin/finance/statistics | Monatliche Einnahmen-Ausgaben-Statistik (?year=) |

#### Immobilien-Panel

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/dashboard/property | Immobilienstatistik (Forderungen/Belegungsquote/Reparaturen/Beschwerden/Einnahmen-Ausgaben-Trend) |
| POST | /admin/export/property-excel | Immobiliendaten als Excel exportieren ({ type: owners|bills }) |

#### Sicherheitspatrouille

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/security-patrol | Liste (?community_id=) |
| POST | /admin/security-patrol | Route erstellen |
| GET | /admin/patrol-record | Protokoll (?patrol_id=&staff_id=) |
| POST | /admin/patrol-record | Protokoll erstellen |

#### Reinigungsverwaltung

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/cleaning-area | Bereichsliste |
| POST | /admin/cleaning-area | Bereich erstellen |
| GET | /admin/cleaning-record | Protokoll (?area_id=) |
| POST | /admin/cleaning-record | Protokoll erstellen |

#### Grünanlagenverwaltung

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/green-area | Bereichsliste |
| POST | /admin/green-area | Bereich erstellen |
| GET | /admin/green-maintenance | Pflegeprotokoll (?area_id=) |
| POST | /admin/green-maintenance | Protokoll erstellen |

#### Community-Aktivitäten

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/activity | Liste (?status=) |
| POST | /admin/activity | Aktivität erstellen |
| PUT | /admin/activity/{hashid} | Aktualisieren |
| DELETE | /admin/activity/{hashid} | Löschen |
| GET | /admin/activity-signup | Anmeldeliste (?activity_id=) |
| PUT | /admin/activity-signup/{id}/checkin | Einchecken |

#### Energieverbrauchsverwaltung

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/energy-meter | Zählerliste (?room_id=&meter_type=) |
| POST | /admin/energy-meter | Zähler erstellen |
| GET | /admin/energy-record | Ableseprotokoll (?meter_id=&date_start=&date_end=) |
| POST | /admin/energy-record | Protokoll erstellen |

#### Mitarbeiterverwaltung

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/staff | Liste (?community_id=&status=) |
| POST | /admin/staff | Erstellen |
| PUT | /admin/staff/{hashid} | Aktualisieren |
| DELETE | /admin/staff/{hashid} | Löschen |
| POST | /admin/staff/batch/status | Massenaktivierung/-deaktivierung |

#### Benachrichtigungen

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/notification-template | Vorlagenliste |
| POST | /admin/notification-template | Vorlage erstellen |
| PUT | /admin/notification-template/{hashid} | Vorlage aktualisieren |
| DELETE | /admin/notification-template/{hashid} | Vorlage löschen |
| GET | /admin/notification | Nachrichtenliste (?type=&is_read=) |
| POST | /admin/notification/send | Benachrichtigung manuell senden |

#### Genehmigungsworkflow

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/approval-type | Genehmigungstypenliste |
| POST | /admin/approval-type | Genehmigungstyp erstellen |
| GET | /admin/approval | Genehmigungsliste (?status=) |
| GET | /admin/approval/{hashid} | Genehmigungsdetails |
| POST | /admin/approval | Genehmigung einreichen |
| PUT | /admin/approval/{hashid}/approve | Genehmigen (bestätigen/ablehnen) |

#### Zahlungsverwaltung

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/payment-order | Auftragsliste |
| GET | /admin/payment-order/{hashid} | Auftragsdetails |
| POST | /admin/payment-order/{hashid}/refund | Rückerstattung |
| GET | /admin/payment/statistics | Zahlungsstatistik |

#### Eigentümer-Abstimmung

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /admin/vote | Abstimmungsliste (?status=) |
| POST | /admin/vote | Abstimmung erstellen |
| GET | /admin/vote/{hashid}/statistics | Auszählungsstatistik |
| PUT | /admin/vote/{hashid}/publish | Abstimmung veröffentlichen |
| PUT | /admin/vote/{hashid}/end | Abstimmung beenden |

#### SLA-Verwaltung · Intelligente Zahlungserinnerung · Inspektionsverwaltung · Shop-Verwaltung · Gesichtserkennungsverwaltung · Konzernverwaltung · Wissensdatenbank

(Die vollständigen Endpunkte finden Sie in der Datei `docs/API.md`)

---

## Geschäftssystem-API (service :8788)

### Öffentliche Schnittstellen — ohne Authentifizierung

#### POST /api/captcha/generate
Klick-Captcha abrufen. (Identisch mit Admin-Panel)

#### POST /api/captcha/verify
Klick-Captcha prüfen. (Anfrage/Antwort identisch mit Admin-Panel)

#### POST /api/auth/login
Eigentümer-Anmeldung.

Anfrageparameter:
| Parameter | Typ | Beschreibung |
|------|------|------|
| phone | string | Telefonnummer |
| password | string | Passwort |
| captcha_key | string | Captcha-Key |
| clicks | array | Klickkoordinaten |

Antwort:
```json
{
  "code": 0,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "owner": { "id": "xB9k...", "name": "张三", "phone": "138****1234" }
  }
}
```

#### POST /api/auth/register
Eigentümer-Registrierung.

Anfrageparameter:
| Parameter | Typ | Beschreibung |
|------|------|------|
| phone | string | Telefonnummer |
| password | string | Passwort (mindestens 6 Zeichen) |
| name | string | Name |
| captcha_key | string | Captcha-Key |
| clicks | array | Klickkoordinaten |
| room_id | string | (optional) Hashids der zu bindenden Immobilie |
| id_card_last4 | string | (optional) Letzte 4 Stellen des Personalausweises |

#### POST /api/auth/refresh
Token aktualisieren.

---

### Eigentümer-Schnittstellen — Authentifizierung erforderlich (Bearer Token)

Alle Schnittstellen haben das Präfix `/service` und erfordern den Header `Authorization: Bearer {access_token}`.

#### Startseite

**GET /service/home**

Antwort:
```json
{
  "code": 0,
  "data": {
    "room_count": 2,
    "pending_amount": "1250.00",
    "pending_bill_count": 3,
    "repairing_count": 1,
    "announcements": [{ "id": "xB9k...", "title": "停水通知", "published_at": "2026-05-20 09:00" }]
  }
}
```

#### Meine Immobilien

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /service/rooms | Liste meiner Immobilien |
| GET | /service/room/{hashid} | Immobiliendetails (inkl. Fläche, Ausrichtung, Eigentum, Wohnanlageninfo) |

#### Gebührenverwaltung

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /service/fees/bills | Rechnungsliste (?status=0 unbezahlt/1 teilweise bezahlt/2 bezahlt/3 überfällig) |
| GET | /service/fees/bill/{hashid} | Rechnungsdetails (inkl. Gebührenart, Zahlungshistorie) |
| GET | /service/fees/payments | Zahlungshistorie |
| POST | /service/fees/pay | Online-Zahlung ({ bill_id, payment_method, password }) |
| GET | /service/fees/statistics | Gebührenstatistik (?year=2026) |

#### Reparatur

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /service/repairs | Reparaturliste (?status=) |
| GET | /service/repair/{hashid} | Reparaturdetails (inkl. Fortschritts-Timeline) |
| POST | /service/repair | Reparaturauftrag einreichen ({ room_id, category, urgency, description, images[], scheduled_at }) |
| DELETE | /service/repair/{hashid} | Stornieren (Passwort erforderlich, { password }) |
| POST | /service/repair/{hashid}/rate | Bewerten ({ rating: 1-5, feedback }) |

#### Beschwerde & Vorschlag

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /service/complaints | Beschwerdeliste |
| GET | /service/complaint/{hashid} | Beschwerdedetails (inkl. Bearbeitungsfortschritt) |
| POST | /service/complaint | Beschwerde einreichen ({ type, category, title, content, is_anonymous, images[] }) |
| POST | /service/complaint/{hashid}/satisfaction | Zufriedenheitsbewertung ({ satisfaction: 1-5 }) |

#### Ankündigungen

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /service/announcements | Ankündigungsliste (?category=) |
| GET | /service/announcement/{hashid} | Ankündigungsdetails |

#### Parken

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /service/parking/vehicles | Meine Fahrzeuge |
| GET | /service/parking/spaces | Meine Parkplätze |
| GET | /service/parking/records | Parkprotokoll |

#### Besucher

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /service/visitors | Meine Besuchertermine |
| POST | /service/visitor | Termin erstellen (Zugangscode wird generiert) |
| PUT | /service/visitor/{hashid} | Termin ändern |
| DELETE | /service/visitor/{hashid} | Termin stornieren |

#### Community-Aktivitäten

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /service/activities | Aktivitätsliste (?status=) |
| GET | /service/activity/{hashid} | Aktivitätsdetails |
| POST | /service/activity/{hashid}/signup | Anmelden |
| POST | /service/activity/{hashid}/cancel | Anmeldung stornieren |

#### Persönliche Daten

| Methode | Pfad | Beschreibung |
|------|------|------|
| GET | /service/profile | Persönliche Daten |
| PUT | /service/profile | Ändern ({ name, email, gender, birthday }) |
| PUT | /service/profile/password | Passwort ändern ({ old_password, new_password }) |
| POST | /service/profile/logout | Abmelden |

---

## Offene API — API-Key-Authentifizierung

Eingehende, rein lesende Schnittstellen für Drittsysteme (Immobilienplattform-Anbindung, Daten-Dashboards usw.). Präfix `/open`, alle nur lesend.

### Authentifizierungsmethode

Jede Anfrage muss den Header `X-API-Key` mit dem von `scripts/gen_api_key.php` generierten Key tragen (64-stellig hex, in der Datenbank wird nur der SHA-256-Hash gespeichert):

```bash
curl -H "X-API-Key: <Ihr Key>" http://localhost:8788/open/announcements
```

- Fehlender oder falscher Key führt zu `401` (`{"code":401,"message":"无效的API Key","data":[]}`)
- Key-Verwaltung: `php scripts/gen_api_key.php [--name=Verwendungszweck]` zum Generieren; Deaktivieren/Löschen direkt über die Tabelle `erik_api_key` (`status=0` deaktiviert, der Key verliert sofort seine Gültigkeit)

### Endpunkte

#### GET /open/announcements — Ankündigungsliste

Parameter: `page` (Standard 1), `category` (optional). Antwortstruktur identisch mit `/service/announcements`.

```bash
curl -H "X-API-Key: <Ihr Key>" "http://localhost:8788/open/announcements?page=1"
```

#### GET /open/bills — Rechnungsabfrage

Parameter: `bill_number` (erforderlich, Rechnungsnummer). Gibt die Details einer einzelnen Rechnung zurück (inkl. Gebührenart, Raumnummer, offener Betrag). Bei Nichtexistenz wird 404 zurückgegeben.

```bash
curl -H "X-API-Key: <Ihr Key>" "http://localhost:8788/open/bills?bill_number=B202608160001"
```

#### GET /open/repairs — Reparaturstatusabfrage

Parameter: `order_number` (erforderlich, Reparaturauftragsnummer). Gibt den aktuellen Status und die Fortschritts-Timeline zurück (`progress`-Array). Bei Nichtexistenz wird 404 zurückgegeben.

```bash
curl -H "X-API-Key: <Ihr Key>" "http://localhost:8788/open/repairs?order_number=R202608160001"
```

---

## Fehlercodes

| code | Bedeutung | Beschreibung |
|------|------|------|
| 0 | Erfolg | Normale Antwort |
| 400 | Anfragefehler | Parameterformat falsch |
| 401 | Nicht authentifiziert | Token fehlt/abgelaufen/ungültig/auf der Blacklist |
| 403 | Keine Berechtigung | Benutzerrolle enthält die benötigte Berechtigung nicht / Konto deaktiviert |
| 404 | Nicht vorhanden | Ressource nicht gefunden |
| 405 | Methode nicht erlaubt | Nicht-GET/POST/PUT/DELETE/OPTIONS HTTP-Methode |
| 413 | Anforderung zu groß | Mehr als 10 MB |
| 415 | Nicht unterstützter Medientyp | Content-Type ist nicht JSON oder form-urlencoded |
| 422 | Validierung fehlgeschlagen | Formularparameter entsprechen nicht den Regeln / Passwortbestätigung fehlgeschlagen / Captcha-Fehler |
| 429 | Zu viele Anfragen | Ratenlimit ausgelöst / Kontosperrung |
| 500 | Serverfehler | Unerwartete Ausnahme |

## Ratenlimit-Antwortheader

Bei Auslösung des Ratenlimits wird 429 zurückgegeben; die Antwort enthält folgende Header:

| Antwortheader | Beschreibung |
|--------|------|
| X-RateLimit-Limit | Limitanzahl |
| X-RateLimit-Remaining | Verbleibende Anzahl |
| X-RateLimit-Reset | Zurücksetzzeit (Unix-Zeitstempel) |
| Retry-After | Empfohlene Wartezeit in Sekunden |
