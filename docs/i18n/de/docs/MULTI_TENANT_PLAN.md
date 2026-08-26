# Bewertung des Multi-Tenant-SaaS-Plans (Multi-Tenant Plan)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> Status: Bewertungsentwurf (P3-① Vorabaufgabe) | Datum: 2026-08-16

## 1. Bestandsaufnahme

### 1.1 Tabellenstruktur-Klassifizierung (65 Tabellen, per docs/install.sql verifiziert)

| Kategorie | Tabellen | Beschreibung |
|------|-----|------|
| Global/Plattform-Tabellen | erik_admin_user / admin_role / admin_permission / admin_user_role / admin_role_permission、erik_system_config、erik_operation_log | Autorisierung, Konfiguration, Audit — naturgemäß plattformweit, nicht an Mandanten gebunden |
| Wohnanlagen-dimensionale Tabellen | erik_community und 40+ Geschäftstabellen, die über community_id zugeordnet sind (building/unit/room/owner/fee_*/repair_order/parking_*/announcement usw.) | über community_id indirekt dem Mandanten zugeordnet |
| Konzern-Verknüpfungstabellen | erik_group (Konzern)、erik_group_community (Konzern↔Wohnanlage) | derzeit **optionale Verknüpfung**, keine Mandantensemantik, wohnanlagenübergreifende Zusammenfassung per join |
| Plattform-Erweiterungstabellen | erik_notification_template、erik_knowledge_base、erik_mall_*、erik_face_info usw. | teils plattformweit, teils wohnanlagenweit; Fallweise Prüfung erforderlich |
| Verwechselbare Tabelle | **erik_tenant (Mieter-Tabelle)** | ⚠️ Semantikkonflikt: es ist der „Wohnungsmieter" (Dimension room_id/owner_id), **nicht** der SaaS-Mandant |

### 1.2 Autorisierungskette (admin-Seite, code-verifiziert)

```
Globale Middleware: Cors → SecurityFilter → RateLimit
Routengruppen-Middleware: AdminAuth(JWT → $request->adminId) → AdminPermission(RBAC method.path) → OperationLog → Controller
```

- `AdminAuth` hat bereits ein Request-Injektionsmuster (`$request->adminId`); der Mandantenkontext kann vollständig nachgebildet werden
- `AdminPermission` ist plattformweites RBAC, **orthogonal** zur Mandantenisolierung, überlagerbar
- service-Eigentümer-Portal: JWT trägt owner_id, Daten sind über room_owner → room.community_id natürlich eingeschränkt, Cross-Tenant-Risiko gering

### 1.3 Kernschlussfolgerungen

- Es gibt kein vorhandenes SaaS-Mandantenmodell; der Name `erik_tenant` ist bereits vom Mieter belegt, das neue Konzept muss den Namen meiden
- Alle Controller verwenden direkte Eloquent-Abfragen, keine Repository-Schicht, keine globalen Scopes — die Isolierung muss auf Modellebene umgesetzt werden
- config/database.php hat eine einzelne Verbindung, aber illuminate/database unterstützt nativ mehrere connections (Reserve für die Evolution zu getrennten Datenbanken)

## 2. Lösungsvergleich und Empfehlung

| Lösung | Mechanismus | Umbauaufwand | Betriebskosten | Geeignet für |
|------|------|--------|----------|------|
| **A. Gemeinsame DB + tenant_id-Zeilenisolierung (empfohlen)** | Mandantentabelle + tenant_id-Spalte in Geschäftstabellen + Eloquent-Globalscope-Filter | Mittel (2 Tabellen mit Spalte + Middleware + Globalscope + Altdaten-Befüllung) | Niedrig (Einzel-DB-Backup/Migration unverändert) | Mittel-/Klein-Wohnanlagen, <5 Mio. Zeilen pro Mandant |
| B. Getrennte Datenbank (eine DB pro Mandant) | Verbindungs-Routing + datenbankübergreifende Aggregation | Hoch (Verbindungsverwaltung/DB-übergreifende Berichte/Migration×N/Backup×N) | Hoch | Große Konzerne, Compliance-Isolierungsanforderungen |
| C. Hybrid (sensible DB getrennt + gemeinsame) | A+B-Kombination | Hoch | Hoch | Starke Isolierungsszenarien wie Zahlung/Gesicht |

**Empfehlung A, B als Evolutionsrichtung.** Gründe:

1. Die bestehenden 65 Tabellen liegen einheitlich in einer DB; das tenant_id-Datenmodell von A behindert eine spätere Aufteilung nicht (der Filter wechselt von Zeilen- auf DB-Granularität; unter A ist die Mandanten-ID bereits global modelliert)
2. Alle Geschäftsdaten sind über community_id zugeordnet; tenant_id muss nur in den **Top-Level-Tabellen** ergänzt werden, die 40 Zwischentabellen werden über den Zugriffspfad abgesichert, keine spaltenweise Erweiterung
3. Beide Enden (admin/service) teilen dasselbe Datenmodell; der Umbau von A konzentriert sich auf die Laufzeitschicht des admin
4. Bei der aktuellen Einzelmaschinen-Bereitstellung ist die Backup-/Migrationskomplexität von B nicht tragbar

## 3. Isolationspunkt-Design

### 3.1 Datenmodell (minimaler Satz)

- Neue Tabelle `erik_platform_tenant` (Vermeidung des Konflikts mit der Mietertabelle erik_tenant): id/name/status/created_at usw.
- `erik_community` erhält `tenant_id BIGINT NOT NULL DEFAULT 0`, Index `(tenant_id, community_id)`
- `erik_admin_user` erhält `tenant_id BIGINT NOT NULL DEFAULT 0` (0 = Plattform-Superadministrator)
- Die 40 Geschäftszwischentabellen (building/room/fee_bill usw.) **erhalten keine Spalte**, Zuordnung über community_id

### 3.2 Laufzeitschicht-Dreiergespann

1. **TenantContext-Middleware**: JWT-Payload um den Anspruch `tenant_id` erweitern → `$request->tenantId` (Nachbildung des AdminAuth-Injektionsmusters); Freigabeliste für Anmeldung/Installation/plattformweite Routen (user/role/permission/config)
2. **TenantScope-Globalscope**: Eloquent-Globalscope an Community und plattformweite Geschäftsmodelle hängen, automatischer Filter nach `$request->tenantId`; `find()` ist ebenfalls durch den Scope begrenzt — verhindert von Natur aus direkte Einzelabfragen über Mandantengrenzen
3. **Tenant::for() expliziter Kontext**: Geplante Aufgaben/Queues/Importe haben keine HTTP-Anfrage; mit Closures explizit den Mandanten angeben; bei fehlendem Kontext **fail-closed** (Abfrage verweigern), kein stilles Durchlassen ohne Filter

### 3.3 Testschwerpunkte für die Zugriffsschutzprüfung (Abnahmematrix)

| Testfall | Erwartung |
|------|------|
| Admin von Mandant A listet community/building/fee_bill von Mandant B | Leeres Ergebnis oder nur A-Daten |
| Admin von Mandant A ruft Einzelsätze von Mandant B per find/update/delete ab (direkte id-Abfrage) | 403 / leere Daten / Verweigerung |
| Plattform-Admin (tenant_id=0) führt mandantenübergreifende Aktionen aus | Durchlass (Plattform-Fähigkeit) |
| Eigentümer des service-Portals führt wohnanlagenübergreifende Aktionen aus (Zahlung/Reparatur) | Verweigerung (community-Zugehörigkeitsprüfung) |
| Geplante Aufgabe/Queue ohne Mandantenkontext | fail-closed mit Fehler statt ohne Filter |

## 4. Evolutionspfad (schrittweise Migration)

| Schritt | Inhalt | Abnahme |
|------|------|------|
| 1. Datenebene | platform_tenant-Tabelle anlegen + Spalten in community/admin_user + idempotente Migration + Standardmandanten initialisieren und Altdaten befüllen | Jede community muss einen Mandanten haben, Bericht über verwaiste Daten auf null |
| 2. Laufzeitschicht | TenantContext-Middleware + TenantScope + Tenant::for()-Werkzeug + Routen-Freigabeliste | Single-Tenant-Regression: alle 133 Tests bestanden |
| 3. Pilotmodule | Konzernverwaltung → Wohnanlage → Eigentümer → Gebühren (Rechnungen): zuerst diese vier Module isolieren | Zugriffsschutz-Testmatrix bestanden |
| 4. Vollständiger Rollout | Modulweise nach Charge (1. Charge Kern → 2. Charge Hilfsfunktionen → Erweiterungsmodule) | Zugriffsschutzmatrix für alle Module bestanden |
| 5. Evolution | Bei >5 Mio. Zeilen pro Mandant oder Compliance-Anforderungen Datenbankaufteilung prüfen (Lösung B); das Datenmodell von A blockiert nicht | Bewertung des Aufteilungsplans |

Datenmigrationsstrategie: Alle Altdaten werden dem „Standardmandanten" zugeordnet (vom Migrationsskript erstellt); keine Geschäftsdaten werden gelöscht oder geändert; das Migrationsskript ist idempotent und beliebig oft ausführbar.

## 5. Risikoliste

| Risiko | Betroffener Bereich | Abschwächung / Rollback |
|------|--------|-------------|
| Umbau der 58+17 Controller-Abfragepfade ist umfangreich | Alle Geschäftsschnittstellen | Globalscope deckt ~80% Listen/Details ab; raw queries und Massenimporte über Tenant::for(); chargeweise Canary-Rollout |
| Globalscope verletzt plattformweite Abfragen (Dashboard mit wohnanlagenübergreifender Zusammenfassung) | Dashboard/Berichte | Plattformschnittstellen explizit mit Tenant::without() oder tenant_id=0-Bypass |
| Geplante Aufgaben/Queues ohne Anfragekontext | Hintergrundaufgaben wie Mahnung/SLA/Benachrichtigung | Explizit mit Tenant::for() umschließen + fail-closed |
| Fehler bei der Befüllung von Altdaten | Alle Altdaten | Idempotentes Skript + Befüllungsvalidierung + Dry-Run-Modus |
| Index-/Leistungseinfluss | Hochfrequente Tabellen (fee_bill/room/owner) | Gemeinsamer Index (tenant_id, community_id); Überprüfung der Slow-Query-Logs |
| Regression der 133 Tests | Gesamtumfang | Nach Scope-Injektion erst vollständige Regression laufen lassen, dann Pilot starten |
| Namensverwechslung (erik_tenant Mieter vs. SaaS-Mandant) | Entwicklerkognition | Neue Tabelle als platform_tenant benennen, explizit in der Dokumentation erklären |
| **Rollback-Plan** | — | Globalscope per Konfigurationsschalter einstellbar (Single-Tenant-Semantik wiederherstellen), Datenspalten bleiben ohne Löschung erhalten, keine destruktiven Änderungen |

## 6. Bewertungsergebnis

**Sofort empfohlen**:
- Gemeinsame DB + tenant_id-Zeilenisolierung (Lösung A), neue Tabelle `erik_platform_tenant`, community/admin_user um Spalten erweitern
- TenantContext-Middleware + TenantScope-Globalscope + Tenant::for()-Werkzeug
- Pilotreihenfolge: Konzern → Wohnanlage → Eigentümer → Gebühren
- Vorausgesetzte Abhängigkeit: erledigt — Multi-Tenant-Tabellen/Spalten/Befüllung sind in docs/install.sql integriert (2026-08-16 zusammengeführt, einziger Datenbank-Einstiegspunkt)

**Später empfohlen**:
- Getrennte DB-Isolierung (B): nur bei >5 Mio. Zeilen pro Mandant oder Compliance-Anforderungen starten; Datenmodell ist vorbereitet
- Hybride Lösung (C): erst bei expliziter Kundennachfrage für stark isolierte Szenarien wie Zahlung/Gesicht bewerten

**Nicht empfohlen**:
- Schema-Ebenen-Isolierung (MySQL hat keine eigenständige Schema-Semantik, Kosten gleichwertig zur getrennten DB)
- Dynamisches Multi-DB-Routing (bei Einzelmaschinen-Bereitstellung kein Nutzen)
- Mandantenindividuelle Schema/Felder (YAGNI)
- Die Mietertabelle erik_tenant als SaaS-Mandanten umnutzen/umbauen (Semantikkonflikt, zerstört die Mietergeschäftsfunktion)
