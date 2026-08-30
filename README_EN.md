# Property Management Platform

[中文](../../README.md) | [English](docs/i18n/en/README.md) | [한국어](docs/i18n/ko/README.md) | [Русский](docs/i18n/ru/README.md) | [Deutsch](docs/i18n/de/README.md) | [Français](docs/i18n/fr/README.md) | [Español](docs/i18n/es/README.md) | [Português](docs/i18n/pt/README.md) | [हिन्दी](docs/i18n/hi/README.md) | [العربية](docs/i18n/ar/README.md) | [বাংলা](docs/i18n/bn/README.md) | [Bahasa Indonesia](docs/i18n/id/README.md) | [日本語](docs/i18n/ja/README.md)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

A full-stack property management system covering 22 business modules + 12 extension features (notifications, approval workflow, payments, voting, SLA, data dashboard, collections, inspections, marketplace, face recognition, group management, AI Q&A). The admin panel and owner service are independently deployed, with Flutter Web (PC-style dashboard) and HarmonyOS mobile clients.

## Project Structure

```
property-management-platform/
├── admin/                         # Admin panel — webman v2 project
│   ├── app/
│   │   ├── admin/controller/      # Admin controllers
│   │   ├── api/v1/controller/     # Public API controllers
│   │   ├── common/                # Shared utilities
│   │   ├── middleware/            # Middleware (auth/authz/rate-limit/security)
│   │   ├── model/                 # Data models (Eloquent ORM)
│   │   ├── queue/                 # Queue jobs
│   │   └── process/               # Process management
│   ├── apps/
│   │   ├── flutter/               # Admin Flutter Web (PC dashboard style)
│   │   └── harmonyos/             # Admin HarmonyOS App
│   ├── config/                    # Config files (with Chinese annotations)
│   ├── database/
│   │   └── backup/                # Database backup scripts
│   ├── resource/
│   │   └── translations/          # i18n language files (zh_CN / en)
│   ├── docs/                      # Admin documentation
│   ├── tests/                     # Unit tests
│   └── public/                    # Web entry point
├── service/                       # Owner-facing API — webman v2 project
│   ├── app/
│   │   ├── api/v1/controller/     # Owner API controllers
│   │   ├── common/                # Shared utilities
│   │   ├── middleware/            # Middleware
│   │   ├── model/                 # Data models
│   │   └── process/               # Process management
│   ├── config/                    # Config files
│   ├── resource/
│   │   └── translations/          # i18n language files
├── apps/
│   ├── flutter/                   # Owner portal Flutter Web (PC style)
│   └── harmonyos/                 # Owner portal HarmonyOS App
└── docs/                          # Project documentation
    ├── ARCHITECTURE.md
    ├── ARCHITECTURE_DESIGN.md
    ├── ARCHITECTURE_DIAGRAM.md    # System architecture diagram
    ├── FLOWCHART.md               # Business flowchart
    ├── FUNCTION_DIAGRAM.md        # Function module diagram
    ├── LIFECYCLE_DIAGRAM.md       # Lifecycle diagram
    ├── SECURITY_ARCHITECTURE.md   # Security architecture diagram
    ├── API.md
    ├── FEATURES.md
    └── FEATURE_DESIGN.md
```

## Project Scale

| Layer | Count | Details |
|-------|-------|---------|
| Database Tables | 65 | All `management_` prefix, BIGINT non-auto-increment PK |
| PHP Models | 64 | With encryptable field encryption |
| Admin Controllers | 58 | General admin + 22 modules + 12 extensions |
| Service Controllers | 17 | Complete owner-facing API |
| API Routes | 178 | admin 125 + service 53 |
| Flutter Admin | 42 pages | 42 page modules, 96 files/6,662 lines |
| Flutter Owner | 13 pages | Bills/Repairs/Parking/Visitors/Activities/Notifications/Votes/Mall/Chat/Face, 32 files/3,582 lines |
| HarmonyOS | 7 pages | Login/Home/Bills/Repairs(2)/Announcements/Profile, 11 files/927 lines |
| Tests | 459 total | admin 258(619 assertions) + service 201(661 assertions), see [test reports](docs/tests/) |
| HarmonyOS | Complete scaffold | Service layer + Auth + Login/Home pages |
| Tests | 18/18 passing | 45 assertions, 100% pass rate |

## System Architecture & Design Diagrams

> Overview diagrams below. See detailed charts: [Architecture](docs/ARCHITECTURE_DIAGRAM.md) · [Flowchart](docs/FLOWCHART.md) · [Functions](docs/FUNCTION_DIAGRAM.md) · [Lifecycle](docs/LIFECYCLE_DIAGRAM.md) · [Security](docs/SECURITY_ARCHITECTURE.md)

### System Architecture Overview

<img src="docs/images/readme_en_architecture.svg" alt="System Architecture Overview" width="460">

### Core Business Flow

<img src="docs/images/readme_en_business_flow.svg" alt="Core Business Flow" width="860">

### Function Module Overview

<img src="docs/images/readme_en_modules.svg" alt="Function Module Overview" width="860">

### Entity Lifecycle

<img src="docs/images/readme_en_lifecycle.svg" alt="Entity Lifecycle" width="460">

### 19-Layer Defense-in-Depth Security

<img src="docs/images/readme_en_security.svg" alt="19-Layer Defense-in-Depth Security" width="330">

## Feature Modules (22 Modules)

| Batch | Modules | Status |
|-------|---------|--------|
| Batch 1 | Community, Building, Unit, RoomType, Room, Owner, Tenant, Fee, Repair, Announcement (10) | ✅ Complete |
| Batch 2 | Parking, Equipment, Complaint, Visitor, Contract, Finance (6) + Dashboard/Export (platform features) | ✅ Complete |
| Batch 3 | Patrol, Cleaning, Green, Activity, Energy, Staff (6) | ✅ Complete |
| Extensions | Notifications, Approval, Payment, Voting, SLA, Data Dashboard, Collection, Inspection, Mall, Face, Group, Knowledge (12) | ✅ Complete |
| Platform | Report Center (income/expense trends, collection rate, business distribution, arrears ranking, PDF export) + Owner home page stats (complaints / activities / votes / unread) | ✅ Complete |

## Tech Stack

### Backend
- **Framework**: webman v2 (workerman/webman)
- **Language**: PHP 8.3+
- **Database**: MySQL 8.0+, table prefix `management_`, BIGINT non-auto-increment PKs
- **Search Engine**: Elasticsearch 8.x
- **Cache**: Redis 7.x

### Core Dependencies

| Package | Purpose |
|---------|---------|
| `erikwang2013/snowflake-php` | Globally unique BIGINT primary key generation |
| `erikwang2013/hashids` | API-layer ID encryption/decryption |
| `erikwang2013/jwt-webman` | JWT authentication (HS256) |
| `erikwang2013/encryption` | API transport AES-256-CBC encryption |
| `erikwang2013/encryptable` | Database field encryption |
| `erikwang2013/webman-scout` | Elasticsearch data sync and full-text search |
| `erikwang2013/season` | Country flag data |
| `erikwang2013/security-php` | Security scanning |
| `erikwang2013/poster-php` | Sensitive operation verification |
| `phpoffice/phpspreadsheet` | Excel export |
| `barryvdh/laravel-dompdf` | PDF export |
| `hg/apidoc` | API documentation auto-generation |

### Frontend
- **Flutter 3.x** + GetX (with i18n) + Dio + fl_chart — PC-style web dashboard
- **HarmonyOS ArkTS** + @ohos.net.http — Mobile client

### API Documentation

Start the services and access the auto-generated apidoc:

| Side | URL | Groups |
|------|-----|--------|
| Admin | `http://localhost:8787/apidoc` | 10 groups (common/dashboard/system/property-core/property-aux/property-adv/extensions/export/import/upload) |
| Service | `http://localhost:8788/apidoc` | 9 groups (Public/Home/Fee/Repair/Feedback/Parking/Activity/Profile/Extensions) |

### Internationalization (i18n)
- **PHP Backend**: symfony/translation, language files in `resource/translations/{zh_CN,en}/messages.php`
- **Flutter Web**: GetX `Translations`, `lib/i18n/messages.dart`
- **Default**: Simplified Chinese (zh_CN), fallback to English (en)

## Security (19-Layer Defense-in-Depth)

1. Click Captcha → 2. Password Confirmation → 3. Random Verification → 4. Security Scan → 5. Attack Interception (XSS/SQLi/CSRF) → 6. HTTPS + AES-256-CBC → 7. JWT HS256 → 8. Concurrent Session Limit (max 3) → 9. Account Lockout (5 failures/15 min) → 10. RBAC (method.path granularity) → 11. Redis Sliding Window Rate Limit → 12. Redis Circuit Breaker (payment/webhook fast-fail + half-open probe) → 13. Hashids ID Protection → 14. Request Body Encryption → 15. DB Field Encryption → 16. Display Masking → 17. Full Audit Trail (8 platform sources) → 18. CSP Headers → 19. PDF Copyright Watermark

## Coding Standards

- All new files include copyright header: `Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz`
- Use `use` imports instead of `\` prefix for global functions/classes
- Config files include Chinese annotations for each setting
- Primary keys: `BIGINT UNSIGNED NOT NULL`, generated by snowflake-php at the application layer
- API-layer ID transmission uses hashids encoding

## Quick Start

### Option 1: One-Click Install Script (Fastest)

```bash
bash scripts/deploy.sh
# Automatically: git pull → generate .env + keys for both apps → Docker Compose up
# → database init (idempotent) → monitoring smoke test
# Admin http://localhost:8787 · Service http://localhost:8788
```

> Requires Docker + Docker Compose. Idempotent and re-runnable; see [scripts/deploy.sh](scripts/deploy.sh).

### Option 2: Web Installer (Recommended)

Start the admin panel and open `http://localhost:8787/install` to configure the database and create an admin account through the UI.

```bash
cd admin
cp .env.example .env
composer install
php start.php start -d
# Visit http://localhost:8787/install to complete setup
```

See [Installation Guide](docs/INSTALL.md) for details.

### Option 3: Manual Setup

#### Requirements

- PHP 8.1+
- MySQL 8.0+
- Redis 6.0+
- Composer 2.x
- Flutter SDK 3.x (for frontend development)

#### 1. Initialize Database

```bash
# Create database
mysql -u root -e "CREATE DATABASE IF NOT EXISTS management DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# Import merged install script (all 65 tables + RBAC seed data)
mysql -u root management < docs/install.sql
```

#### 2. Start Admin Panel

```bash
cd admin
cp .env.example .env
# Edit .env to configure database credentials
composer install
php start.php start -d
# Admin API runs at http://localhost:8787
```

### 3. Start Owner Service

```bash
cd service
cp .env.example .env
# Edit .env to configure database credentials
composer install
php start.php start -d
# Service API runs at http://localhost:8788
```

### 4. Start Frontend (Dev)

```bash
cd apps/flutter
flutter pub get
flutter run -d chrome
```

### 5. Run Tests

```bash
# Admin tests
cd admin && php vendor/bin/phpunit

# Service tests
cd service && php vendor/bin/phpunit
```

| Project | Tests | Assertions | Pass Rate |
|---------|-------|------------|-----------|
| admin | 260 | 622 | 100% (2 DB-gated skips) |
| service | 201 | 744 | 100% (8 DB-gated skips) |
| **Total** | **461** | **1366** | — |

Service test coverage: all 19 API controllers, 6 middleware, models/common services, security & feature regression
Full unit/API/E2E test reports: [docs/tests/](docs/tests/) (admin-unit-report / service-unit-report / api-report / e2e-report / go-unit-report / rust-unit-report)

### Docker Deployment

```bash
cd admin
cp .env.docker .env
docker-compose up -d
# Includes Nginx + PHP + MySQL + Redis + Elasticsearch
```

## Deployment Topology

```
Nginx (:443) → admin webman (:8787) + service webman (:8788) → MySQL + Redis + Elasticsearch
Static files: Flutter Web build/
```

## Usage Guide

### Admin Panel

1. Open `http://localhost:8787` in a browser and sign in with the default admin account (see below).
2. **Set up base data**: enter Community → Building → Unit → Room Type → Room, then bind owners under Owner Management.
3. **Daily operations**:
   - Fees: configure fee types → batch-generate bills → owners pay online/offline;
   - Repairs: owner submits → admin assigns → progress updates → completion review;
   - Report Center: view income/expense trends, collection rate, business distribution and arrears ranking by date range, export to PDF.
4. **System**: User Management (admins), Roles & Permissions (RBAC), System Config (key-values), Audit Logs.

### Owner Portal (service)

1. Open `http://localhost:8788` (or Flutter Web / HarmonyOS app), register or sign in.
2. Home page stats: my rooms, pending fees, active repairs, pending complaints, ongoing activities/votes, unread messages.
3. Common actions: pay fees, submit repairs, visitor appointments, parking lookup, activity signup, voting, AI Q&A.

### Mobile

- **Flutter Web**: `cd apps/flutter && flutter run -d chrome` (owner portal)
- **HarmonyOS**: open `apps/harmonyos` in DevEco Studio and build.

## Default Admin Account

| Username | Password | Role |
|----------|----------|------|
| admin | admin123 | Super Admin |

> Change the default password immediately in production.

## Document Index

| Document | Description |
|----------|-------------|
| [Installation Guide](docs/INSTALL.md) | Deployment guide: database init, Docker, FAQ |
| [Install SQL](docs/install.sql) | All 65 tables + RBAC seed data, single import |
| [Editions Comparison](docs/EDITIONS.md) | Lite / Standard / Full edition feature and spec comparison |
| [Architecture Design](docs/ARCHITECTURE_DESIGN.md) | Layered architecture, middleware chain, security defense-in-depth |
| [Architecture Diagrams](docs/ARCHITECTURE.md) | Mermaid diagrams (topology, request lifecycle, data encryption, deployment) |
| [Architecture Diagram](docs/ARCHITECTURE_DIAGRAM.md) | System architecture, layered detail, deployment (Mermaid visualization) |
| [Business Flowchart](docs/FLOWCHART.md) | Auth flow, fee management, repair handling, property, complaint, visitor |
| [Function Diagram](docs/FUNCTION_DIAGRAM.md) | 34 modules overview, dependencies, admin feature tree, owner portal map |
| [Lifecycle Diagram](docs/LIFECYCLE_DIAGRAM.md) | Request lifecycle, entity lifecycle, token lifecycle, CRUD flow |
| [Security Architecture](docs/SECURITY_ARCHITECTURE.md) | 18-layer defense-in-depth, attack surface matrix, encryption chain, audit system |
| [Feature Design](docs/FEATURE_DESIGN.md) | 34 module feature specifications |
| [Features](docs/FEATURES.md) | Feature checklist and module overview |
| [API Reference](docs/API.md) | Complete API endpoints and parameters |

## Support

Thank you for your support!

| <img src="admin/docs/weixinpay.svg" width="130" height="130" alt="WeChat Pay"> | <img src="admin/docs/alipay.svg" width="130" height="130" alt="Alipay"> |
|:---:|:---:|
| WeChat Pay | Alipay |

### Global Bank Transfer Tipping

Support from anywhere in the world via bank transfer to ZA Bank (Hong Kong):

| Item | Details |
|------|---------|
| Beneficiary Name | WANG KEXUN |
| Beneficiary Account Number | 881015918251 |
| Beneficiary Bank | ZA Bank Limited |
| SWIFT Code | AABLHKHHXXX |
| Bank Code | 387 |
| Bank Address | Core F, Cyberport 3, 100 Cyberport Road, Hong Kong |

> **Correspondent (intermediary) bank for cross-border remittance**: The following is correspondent bank (intermediary) information, NOT the beneficiary bank. Please check with your remitting bank whether correspondent bank information is required.
>
> - **For HKD, CNY and USD remittance** (Citibank N.A. Hong Kong): SWIFT `CITIHKXXXX`, Bank Code 006, Branch Code 391, Address: Citibank Tower, Citibank Plaza, 3 Garden Road, Central, Hong Kong
> - **For other currencies** (THE BANK OF NEW YORK MELLON): SWIFT `IRVTUS3NXXX`, Address: 240 GREENWICH STREET, NEW YORK, United States

Your support is greatly appreciated!

### Crypto Donation

If this project helps you, donations are welcome. Thank you!

| Network | QR Code | Wallet Address |
|---|---|---|
| BNB Smart Chain (BEP20) | [<img src="docs/coin/1.jpg" width="150" alt="BNB Smart Chain (BEP20)">](docs/coin/1.jpg) | `0x355d429f97511897ccb4e271ec888205f9ab6629` |
| Tron (TRC20) | [<img src="docs/coin/2.jpg" width="150" alt="Tron (TRC20)">](docs/coin/2.jpg) | `TEdDHWLajt1XvqtPDWmQctdrJaC3pzZZzz` |
| Ethereum (ERC20) | [<img src="docs/coin/3.jpg" width="150" alt="Ethereum (ERC20)">](docs/coin/3.jpg) | `0x355d429f97511897ccb4e271ec888205f9ab6629` |
| Aptos | [<img src="docs/coin/4.jpg" width="150" alt="Aptos">](docs/coin/4.jpg) | `0x836e3780edfc3f7b2372b39e2a1a3a5d7adfaccd96c726f21cfde1b50dd68030` |
| Plasma | [<img src="docs/coin/5.jpg" width="150" alt="Plasma">](docs/coin/5.jpg) | `0x355d429f97511897ccb4e271ec888205f9ab6629` |
| Polygon POS | [<img src="docs/coin/6.jpg" width="150" alt="Polygon POS">](docs/coin/6.jpg) | `0x355d429f97511897ccb4e271ec888205f9ab6629` |
| Solana | [<img src="docs/coin/7.jpg" width="150" alt="Solana">](docs/coin/7.jpg) | `2hfhboHdmdrYsY25XfQSsEWxq5ip4EQsR7f4AzSRMUyr` |
| The Open Network (TON) | [<img src="docs/coin/8.jpg" width="150" alt="The Open Network (TON)">](docs/coin/8.jpg) | `UQB9kFQohzmXUir9QSSZq01iwl9aQZIDdBpNmDklljRtCoGK` |
| Arbitrum One | [<img src="docs/coin/9.jpg" width="150" alt="Arbitrum One">](docs/coin/9.jpg) | `0x355d429f97511897ccb4e271ec888205f9ab6629` |
| AVAX C-Chain | [<img src="docs/coin/10.jpg" width="150" alt="AVAX C-Chain">](docs/coin/10.jpg) | `0x355d429f97511897ccb4e271ec888205f9ab6629` |

## License

MIT License. See [LICENSE](LICENSE) for details.
