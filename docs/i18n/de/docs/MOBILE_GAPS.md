# Checkliste zur Schließung der Mobile-Lücken

> Erstellungsdatum: 2026-08-16 · Quelle: pmp-team ci-agent (P3-③ Bestandsaufnahme, nur lesend)
> Entsprechender Fahrplan: docs/PROJECT_PLAN.md P3 — „HarmonyOS von 7 auf Kernpfade erweitern (Zahlung/Reparatur/Ankündigung/Besucher/Parken), Flutter-Eigentümer-Portal für Mobilgeräte anpassen"

## I. Ist-Zustand des HarmonyOS-Eigentümer-Portals (apps/harmonyos, 7 Seiten)

| Seite | Route (in main_pages.json registriert) | Aufgerufene API |
|------|------------------------------|---------|
| LoginPage | pages/LoginPage | Anmeldung (AuthService) |
| HomePage | pages/HomePage | GET /service/home (Dashboard: offene Zahlungen/Aufträge/Immobilienzahl + Ankündigungsliste) |
| FeeBillsPage | pages/FeeBillsPage | GET /service/fees/bills?page=1&per_page=50 |
| RepairListPage | pages/RepairListPage | GET /service/repairs |
| RepairSubmitPage | pages/RepairSubmitPage | POST /service/repair |
| AnnouncementPage | pages/AnnouncementPage | GET /service/announcements?page=1&per_page=50 |
| ProfilePage | pages/ProfilePage | GET /service/profile、POST /service/profile/logout |

**Navigations-Status** (gesamte App nur 4 Sprünge): Login→Home、Home→Login (Abmelden)、Profile→Login、RepairList→RepairSubmit. Die HomePage hat nur Statistik-Karten + Ankündigungsliste, kein Funktionseingangs-Raster; die Seiten FeeBills/Announcement/Profile existieren, haben aber **keinen Eingang und sind nicht erreichbar**.

## II. Kernpfad-Abgleich HarmonyOS

| Kernpfad | Ist-Zustand | Lückenart |
|---------|------|---------|
| Zahlung | Seite vorhanden, API funktioniert | Nur Frontend: Home ohne Eingang (nicht erreichbar) |
| Reparatur | Listen- + Einreichungsseite vorhanden, API funktioniert | Nur Frontend: Home ohne Eingang (nicht erreichbar) |
| Ankündigung | Seite vorhanden, API funktioniert | Nur Frontend: Home ohne Eingang (nicht erreichbar) |
| Besucher | Seite fehlt | Neue Seite erforderlich (API vorhanden: GET/POST/PUT/DELETE /visitor*) |
| Parken | Seite fehlt | Neue Seite erforderlich (API vorhanden: /parking/vehicles、/parking/spaces、/parking/records) |

Keine Backend-Lücken: Die service APIs der 5 Kernpfade sind alle fertig (fees/repairs/announcements als permanente Routen; parking/visitors hinter der Standard-Edition-Sperre). ApiService.ets hat bereits generische get/post/put/delete; neue Seiten können direkt darauf aufbauen.

## III. Ist-Zustand des Flutter-Eigentümer-Portals (apps/flutter, 13 Module)

**Seitenliste**: login、home、fee、repair、parking×3、visitor×2、activity、notification、vote、mall×3、chat、face、profile — alle routenregistriert (app.dart getPages), alle 5 Kernpfade implementiert.

**Mobile-Anpassungsproblem**: Nur home_page / login_page verwenden LayoutBuilder/MediaQuery mit responsiven Breakpoints; **10 Seiten haben hartkodierte Desktop-Breiten**, bei Handybreite (<400px) kommt es zwangsläufig zu RenderFlex-Überläufen:

| Seite | Hartkodierung |
|------|--------|
| chat_page | SizedBox(width: 600) |
| mall_products_page | width: 800 |
| mall_product_detail / mall_orders | SizedBox(width: 600) |
| notification_list | width: 480 + SizedBox(width: 600) |
| vote_list / vote_detail | SizedBox(width: 600) |
| activity_detail、parking_records/vehicles、visitor_list、face_register | keine Breakpoint-Behandlung (vermutlich gleiche Probleme, nicht zeilenweise geprüft) |

Außerdem: keine untere Navigationsleiste (BottomNavigationBar), Eingänge über AppBar + Raster; Seiten-Padding 24 eher Desktop-Stil. i18n-Zweisprachigkeit vorhanden.

## IV. Lückenliste (kategorisiert + Aufwand)

### Backend-Abhängigkeiten (keine)

### Nur Frontend

| # | Punkt | Aufwand |
|---|----|--------|
| 1 | HarmonyOS HomePage um Funktionseingangs-Raster erweitern (analog zum Flutter-12-Eingänge), Zahlung/Reparatur/Ankündigung/Besucher/Parken/Profil anbinden | M |
| 2 | HarmonyOS neue VisitorPage (Liste + Anlegen, nutzt VisitorController) | M |
| 3 | HarmonyOS neue ParkingPage (Fahrzeuge/Parkplätze/Protokolle, nutzt ParkingController) | M |
| 4 | Flutter-Eigentümer-Portal: hartkodierte Breiten beseitigen (600/800/480 → innerhalb maxWidth begrenzen oder ConstrainedBox verwenden) | S |
| 5 | Flutter-Eigentümer-Portal: untere Navigationsleiste + kompaktes Padding ergänzen (falls Handy als Abnahmeziel) | M |

### Abnahme/Integration erforderlich

| # | Punkt | Aufwand |
|---|----|--------|
| 6 | HarmonyOS auf echtem Gerät/Emulator: Zahlung→Bezahlung, Reparatur-Einreichung, Besucherregistrierung als Gesamtkette verifizieren | S (durch Testgeräte begrenzt, PROJECT_PLAN hat dieses Risiko bereits gelistet) |

## V. Empfohlene Umsetzungsreihenfolge

1. Lücke 1 (beste Preis-Leistung: nutzt die 3 vorhandenen Seiten, null neue Seiten)
2. Lücke 4 (Flutter-Überlauf ist ein harter Fehler, Handy stürzt sicher ab)
3. Lücken 2、3 (neue Seiten)
4. Lücke 5 (Erlebnisoptimierung)
5. Lücke 6 (erfordert Geräte, unabhängig durchführen)
