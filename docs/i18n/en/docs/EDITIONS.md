# Editions Comparison

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

The property management system comes in three editions: Lite, Standard, and Full, which are cumulative.

---

## Overview

| Metric | Lite | Standard | Full |
|------|:-----------:|:---------------:|:-----------:|
| Database tables | **21** | **31** | **65** |
| Eloquent models | 19 | 30 | 58 |
| Admin controllers | 17 | 28 | 47 |
| Owner controllers | 9 | 12 | 17 |
| API routes | 35 | 70 | 178 |
| Business modules | 10 | 18 | 34 |
| Security layers | 18 | 18 | 18 |

---

## Feature Module Comparison

### Lite

Core property management, including the admin general system + 10 core business modules.

**Admin**: dashboard, user/role/permission/config/log CRUD, community/building/unit/layout/property/owner/tenant/charges/repair/announcement CRUD

**Owner**: register/login, home, my properties, bill payment, repair submit/rate, announcement view, personal info

---

### Standard

Adds 6 auxiliary business modules + panel visualization + data export on top of Lite.

**Admin additions**: parking space/vehicle CRUD, equipment ledger + maintenance, complaint handling + follow-up, visitor approval, contract management, income/expense management + statistics

**Owner additions**: my vehicles/parking spaces, parking records, visitor appointment/pass code

---

### Full

Adds advanced modules + 12 extension features on top of Standard.

**Admin additions**: patrol routes + records, cleaning zones + records, greening zones + maintenance, community activity management, energy meters + meter reading, staff management, notification templates + sending, approval engine, payment orders + refunds, voting management + SLA rules + reminder strategies + inspection tasks + mall management + face review + group management + knowledge base

**Owner additions**: community activity sign-up, parking/visitor appointment, message notifications, voting + tallying, browse products + place orders, intelligent Q&A, face registration

---

## Technical Indicator Comparison

| Metric | Lite | Standard | Full |
|------|:------:|:------:|:------:|
| Database tables | 21 | 31 | 65 |
| Model files | 19 | 30 | 58 |
| admin controllers | 17 | 28 | 47 |
| service controllers | 9 | 12 | 17 |
| admin routes | 45 | 80 | 123 |
| service routes | 20 | 35 | 55 |
| Flutter Admin pages | 4 | 7 | 57 |
| HarmonyOS pages | 2 | 3 | 7 |
| Middleware | 7 | 8 | 9 |
| PHP tests | 18 | 18 | 133 |

---

## Security System (Common to All Editions)

18-layer defense in depth: captcha → password confirmation → random verification → security scan → attack blocking → HTTPS + AES-256-CBC → JWT → session control → account lockout → RBAC → rate limiting → ID protection → request encryption → storage encryption → display masking → audit → CSP → copyright watermark

---

## Migration Path

```
Lite
  │
  │  + 6 auxiliary modules + panel + export
  ▼
Standard
  │
  │  + 6 advanced modules + 12 extension features
  ▼
Full
```

Upgrading only requires running the SQL migration file for the corresponding batch — no data migration or destructive changes.

---

## Demo Walkthrough

**Preparation**: `docs/install.sql` has been executed (full table structure including all editions' tables); `admin/.env` has the database connection configured. Edition differences are in route registration and feature visibility; the table structure is uniformly full.

### Lite

1. Load demo data: `cd admin && php ../scripts/demo_data.php` (idempotent, re-runnable)
2. Demo data scope: community/building/unit/layout/property/owner/tenant/charges/bills/announcements + demo accounts, covering Lite core modules
3. What to look at: admin dashboard + user/role/permission/config/log + property/owner/tenant/charges/repair/announcement CRUD; owner register/login, home, my properties, bill payment, repairs, announcements
4. Route differences: only the Lite group is registered; blocks wrapped in `edition_supports('standard'/'full')` are not registered (`admin/config/route.php`)

### Standard

1. Load demo data: `cd admin && php ../scripts/demo_data.php` (idempotent; re-runs only fill gaps, never duplicate)
2. Auxiliary modules have little data; a small amount entered by demo for parking/equipment/complaints/visitors/contracts/income-expense is enough
3. What to look at: admin additions — parking spaces/vehicles, equipment ledger + maintenance, complaint handling + follow-up, visitor approval, contract management, income/expense management + statistics; owner additions — my vehicles/parking spaces, parking records, visitor appointment/pass code
4. Route differences: append the `edition_supports('standard')` group; Lite groups remain

### Full

1. Load demo data: `cd admin && php ../scripts/demo_data.php` (idempotent)
2. Advanced module (payments/approval/voting/mall/inspection/face/group/knowledge base) demo data entered as needed, or created directly with demo accounts
3. What to look at: on top of Standard — patrol/cleaning/greening/energy/staff/notification templates/approval engine/payment orders/voting/SLA/reminders/inspection/mall/face/group/knowledge base; owner — activity sign-up, message notifications, voting, mall orders, intelligent Q&A, face registration
4. Route differences: full registration; `edition_supports('full')` groups active (`admin/config/route.php`)

### Switching Editions

```bash
# Set the target edition in admin/.env (cumulative; full includes everything)
EDITIONS=lite|standard|full

# Restart webman to apply (container deployment: docker compose restart app; bare metal: php start.php restart)
```

- Fail-fast config: an invalid `EDITIONS` value throws an error immediately (`admin/config/edition.php`), never silently falling back to a wrong edition.
- The demo data script is idempotent; switching editions requires no database cleanup; Standard/Full module data is small and can be entered through real business.
