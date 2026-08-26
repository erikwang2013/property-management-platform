# Versionsvergleich (Editions Comparison)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

Das Immobilienverwaltungssystem gibt es in drei Versionen: Basisversion (Lite), Standardversion (Standard) und Vollversion (Full), stufenweise aufeinander aufbauend.

---

## Übersicht

| Kennzahl | Basisversion (Lite) | Standardversion (Standard) | Vollversion (Full) |
|------|:-----------:|:---------------:|:-----------:|
| Datenbanktabellen | **21** | **31** | **65** |
| Eloquent-Modelle | 19 | 30 | 58 |
| Admin-Controller | 17 | 28 | 47 |
| Eigentümer-Controller | 9 | 12 | 17 |
| API-Routen | 35 | 70 | 178 |
| Geschäftsmodule | 10 | 18 | 34 |
| Sicherheitsebenen | 18 | 18 | 18 |

---

## Funktionsmodul-Vergleich

### Basisversion (Lite)

Kern-Immobilienverwaltung, inkl. allgemeinem Admin-System + 10 Kern-Geschäftsmodulen.

**Admin-Panel**: Dashboard, CRUD für Benutzer/Rollen/Berechtigungen/Konfiguration/Protokolle, CRUD für Wohnanlage/Gebäude/Einheit/Wohntyp/Immobilie/Eigentümer/Mieter/Gebühren/Reparatur/Ankündigung

**Eigentümer-Portal**: Registrierung/Anmeldung, Startseite, Meine Immobilien, Rechnungszahlung, Reparatur einreichen/Bewerten, Ankündigungen ansehen, Persönliche Daten

---

### Standardversion (Standard)

Auf der Basisversion aufbauend: +6 Hilfsgeschäftsmodule + Panel-Visualisierung + Datenexport.

**Admin-Panel neu**: Parkplatz-/Fahrzeug-CRUD, Gerätebuch + Wartung, Beschwerdebearbeitung + Nachbesuch, Besuchergenehmigung, Vertragsverwaltung, Einnahmen-Ausgaben-Verwaltung + Statistik

**Eigentümer-Portal neu**: Meine Fahrzeuge/Parkplätze, Parkprotokoll, Besuchertermin/Zugangscode

---

### Vollversion (Full)

Auf der Standardversion aufbauend: + erweiterte Module + 12 Erweiterungsfunktionen.

**Admin-Panel neu**: Patrouillenrouten + Protokolle, Reinigungsbereiche + Protokolle, Grünbereiche + Pflege, Community-Aktivitätsverwaltung, Energiezähler + Ablesung, Mitarbeiterverwaltung, Benachrichtigungsvorlagen + Versand, Genehmigungs-Engine, Zahlungsaufträge + Rückerstattung, Abstimmungsverwaltung + SLA-Regeln + Mahnstrategien + Inspektionsaufgaben + Shop-Verwaltung + Gesichtsprüfung + Konzernverwaltung + Wissensdatenbank

**Eigentümer-Portal neu**: Anmeldung zu Community-Aktivitäten, Park-/Besuchertermin, Benachrichtigungen, Abstimmung + Auszählung, Produkte ansehen + Bestellen, Intelligente Fragen & Antworten, Gesichtsregistrierung

---

## Technische Kennzahlen im Vergleich

| Kennzahl | Basisversion | Standardversion | Vollversion |
|------|:------:|:------:|:------:|
| Datenbanktabellen | 21 | 31 | 65 |
| Modelldateien | 19 | 30 | 58 |
| admin-Controller | 17 | 28 | 47 |
| service-Controller | 9 | 12 | 17 |
| admin-Routen | 45 | 80 | 123 |
| service-Routen | 20 | 35 | 55 |
| Flutter-Admin-Seiten | 4 | 7 | 57 |
| HarmonyOS-Seiten | 2 | 3 | 7 |
| Middleware | 7 | 8 | 9 |
| PHP-Tests | 18 | 18 | 133 |

---

## Sicherheitssystem (für alle drei Versionen)

18-Schichten-Verteidigung in der Tiefe: Captcha → Passwortbestätigung → Zufallsprüfung → Sicherheitsscan → Angriffsblockierung → HTTPS + AES-256-CBC → JWT → Sitzungskontrolle → Kontosperrung → RBAC → Ratenlimit → ID-Schutz → Anfrageverschlüsselung → Speicherverschlüsselung → Anzeige-Maskierung → Audit → CSP → Urheberrechtswasserzeichen

---

## Migrationspfad

```
Basisversion (Lite)
  │
  │  + 6 Hilfsmodule + Panel + Export
  ▼
Standardversion (Standard)
  │
  │  + 6 erweiterte Module + 12 Erweiterungsfunktionen
  ▼
Vollversion (Full)
```

Für ein Upgrade genügt die Ausführung der SQL-Migrationsdateien der jeweiligen Charge; keine Datenmigration oder destruktiven Änderungen erforderlich.

---

## Demovorgang

**Vorbereitung**: `docs/install.sql` wurde ausgeführt (vollständiges Tabellenschema, enthält Tabellen aller Versionen); `admin/.env` ist mit der Datenbankverbindung konfiguriert. Die Versionsunterschiede liegen in der Routenregistrierung und Funktionssichtbarkeit; das Tabellenschema ist einheitlich vollständig.

### Basisversion (Lite)

1. Demodaten ausführen: `cd admin && php ../scripts/demo_data.php` (idempotent, beliebig oft ausführbar)
2. Umfang der Demodaten: Wohnanlage/Gebäude/Einheit/Wohntyp/Immobilie/Eigentümer/Mieter/Gebühren/Rechnungen/Ankündigungen + Demo-Konten, deckt die Lite-Kernmodule ab
3. Was ansehen: Admin-Dashboard + Benutzer/Rollen/Berechtigungen/Konfiguration/Protokolle + CRUD für Immobilien/Eigentümer/Mieter/Gebühren/Reparatur/Ankündigungen; Eigentümer-Portal: Registrierung/Anmeldung, Startseite, Meine Immobilien, Rechnungszahlung, Reparatur, Ankündigungen
4. Routenunterschiede: Nur die Lite-Gruppen werden registriert; Blöcke, die von `edition_supports('standard'/'full')` umschlossen sind, werden nicht registriert (`admin/config/route.php`)

### Standardversion (Standard)

1. Demodaten ausführen: `cd admin && php ../scripts/demo_data.php` (idempotent; bei Wiederholung werden nur Lücken ergänzt, keine doppelten Daten)
2. Die Hilfsmodule haben wenig Daten; Parken/Geräte/Beschwerde/Besucher/Vertrag/Einnahmen-Ausgaben können mit wenigen Demo-Einträgen angelegt werden
3. Was ansehen: Admin-Panel neu: Parkplätze/Fahrzeuge, Gerätebuch + Wartung, Beschwerdebearbeitung + Nachbesuch, Besuchergenehmigung, Vertragsverwaltung, Einnahmen-Ausgaben-Verwaltung + Statistik; Eigentümer-Portal neu: Meine Fahrzeuge/Parkplätze, Parkprotokoll, Besuchertermin/Zugangscode
4. Routenunterschiede: `edition_supports('standard')`-Gruppen werden zusätzlich registriert, Lite-Gruppen bleiben erhalten

### Vollversion (Full)

1. Demodaten ausführen: `cd admin && php ../scripts/demo_data.php` (idempotent)
2. Demodaten für erweiterte Module (Zahlung/Genehmigung/Abstimmung/Shop/Inspektion/Gesicht/Konzern/Wissensdatenbank) nach Bedarf anlegen oder direkt mit Demo-Konten erzeugen
3. Was ansehen: zusätzlich zu Standard: Patrouille/Reinigung/Grünanlagen/Energie/Mitarbeiter/Benachrichtigungsvorlagen/Genehmigungs-Engine/Zahlungsaufträge/Abstimmung/SLA/Mahnung/Inspektion/Shop/Gesicht/Konzern/Wissensdatenbank; Eigentümer-Portal: Aktivitätsanmeldung, Benachrichtigungen, Abstimmung, Shop-Bestellung, Intelligente Fragen & Antworten, Gesichtsregistrierung
4. Routenunterschiede: Vollständige Registrierung, `edition_supports('full')`-Gruppen aktiv (`admin/config/route.php`)

### Version umschalten

```bash
# In admin/.env die Zielversion festlegen (stufenweise, full enthält alle Funktionen)
EDITIONS=lite|standard|full

# webman neu starten (Container-Bereitstellung: docker compose restart app; Bare Metal: php start.php restart)
```

- Fail-fast-Konfiguration: Ungültiger `EDITIONS`-Wert führt direkt zu einem Fehler (`admin/config/edition.php`), kein stilles Zurückfallen auf eine falsche Version.
- Das Demo-Datenskript ist idempotent; ein Versionswechsel erfordert kein Leeren der Datenbank. Die Standard-/Full-Module haben wenig Daten und werden über echte Geschäftseingaben befüllt.
