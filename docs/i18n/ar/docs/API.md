# وثيقة الواجهات (API Reference)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## نظرة عامة

- واجهات لوحة الإدارة تعمل على `http://localhost:8787`
- واجهات بوابة الأعمال تعمل على `http://localhost:8788`
- تنسيق الاستجابة الموحد: `{"code": 0, "message": "success", "data": {...}}`
- كل حقول ID تُنقل مشفرة بتشفير hashids
- يُعبَّر عن إصدار API في المسار نفسه (حاليًا `/api/v1/*`)، وليس عبر ترويسة الطلب
- اللغة تتحكم بها ترويسة الطلب `Accept-Language` (`zh-CN` / `en-US`، افتراضيًا `zh-CN`)

### توثيق API عبر الإنترنت

بعد تشغيل الخدمة زُر الوثائق التفاعلية المولدة تلقائيًا عبر `hg/apidoc`:

| الطرف | العنوان | عدد المجموعات |
|----|------|--------|
| لوحة الإدارة | `http://localhost:8787/apidoc` | 10 مجموعات (common/dashboard/system/property-core/property-aux/property-adv/extensions/export/import/upload) |
| بوابة الملاك | `http://localhost:8788/apidoc` | 9 مجموعات (واجهات عامة/الرئيسية/الرسوم/الإصلاح/التغذية الراجعة/المواقف/الأنشطة/الشخصية/التمديد) |

---

## واجهات لوحة الإدارة (admin :8787)

### الواجهات العامة — بلا مصادقة

#### POST /api/v1/captcha/generate
الحصول على رمز تحقق بالنقر.

معاملات الطلب: لا شيء

الاستجابة:
```json
{
  "code": 0,
  "data": {
    "key": "captcha_key_string",
    "image": "base64_encoded_png",
    "extra": { "targets": ["树", "鸟", "花"] }
  }
}
```

#### POST /api/v1/captcha/verify
التحقق من رمز التحقق بالنقر.

معاملات الطلب:
| المعامل | النوع | الوصف |
|------|------|------|
| key | string | مفتاح رمز التحقق، يُرجع من generate |
| clicks | array | إحداثيات النقر [{x, y}, ...] |

الاستجابة:
```json
{
  "code": 0,
  "data": { "valid": true }
}
```

عند فشل التحقق يكون `code` هو 422 و `data.valid` هو `false`.

#### POST /api/v1/auth/login
تسجيل دخول المسؤول.

معاملات الطلب:
| المعامل | النوع | الوصف |
|------|------|------|
| username | string | اسم المستخدم |
| password | string | كلمة المرور |
| captcha_key | string | مفتاح رمز التحقق |
| clicks | array | إحداثيات النقر [{x, y}, ...] |

الاستجابة:
```json
{
  "code": 0,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "user": { "id": "aB3xK9mW...", "username": "admin", "real_name": "管理员" }
  }
}
```

#### POST /api/v1/auth/refresh
تحديث Token.

معاملات الطلب:
| المعامل | النوع | الوصف |
|------|------|------|
| refresh_token | string | رمز التحديث |

الاستجابة:
```json
{
  "code": 0,
  "data": { "access_token": "eyJ..." }
}
```

#### GET /health
فحص الصحة.

#### GET /metrics
مقاييس مراقبة Prometheus.

#### GET /api/docs
وثائق OpenAPI.

---

### واجهات لوحة الإدارة — تتطلب مصادقة (Bearer Token)

كل الواجهات بادئتها `/admin`، وتتطلب حمل `Authorization: Bearer {access_token}`.

#### لوحة القيادة

**GET /admin/dashboard**
الحصول على بيانات إحصاءات لوحة القيادة.

#### إدارة مستخدمي المسؤول

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/user | قائمة المستخدمين (?keyword=&status=&page=&page_size=) |
| POST | /admin/user | إنشاء مستخدم |
| GET | /admin/user/{hashid} | تفاصيل المستخدم |
| PUT | /admin/user/{hashid} | تحديث المستخدم |
| DELETE | /admin/user/{hashid} | حذف المستخدم (يتطلب تأكيد كلمة المرور) |
| POST | /admin/user/batch/destroy | حذف جماعي |
| POST | /admin/user/batch/status | تفعيل/تعطيل جماعي |
| POST | /admin/import/users | استيراد مستخدمين من Excel |

#### إدارة الأدوار والصلاحيات

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/role | قائمة الأدوار |
| POST | /admin/role | إنشاء دور |
| GET | /admin/role/{hashid} | تفاصيل الدور |
| PUT | /admin/role/{hashid} | تحديث الدور |
| DELETE | /admin/role/{hashid} | حذف الدور |
| GET | /admin/permission | قائمة الصلاحيات (شجرية) |
| POST | /admin/permission | إنشاء صلاحية |
| PUT | /admin/permission/{hashid} | تحديث الصلاحية |
| DELETE | /admin/permission/{hashid} | حذف الصلاحية |

#### إعدادات النظام

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/config | قائمة الإعدادات (?group=) |
| POST | /admin/config | إنشاء إعداد |
| PUT | /admin/config/{hashid} | تحديث الإعداد |
| DELETE | /admin/config/{hashid} | حذف الإعداد |

#### سجلات العمليات

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/log | قائمة السجلات (?user_id=&action=&method=&source=&start_date=&end_date=) |

#### المركز الشخصي

| الطريقة | المسار | الوصف |
|------|------|------|
| PUT | /admin/profile | تعديل المعلومات الشخصية |
| PUT | /admin/profile/password | تعديل كلمة المرور |
| POST | /admin/profile/logout | تسجيل الخروج |

#### التصدير

| الطريقة | المسار | الوصف |
|------|------|------|
| POST | /admin/export/excel | تصدير Excel ({ table, columns, conditions, title }) |
| POST | /admin/export/pdf | تصدير PDF ({ type, title, data }) |

---

### إدارة العقارات — واجهات لوحة الإدارة

#### إدارة المجمعات السكنية

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/community | القائمة (?keyword=&status=) |
| POST | /admin/community | إنشاء |
| GET | /admin/community/{hashid} | التفاصيل |
| PUT | /admin/community/{hashid} | تحديث |
| DELETE | /admin/community/{hashid} | حذف (يتطلب كلمة المرور) |

#### إدارة المباني

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/building | القائمة (?community_id=&keyword=) |
| POST | /admin/building | إنشاء |
| GET | /admin/building/{hashid} | التفاصيل |
| PUT | /admin/building/{hashid} | تحديث |
| DELETE | /admin/building/{hashid} | حذف |

#### إدارة الوحدات

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/unit | القائمة (?building_id=) |
| POST | /admin/unit | إنشاء |
| GET | /admin/unit/{hashid} | التفاصيل |
| PUT | /admin/unit/{hashid} | تحديث |
| DELETE | /admin/unit/{hashid} | حذف |

#### إدارة أنواع الوحدات

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/room-type | القائمة |
| POST | /admin/room-type | إنشاء |
| GET | /admin/room-type/{hashid} | التفاصيل |
| PUT | /admin/room-type/{hashid} | تحديث |
| DELETE | /admin/room-type/{hashid} | حذف |

#### إدارة العقارات

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/room | القائمة (?community_id=&building_id=&unit_id=&status=) |
| POST | /admin/room | إنشاء |
| GET | /admin/room/{hashid} | التفاصيل |
| PUT | /admin/room/{hashid} | تحديث |
| DELETE | /admin/room/{hashid} | حذف |
| GET | /admin/room/tree | شجرة العقارات (مجمع←مبنى←وحدة←عقار) |

#### إدارة الملاك

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/owner | القائمة (?keyword=&status=) |
| POST | /admin/owner | إنشاء |
| GET | /admin/owner/{hashid} | التفاصيل (شاملة العقارات المرتبطة) |
| PUT | /admin/owner/{hashid} | تحديث |
| DELETE | /admin/owner/{hashid} | حذف (يتطلب كلمة المرور) |
| POST | /admin/owner/batch/import | استيراد جماعي من Excel |
| POST | /admin/owner/batch/destroy | حذف جماعي |

#### إدارة المستأجرين

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/tenant | القائمة (?room_id=&status=) |
| POST | /admin/tenant | إنشاء |
| GET | /admin/tenant/{hashid} | التفاصيل |
| PUT | /admin/tenant/{hashid} | تحديث |
| DELETE | /admin/tenant/{hashid} | حذف |

#### أنواع الرسوم

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/fee-type | القائمة |
| POST | /admin/fee-type | إنشاء |
| GET | /admin/fee-type/{hashid} | التفاصيل |
| PUT | /admin/fee-type/{hashid} | تحديث |
| DELETE | /admin/fee-type/{hashid} | حذف |

#### إدارة الفواتير

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/fee-bill | القائمة (?community_id=&status=&due_date_start=&due_date_end=) |
| POST | /admin/fee-bill | إنشاء فاتورة |
| GET | /admin/fee-bill/{hashid} | التفاصيل |
| PUT | /admin/fee-bill/{hashid} | تحديث |
| DELETE | /admin/fee-bill/{hashid} | حذف |
| POST | /admin/fee-bill/batch/generate | توليد فواتير جماعي |

#### سجلات الدفع

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/fee-payment | القائمة (?bill_id=&payment_method=&date_start=&date_end=) |
| POST | /admin/fee-payment/offline | تسجيل تحصيل خارجي |

#### إدارة طلبات الإصلاح

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/repair | القائمة (?status=&category=) |
| POST | /admin/repair | إنشاء |
| GET | /admin/repair/{hashid} | التفاصيل (شاملة سجلات التقدم) |
| PUT | /admin/repair/{hashid} | تحديث |
| DELETE | /admin/repair/{hashid} | حذف |
| PUT | /admin/repair/{id}/assign | إرسال العمالة ({ staff_id }) |
| POST | /admin/repair/{id}/progress | تحديث التقدم ({ status_to, remark }) |

#### إدارة الإعلانات

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/announcement | القائمة (?community_id=&category=&is_published=) |
| POST | /admin/announcement | إنشاء |
| GET | /admin/announcement/{hashid} | التفاصيل |
| PUT | /admin/announcement/{hashid} | تحديث |
| DELETE | /admin/announcement/{hashid} | حذف |

#### إدارة المواقف

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/parking-space | القائمة (?community_id=) |
| POST | /admin/parking-space | إنشاء موقف |
| PUT | /admin/parking-space/{hashid} | تحديث |
| DELETE | /admin/parking-space/{hashid} | حذف |
| GET | /admin/parking-vehicle | القائمة (?owner_id=&space_id=) |
| POST | /admin/parking-vehicle | إنشاء مركبة |
| PUT | /admin/parking-vehicle/{hashid} | تحديث |
| DELETE | /admin/parking-vehicle/{hashid} | حذف |
| GET | /admin/parking-record | سجلات المواقف (?vehicle_id=&date_start=&date_end=) |

#### إدارة المعدات

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/equipment | القائمة (?community_id=&category=&status=) |
| POST | /admin/equipment | إنشاء |
| PUT | /admin/equipment/{hashid} | تحديث |
| DELETE | /admin/equipment/{hashid} | حذف |
| GET | /admin/equipment-maintenance | سجلات الصيانة (?equipment_id=) |
| POST | /admin/equipment-maintenance | إنشاء صيانة |

#### معالجة الشكاوى

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/complaint | القائمة (?type=&status=) |
| GET | /admin/complaint/{hashid} | التفاصيل |
| PUT | /admin/complaint/{id}/handle | معالجة ({ handler_remark }) |
| POST | /admin/complaint/{id}/visit | متابعة ({ visitor_remark }) |

#### موافقات الزوار

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/visitor | القائمة (?status=) |
| PUT | /admin/visitor/{id}/approve | الموافقة على المرور |

#### إدارة العقود

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/contract | القائمة (?contract_type=&status=) |
| POST | /admin/contract | إنشاء |
| PUT | /admin/contract/{hashid} | تحديث |
| DELETE | /admin/contract/{hashid} | حذف |

#### الإدارة المالية

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/finance-income | قائمة الإيرادات (?income_type=&date_start=&date_end=) |
| POST | /admin/finance-income | تسجيل إيراد |
| GET | /admin/finance-expense | قائمة المصروفات |
| POST | /admin/finance-expense | تسجيل مصروف |
| GET | /admin/finance/statistics | إحصاءات الإيرادات والمصروفات الشهرية (?year=) |

#### لوحة العقارات

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/dashboard/property | إحصاءات العقارات (مستحقات/نسبة الإشغال/إصلاحات/شكاوى/اتجاهات الإيرادات والمصروفات) |
| POST | /admin/export/property-excel | تصدير بيانات العقارات Excel ({ type: owners|bills }) |

#### الدوريات الأمنية

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/security-patrol | القائمة (?community_id=) |
| POST | /admin/security-patrol | إنشاء مسار |
| GET | /admin/patrol-record | السجلات (?patrol_id=&staff_id=) |
| POST | /admin/patrol-record | إنشاء سجل |

#### إدارة النظافة

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/cleaning-area | قائمة المناطق |
| POST | /admin/cleaning-area | إنشاء منطقة |
| GET | /admin/cleaning-record | السجلات (?area_id=) |
| POST | /admin/cleaning-record | إنشاء سجل |

#### إدارة المساحات الخضراء

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/green-area | قائمة المناطق |
| POST | /admin/green-area | إنشاء منطقة |
| GET | /admin/green-maintenance | سجلات الصيانة (?area_id=) |
| POST | /admin/green-maintenance | إنشاء سجل |

#### أنشطة المجتمع

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/activity | القائمة (?status=) |
| POST | /admin/activity | إنشاء نشاط |
| PUT | /admin/activity/{hashid} | تحديث |
| DELETE | /admin/activity/{hashid} | حذف |
| GET | /admin/activity-signup | قائمة التسجيلات (?activity_id=) |
| PUT | /admin/activity-signup/{id}/checkin | تسجيل الحضور |

#### إدارة استهلاك الطاقة

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/energy-meter | قائمة العدادات (?room_id=&meter_type=) |
| POST | /admin/energy-meter | إنشاء عداد |
| GET | /admin/energy-record | سجلات القراءة (?meter_id=&date_start=&date_end=) |
| POST | /admin/energy-record | إنشاء سجل |

#### إدارة الموظفين

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/staff | القائمة (?community_id=&status=) |
| POST | /admin/staff | إنشاء |
| PUT | /admin/staff/{hashid} | تحديث |
| DELETE | /admin/staff/{hashid} | حذف |
| POST | /admin/staff/batch/status | تفعيل/تعطيل جماعي |

#### إشعارات الرسائل

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/notification-template | قائمة القوالب |
| POST | /admin/notification-template | إنشاء قالب |
| PUT | /admin/notification-template/{hashid} | تحديث القالب |
| DELETE | /admin/notification-template/{hashid} | حذف القالب |
| GET | /admin/notification | قائمة الرسائل (?type=&is_read=) |
| POST | /admin/notification/send | إرسال إشعار يدوي |

#### سير عمل الموافقات

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/approval-type | قائمة أنواع الموافقات |
| POST | /admin/approval-type | إنشاء نوع موافقة |
| GET | /admin/approval | قائمة الموافقات (?status=) |
| GET | /admin/approval/{hashid} | تفاصيل الموافقة |
| POST | /admin/approval | تقديم موافقة |
| PUT | /admin/approval/{hashid}/approve | الموافقة (قبول/رفض) |

#### إدارة الدفع

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/payment-order | قائمة الطلبات |
| GET | /admin/payment-order/{hashid} | تفاصيل الطلب |
| POST | /admin/payment-order/{hashid}/refund | الاسترداد |
| GET | /admin/payment/statistics | إحصاءات الدفع |

#### تصويت الملاك

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /admin/vote | قائمة التصويتات (?status=) |
| POST | /admin/vote | إنشاء تصويت |
| GET | /admin/vote/{hashid}/statistics | إحصاءات الفرز |
| PUT | /admin/vote/{hashid}/publish | نشر التصويت |
| PUT | /admin/vote/{hashid}/end | إنهاء التصويت |

#### إدارة SLA · التحصيل الذكي · إدارة التفتيش · إدارة المتجر · إدارة الوجوه · إدارة المجموعة · قاعدة المعرفة

(النقاط الكاملة انظر ملف `docs/API.md`)

---

## واجهات بوابة الأعمال (service :8788)

### الواجهات العامة — بلا مصادقة

#### POST /api/v1/captcha/generate
الحصول على رمز تحقق بالنقر. (نفس لوحة الإدارة)

#### POST /api/v1/captcha/verify
التحقق من رمز التحقق بالنقر. (الطلب/الاستجابة نفس لوحة الإدارة)

#### POST /api/v1/auth/login
تسجيل دخول المالك.

معاملات الطلب:
| المعامل | النوع | الوصف |
|------|------|------|
| phone | string | رقم الهاتف |
| password | string | كلمة المرور |
| captcha_key | string | مفتاح رمز التحقق |
| clicks | array | إحداثيات النقر |

الاستجابة:
```json
{
  "code": 0,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "owner": { "id": "xB9k...", "name": "张三", "phone": "138****1234" }
  }
}
```

#### POST /api/v1/auth/register
تسجيل المالك.

معاملات الطلب:
| المعامل | النوع | الوصف |
|------|------|------|
| phone | string | رقم الهاتف |
| password | string | كلمة المرور (6 أحرف على الأقل) |
| name | string | الاسم |
| captcha_key | string | مفتاح رمز التحقق |
| clicks | array | إحداثيات النقر |
| room_id | string | (اختياري) hashid العقار المرتبط |
| id_card_last4 | string | (اختياري) آخر 4 أرقام من الهوية |

#### POST /api/v1/auth/refresh
تحديث Token.

---

### واجهات بوابة الملاك — تتطلب مصادقة (Bearer Token)

كل الواجهات بادئتها `/service`، وتتطلب حمل `Authorization: Bearer {access_token}`.

#### الصفحة الرئيسية

**GET /service/v1/home**

الاستجابة:
```json
{
  "code": 0,
  "data": {
    "room_count": 2,
    "pending_amount": "1250.00",
    "pending_bill_count": 3,
    "repairing_count": 1,
    "announcements": [{ "id": "xB9k...", "title": "停水通知", "published_at": "2026-05-20 09:00" }]
  }
}
```

#### عقاراتي

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /service/v1/rooms | قائمة عقاراتي |
| GET | /service/v1/room/{hashid} | تفاصيل العقار (شاملة المساحة والاتجاه والملكية ومعلومات المجمع) |

#### إدارة الرسوم

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /service/v1/fees/bills | قائمة الفواتير (?status=0未缴/1部分缴/2已缴/3逾期) |
| GET | /service/v1/fees/bill/{hashid} | تفاصيل الفاتورة (شاملة نوع الرسوم وسجلات الدفع) |
| GET | /service/v1/fees/payments | سجلات الدفع |
| POST | /service/v1/fees/pay | دفع عبر الإنترنت ({ bill_id, payment_method, password }) |
| GET | /service/v1/fees/statistics | إحصاءات الرسوم (?year=2026) |

#### الإصلاح

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /service/v1/repairs | قائمة طلبات الإصلاح (?status=) |
| GET | /service/v1/repair/{hashid} | تفاصيل طلب الإصلاح (شاملة الخط الزمني للتقدم) |
| POST | /service/v1/repair | تقديم طلب إصلاح ({ room_id, category, urgency, description, images[], scheduled_at }) |
| DELETE | /service/v1/repair/{hashid} | إلغاء (يتطلب كلمة المرور، { password }) |
| POST | /service/v1/repair/{hashid}/rate | تقييم ({ rating: 1-5, feedback }) |

#### الشكاوى والاقتراحات

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /service/v1/complaints | قائمة الشكاوى |
| GET | /service/v1/complaint/{hashid} | تفاصيل الشكوى (شاملة تقدم المعالجة) |
| POST | /service/v1/complaint | تقديم شكوى ({ type, category, title, content, is_anonymous, images[] }) |
| POST | /service/v1/complaint/{hashid}/satisfaction | تقييم الرضا ({ satisfaction: 1-5 }) |

#### الإعلانات

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /service/v1/announcements | قائمة الإعلانات (?category=) |
| GET | /service/v1/announcement/{hashid} | تفاصيل الإعلان |

#### المواقف

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /service/v1/parking/vehicles | مركباتي |
| GET | /service/v1/parking/spaces | مواقفي |
| GET | /service/v1/parking/records | سجلات المواقف |

#### الزوار

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /service/v1/visitors | حجوزات زواري |
| POST | /service/v1/visitor | إنشاء حجز (توليد رمز المرور) |
| PUT | /service/v1/visitor/{hashid} | تعديل الحجز |
| DELETE | /service/v1/visitor/{hashid} | إلغاء الحجز |

#### أنشطة المجتمع

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /service/v1/activities | قائمة الأنشطة (?status=) |
| GET | /service/v1/activity/{hashid} | تفاصيل النشاط |
| POST | /service/v1/activity/{hashid}/signup | التسجيل للمشاركة |
| POST | /service/v1/activity/{hashid}/cancel | إلغاء التسجيل |

#### المعلومات الشخصية

| الطريقة | المسار | الوصف |
|------|------|------|
| GET | /service/v1/profile | المعلومات الشخصية |
| PUT | /service/v1/profile | التعديل ({ name, email, gender, birthday }) |
| PUT | /service/v1/profile/password | تغيير كلمة المرور ({ old_password, new_password }) |
| POST | /service/v1/profile/logout | تسجيل الخروج |

---

## API مفتوح — مصادقة API Key

واجهات داخلية للقراءة فقط، لاستدعاء الأنظمة الخارجية (ربط منصات العقارات، شاشات البيانات الكبيرة وغيرها). البادئة `/open`، كلها قراءة فقط.

### طريقة المصادقة

كل طلب يتطلب حمل ترويسة `X-API-Key`، والقيمة هي مفتاح يولده `scripts/gen_api_key.php` (64 بت hex، والقاعدة تخزن ملخص SHA-256 فقط):

```bash
curl -H "X-API-Key: <مفتاحك>" http://localhost:8788/open/v1/announcements
```

- المفتاح الناقص أو الخاطئ يُرجع `401` (`{"code":401,"message":"无效的API Key","data":[]}`)
- إدارة المفاتيح: `php scripts/gen_api_key.php [--name=الغرض]` للتوليد؛ التعطيل/الحذف بالتعامل المباشر مع جدول `management_api_key` (`status=0` تعطيل فوري للمفتاح)

### النقاط

#### GET /open/v1/announcements — قائمة الإعلانات

المعاملات: `page` (افتراضيًا 1)、`category` (اختياري). بنية الاستجابة مطابقة لـ `/service/v1/announcements`.

```bash
curl -H "X-API-Key: <مفتاحك>" "http://localhost:8788/open/v1/announcements?page=1"
```

#### GET /open/v1/bills — استعلام الفواتير

المعاملات: `bill_number` (إلزامي، رقم الفاتورة). يُرجع تفاصيل فاتورة واحدة (شاملة نوع الرسوم ورقم العقار ومبلغ المتأخرات). غير موجود يُرجع 404.

```bash
curl -H "X-API-Key: <مفتاحك>" "http://localhost:8788/open/v1/bills?bill_number=B202608160001"
```

#### GET /open/v1/repairs — استعلام حالة طلب الإصلاح

المعاملات: `order_number` (إلزامي، رقم طلب الإصلاح). يُرجع الحالة الحالية لطلب الإصلاح والخط الزمني للتقدم (مصفوفة `progress`). غير موجود يُرجع 404.

```bash
curl -H "X-API-Key: <مفتاحك>" "http://localhost:8788/open/v1/repairs?order_number=R202608160001"
```

---

## رموز الأخطاء

| code | المعنى | الوصف |
|------|------|------|
| 0 | نجاح | استجابة طبيعية |
| 400 | خطأ في الطلب | تنسيق المعاملات غير صحيح |
| 401 | غير مصادق | Token ناقص/منتهي/غير صالح/مضاف للقائمة السوداء |
| 403 | بلا إذن | دور المستخدم لا يحتوي الصلاحية المطلوبة / الحساب معطل |
| 404 | غير موجود | المورد غير موجود |
| 405 | الطريقة غير مسموحة | طرق HTTP غير GET/POST/PUT/DELETE/OPTIONS |
| 413 | جسم الطلب كبير جدًا | يتجاوز 10MB |
| 415 | نوع الوسائط غير مدعوم | Content-Type ليس JSON أو form-urlencoded |
| 422 | فشل التحقق | معاملات النموذج لا تخضع للقواعد / فشل تأكيد كلمة المرور / رمز تحقق خاطئ |
| 429 | طلبات كثيرة | تفعيل تحديد المعدل / قفل الحساب |
| 500 | خطأ الخادم | استثناء غير متوقع |

## ترويسات استجابة تحديد المعدل

عند تفعيل تحديد المعدل يُرجع 429، وتشمل ترويسات الاستجابة:

| ترويسة الاستجابة | الوصف |
|--------|------|
| X-RateLimit-Limit | عدد المرات المحدود |
| X-RateLimit-Remaining | العدد المتبقي |
| X-RateLimit-Reset | وقت إعادة الضبط (طابع Unix زمني) |
| Retry-After | ثواني الانتظار المقترحة لإعادة المحاولة |
