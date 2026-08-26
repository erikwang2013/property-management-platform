# Mobile Gap List

> Generated: 2026-08-16 · Source: pmp-team ci-agent (P3-③ current-state inventory, read-only)
> Corresponding roadmap: docs/PROJECT_PLAN.md P3 — "Expand HarmonyOS from 7 pages to core paths (payments/repairs/announcements/visitors/parking), Flutter owner-side mobile adaptation"

## 1. HarmonyOS Owner Portal Current State (apps/harmonyos, 7 pages)

| Page | Route (registered in main_pages.json) | API Called |
|------|------------------------------|---------|
| LoginPage | pages/LoginPage | Login (AuthService) |
| HomePage | pages/HomePage | GET /service/home (dashboard: pending payments/repair tickets/property count + announcement list) |
| FeeBillsPage | pages/FeeBillsPage | GET /service/fees/bills?page=1&per_page=50 |
| RepairListPage | pages/RepairListPage | GET /service/repairs |
| RepairSubmitPage | pages/RepairSubmitPage | POST /service/repair |
| AnnouncementPage | pages/AnnouncementPage | GET /service/announcements?page=1&per_page=50 |
| ProfilePage | pages/ProfilePage | GET /service/profile, POST /service/profile/logout |

**Current navigation** (only 4 transitions in the entire app): Login→Home, Home→Login (logout), Profile→Login, RepairList→RepairSubmit. HomePage only has stat cards + announcement list, no function entry grid; FeeBills/Announcement/Profile pages exist but have **no entry point and are unreachable**.

## 2. HarmonyOS Core Path Comparison

| Core Path | Current State | Gap Type |
|---------|------|---------|
| Payments | Page exists, API works | Frontend only: no Home entry (unreachable) |
| Repairs | List + submit pages exist, API works | Frontend only: no Home entry (unreachable) |
| Announcements | Page exists, API works | Frontend only: no Home entry (unreachable) |
| Visitors | Page missing | New page needed (APIs already exist: GET/POST/PUT/DELETE /visitor*) |
| Parking | Page missing | New page needed (APIs already exist: /parking/vehicles, /parking/spaces, /parking/records) |

No backend gaps: the service APIs for all 5 core paths are ready (fees/repairs/announcements are resident routes; parking/visitors are within the standard-edition gate). ApiService.ets already has generic get/post/put/delete, so new pages can reuse it directly.

## 3. Flutter Owner Portal Current State (apps/flutter, 13 modules)

**Page list**: login, home, fee, repair, parking×3, visitor×2, activity, notification, vote, mall×3, chat, face, profile — all registered with routes (app.dart getPages), all 5 core paths implemented.

**Mobile adaptation issues**: only home_page / login_page use LayoutBuilder/MediaQuery responsive breakpoints; **10 pages hardcode desktop widths**, which will inevitably cause RenderFlex overflow on phone widths (<400px):

| Page | Hardcoded |
|------|--------|
| chat_page | SizedBox(width: 600) |
| mall_products_page | width: 800 |
| mall_product_detail / mall_orders | SizedBox(width: 600) |
| notification_list | width: 480 + SizedBox(width: 600) |
| vote_list / vote_detail | SizedBox(width: 600) |
| activity_detail, parking_records/vehicles, visitor_list, face_register | No breakpoint handling (same issue expected, not verified line by line) |

Also: no bottom navigation bar (BottomNavigationBar); entry points rely on AppBar + grid; page padding of 24 is desktop-oriented. Bilingual i18n already in place.

## 4. Gap List (Categorized + Effort)

### Backend-dependent (none)

### Frontend only

| # | Item | Effort |
|---|----|--------|
| 1 | Add a function entry grid to HarmonyOS HomePage (matching the 12 Flutter entries), wiring up payments/repairs/announcements/visitors/parking/personal center | M |
| 2 | Add HarmonyOS VisitorPage (list + create, reusing VisitorController) | M |
| 3 | Add HarmonyOS ParkingPage (vehicles/spaces/records, reusing ParkingController) | M |
| 4 | Remove hardcoded widths in the Flutter owner portal (600/800/480 → constrain within maxWidth or use ConstrainedBox) | S |
| 5 | Add bottom navigation bar + compact padding to the Flutter owner portal (if mobile is the acceptance target) | M |

### Requires joint debugging

| # | Item | Effort |
|---|----|--------|
| 6 | Verify the full payment→pay, repair submission, and visitor registration flows on HarmonyOS real device/emulator | S (constrained by test devices; PROJECT_PLAN lists this risk) |

## 5. Recommended Implementation Order

1. Gap 1 (best cost-benefit: reuse 3 existing pages, zero new pages)
2. Gap 4 (Flutter overflow is a hard defect, phones will crash)
3. Gaps 2, 3 (new pages)
4. Gap 5 (UX polish)
5. Gap 6 (requires a device, do independently)
