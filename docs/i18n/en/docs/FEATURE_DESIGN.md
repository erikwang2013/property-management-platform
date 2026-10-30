# Feature Design

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

<img src="../../../images/pet_xiaozhu.svg" alt="小筑 · project mascot" width="110" align="right">

<img src="../../../images/design_function.svg" alt="Function Module Overview" width="1000">

> English edition: `../../../images/design_function_en.svg`


## Overview

The property management system is divided into an **admin portal** (used internally by the property company) and an **owner portal** (used by community owners/tenants), covering 15 business modules delivered in 3 batches.

---

## Batch 1: Core Business

### 1. Community Management

**Admin:**
- Community list (search, pagination, status filter)
- Create/view/edit/delete community
- Community info: name, address (province/city/district), building area, number of buildings, number of housing units, developer, property company, contact phone
- Delete requires password re-confirmation and uses soft delete

**Owner:** no admin permissions needed; the home page shows the bound community's info.

### 2. Building Management

**Admin:**
- Building list filtered by community
- Create/view/edit/delete building
- Building info: name, type (tower/slab/villa/commercial), floors, units, elevators, year built, structure type
- Supports sorting

### 3. Unit Management

**Admin:**
- Unit list filtered by building
- Create/view/edit/delete unit
- Unit info: name, households per floor

### 4. Layout (RoomType) Management

**Admin:**
- Layout list CRUD
- Layout info: name (e.g., 3-bedroom 2-living-room), bedroom/living room/bathroom counts, floor plan image

### 5. Property (Room) Management

**Admin:**
- Property tree view (community→building→unit→room)
- Create/view/edit/delete room
- Room info: room number, floor, layout, area (indoor/shared/total), orientation, decoration, use (residential/commercial/office), status (vacant/sold/rented/owner-occupied)
- Batch bind/unbind owners

**Owner:**
- View my bound property list
- View property details (area, orientation, layout, ownership info)

### 6. Owner Management

**Admin:**
- Owner list (search, pagination, status filter)
- Create/view/edit/delete owner
- Owner info: name, phone (encrypted), email (encrypted), ID card (encrypted), gender, birthday, emergency contact, move-in date
- Batch import (Excel), batch enable/disable, batch delete
- Property bind/unbind

**Owner:**
- Register (phone + password + captcha, optional property-binding verification)
- Login (phone + password + click captcha, account lockout protection)
- View/edit personal info
- Change password, log out

### 7. Tenant Management

**Admin:**
- Tenant list filtered by property/landlord
- Create/view/edit/delete tenant
- Tenant info: name, phone (encrypted), ID card (encrypted), lease start/end, monthly rent, status

### 8. Charge (Fee) Management

**Charge types (admin):**
- Charge type CRUD: property fee, water, electricity, gas, heating, parking fee, maintenance fund, other
- Unit price, billing unit (yuan/m²/month, yuan/ton, yuan/kWh, etc.), billing cycle (monthly/quarterly/yearly), whether mandatory

**Bill management (admin):**
- Query bills by community/building/property
- Manually create/edit bills (backend endpoint remains; the Flutter bill page's create button was removed because its payload was incomplete)
- Batch-generate bills (backend endpoint remains; the Flutter batch-generate button was removed)
- Bill info: charge type, amount, late fee, charge cycle, due date
- Status: unpaid/partially paid/paid/overdue/exempted
- Batch payment reminders

**Bills (owner):**
- My bill list (filter by status: unpaid/partially paid/paid/overdue/waived)
- Bill details
- Online payment is not connected to a gateway (`POST /service/v1/fees/pay` always returns 503; the pay dialog/button was removed); pay via an admin-created payment order or offline
- Payment history inquiry
- Charge statistics (annual/monthly trends, charge category share)

**Payment records (admin):**
- Payment record inquiry
- Offline collection registration (cash/card/bank transfer)

### 9. Announcements

**Admin:**
- Announcement list CRUD
- Publish announcements per community
- Categories: notice/announcement/reminder/activity
- Pin, draft/published status

**Owner:**
- View published announcement list (filter by category)
- Announcement details

---

## Batch 2: Auxiliary Business

### 10. Parking Management

**Admin:**
- Parking space management (number, above/below ground, area, status: vacant/sold/rented/maintenance)
- Vehicle management (plate number encrypted, brand, color, type, bound space/owner)
- Parking record inquiry (entry/exit times, duration, fee)

**Owner:**
- My vehicles list
- My parking spaces list
- Parking record inquiry

### 11. Equipment Management

**Admin:**
- Equipment ledger (name, number, category: elevator/fire/gate-access/monitoring/water-supply-drainage/power-supply/HVAC)
- Equipment info: brand, model, installation location, installation date, warranty expiry, design life
- Maintenance records: routine servicing/periodic maintenance/fault repair/overhaul/replacement
- Maintenance personnel, cost, maintenance vendor, next maintenance date

## Batch 3: Advanced Features

### 12. Security Patrol

**Admin:**
- Patrol route management (route coordinates, checkpoints)
- Patrol records (start/end times, duration, exception notes)
- Patrol completion rate statistics

### 13. Cleaning Management

**Admin:**
- Cleaning zone management (location, area, frequency: daily/weekly/biweekly/monthly)
- Cleaning records (cleaning time, supervisor, servicing notes, on-site photos)
- Cleaning completion rate statistics

### 14. Greening Management

**Admin:**
- Greening zone management (location, area, main plants)
- Maintenance records (watering/pruning/fertilizing/pest control/replanting, cost)

### 15. Staff Management

**Admin:**
- Staff info (name, phone encrypted, ID card encrypted, position, department, hire date)
- Departments: management/customer service/engineering/security/cleaning/greening/finance
- Status: active/departed/on leave

---

## Panel Visualization & Export

### Dashboard Panels

**Admin dashboard:**
- Core metric cards: total receivable, total received, arrears rate, occupancy rate
- Charge trend line chart (monthly/quarterly)
- Charge category pie chart
- Recent operation logs

**Owner home page:**
- My property count, pending payment amount, latest announcements

### Excel Export

- Owner list export
- Bill report export
- Payment record export
- Sensitive data auto-masked on export

### PDF Export

- Dashboard panel visualization export
- PDF header copyright + non-removable footer copyright watermark
- A4 landscape layout

---

## Cross-Module Features

| Feature | Description |
|------|------|
| ID protection | All endpoint IDs transmitted as hashids-encoded |
| Data encryption | Sensitive fields (phone/email/ID card) AES-256-CBC at the API layer, encryptable at the DB layer |
| Operation audit | All admin POST/PUT/DELETE operations auto-recorded, with auto source detection |
| Access control | RBAC method.path granularity, super admin `*` marker |
| Rate limiting | Redis sliding window, login 10/minute, owner registration 5/minute (no public admin registration) |
| Captcha | Click-style Chinese captcha, mandatory on login (owner side also on registration) |
| Soft delete | Owners, communities, properties, announcements support soft delete |
| Internationalization | Chinese/English bilingual, PHP symfony/translation + Flutter GetX Translations, Chinese default, English fallback |
| API docs | Auto-generated by `hg/apidoc`, admin 10 groups + service 6 groups, `/apidoc/config` provides the config API |
| Tests | Backend 65 tests (admin 43/103 assertions + service 22/42) ship with the tree, plus 11 Flutter tests; CI coverage floors admin 1.7% / service 3%, both stacks pass PHPStan, flutter analyze zero issues |
| Flutter Web | 5 pages (login/home/charges/parking/profile), PC desktop style, GetX state management |

## Extension Features (Batch 4)

### Payment Integration
- WeChat/Alipay payment order management (admin creates orders via `POST /admin/payment-order/create`)
- Payment callback handling, refunds, reconciliation statistics
- Refunds require an idempotency key `request_id` (max 64 chars), support partial refunds, and return the cumulative refund amount
- Online credit is capped at the bill's current unpaid amount (`credited_amount`); excess goes to the automatic refund queue, and reconciliation re-enqueues unrefunded overpayments
- Offline collection is rejected while an unexpired online payment order exists; associated bills auto-updated

