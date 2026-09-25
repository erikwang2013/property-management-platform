# Funktionsdesign-Dokument (Feature Design)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

<img src="../../../images/pet_xiaozhu.svg" alt="小筑 · project mascot" width="110" align="right">

<img src="../../../images/design_function.svg" alt="Funktionsmodul-Gesamtübersicht" width="1000">

> English edition: `../../../images/design_function_en.svg`


## Überblick

Das Immobilienverwaltungssystem gliedert sich in **Admin-Panel** (interne Nutzung durch die Verwaltungsgesellschaft) und **Eigentümer-Portal** (Nutzung durch Eigentümer/Mieter der Wohnanlage) und deckt 15 Geschäftsmodule ab, die in 3 Chargen geliefert werden.

---

## Charge 1: Kernbetrieb

### 1. Wohnanlagen-/Gemeindeverwaltung (Community)

**Admin-Panel:**
- Wohnanlagenliste (Suche, Paginierung, Statusfilter)
- Wohnanlage erstellen/ansehen/bearbeiten/löschen
- Wohnanlagen-Informationen: Name, Adresse (Provinz/Stadt/Kreis), Gebäudefläche, Anzahl Gebäude, Anzahl Wohneinheiten, Bauträger, Verwaltungsgesellschaft, Telefonnummer
- Löschen erfordert Passwort-Zweitbestätigung, verwendet Soft-Delete

**Eigentümer-Portal:** Keine Verwaltungsrechte nötig; die Startseite zeigt die Informationen der gebundenen Wohnanlage.

### 2. Gebäudeverwaltung (Building)

**Admin-Panel:**
- Gebäudeliste nach Wohnanlage filtern
- Gebäude erstellen/ansehen/bearbeiten/löschen
- Gebäude-Informationen: Name, Typ (Hochhaus/Plattenbau/Villa/Gewerbe), Anzahl Etagen, Anzahl Einheiten, Anzahl Aufzüge, Baujahr, Konstruktionstyp
- Sortierung unterstützt

### 3. Einheitenverwaltung (Unit)

**Admin-Panel:**
- Einheitenliste nach Gebäude filtern
- Einheit erstellen/ansehen/bearbeiten/löschen
- Einheiten-Informationen: Name, Anzahl Wohnungen pro Etage

### 4. Wohntypverwaltung (RoomType)

**Admin-Panel:**
- CRUD der Wohntypenliste
- Wohntyp-Informationen: Name (z. B. 3 Zimmer/2 Wohnzimmer), Anzahl Zimmer/Wohnzimmer/Bäder, Wohntyp-Grundriss

### 5. Immobilienverwaltung (Room)

**Admin-Panel:**
- Immobilienbaumansicht (Wohnanlage → Gebäude → Einheit → Wohnung)
- Immobilie erstellen/ansehen/bearbeiten/löschen
- Immobilien-Informationen: Wohnungsnummer, Etage, Wohntyp, Fläche (Wohnfläche/Gemeinschaftsfläche/Gesamtfläche), Ausrichtung, Ausstattung, Nutzung (Wohnen/Gewerbe/Büro), Status (leer/verkauft/vermietet/selbst genutzt)
- Eigentümer in Serie binden/lösen

**Eigentümer-Portal:**
- Liste meiner gebundenen Immobilien ansehen
- Immobiliendetails ansehen (Fläche, Ausrichtung, Wohntyp, Eigentumsinformationen)

### 6. Eigentümerverwaltung (Owner)

**Admin-Panel:**
- Eigentümerliste (Suche, Paginierung, Statusfilter)
- Eigentümer erstellen/ansehen/bearbeiten/löschen
- Eigentümer-Informationen: Name, Mobilnummer (verschlüsselt), E-Mail (verschlüsselt), Personalausweis (verschlüsselt), Geschlecht, Geburtstag, Notfallkontakt, Einzugsdatum
- Massenimport (Excel), Massenaktivierung/-deaktivierung, Massenlöschen
- Immobilienbindung/-lösung

**Eigentümer-Portal:**
- Registrierung (Mobilnummer + Passwort + Verifizierungscode, optional mit Immobilienbindungs-Verifizierung)
- Anmeldung (Mobilnummer + Passwort + Klick-Verifizierungscode, Kontosperr-Schutz)
- Persönliche Informationen ansehen/ändern
- Passwort ändern, Abmelden

### 7. Mieterverwaltung (Tenant)

**Admin-Panel:**
- Mieterliste nach Immobilie/Vermieter filtern
- Mieter erstellen/ansehen/bearbeiten/löschen
- Mieter-Informationen: Name, Mobilnummer (verschlüsselt), Personalausweis (verschlüsselt), Mietvertragszeitraum, Monatsmiete, Status

### 8. Gebührenverwaltung (Fee)

**Gebührenarten (Admin-Panel):**
- CRUD der Gebührenarten: Hausgeld, Wasser, Strom, Gas, Heizung, Parkgebühr, Instandhaltungsrücklage, Sonstige
- Einzelpreis, Abrechnungseinheit (EUR/m²/Monat, EUR/t, EUR/kWh usw.), Abrechnungszeitraum (monatlich/vierteljährlich/jährlich), Pflichtfeld

**Rechnungsverwaltung (Admin-Panel):**
- Rechnungen nach Wohnanlage/Gebäude/Immobilie abfragen
- Rechnung manuell erstellen/bearbeiten
- Rechnungen in Serie erzeugen (Wohnanlage + Gebührenart + Zeitraum wählen, automatisch für alle Wohnungen erzeugen)
- Rechnungs-Informationen: Gebührenart, Betrag, Mahngebühr, Gebührenzeitraum, Fälligkeitsdatum
- Status: unbezahlt/teilbezahlt/bezahlt/überfällig/befreit
- Massen-Mahnbenachrichtigungen

**Rechnungen (Eigentümer-Portal):**
- Meine Rechnungsliste (nach Status filtern: unbezahlt/bezahlt/überfällig)
- Rechnungsdetails
- Online-Bezahlung (WeChat/Alipay, erfordert Passwort-Zweitbestätigung)
- Zahlungsverlauf abfragen
- Gebührenstatistik (Jahres-/Monatstrend, Anteil nach Gebührenkategorie)

**Zahlungsaufzeichnungen (Admin-Panel):**
- Zahlungsverlauf abfragen
- Offline-Zahlungserfassung (Barzahlung/Kartenzahlung/Überweisung)

### 9. Reparaturauftragsverwaltung (Repair)

**Admin-Panel:**
- Reparaturauftragsliste (nach Status/Kategorie filtern)
- Reparaturauftragsdetails ansehen
- Auftragszuweisung (Reparaturpersonal zuweisen)
- Reparaturfortschritt aktualisieren

**Eigentümer-Portal:**
- Meine Reparaturauftragsliste
- Reparaturauftrag einreichen (Immobilie, Kategorie, Dringlichkeit, Beschreibung, Bilder hochladen, Termin wählen)
- Reparaturauftragsdetails und Fortschritt ansehen
- Reparaturauftrag stornieren (nur im Status „wartet auf Zuweisung", mit Passwortbestätigung)
- Reparaturauftrag bewerten (1-5 Sterne + Textbewertung)

### 10. Bekanntmachungen (Announcement)

**Admin-Panel:**
- CRUD der Bekanntmachungsliste
- Bekanntmachungen je Wohnanlage veröffentlichen
- Kategorien: Hinweis/Bekanntmachung/Erinnerung/Aktivität
- Anpinnen, Entwurf/Veröffentlicht-Status

**Eigentümer-Portal:**
- Liste der veröffentlichten Bekanntmachungen ansehen (nach Kategorie filtern)
- Bekanntmachungsdetails

---

## Charge 2: Zusatzbetrieb

### 11. Parkplatzverwaltung (Parking)

**Admin-Panel:**
- Stellplatzverwaltung (Nummer, oberirdisch/unterirdisch, Fläche, Status: frei/verkauft/vermietet/Instandhaltung)
- Fahrzeugverwaltung (Kennzeichen verschlüsselt, Marke, Farbe, Typ, gebunden an Stellplatz/Eigentümer)
- Parkaufzeichnungen abfragen (Einfahrt-/Ausfahrtszeit, Parkdauer, Gebühr)

**Eigentümer-Portal:**
- Meine Fahrzeugliste
- Meine Stellplatzliste
- Parkaufzeichnungen abfragen

### 12. Geräteverwaltung (Equipment)

**Admin-Panel:**
- Gerätebestand (Name, Nummer, Kategorie: Aufzug/Brandschutz/Zutritt/Überwachung/Wasser & Abwasser/Stromversorgung/HLK)
- Geräte-Informationen: Marke, Modell, Einbauort, Einbaudatum, Garantieablauf, Auslegungslebensdauer
- Wartungsaufzeichnungen: Routineinspektion/regelmäßige Wartung/Fehlerbehebung/Großreparatur/Austausch
- Wartungspersonal, Kosten, Wartungsunternehmen, nächster Wartungstermin

### 13. Beschwerden & Vorschläge (Complaint)

**Admin-Panel:**
- Beschwerdeliste (nach Typ/Status filtern)
- Beschwerde bearbeiten (Bearbeiter zuweisen, Bearbeitungsvermerk eintragen)
- Rückrufregistrierung (Rückrufvermerk, Zufriedenheitserfassung)

**Eigentümer-Portal:**
- Meine Beschwerden-/Vorschlagsliste
- Beschwerde/Vorschlag einreichen (Typ: Beschwerde/Vorschlag/Lob, Kategorie: Service/Umwelt/Sicherheit/Anlagen/Lärm/Schwarzbau)
- Anonymes Einreichen und Bild-Upload unterstützt
- Bearbeitungsfortschritt ansehen
- Zufriedenheitsbewertung

### 14. Besucherverwaltung (Visitor)

**Admin-Panel:**
- Genehmigung von Besucherterminen
- Besucherprotokoll abfragen

**Eigentümer-Portal:**
- Besuchertermin (Besuchername, Telefon, Personalausweis, Kennzeichen, Anzahl Begleitpersonen, Besuchsgrund, voraussichtliche Zeit)
- Zugangscode erzeugen
- Termin ändern/stornieren

### 15. Vertragsverwaltung (Contract)

**Admin-Panel:**
- Vertragsliste (nach Typ/Status filtern)
- Vertragsarten: Hausverwaltungsvertrag/Mietvertrag/Wartungsvertrag/Dienstleistungsvertrag/Beschaffungsvertrag
- Vertrags-Informationen: Nummer, Vertragsparteien, Betrag, Laufzeit, Unterzeichnungsdatum, Anlagen
- Status: Entwurf/laufend/abgelaufen/beendet/verlängert

### 16. Finanzverwaltung (Finance)

**Admin-Panel:**
- Einnahmenverwaltung (Hausgeld/Parkgebühr/Miete/Werbeeinnahmen/Instandhaltungsrücklage/Sonstige)
- Ausgabenverwaltung (Personal/Gerätebeschaffung/Wartung/Energie/Reinigung & Grünflächen/Büro/Steuern/Sonstige)
- Einnahmen-/Ausgabenstatistikberichte (monatlich/vierteljährlich/jährlich)

---

## Charge 3: Erweiterte Funktionen

### 17. Sicherheitspatrouille (Security Patrol)

**Admin-Panel:**
- Patrouillenroutenverwaltung (Routen-Koordinaten, Kontrollpunkte)
- Patrouillenprotokoll (Start-/Endzeit, Dauer, Anomalievermerk)
- Patrouillen-Abschlussquotenstatistik

### 18. Reinigungsverwaltung (Cleaning)

**Admin-Panel:**
- Reinigungsbereichsverwaltung (Ort, Fläche, Frequenz: täglich/wöchentlich/alle zwei Wochen/monatlich)
- Reinigungsprotokoll (Reinigungszeit, Prüfer, Prüfvermerk, Vor-Ort-Fotos)
- Reinigungs-Abschlussquotenstatistik

### 19. Grünflächenverwaltung (Green)

**Admin-Panel:**
- Grünflächenbereichsverwaltung (Ort, Fläche, Hauptpflanzen)
- Pflegeprotokoll (Bewässerung/Schnitt/Düngung/Schädlingsbekämpfung/Nachpflanzung, Kosten)

### 20. Gemeinschaftsaktivitäten (Activity)

**Admin-Panel:**
- Aktivitätsverwaltung (Titel, Inhalt, Kategorien: Sport/Feste/Wohltätigkeit/Vorträge/Familie)
- Titelbild, Ort, maximale Teilnehmerzahl, Zeit, Kosten
- Status: Anmeldung läuft/laufend/beendet/abgesagt
- Anmeldeliste ansehen

**Eigentümer-Portal:**
- Aktivitätsliste (Filter: Anmeldung läuft/laufend)
- Aktivitätsdetails
- Anmelden/Anmeldung stornieren

### 21. Energiemanagement (Energy)

**Admin-Panel:**
- Zählerverwaltung (Stromzähler/Wasserzähler/Gaszähler/Wärmezähler, Nummer)
- Ableseprotokoll (aktueller Stand, Verbrauch, Einzelpreis, Gebühr)
- Automatische Erzeugung zugehöriger Rechnungen

### 22. Mitarbeiterverwaltung (Staff)

**Admin-Panel:**
- Mitarbeiter-Informationen (Name, Mobilnummer verschlüsselt, Personalausweis verschlüsselt, Position, Abteilung, Eintrittsdatum)
- Abteilungen: Verwaltung/Kundenservice/Technik/Sicherheit/Reinigung/Grünflächen/Finanzen
- Status: aktiv/ausgeschieden/beurlaubt

---

## Panel-Visualisierung und Export

### Dashboard-Panels

**Admin-Panel-Dashboard:**
- Kernkennzahlen-Karten: Gesamtforderungen, Gesamteinnahmen, Rückstandsquote, Belegungsquote
- Gebührentrend-Liniendiagramm (monatlich/vierteljährlich)
- Kreisdiagramm nach Gebührenkategorie
- Reparaturstatistik (nach Kategorie, nach Status)
- Beschwerdestatistik
- Letzte Betriebsprotokolle

**Eigentümer-Portal-Startseite:**
- Anzahl meiner Immobilien, offener Zahlungsbetrag, Anzahl laufender Reparaturaufträge, neueste Bekanntmachungen

### Excel-Export

- Export der Eigentümerliste
- Export der Rechnungsberichte
- Export der Zahlungsaufzeichnungen
- Export der Finanzberichte
- Automatische Maskierung sensibler Daten beim Export

### PDF-Export

- Export der Dashboard-Visualisierung
- Finanzbericht als PDF (Seitenkopf mit Copyright + nicht entfernbarer Copyright-Wasserzeichen in der Fußzeile)
- A4-Querformat

---

## Modulübergreifende Funktionen

| Funktion | Beschreibung |
|------|------|
| ID-Schutz | Alle Schnittstellen-IDs werden per hashids kodiert übertragen |
| Datenverschlüsselung | Sensible Felder (Mobilnummer/E-Mail/Personalausweis) per AES-256-CBC in der API-Schicht, encryptable in der DB-Schicht |
| Betriebsprüfung | Alle Admin-POST/PUT/DELETE-Vorgänge werden automatisch protokolliert, inkl. automatischer Erkennung der Quellplattform |
| Zugriffskontrolle | RBAC mit method.path-Granularität, Superadministrator mit *-Kennzeichnung |
| Ratenbegrenzung | Redis-Sliding-Window, Anmeldung 10-mal/Minute, Registrierung 5-mal/Minute |
| Verifizierungscode | Klickbasierter chinesischer Verifizierungscode, Pflicht bei Anmeldung/Registrierung |
| Soft-Delete | Eigentümer, Wohnanlagen, Immobilien und Bekanntmachungen unterstützen Soft-Delete |
| Internationalisierung | Zweisprachig Chinesisch/Englisch, PHP symfony/translation + Flutter GetX Translations, Standard Chinesisch, Fallback Englisch |
| API-Dokumentation | Automatisch per `hg/apidoc` erzeugt, 57 der 58 Controller nach 10 Gruppen annotiert (Base/Docs/Install nicht gruppiert), `/apidoc/config` bietet die Konfigurations-API |
| Tests | TDD-Prozess, 133 Tests/465 Assertions, service 100 % bestanden, flutter analyze null Probleme |
| Flutter Web | 13 Seiten (Anmeldung/Startseite/Gebühren/Reparatur/Personalbereich usw.), PC-Desktop-Stil, GetX-Zustandsverwaltung |
| HarmonyOS | Vollständiges Projektskelett, ArkTS-Servicelayer + Authentifizierung + Anmeldung/Startseite, @ohos.net.http |

## Erweiterte Funktionen (Charge 4)

### Nachrichtenzentrale
- Konfigurierbare Benachrichtigungsvorlagen (App-Push/SMS/E-Mail)
- Rechnungserinnerungen, Reparaturfortschritt, Bekanntmachungsveröffentlichung automatisch benachrichtigen
- Nachrichtenliste im Eigentümer-Portal + Gelesen-Verwaltung

### Genehmigungs-Workflow-Engine
- Konfigurierbare Genehmigungstypen und -schritte (Vorgesetzter → Abteilungsleiter → Geschäftsführer)
- Reparaturauftragszuweisung/Besuchergenehmigung/Vertragsgenehmigung laufen über standardisierte Prozesse
- Genehmigungsprotokolle nachvollziehbar

### Zahlungsintegration
- WeChat-/Alipay-Zahlungsauftragsverwaltung
- Zahlungs-Callback-Verarbeitung, Rückerstattung, Abgleichstatistik
- Automatische Aktualisierung zugehöriger Rechnungen

### Eigentümer-Abstimmung/Beschluss
- Normale Abstimmung + Eigentümerversammlungs-Beschluss (nach Fläche gewichtet)
- Optionsverwaltung, Abstimmungsprotokoll, automatische Auszählung
- Teilnahmequotenstatistik

### Reparatur-SLA-Automatik-Eskalation
- Antwort-/Lösungsfristen nach Kategorie + Dringlichkeit konfigurieren
- Automatische Eskalation an die nächsthöhere Rolle bei Zeitüberschreitung
- Automatische Erfassung von Verspätungsstrafen

### Intelligente Mahnung
- Gestaffelte Mahnstrategie konfigurieren (überfällige Tage → Aktion)
- Automatisches Mahnen überfälliger Rechnungen (App/SMS/Telefon/Hausbesuch)
- Automatische Berechnung der Mahngebühr

### Inspektions-Mobilanwendung
- Inspektionsaufgaben zuweisen (GPS-Route + Kontrollpunkte)
- Mobile Stempelung (Standort + Foto + Anomalie-Markierung)
- Inspektions-Abschlussquotenstatistik

### Gemeinschafts-Marktplatz
- Warenkategorien/Veröffentlichung/Zurückziehen verwalten
- Eigentümer browsen + bestellen + Auftragsverfolgung
- Versand-/Rückerstattungsverwaltung

### Gesichtserkennung
- Gesichtsregistrierung der Eigentümer (Anbindung an Drittanbieter-Erkennungsdienst)
- Prüfung und Freischaltung im Admin-Panel
- Verknüpfung mit Zutrittskontrolle

### Gruppenverwaltung mehrerer Wohnanlagen
- Gruppe→Wohnanlage-Viel-zu-Viel-Verknüpfung
- Datenaggregation über Wohnanlagen hinweg (einheitliche Ansicht für Immobilien/Eigentümer/Gebühren)

### Intelligente Frage-Antwort
- Wissensdatenbankverwaltung (Kategorien/Artikel/Schlüsselwörter)
- Automatische Zuordnung von Eigentümerfragen
- Dialogprotokoll + Lösungsquotenstatistik

### Daten-Großbildschirm
- Vollbild-Echtzeitvisualisierung der Immobilienverwaltungsdaten
- Vier Panels: Gebühren/Reparatur/Geräte/Energie
- Automatische Rotation und Aktualisierung
