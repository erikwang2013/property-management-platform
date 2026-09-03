# وثيقة تصميم البنية (Architecture Design)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## 1. نظرة عامة على بنية النظام

يعتمد نظام إدارة العقارات بنية طبقية من «خلفيتين + واجهات متعددة». لوحة الإدارة (admin) وبوابة أعمال الملاك (service) مشروعان webman v2 مستقلان، يتعاونان عبر مشاركة قاعدة بيانات MySQL. تغطي الواجهات Flutter Web (بنمط لوحة إدارة PC) وطرف HarmonyOS للجوال.

### أهداف التصميم

- **نشر مستقل**: admin و service لكل منهما إقلاع/إيقاف مستقل، توسعة/تقلص مستقلة، إدارة مفاتيح مستقلة
- **بيانات مشتركة**: يتشاركان نفس قاعدة بيانات MySQL، تجنبًا لمشاكل مزامنة البيانات
- **معايير موحدة**: يتبع المشروعان نفس معايير الكود ونمط الإعدادات وسياسات الأمان
- **ويب موجه لـ PC أولًا**: Flutter Web مصمم بنمط لوحة إدارة سطح المكتب (شريط جانبي + شريط علوي + منطقة محتوى)

## 2. البنية الطبقية

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

## 3. سلسلة تنفيذ الوسطيات

### لوحة الإدارة (admin)
```
Cors → SecurityFilter(方法检查→405) → RateLimit(限流) 
  → AdminAuth(JWT验证) → AdminPermission(RBAC鉴权)
    → OperationLog(操作记录) → Controller
```

### بوابة الأعمال (service)
```
Cors → SecurityFilter(方法检查→405) → RateLimit(限流)
  → Controller（URL 版本路由）           # /api/v1/* 公开接口
  → ServiceAuth(JWT业主认证) → Controller       # /service/v1/* 认证接口
```

### شرح الوسطيات العامة

| الوسطية | الموقع | المسؤولية |
|--------|------|------|
| Cors | أول موضع عام | معالجة ترويسات مشاركة الموارد عبر النطاقات |
| SecurityFilter | عام | القائمة البيضاء لطرق HTTP، اعتراض XSS/حقن SQL/اجتياز المسار/حقن الأوامر/هجمات CSRF، القائمة السوداء IP |
| RateLimit | عام | تحديد معدل نافذة منزلقة في Redis (ذرّي عبر Lua)، افتراضيًا 60 مرة/دقيقة |
| AdminAuth | مسارات /admin | التحقق من JWT Token، حقن adminId |
| AdminPermission | مسارات /admin | التحقق من صلاحيات RBAC method.path (ذاكرة Redis 60s) |
| OperationLog | مسارات /admin | تسجيل تلقائي لعمليات POST/PUT/DELETE (شامل كشف الطرف المصدر) |
| ServiceAuth | مسارات /service | التحقق من JWT Token، حقن ownerId |

## 4. دورة حياة المعرّف الكاملة

```
التوليد: SnowflakeService::generate()
      datacenter_id(5bit) + worker_id(5bit) + timestamp(41bit) + sequence(12bit)
      → BIGINT(18) مثال: 1750123456789

التخزين: جداول MySQL management_*
      id BIGINT UNSIGNED NOT NULL (غير تلقائي التزايد)
      الحقول الحساسة encryptable cast → تخزين مشفر AES-256-CBC

النقل: HashidsService::encode(bigint) → سلسلة hashid مثال: aB3xK9mW2pQ7rT5v
      كل حقول ID في طلبات/استجابات API تستخدم hashid بشكل موحد

فك التشفير: HashidsService::decode(hashid) → BIGINT
      hashid غير صالح يلقي InvalidArgumentException
```

## 5. طبقات تشفير البيانات

### طبقة النقل (encryption)
- تشفير AES-256-CBC
- العميل يشفّر البيانات الحساسة قبل الإرسال، والخادم يفك التشفير بعد الاستلام
- مفتاح مستقل `ENCRYPTION_KEY`

### طبقة التخزين (encryptable)
- آلية `$casts` في النموذج تشفّر/تفك تلقائيًا
- الحقول الحساسة: phone, email, id_card, emergency_contact, emergency_phone
- مفتاح مستقل `ENCRYPTABLE_KEY`
- الكتابة تشفّر تلقائيًا إلى نص مشفر، والقراءة تفك تلقائيًا إلى نص صريح

### طبقة العرض (إخفاء البيانات)
- رقم الهاتف: `138****1234`
- البريد: `a***@example.com`
- الهوية: `********`
- تصدير Excel/PDF يُخفي تلقائيًا

## 6. المصادقة والصلاحيات

### مصادقة JWT
- الخوارزمية: HS256
- access_token: صلاحية ساعتين
- refresh_token: صلاحية 14 يومًا
- تقييد التزامن: نفس المستخدم 3 Tokens صالحة كحد أقصى، عند التجاوز يُضاف الأقدم إلى القائمة السوداء
- قفل الحساب: 5 محاولات تسجيل دخول فاشلة متتالية تقفل 15 دقيقة

### نموذج صلاحيات RBAC
- مستخدم ← دور ← صلاحية (متعدد إلى متعدد)
- أنواع الصلاحيات: type=1(قائمة) / type=2(زر) / type=3(API)
- تنسيق معرف الصلاحية: `{method}.{path}` مثال: `get.admin/user`
- معرف المدير الأعلى: `*` (يتجاوز كل فحوصات الصلاحيات)
- شجرة الصلاحيات: parent_id ذاتية المرجع تدعم أعماقًا بلا حدود

## 7. الدفاع الأمني المتعمق (18 طبقة)

```
الطبقة 1  رمز التحقق بالنقر    ← تحقق بشري إلزامي عند تسجيل الدخول/التسجيل
الطبقة 2  التأكيد الثانوي لكلمة المرور ← العمليات الحساسة (حذف/دفع/إنهاء عقد) تتطلب إدخال كلمة المرور
الطبقة 3  تحقق عشوائي poster   ← العمليات الحساسة عالية التردد تظهر رمز تحقق عشوائيًا
الطبقة 4  security-php         ← فحص أمني تلقائي ضمن دورة الطلب
الطبقة 5  SecurityFilter       ← اعتراض XSS/حقن SQL/اجتياز المسار/حقن الأوامر/CSRF
الطبقة 6  أمان النقل           ← HTTPS + AES-256-CBC
الطبقة 7  مصادقة JWT           ← HS256، انتهاء ساعتين + refresh token
الطبقة 8  التحكم بالتزامن      ← نفس المستخدم 3 Tokens كحد أقصى، التجاوز للقائمة السوداء
الطبقة 9  قفل الحساب           ← 5 محاولات فاشلة تقفل 15 دقيقة
الطبقة 10 مصادقة RBAC          ← تحكم بالصلاحيات بدقة method.path
الطبقة 11 حماية تحديد المعدل    ← نافذة منزلقة في Redis ذرّية Lua
الطبقة 12 حماية المعرّفات       ← تشفير Hashids، لا يمكن استنتاج المعرّف الحقيقي
الطبقة 13 تشفير جسم الطلب       ← AES-256-CBC للحقول الحساسة
الطبقة 14 تشفير التخزين         ← تشفير حقول encryptable في قاعدة البيانات
الطبقة 15 إخفاء العرض           ← إخفاء رقم الهاتف/البريد/الهوية
الطبقة 16 تتبع التدقيق          ← تسجيل كامل OperationLog (شامل الكشف التلقائي للطرف المصدر)
الطبقة 17 حماية ترويسات HTTP    ← CSP + X-Permitted-Cross-Domain-Policies
الطبقة 18 حماية المخرجات        ← علامة حقوق PDF (غير قابلة للإزالة) + إخفاء البيانات الحساسة في Excel
```

## 8. سياسة تحديد المعدل

تعتمد خوارزمية نافذة منزلقة Sorted Set في Redis، ينفذها سكربت Lua ذرّيًا:

| الواجهة | التحديد |
|------|------|
| الافتراضي | 60 مرة/دقيقة/IP/مسار |
| POST /api/v1/auth/login | 10 مرات/دقيقة |
| POST /api/v1/auth/register | 5 مرات/دقيقة |

التجاوز يُرجع 429 + ترويسات `X-RateLimit-Limit/Remaining/Reset/Retry-After`.

## 9. سياسة إصدارات API

- يُعبَّر عن الإصدار في مسار الواجهة نفسه (مثل `/api/v1/*` و`/service/v1/*`)، وليس عبر ترويسة الطلب
- مسارات الإصدارات غير الموجودة تُرجع 404 مباشرة من الموجّه (بدون وسيطة)
- المتحكمات منظمة حسب الإصدار: `app/api/{version}/controller/`
- إضافة إصدار جديد تعني تسجيل مجموعة مسارات `/{namespace}/v{version}` جديدة (التحكمات تحت `app/api/v1/controller/`)؛ مسارات الإصدارات غير الموجودة تُرجع 404 من FastRoute

## 10. بنية النشر

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

### خدمات Docker Compose

| الخدمة | الصورة | الوصف |
|------|------|------|
| nginx | nginx:alpine | وكيل عكسي + ملفات ثابتة |
| admin | بناء Dockerfile | PHP 8.3 + OPcache |
| service | بناء Dockerfile | PHP 8.3 + OPcache |
| mysql | mysql:8.0 | استمرارية بيانات بحجم |
| redis | redis:7-alpine | ذاكرة/تحديد معدل/Session |
| elasticsearch | elasticsearch:8.x | بحث نص كامل |

## 11. تصميم التدويل (i18n)

### بنية ملفات اللغة

يدعم النظام الصينية المبسطة (zh_CN) والإنجليزية (en)، الافتراضي الصينية.

**خلفية PHP:**
```
resource/translations/
├── zh_CN/
│   └── messages.php    # 中文语言包（42+翻译键）
└── en/
    └── messages.php    # 英文语言包
```

مدفوعة بـ symfony/translation، الإعداد في `config/translation.php`:
- `locale`: `zh_CN`
- `fallback_locale`: `['zh_CN', 'en']`
- `path`: `resource/translations`

في المتحكمات الحصول على الترجمة عبر `$this->__('key')`:
```php
return $this->success([], $this->__('create_success'));
return $this->fail($this->__('community.name_required'), 422);
```

دالة `__()` داخليًا تستدعي الدالة العامة `trans()` في webman، وعند غياب الترجمة تنخفض لإرجاع المفتاح نفسه.

**Flutter Web:**
```
apps/flutter/lib/i18n/
└── messages.dart       # AppTranslations extends GetX Translations
```

تستخدم GetX `Translations`، 101 مفتاح ترجمة. الاستخدام عبر امتداد `.tr`:
```dart
Text('login_btn'.tr)   // 中文: "登 录", 英文: "Login"
Text('phone_hint'.tr)  // "请输入手机号" / "Enter phone number"
```

تبديل اللغة:
```dart
Get.updateLocale(Locale('zh', 'CN'));  // 切换中文
Get.updateLocale(Locale('en', 'US'));  // 切换英文
```

### تصنيف مفاتيح الترجمة

| التصنيف | أمثلة مفاتيح PHP | أمثلة مفاتيح Flutter |
|------|-----------|---------------|
| عام | `success`, `fail`, `not_found` | `confirm`, `cancel`, `save` |
| مصادقة | `auth.login_success`, `auth.*` | `login_btn`, `phone_hint` |
| مجمع | `community.name_required` | - |
| رسوم | `fee.bill_not_found`, `fee.*` | `fee_management`, `bill_status` |
| إصلاح | `repair.not_found`, `repair.*` | `repair_submit`, `urgency_normal` |
| شكوى | `complaint.submit_success` | `complaint_type`, `type_complaint` |
| شخصي | - | `profile`, `change_password` |

**HarmonyOS:** يستخدم مؤهلات الموارد `resources/base/element/string.json` + `resources/en_US/element/string.json` (يُنفذ بالتزامن عند إنشاء مشروع HarmonyOS).

## 12. استراتيجية الاختبار

### سير اختبار TDD

يتبع المشروع سير TDD (التطوير الموجه بالاختبارات): أحمر ← أخضر ← إعادة هيكلة.

```
RED: اكتب الاختبار أولًا ولاحظ الفشل
  ↓
GREEN: اكتب الحد الأدنى من الكود لتمرير الاختبار
  ↓
REFACTOR: نظف الكود مع إبقاء الاختبارات خضراء
```

### تغطية الاختبار

| الطبقة | إطار الاختبار | محتوى الاختبار |
|----|---------|---------|
| الخدمات الأساسية | PHPUnit | توليد Snowflake ID، تشفير/فك Hashids، تنسيق الاستجابة |
| قاعدة البيانات | PHPUnit + PDO | التحقق من بنية الجداول (مفتاح BIGINT أساسي، غير تلقائي التزايد، بادئة management_) |
| التدويل | PHPUnit | وجود ملفات الترجمة، تطابق مفاتيح الصينية/الإنجليزية |
| نقاط API | PHPUnit | فحص الصحة، تنسيق الاستجابة |
| الوسطيات | اختبارات تكامل | مصادقة JWT، تحديد المعدل، الصلاحيات |

### تشغيل الاختبارات

```bash
cd admin && php vendor/bin/phpunit    # 管理端: 60 tests, 164 assertions
cd service && php vendor/bin/phpunit  # 业务端: 18 tests, 45 assertions, 100% pass
```

## 13. بنية الواجهات

### Flutter Web (نمط سطح مكتب PC)

```
apps/flutter/lib/
├── main.dart                    # المدخل، تهيئة ApiService + AuthService
├── app.dart                     # GetMaterialApp، جدول المسارات + الثيم + i18n
├── config/
│   ├── api_config.dart          # ثوابت نقاط API (تشير إلى service :8788)
│   └── theme.dart               # ثيم Material 3 (نظام ألوان Ant Design)
├── services/
│   ├── api_service.dart         # مفرد Dio + معترض JWT + تحديث تلقائي عند 401
│   ├── auth_service.dart        # تسجيل الدخول/الخروج/استمرار Token
│   └── storage_service.dart     # تغليف shared_preferences
├── i18n/
│   └── messages.dart            # GetX Translations (101 مفتاحًا، zh_CN/en)
├── pages/
│   ├── login/                   # صفحة دخول بنمط PC (Card وسطي + تحقق من النموذج)
│   ├── home/                    # لوحة القيادة (4 StatCard + قائمة الإعلانات)
│   ├── fee/                     # قائمة الفواتير / التفاصيل / نافذة الدفع
│   ├── repair/                  # قائمة الإصلاح / التقديم / التفاصيل + التقييم
│   └── profile/                 # المعلومات الشخصية / تغيير كلمة المرور / الخروج
└── widgets/
    └── stat_card.dart           # مكوّن بطاقة الإحصاء (أيقونة + عنوان + قيمة)
```

### طرف HarmonyOS للجوال

```
apps/harmonyos/entry/src/main/ets/
├── services/
│   ├── ApiService.ets           # تغليف @ohos.net.http، Bearer Token
│   └── AuthService.ets          # تسجيل الدخول/الخروج (استمرار Preference)
├── model/
│   └── Models.ets               # تعريفات واجهات TypeScript
├── pages/
│   ├── LoginPage.ets            # دخول برقم الهاتف + كلمة المرور
│   └── HomePage.ets             # لوحة القيادة (بطاقات الإحصاء + قائمة الإعلانات)
└── resources/
    ├── base/element/string.json # 中文资源
    └── en_US/element/string.json# 英文资源
```

### الاختيارات التقنية

| الطبقة | Flutter Web | HarmonyOS |
|----|------------|-----------|
| إدارة الحالة | GetX | @State + @Prop |
| HTTP | Dio + معترض JWT | @ohos.net.http |
| الاستمرارية | shared_preferences | @ohos.data.preferences |
| المخططات | fl_chart | مكوّن Web + ECharts |
| التدويل | GetX Translations | مؤهلات resource |
| التوجيه | مسارات GetX المسماة | router.pushUrl/replaceUrl |

## 14. بنية الوظائف الموسعة

### مركز إشعارات الرسائل
قالب الرسالة ← توليد الإشعار ← إرسال متعدد القنوات (داخل التطبيق/رسائل SMS/بريد/دفع)

### سير عمل الموافقات
إعداد نوع الموافقة ← تقديم المثيل ← تنقل الخطوات (قبول/رفض) ← إشعار الموفق التالي

### سير الدفع
إنشاء طلب دفع ← دفع طرف ثالث ← استدعاء غير متزامن ← تحديث حالة الفاتورة ← تسجيل سجل الدفع

### تصويت الملاك
نشر التصويت ← تصويت الملاك (مرجح بالمساحة) ← فرز لحظي ← إحصاء النتائج

### ترقية SLA التلقائية
مطابقة قواعد SLA ← فحص مهلة مجدول ← ترقية تلقائية ← تسجيل الغرامات

### التحصيل الذكي
مطابقة استراتيجية التحصيل ← كشف المتأخرات ← توليد مهام التحصيل تلقائيًا ← تنفيذ إجراء التحصيل

### إدارة التفتيش
توزيع المهام ← تسجيل GPS من الجوال ← رفع الصور ← وضع علامات الشذوذ ← إحصاء الاكتمال

### إدارة المجموعة
مجموعة ← ربط المجمعات ← تجميع البيانات عبر المجمعات (العقارات/الملاك/التحصيل/الإصلاح)

## 15. توثيق API

يستخدم `hg/apidoc` لتوليد وثائق الواجهات تلقائيًا من شروح المتحكمات، مجمعة حسب الوظائف.

**لوحة الإدارة** (`http://localhost:8787/apidoc`): 10 مجموعات — 57 متحكمًا محقونًا بالشروح (Base/Docs/Install غير مجمعة)

| المجموعة | العدد | المتحكمات |
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

**بوابة الأعمال** (`http://localhost:8788/apidoc`): 9 مجموعات — 17 متحكمًا محقونًا بالشروح

| المجموعة | العدد | المتحكمات |
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

### معايير الشروح

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

### كتل التعريف العامة

| اسم الكتلة | المحتوى |
|------|------|
| `pagination` | معاملات page/page_size للترقيم |
| `searchParams` | تصفية البحث keyword/status |
| `dateRange` | نطاق التاريخ start_date/end_date |
| `passwordConfirm` | تأكيد كلمة المرور password |

## 16. تنسيق الاستجابة الموحد

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

| code | المعنى |
|------|------|
| 0 | نجاح |
| 400 | خطأ في المعاملات |
| 401 | غير مصادق |
| 403 | بلا إذن |
| 404 | غير موجود |
| 422 | فشل التحقق |
| 429 | طلبات كثيرة جدًا |
| 500 | خطأ الخادم |
