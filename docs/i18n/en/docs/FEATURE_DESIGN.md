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
- Manually create/edit bills
- Batch-generate bills (select community + charge type + cycle; auto-generate for all rooms)
- Bill info: charge type, amount, late fee, charge cycle, due date
- Status: unpaid/partially paid/paid/overdue/exempted
- Batch payment reminders

**Bills (owner):**
- My bill list (filter by status: unpaid/paid/overdue)
- Bill details
- Online payment (WeChat/Alipay, requires password re-confirmation)
- Payment history inquiry
- Charge statistics (annual/monthly trends, charge category share)

**Payment records (admin):**
- Payment record inquiry
- Offline collection registration (cash/card/bank transfer)

### 9. Repair Management

**Admin:**
- Repair list (filter by status/category)
- Repair detail view
- Dispatch (assign repair personnel)
- Update repair progress

**Owner:**
- My repair list
- Submit repair (select property, category, urgency, description, upload images, appointment time)
- View repair details and progress
- Cancel repair (only in pending-dispatch status, requires password confirmation)
- Rate the repair (1-5 stars + text review)

### 10. Announcements

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

### 11. Parking Management

**Admin:**
- Parking space management (number, above/below ground, area, status: vacant/sold/rented/maintenance)
- Vehicle management (plate number encrypted, brand, color, type, bound space/owner)
- Parking record inquiry (entry/exit times, duration, fee)

**Owner:**
- My vehicles list
- My parking spaces list
- Parking record inquiry

### 12. Equipment Management

**Admin:**
- Equipment ledger (name, number, category: elevator/fire/gate-access/monitoring/water-supply-drainage/power-supply/HVAC)
- Equipment info: brand, model, installation location, installation date, warranty expiry, design life
- Maintenance records: routine inspection/periodic servicing/fault repair/overhaul/replacement
- Maintenance personnel, cost, maintenance vendor, next maintenance date

### 13. Complaints & Suggestions

**Admin:**
- Complaint list (filter by type/status)
- Handle complaints (assign handler, fill in handling notes)
- Follow-up registration (follow-up notes, satisfaction records)

**Owner:**
- My complaints/suggestions list
- Submit complaint/suggestion (type: complaint/suggestion/praise; category: service/environment/security/facilities/noise/illegal construction)
- Supports anonymous submission and image upload
- View handling progress
- Satisfaction rating

### 14. Visitor Management

**Admin:**
- Visitor appointment approval
- Visitor record inquiry

**Owner:**
- Visitor appointment (visitor name, phone, ID card, plate number, companion count, visit reason, expected time)
- Generate pass code
- Modify/cancel appointment

### 15. Contract Management

**Admin:**
- Contract list (filter by type/status)
- Contract types: property contract/lease contract/maintenance contract/service contract/procurement contract
- Contract info: number, parties, amount, start/end dates, signing date, attachments
- Status: draft/in performance/expired/terminated/renewed

### 16. Finance Management

**Admin:**
- Income management (property fee/parking fee/rent/advertising fee/maintenance fund/other)
- Expense management (labor/equipment procurement/maintenance/energy/cleaning-greening/office/taxes/other)
- Income/expense statistics reports (monthly/quarterly/yearly)

---

## Batch 3: Advanced Features

### 17. Security Patrol

**Admin:**
- Patrol route management (route coordinates, checkpoints)
- Patrol records (start/end times, duration, exception notes)
- Patrol completion rate statistics

### 18. Cleaning Management

**Admin:**
- Cleaning zone management (location, area, frequency: daily/weekly/biweekly/monthly)
- Cleaning records (cleaning time, inspector, inspection notes, on-site photos)
- Cleaning completion rate statistics

### 19. Greening Management

**Admin:**
- Greening zone management (location, area, main plants)
- Maintenance records (watering/pruning/fertilizing/pest control/replanting, cost)

### 20. Community Activities

**Admin:**
- Activity management (title, content, category: sports/festival/charity/lecture/family)
- Cover image, location, max participants, time, fee
- Status: signing up/in progress/ended/cancelled
- Sign-up list view

**Owner:**
- Activity list (filter: signing up/in progress)
- Activity details
- Sign up/cancel sign-up

### 21. Energy Management

**Admin:**
- Meter management (electricity/water/gas/heating meters, numbers)
- Meter reading records (current reading, usage, unit price, fee)
- Associated bill auto-generation

### 22. Staff Management

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
- Repair statistics (by category, by status)
- Complaint statistics
- Recent operation logs

**Owner home page:**
- My property count, pending payment amount, in-progress repairs count, latest announcements

### Excel Export

- Owner list export
- Bill report export
- Payment record export
- Finance report export
- Sensitive data auto-masked on export

### PDF Export

- Dashboard panel visualization export
- Finance report PDF (header copyright + non-removable footer copyright watermark)
- A4 landscape layout

---

## Cross-Module Features

| Feature | Description |
|------|------|
| ID protection | All endpoint IDs transmitted as hashids-encoded |
| Data encryption | Sensitive fields (phone/email/ID card) AES-256-CBC at the API layer, encryptable at the DB layer |
| Operation audit | All admin POST/PUT/DELETE operations auto-recorded, with auto source detection |
| Access control | RBAC method.path granularity, super admin `*` marker |
| Rate limiting | Redis sliding window, login 10/minute, registration 5/minute |
| Captcha | Click-style Chinese captcha, mandatory on login/register |
| Soft delete | Owners, communities, properties, announcements support soft delete |
| Internationalization | Chinese/English bilingual, PHP symfony/translation + Flutter GetX Translations, Chinese default, English fallback |
| API docs | Auto-generated by `hg/apidoc`; 57 of 58 controllers annotated in 10 groups (Base/Docs/Install ungrouped), `/apidoc/config` provides the config API |
| Tests | TDD flow, 133 tests / 465 assertions, service 100% pass, flutter analyze zero issues |
| Flutter Web | 13 pages (login/home/charges/repairs/profile, etc.), PC desktop style, GetX state management |
| HarmonyOS | Complete project skeleton, ArkTS service layer + auth + login/home, @ohos.net.http |

## Extension Features (Batch 4)

### Message Notification Center
- Configurable notification templates (App push/SMS/email)
- Auto-notify on bill reminders, repair progress, announcement publishing
- Owner message list + read management

### Approval Workflow Engine
- Configurable approval types and steps (supervisor→manager→director)
- Repair dispatch/visitor approval/contract approval follow standardized flows
- Approval records traceable

### Payment Integration
- WeChat/Alipay payment order management
- Payment callback handling, refunds, reconciliation statistics
- Associated bills auto-updated

### Owner Voting / Resolution
- Regular voting + owners' meeting resolutions (area-weighted)
- Option management, voting records, automatic tallying
- Participation rate statistics

### Repair SLA Auto Escalation
- Configure response/resolution time limits by category + urgency
- Timeouts auto-escalate to higher roles
- Timeout penalties auto-recorded

### Smart Payment Reminders
- Tiered reminder strategy config (overdue days → action)
- Auto-match overdue bills and execute reminders (App/SMS/phone/on-site)
- Late fees auto-calculated

### Mobile Inspection
- Inspection task dispatch (GPS routes + checkpoints)
- Mobile check-in (location + photos + exception marking)
- Inspection completion rate statistics

### Community Mall
- Product category/list/on-shelf/off-shelf management
- Owner browsing + ordering + order tracking
- Shipping/refund management

### Face Recognition
- Owner face registration (third-party recognition service integration)
- Admin review and authentication
- Gate-access association

### Multi-Community Group Management
- Group→community many-to-many association
- Cross-community data aggregation (unified property/owner/charges view)

### Intelligent Q&A
- Knowledge base management (categories/articles/keywords)
- Auto-matching owner questions
- Chat records + resolution rate statistics

### Data Dashboard
- Full-screen real-time property data visualization
- Four panels: charges/repairs/equipment/energy
- Auto-rotating refresh
