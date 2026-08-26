# Architecture Design

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## 1. System Architecture Overview

The property management system uses a "dual backend + multi frontend" layered architecture. The admin portal (admin) and owner business service (service) are two independent webman v2 projects that work together over a shared MySQL database. Frontends cover Flutter Web (PC admin style) and HarmonyOS mobile.

### Design Goals

- **Independent deployment**: admin and service start/stop, scale, and manage keys independently
- **Shared data**: share the same MySQL database, avoiding data sync issues
- **Unified standards**: both projects follow the same coding standards, config style, and security policy
- **PC-first Web**: Flutter Web is designed in desktop admin style (sidebar + top bar + content area)

## 2. Layered Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        路由层 (Route Layer)                   │
│   config/route.php — URL → Controller 映射 + 中间件绑定       │
├─────────────────────────────────────────────────────────────┤
│                       中间件层 (Middleware Layer)              │
│   SecurityFilter → RateLimit → ApiVersion → Auth → Permission │
├─────────────────────────────────────────────────────────────┤
│                      控制器层 (Controller Layer)               │
│   BaseController → 请求验证 → ID编解码 → 业务逻辑 → 响应格式化  │
├─────────────────────────────────────────────────────────────┤
│                        服务层 (Service Layer)                  │
│   HashidsService | SnowflakeService | EncryptionService       │
├─────────────────────────────────────────────────────────────┤
│                        模型层 (Model Layer)                    │
│   Eloquent ORM + encryptable 自动加解密 + scout ES 同步        │
├─────────────────────────────────────────────────────────────┤
│                        驱动层 (Driver Layer)                   │
│   MySQL PDO | Elasticsearch HTTP | Redis                      │
└─────────────────────────────────────────────────────────────┘
```

## 3. Middleware Execution Chain

### Admin

```
Cors → SecurityFilter(方法检查→405) → RateLimit(限流)
  → AdminAuth(JWT验证) → AdminPermission(RBAC鉴权)
    → OperationLog(操作记录) → Controller
```

### Service

```
Cors → SecurityFilter(方法检查→405) → RateLimit(限流)
  → ApiVersion(版本校验) → Controller           # /api/* 公开接口
  → ServiceAuth(JWT业主认证) → Controller       # /service/* 认证接口
```

### Global Middleware Notes

| Middleware | Position | Responsibility |
|--------|------|------|
| Cors | First globally | CORS header handling |
| SecurityFilter | Global | HTTP method whitelist, XSS/SQL injection/path traversal/command injection/CSRF attack blocking, IP blacklist |
| RateLimit | Global | Redis sliding window rate limiting (Lua atomic), default 60/min |
| ApiVersion | /api routes | Validates the API-Version request header, injects the version number |
| AdminAuth | /admin routes | JWT Token validation, injects adminId |
| AdminPermission | /admin routes | RBAC method.path permission check (Redis 60s cache) |
| OperationLog | /admin routes | Auto-records POST/PUT/DELETE operations (with source detection) |
| ServiceAuth | /service routes | JWT Token validation, injects ownerId |

## 4. ID Full Lifecycle

```
生成: SnowflakeService::generate()
      datacenter_id(5bit) + worker_id(5bit) + timestamp(41bit) + sequence(12bit)
      → BIGINT(18) 例: 1750123456789

存储: MySQL erik_* 表
      id BIGINT UNSIGNED NOT NULL（非自增）
      敏感字段 encryptable cast → AES-256-CBC 加密存储

传输: HashidsService::encode(bigint) → hashid 字符串 例: aB3xK9mW2pQ7rT5v
      API 请求/响应中的所有 ID 字段统一使用 hashid

解码: HashidsService::decode(hashid) → BIGINT
      无效 hashid 抛出 InvalidArgumentException
```

## 5. Layered Data Encryption

### Transport Layer (encryption)
- AES-256-CBC encryption
- Client encrypts sensitive data before sending; server decrypts on receipt
- Independent key `ENCRYPTION_KEY`

### Storage Layer (encryptable)
- Model `$casts` mechanism auto-encrypts/decrypts
- Sensitive fields: phone, email, id_card, emergency_contact, emergency_phone
- Independent key `ENCRYPTABLE_KEY`
- Writes auto-encrypt to ciphertext; reads auto-decrypt to plaintext

### Display Layer (masking)
- Phone: `138****1234`
- Email: `a***@example.com`
- ID card: `********`
- Excel/PDF export auto-masked

## 6. Authentication & Authorization

### JWT Authentication
- Algorithm: HS256
- access_token: 2-hour validity
- refresh_token: 14-day validity
- Concurrency limit: max 3 valid tokens per user; when exceeded, the oldest token goes to the blacklist
- Account lockout: 5 consecutive login failures locks for 15 minutes

### RBAC Permission Model
- User → Role → Permission (many-to-many)
- Permission types: type=1 (menu) / type=2 (button) / type=3 (API)
- Permission identifier format: `{method}.{path}` e.g. `get.admin/user`
- Super admin identifier: `*` (skips all permission checks)
- Permission tree: self-referencing parent_id supports unlimited depth

## 7. Security Defense in Depth (18 Layers)

```
第1层  点击验证码      → 登录/注册强制人机验证
第2层  密码二次确认    → 敏感操作（删除/缴费/合同终止）必须输入密码
第3层  poster随机验证  → 高频敏感操作随机弹出验证码
第4层  security-php    → 请求周期内自动安全扫描
第5层  SecurityFilter  → XSS/SQL注入/路径遍历/命令注入/CSRF 攻击拦截
第6层  传输安全        → HTTPS + AES-256-CBC
第7层  JWT 认证        → HS256，2h过期 + refresh token
第8层  并发控制        → 同一用户最多3个Token，超出黑名单
第9层  账号锁定        → 连续5次失败锁定15分钟
第10层 RBAC 鉴权       → method.path 粒度权限控制
第11层 限流保护        → Redis 滑动窗口 Lua原子化
第12层 ID 保护         → Hashids 编码，不可逆推真实ID
第13层 请求体加密      → AES-256-CBC 敏感字段
第14层 存储加密        → encryptable DB字段加密
第15层 展示脱敏        → 手机号/邮箱/身份证脱敏
第16层 审计追溯        → OperationLog 全量记录（含来源端 source 自动检测）
第17层 HTTP 头防护     → CSP + X-Permitted-Cross-Domain-Policies
第18层 出口保护        → PDF 版权水印（不可移除）+ Excel 敏感数据脱敏
```

## 8. Rate Limiting Strategy

Based on the Redis Sorted Set sliding window algorithm, executed atomically via Lua scripts:

| Endpoint | Limit |
|------|------|
| Default | 60/min/IP/route |
| POST /api/auth/login | 10/min |
| POST /api/auth/register | 5/min |

Over-limit returns 429 + `X-RateLimit-Limit/Remaining/Reset/Retry-After` response headers.

## 9. API Versioning Strategy

- Version is controlled via the `API-Version` request header (default `v1`), not in the URL
- Unsupported versions return 400
- Controllers are organized by version: `app/api/{version}/controller/`
- Adding a version only requires creating the directory and registering it in the `ApiVersion` middleware

## 10. Deployment Architecture

```
┌─────────────────────────────────────┐
│            CloudFlare DNS + CDN      │
└────────────────┬────────────────────┘
                 │
┌────────────────▼────────────────────┐
│          Nginx (:443)                │
│   反向代理 + Gzip + SSL 终结         │
│   静态文件: Flutter Web build/       │
└──────┬──────────────────┬───────────┘
       │                  │
┌──────▼──────┐    ┌──────▼──────┐
│ admin webman│    │service webman│
│ :8787       │    │ :8788       │
│ 管理后台API │    │ 业主端API    │
└──────┬──────┘    └──────┬──────┘
       │                  │
       └────────┬─────────┘
                │
┌───────────────┼───────────────────┐
│               │                   │
┌▼──────┐  ┌────▼───┐  ┌──────────▼┐
│MySQL  │  │ Redis  │  │Elasticsearch│
│:3306  │  │ :6379  │  │ :9200      │
└───────┘  └────────┘  └────────────┘
```

### Docker Compose Services

| Service | Image | Description |
|------|------|------|
| nginx | nginx:alpine | Reverse proxy + static files |
| admin | Dockerfile build | PHP 8.3 + OPcache |
| service | Dockerfile build | PHP 8.3 + OPcache |
| mysql | mysql:8.0 | Data volume persistence |
| redis | redis:7-alpine | Cache/rate limiting/Session |
| elasticsearch | elasticsearch:8.x | Full-text search |

## 11. Internationalization Design (i18n)

### Language File Structure

The system supports Simplified Chinese (zh_CN) and English (en); Chinese is the default.

**PHP Backend:**
```
resource/translations/
├── zh_CN/
│   └── messages.php    # 中文语言包（42+翻译键）
└── en/
    └── messages.php    # 英文语言包
```

Driven by symfony/translation, configured in `config/translation.php`:
- `locale`: `zh_CN`
- `fallback_locale`: `['zh_CN', 'en']`
- `path`: `resource/translations`

Controllers fetch translations via `$this->__('key')`:
```php
return $this->success([], $this->__('create_success'));
return $this->fail($this->__('community.name_required'), 422);
```

The `__()` method internally calls webman's global `trans()` function; missing translations fall back to returning the key itself.

**Flutter Web:**
```
apps/flutter/lib/i18n/
└── messages.dart       # AppTranslations extends GetX Translations
```

Uses GetX `Translations` with 101 translation keys, accessed via the `.tr` extension:
```dart
Text('login_btn'.tr)   // 中文: "登 录", 英文: "Login"
Text('phone_hint'.tr)  // "请输入手机号" / "Enter phone number"
```

Language switching:
```dart
Get.updateLocale(Locale('zh', 'CN'));  // 切换中文
Get.updateLocale(Locale('en', 'US'));  // 切换英文
```

### Translation Key Categories

| Category | PHP key examples | Flutter key examples |
|------|-----------|---------------|
| General | `success`, `fail`, `not_found` | `confirm`, `cancel`, `save` |
| Auth | `auth.login_success`, `auth.*` | `login_btn`, `phone_hint` |
| Community | `community.name_required` | - |
| Charges | `fee.bill_not_found`, `fee.*` | `fee_management`, `bill_status` |
| Repairs | `repair.not_found`, `repair.*` | `repair_submit`, `urgency_normal` |
| Complaints | `complaint.submit_success` | `complaint_type`, `type_complaint` |
| Profile | - | `profile`, `change_password` |

**HarmonyOS:** uses `resources/base/element/string.json` + `resources/en_US/element/string.json` resource qualifiers (implemented when the HarmonyOS project is created).

## 12. Testing Strategy

### TDD Test Flow

The project follows a TDD (test-driven development) flow: red → green → refactor.

```
RED: 先写测试，观察失败
  ↓
GREEN: 写最小代码使测试通过
  ↓
REFACTOR: 清理代码，保持测试绿
```

### Test Coverage

| Layer | Framework | Test Content |
|----|---------|---------|
| Base services | PHPUnit | Snowflake ID generation, Hashids encode/decode, response format |
| Database | PHPUnit + PDO | Table structure validation (BIGINT primary keys, non-auto-increment, erik_ prefix) |
| Internationalization | PHPUnit | Translation file existence, Chinese/English key consistency |
| API endpoints | PHPUnit | Health check, response format |
| Middleware | Integration tests | JWT auth, rate limiting, permissions |

### Running Tests

```bash
cd admin && php vendor/bin/phpunit    # 管理端: 60 tests, 164 assertions
cd service && php vendor/bin/phpunit  # 业务端: 18 tests, 45 assertions, 100% pass
```

## 13. Frontend Architecture

### Flutter Web (PC Desktop Style)

```
apps/flutter/lib/
├── main.dart                    # 入口，初始化 ApiService + AuthService
├── app.dart                     # GetMaterialApp，路由表 + 主题 + i18n
├── config/
│   ├── api_config.dart          # API 端点常量（指向 service :8788）
│   └── theme.dart               # Material 3 主题（Ant Design 色系）
├── services/
│   ├── api_service.dart         # Dio 单例 + JWT 拦截器 + 401 自动刷新
│   ├── auth_service.dart        # 登录/登出/Token 持久化
│   └── storage_service.dart     # shared_preferences 封装
├── i18n/
│   └── messages.dart            # GetX Translations（101键，zh_CN/en）
├── pages/
│   ├── login/                   # PC 风格登录页（居中 Card + 表单验证）
│   ├── home/                    # 仪表盘（4个 StatCard + 公告列表）
│   ├── fee/                     # 账单列表 / 详情 / 缴费弹窗
│   ├── repair/                  # 报修列表 / 提交 / 详情 + 评价
│   └── profile/                 # 个人信息 / 修改密码 / 退出
└── widgets/
    └── stat_card.dart           # 统计卡片组件（图标 + 标题 + 数值）
```

### HarmonyOS Mobile

```
apps/harmonyos/entry/src/main/ets/
├── services/
│   ├── ApiService.ets           # @ohos.net.http 封装，Bearer Token
│   └── AuthService.ets          # 登录/登出（Preference 持久化）
├── model/
│   └── Models.ets               # TypeScript 接口定义
├── pages/
│   ├── LoginPage.ets            # 手机号 + 密码登录
│   └── HomePage.ets             # 仪表盘（统计卡片 + 公告列表）
└── resources/
    ├── base/element/string.json # 中文资源
    └── en_US/element/string.json# 英文资源
```

### Technology Choices

| Layer | Flutter Web | HarmonyOS |
|----|------------|-----------|
| State management | GetX | @State + @Prop |
| HTTP | Dio + JWT interceptor | @ohos.net.http |
| Persistence | shared_preferences | @ohos.data.preferences |
| Charts | fl_chart | Web component + ECharts |
| i18n | GetX Translations | resource qualifiers |
| Routing | GetX named routes | router.pushUrl/replaceUrl |

## 14. Extension Feature Architecture

### Message Notification Center
Message template → notification generation → multi-channel sending (in-app/SMS/email/push)

### Approval Workflow
Approval type config → instance submission → step transitions (approve/reject) → notify the next approver

### Payment Flow
Create payment order → third-party payment → async callback → update bill status → record payment log

### Owner Voting
Publish vote → owners vote (area-weighted) → real-time tally → result statistics

### SLA Auto Escalation
SLA rule matching → scheduled timeout checks → auto escalation → penalty records

### Smart Payment Reminders
Reminder strategy matching → overdue detection → auto-generate reminder tasks → execute reminder actions

### Inspection Management
Task dispatch → mobile GPS check-in → photo upload → exception marking → completion statistics

### Group Management
Group → community association → cross-community data aggregation (property/owner/charges/repairs)

## 15. API Documentation

Endpoint docs are auto-generated from controller annotations with `hg/apidoc`, grouped by feature.

**Admin** (`http://localhost:8787/apidoc`): 10 groups — 57 controllers annotated (Base/Docs/Install ungrouped)

| Group | Count | Controllers |
|------|------|--------|
| `common` | 2 | Auth, Captcha |
| `dashboard` | 3 | Dashboard, Metrics, Health |
| `export` | 1 | Export |
| `import` | 1 | Import |
| `upload` | 1 | Upload |
| `system` | 6 | User, Role, Permission, Config, Log, Profile |
| `property-core` | 12 | Community, Building, Unit, RoomType, Room, Owner, Tenant, FeeType, FeeBill, FeePayment, Repair, Announcement |
| `property-aux` | 9 | Parking(3), Equipment(2), Complaint, Visitor, Contract, Finance |
| `property-adv` | 11 | Activity(2), Patrol(2), Cleaning(2), Green(2), Energy(2), Staff |
| `extensions` | 11 | Notification, Approval, Payment, Vote, Sla, Collection, Inspection, Mall, Face, Group, Knowledge |

**Service** (`http://localhost:8788/apidoc`): 9 groups — 17 controllers annotated

| Group | Count | Controllers |
|------|------|--------|
| `public` | 2 | Auth, Captcha |
| `home` | 2 | Home, Room |
| `fee` | 1 | Fee |
| `repair` | 1 | Repair |
| `feedback` | 2 | Complaint, Announcement |
| `parking` | 2 | Parking, Visitor |
| `activity` | 1 | Activity |
| `profile` | 1 | Profile |
| `extensions` | 5 | Notification, Vote, Mall, Knowledge, Face |

### Annotation Conventions

```php
/**
 * 小区列表
 * @Apidoc\Method("GET")
 * @Apidoc\Url("/admin/community")
 * @Apidoc\Group("property-core")
 * @Apidoc\Sort(1)
 * @Apidoc\Param("keyword", type="string", require=false, desc="搜索关键词")
 * @Apidoc\Param(ref="pagination")
 * @Apidoc\Returned("id", type="string", desc="hashid")
 */
```

### Common Definition Blocks

| Block | Content |
|------|------|
| `pagination` | page/page_size pagination params |
| `searchParams` | keyword/status search filters |
| `dateRange` | start_date/end_date date range |
| `passwordConfirm` | password confirmation |

## 16. Unified Response Format

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

| code | Meaning |
|------|------|
| 0 | Success |
| 400 | Parameter error |
| 401 | Unauthenticated |
| 403 | No permission |
| 404 | Not found |
| 422 | Validation failed |
| 429 | Too many requests |
| 500 | Server error |
