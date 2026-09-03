# Dokumen Desain Arsitektur (Architecture Design)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## 1. Ikhtisar Arsitektur Sistem

Sistem Manajemen Properti menggunakan arsitektur berlapis «dua backend + multi frontend». Panel admin dan portal pemilik service adalah dua proyek webman v2 independen, bekerja sama melalui berbagi database MySQL. Frontend mencakup Flutter Web (gaya backoffice PC) dan aplikasi mobile HarmonyOS.

### Tujuan Desain

- **Deployment independen**: admin dan service masing-masing start/stop independen、scale independen、manajemen kunci independen
- **Berbagi data**: berbagi database MySQL yang sama, menghindari masalah sinkronisasi data
- **Standar terpadu**: dua proyek mengikuti standar kode、gaya konfigurasi、kebijakan keamanan yang sama
- **Web prioritas PC**: Flutter Web dirancang dengan gaya backoffice desktop (sidebar + topbar + area konten)

## 2. Arsitektur Berlapis

```
┌─────────────────────────────────────────────────────────────┐
│                        路由层 (Route Layer)                   │
│   config/route.php — URL → Controller 映射 + 中间件绑定       │
├─────────────────────────────────────────────────────────────┤
│                       中间件层 (Middleware Layer)              │
│   SecurityFilter → RateLimit → Auth → Permission               │
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

## 3. Rantai Eksekusi Middleware

### Panel admin (admin)
```
Cors → SecurityFilter(方法检查→405) → RateLimit(限流) 
  → AdminAuth(JWT验证) → AdminPermission(RBAC鉴权)
    → OperationLog(操作记录) → Controller
```

### Portal pemilik (service)
```
Cors → SecurityFilter(方法检查→405) → RateLimit(限流)
  → Controller（URL 版本路由）           # /api/v1/* 公开接口
  → ServiceAuth(JWT业主认证) → Controller       # /service/v1/* 认证接口
```

### Penjelasan Middleware Global

| Middleware | Posisi | Tanggung jawab |
|--------|------|--------|
| Cors | Global posisi pertama | Pemrosesan header berbagi sumber daya lintas origin |
| SecurityFilter | Global | Whitelist metode HTTP、pemblokiran serangan XSS/injeksi SQL/path traversal/injeksi perintah/CSRF、blacklist IP |
| RateLimit | Global | Rate limit sliding window Redis (atomik Lua), default 60 kali/menit |
| AdminAuth | Route /admin | Validasi JWT Token, injeksi adminId |
| AdminPermission | Route /admin | Validasi izin RBAC method.path (cache Redis 60s) |
| OperationLog | Route /admin | Rekaman otomatis operasi POST/PUT/DELETE (termasuk deteksi sumber) |
| ServiceAuth | Route /service | Validasi JWT Token, injeksi ownerId |

## 4. Siklus Hidup Lengkap ID

```
生成: SnowflakeService::generate()
      datacenter_id(5bit) + worker_id(5bit) + timestamp(41bit) + sequence(12bit)
      → BIGINT(18) 例: 1750123456789

存储: MySQL management_* 表
      id BIGINT UNSIGNED NOT NULL（非自增）
      敏感字段 encryptable cast → AES-256-CBC 加密存储

传输: HashidsService::encode(bigint) → hashid 字符串 例: aB3xK9mW2pQ7rT5v
      API 请求/响应中的所有 ID 字段统一使用 hashid

解码: HashidsService::decode(hashid) → BIGINT
      无效 hashid 抛出 InvalidArgumentException
```

## 5. Lapisan Enkripsi Data

### Lapisan transfer（encryption）
- Enkripsi AES-256-CBC
- Client mengenkripsi sebelum mengirim data sensitif, server mendekripsi setelah menerima
- Kunci independen `ENCRYPTION_KEY`

### Lapisan penyimpanan（encryptable）
- Mekanisme Model `$casts` enkripsi/dekripsi otomatis
- Field sensitif: phone, email, id_card, emergency_contact, emergency_phone
- Kunci independen `ENCRYPTABLE_KEY`
- Tulis otomatis enkripsi menjadi ciphertext, baca otomatis dekripsi menjadi teks polos

### Lapisan tampilan（masking）
- Nomor ponsel: `138****1234`
- Email: `a***@example.com`
- KTP: `********`
- Ekspor Excel/PDF otomatis masking

## 6. Autentikasi dan Izin

### Autentikasi JWT
- Algoritma: HS256
- access_token: masa berlaku 2 jam
- refresh_token: masa berlaku 14 hari
- Pembatasan konkuren: satu user maksimal 3 Token valid, jika melebihi Token tertua masuk blacklist
- Penguncian akun: 5 kali login gagal beruntun terkunci 15 menit

### Model Izin RBAC
- User → Peran → Izin (banyak-ke-banyak)
- Tipe izin: type=1(menu) / type=2(tombol) / type=3(API)
- Format penanda izin: `{method}.{path}` contoh: `get.admin/user`
- Penanda super admin: `*`（melewati semua pemeriksaan izin）
- Pohon izin: parent_id referensi diri mendukung level tanpa batas

## 7. Pertahanan Berlapis Keamanan (18 lapis)

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
第12层 熔断保护        → Redis 熔断器（支付/回调快速失败+半开探测）
第13层 ID 保护         → Hashids 编码，不可逆推真实ID
第14层 请求体加密      → AES-256-CBC 敏感字段
第15层 存储加密        → encryptable DB字段加密
第16层 展示脱敏        → 手机号/邮箱/身份证脱敏
第17层 审计追溯        → OperationLog 全量记录（含来源端 source 自动检测）
第18层 HTTP 头防护     → CSP + X-Permitted-Cross-Domain-Policies
第19层 出口保护        → PDF 版权水印（不可移除）+ Excel 敏感数据脱敏
```

## 8. Kebijakan Rate Limit

Berdasarkan algoritma sliding window Redis Sorted Set, dieksekusi atomik skrip Lua:

| Endpoint | Batasan |
|------|------|
| Default | 60 kali/menit/IP/route |
| POST /api/v1/auth/login | 10 kali/menit |
| POST /api/v1/auth/register | 5 kali/menit |

Melebihi batas mengembalikan 429 + header respons `X-RateLimit-Limit/Remaining/Reset/Retry-After`.

## 9. Kebijakan Versi API

- Versi diekspresikan di dalam route API itu sendiri (mis. `/api/v1/*`, `/service/v1/*`), bukan lewat header request
- Jalur versi yang tidak ada mengembalikan 404 langsung dari router (tanpa middleware)
- Controller diorganisasi per versi: `app/api/{version}/controller/`
- Menambah versi baru = mendaftarkan grup route `/{namespace}/v{version}` baru (controller di bawah `app/api/v1/controller/`); jalur versi yang tidak ada mengembalikan 404 dari FastRoute

## 10. Arsitektur Deployment

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

### Layanan Docker Compose

| Layanan | Image | Deskripsi |
|------|------|------|
| nginx | nginx:alpine | Reverse proxy + file statis |
| admin | build Dockerfile | PHP 8.3 + OPcache |
| service | build Dockerfile | PHP 8.3 + OPcache |
| mysql | mysql:8.0 | Persistensi volume data |
| redis | redis:7-alpine | Cache/rate limit/Session |
| elasticsearch | elasticsearch:8.x | Pencarian teks lengkap |

## 11. Desain Internasionalisasi (i18n)

### Struktur File Bahasa

Sistem mendukung Mandarin Sederhana (zh_CN) dan Inggris (en), default Mandarin.

**Backend PHP:**
```
resource/translations/
├── zh_CN/
│   └── messages.php    # 中文语言包（42+翻译键）
└── en/
    └── messages.php    # 英文语言包
```

Didukung symfony/translation, konfigurasi di `config/translation.php`:
- `locale`: `zh_CN`
- `fallback_locale`: `['zh_CN', 'en']`
- `path`: `resource/translations`

Di controller ambil terjemahan melalui `$this->__('key')`:
```php
return $this->success([], $this->__('create_success'));
return $this->fail($this->__('community.name_required'), 422);
```

Metode `__()` secara internal memanggil fungsi global `trans()` webman, jika terjemahan tidak ada fallback mengembalikan key itu sendiri.

**Flutter Web:**
```
apps/flutter/lib/i18n/
└── messages.dart       # AppTranslations extends GetX Translations
```

Menggunakan GetX `Translations`, 101 kunci terjemahan. Digunakan melalui ekstensi `.tr`:
```dart
Text('login_btn'.tr)   // 中文: "登 录", 英文: "Login"
Text('phone_hint'.tr)  // "请输入手机号" / "Enter phone number"
```

Beralih bahasa:
```dart
Get.updateLocale(Locale('zh', 'CN'));  // 切换中文
Get.updateLocale(Locale('en', 'US'));  // 切换英文
```

### Klasifikasi Kunci Terjemahan

| Kategori | Contoh kunci PHP | Contoh kunci Flutter |
|------|-----------|---------------|
| Umum | `success`, `fail`, `not_found` | `confirm`, `cancel`, `save` |
| Autentikasi | `auth.login_success`, `auth.*` | `login_btn`, `phone_hint` |
| Komunitas | `community.name_required` | - |
| Biaya | `fee.bill_not_found`, `fee.*` | `fee_management`, `bill_status` |
| Perbaikan | `repair.not_found`, `repair.*` | `repair_submit`, `urgency_normal` |
| Keluhan | `complaint.submit_success` | `complaint_type`, `type_complaint` |
| Pribadi | - | `profile`, `change_password` |

**HarmonyOS:** menggunakan qualifier resource `resources/base/element/string.json` + `resources/en_US/element/string.json` (diimplementasikan bersamaan saat membuat proyek HarmonyOS).

## 12. Strategi Pengujian

### Alur Pengujian TDD

Proyek mengikuti alur TDD (test-driven development): merah→hijau→refactor.

```
RED: 先写测试，观察失败
  ↓
GREEN: 写最小代码使测试通过
  ↓
REFACTOR: 清理代码，保持测试绿
```

### Cakupan Pengujian

| Lapisan | Framework pengujian | Konten pengujian |
|----|---------|---------|
| Layanan dasar | PHPUnit | Pembuatan ID Snowflake、encoding/dekoding Hashids、format respons |
| Database | PHPUnit + PDO | Validasi struktur tabel (primary key BIGINT、non-auto-increment、prefiks management_) |
| Internasionalisasi | PHPUnit | Eksistensi file terjemahan、konsistensi kunci Mandarin-Inggris |
| Endpoint API | PHPUnit | Health check、format respons |
| Middleware | Integration test | Autentikasi JWT、rate limit、izin |

### Menjalankan Pengujian

```bash
cd admin && php vendor/bin/phpunit    # 管理端: 60 tests, 164 assertions
cd service && php vendor/bin/phpunit  # 业务端: 18 tests, 45 assertions, 100% pass
```

## 13. Arsitektur Frontend

### Flutter Web (gaya desktop PC)

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

### Aplikasi Mobile HarmonyOS

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

### Pemilihan Teknologi

| Lapisan | Flutter Web | HarmonyOS |
|----|------------|-----------|
| Manajemen state | GetX | @State + @Prop |
| HTTP | Dio + JWT interceptor | @ohos.net.http |
| Persistensi | shared_preferences | @ohos.data.preferences |
| Grafik | fl_chart | Komponen Web + ECharts |
| Internasionalisasi | GetX Translations | qualifier resource |
| Route | GetX named routes | router.pushUrl/replaceUrl |

## 14. Arsitektur Fitur Ekstensi

### Pusat Notifikasi Pesan
Template pesan → pembuatan notifikasi → pengiriman multi-channel (dalam App/SMS/email/push)

### Alur Persetujuan
Konfigurasi tipe persetujuan → submit instance → alur langkah (lulus/tolak) → notifikasi approver berikutnya

### Alur Pembayaran
Buat order pembayaran → pembayaran pihak ketiga → callback async → update status tagihan → catat log pembayaran

### Voting Pemilik
Terbit voting → pemilik vote (bobot luas) → hitung suara real-time → statistik hasil

### Eskalasi SLA Otomatis
Pencocokan aturan SLA → cek timeout terjadwal → eskalasi otomatis → catat denda

### Penagihan Cerdas
Pencocokan strategi penagihan → deteksi keterlambatan → generate tugas penagihan otomatis → eksekusi tindakan penagihan

### Manajemen Pemeliharaan
Dispatch tugas → check-in GPS mobile → upload foto → penanda anomali → statistik selesai

### Manajemen Grup
Grup → kaitan komunitas → agregasi data lintas komunitas (properti/pemilik/penagihan/perbaikan)

## 15. Dokumentasi API

Menggunakan `hg/apidoc` membuat dokumentasi antarmuka otomatis dari anotasi controller, dikelompokkan sesuai fungsi.

**Panel admin** (`http://localhost:8787/apidoc`): 10 grup — 57 controller diberi anotasi (Base/Docs/Install tidak digrup)

| Grup | Jumlah | Controller |
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

**Portal pemilik** (`http://localhost:8788/apidoc`): 9 grup — 17 controller diberi anotasi

| Grup | Jumlah | Controller |
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

### Standar Anotasi

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

### Blok Definisi Umum

| Nama blok | Konten |
|------|------|
| `pagination` | Parameter paginasi page/page_size |
| `searchParams` | Filter pencarian keyword/status |
| `dateRange` | Rentang tanggal start_date/end_date |
| `passwordConfirm` | Konfirmasi kata sandi password |

## 16. Format Respons Terpadu

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

| code | Makna |
|------|------|
| 0 | Sukses |
| 400 | Kesalahan parameter |
| 401 | Belum autentikasi |
| 403 | Tanpa izin |
| 404 | Tidak ada |
| 422 | Validasi gagal |
| 429 | Terlalu sering request |
| 500 | Kesalahan server |
