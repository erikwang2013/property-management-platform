# Features

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## Feature List

| # | Module | Batch | Admin | Owner | Tables |
|------|------|---------|---------|--------|--------|
| 1 | Community management | Batch 1 | CRUD + search pagination | View bound community | management_community |
| 2 | Building management | Batch 1 | CRUD + filter by community | - | management_building |
| 3 | Unit management | Batch 1 | CRUD + filter by building | - | management_unit |
| 4 | Layout management | Batch 1 | CRUD | - | management_room_type |
| 5 | Property management | Batch 1 | CRUD + property tree + batch owner binding | My property list/detail | management_room |
| 6 | Owner management | Batch 1 | CRUD + batch import/enable-disable/delete | Register/login/personal info | management_owner, management_room_owner |
| 7 | Tenant management | Batch 1 | CRUD + filter by property | - | management_tenant |
| 8 | Charge management | Batch 1 | Charge type CRUD + bill management + batch generation + offline collection | Bill inquiry + online payment + charge statistics | management_fee_type, management_fee_bill, management_fee_payment |
| 9 | Repair management | Batch 1 | Repair list + dispatch + progress updates | Submit repair + view progress + rate | management_repair_order, management_repair_progress |
| 10 | Announcements | Batch 1 | CRUD + publish/pin | Announcement list/detail | management_announcement |
| 11 | Parking management | Batch 2 | Space/vehicle management + parking records | My spaces/vehicles + parking records | management_parking_space, management_parking_vehicle, management_parking_record |
| 12 | Equipment management | Batch 2 | Equipment ledger + maintenance records | - | management_equipment, management_equipment_maintenance |
| 13 | Complaints & suggestions | Batch 2 | Complaint list + handling + follow-up | Submit complaint + view progress + rate | management_complaint |
| 14 | Visitor management | Batch 2 | Visitor approval + record inquiry | Visitor appointment + pass code | management_visitor |
| 15 | Contract management | Batch 2 | CRUD + status management | - | management_contract |
| 16 | Finance management | Batch 2 | Income/expense management + statistics reports | - | management_finance_income, management_finance_expense |
| 17 | Security patrol | Batch 3 | Patrol routes + patrol records | - | management_security_patrol, management_patrol_record |
| 18 | Cleaning management | Batch 3 | Cleaning zones + cleaning records | - | management_cleaning_area, management_cleaning_record |
| 19 | Greening management | Batch 3 | Greening zones + maintenance records | - | management_green_area, management_green_maintenance |
| 20 | Community activities | Batch 3 | Activity management + sign-up viewing | Activity list + sign-up | management_community_activity, management_activity_signup |
| 21 | Energy management | Batch 3 | Meter management + meter reading records | - | management_energy_meter, management_energy_record |
| 22 | Staff management | Batch 3 | CRUD + status management | - | management_staff |

## Extension Features (Batch 4 — 12 modules)

| # | Module | Admin | Owner | Tables |
|------|------|---------|--------|--------|
| 23 | Message notifications | Template CRUD + manual sending + list | My messages + mark read | management_notification_template, management_notification |
| 24 | Approval workflow | Approval types + instances + step transitions | - | management_approval_type, management_approval, management_approval_record |
| 25 | Payment integration | Order management + refunds + WeChat/Alipay callbacks | - | management_payment_order |
| 26 | Owner voting | Vote CRUD + options + area-weighted statistics | Vote list + voting + area weighting | management_vote, management_vote_option, management_vote_record |
| 27 | SLA auto escalation | Rule config + timeout checks + penalties | - | management_sla_rule, management_sla_record |
| 28 | Smart payment reminders | Strategy config + overdue matching + late fees | - | management_collection_strategy, management_collection_record |
| 29 | Mobile inspection | Task dispatch + GPS check-in + photos | - | management_inspection_task, management_inspection_checkpoint |
| 30 | Community mall | Category/product/order/shipping management | Browse products + place orders + my orders | management_mall_category, management_mall_product, management_mall_order |
| 31 | Face recognition | Review management | Register face + authentication status | management_face_info |
| 32 | Group management | Group CRUD + community association + cross-community aggregation | - | management_group, management_group_community |
| 33 | Intelligent Q&A | Knowledge base + chat records + statistics | Ask questions + keyword matching | management_knowledge_base, management_chat_record |
| - | Data dashboard | Real-time property data visualization, full-screen display | - | (reuses existing data endpoints) |

## Admin Panel Modules (already in admin)

| Module | Features |
|------|------|
| Dashboard | Real-time statistics/trends/distribution/logs (Redis 5m cache) |
| User management | Admin user CRUD + batch delete/enable-disable + Excel import |
| Roles & permissions | CRUD + permission tree + RBAC method.path authorization |
| System config | Key-value CRUD |
| Operation audit | Log inquiry + 8 platform-source auto detection |
| File management | Upload + Excel/PDF export (sensitive data masked) |
| Security management | 18-layer defense in depth + security.txt |
| Ops monitoring | Health check + Prometheus metrics + API docs |
| Internationalization | Chinese/English bilingual, PHP symfony/translation + Flutter GetX Translations + HarmonyOS resource qualifiers |
| API docs | Auto-generated by `hg/apidoc`, admin 10 groups + service 9 groups, organized by feature module |

## Cross-Cutting Features

### ID Encryption in Transport
ID fields in all API request and response payloads are encoded/decoded with `erikwang2013/hashids`. Clients receive hashid strings (e.g. `aB3xK9mW2pQ7rT5v`); the backend decodes them to BIGINT for operations.

### Sensitive Data Protection
- API transport layer: `erikwang2013/encryption` — AES-256-CBC
- Database storage layer: `erikwang2013/encryptable` — Eloquent Model casts auto-encrypt/decrypt
- Frontend display layer: phone 138****1234, email a***@e.com

### Operation Audit
All admin POST/PUT/DELETE operations are recorded automatically, including acting user, IP, path, parameters (masked), operation time, and source (web/ios/android/harmonyos/windows/macos/linux/ipados).

### Access Control
- Admin: RBAC method.path granularity authorization; super admin `*` bypasses checks
- Owner: JWT Bearer Token authentication; owners can only operate on their own data

### Security Protection
18-layer defense in depth: captcha → password confirmation → random verification → security scan → attack blocking → transport encryption → JWT → session control → account lockout → RBAC → rate limiting → ID protection → request encryption → storage encryption → display masking → audit → CSP → copyright watermark

### Export Features
- Excel: PhpSpreadsheet, blue header with white text + frozen first row + auto-filter + sensitive data masking
- PDF: Dompdf A4 landscape, header copyright + non-removable footer copyright watermark
- Panel visualization data export to PDF

### Search Engine
- `erikwang2013/webman-scout` drives Elasticsearch
- Automatic index sync (auto-push on create/update/delete)
- Index prefix `management_`, consistent with the database table prefix

### Internationalization (i18n)
- **PHP Backend**: symfony/translation — `resource/translations/{zh_CN,en}/messages.php`, 42 translation keys, controllers fetch translations via the `__()` method
- **Flutter Web**: GetX `Translations` — `lib/i18n/messages.dart`, 101 translation keys, pages use the `.tr` extension
- **HarmonyOS**: `resources/{base,en_US}/element/string.json` resource qualifiers
- **Default language**: Simplified Chinese (zh_CN), fallback language English (en)
- **Request header**: `Accept-Language` controls the response language

### Test Coverage
- **Test framework**: PHPUnit 12.x
- **TDD flow**: red → green → refactor, tests before code
- **Admin**: 60 tests, 164 assertions, covering base services, environment config, security validation
- **Service**: 18 tests, 45 assertions, 100% pass rate
- **Total**: 78 tests, 209 assertions
- **Coverage scope**: Snowflake ID generation uniqueness, Hashids encode/decode round-trips, unified response format, 64-table schema validation, Chinese/English translation key consistency
- **Flutter**: flutter analyze with zero issues
- **API docs**: auto-generated by `hg/apidoc`, admin (10 groups) + service (9 groups), endpoint docs organized by feature module
