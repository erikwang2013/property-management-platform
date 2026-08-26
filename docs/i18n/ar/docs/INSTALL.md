# دليل التثبيت

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

يرشدك هذا المستند إلى نشر نظام إدارة العقارات من الصفر.

---

## المحتويات

1. [معالج التثبيت عبر الويب (موصى به)](#معالج-التثبيت-عبر-الويب-موصى-به)
2. [التثبيت اليدوي](#التثبيت-اليدوي)
3. [النشر عبر Docker](#النشر-عبر-docker)
4. [الحسابات الافتراضية](#الحسابات-الافتراضية)
5. [التحقق من التثبيت](#التحقق-من-التثبيت)
6. [الأسئلة الشائعة](#الأسئلة-الشائعة)

---

## معالج التثبيت عبر الويب (موصى به)

يضم المشروع معالج تثبيت عبر الويب، بعد تشغيل لوحة الإدارة يمكن إتمام كل الإعدادات عبر المتصفح.

### خطوات الاستخدام

```bash
# 1. ادخل إلى دليل لوحة الإدارة
cd admin

# 2. أنشئ ملف متغيرات البيئة (انسخ من القالب)
cp .env.example .env

# 3. ثبّت التبعيات
composer install --no-dev --optimize-autoloader

# 4. شغّل الخدمة
php start.php start -d
```

### 5. افتح معالج التثبيت

زُر **`http://localhost:8787/install`** في المتصفح، وأكمل إعداد الخطوات الثلاث حسب التعليمات:

| الخطوة | المحتوى | الوصف |
|------|------|------|
| الخطوة 1 | إعداد قاعدة البيانات | املأ المضيف والمنفذ واسم القاعدة واسم المستخدم وكلمة المرور |
| الخطوة 2 | حساب المسؤول | اضبط اسم مستخدم وكلمة مرور دخول لوحة الإدارة (6 أحرف على الأقل) |
| الخطوة 3 | تأكيد التثبيت | راجع معلومات الإعداد، بعد الضغط على تأكيد يُنفَّذ التثبيت تلقائيًا |

عملية التثبيت تُنجز تلقائيًا:
1. اختبار اتصال قاعدة البيانات
2. كتابة ملف الإعداد `.env`
3. استيراد كل جداول البيانات الـ65 + بيانات صلاحيات البذرة
4. إنشاء حساب المسؤول ومنحه دور المدير الأعلى
5. إنشاء ملف قفل التثبيت `public/.installed`

### بعد اكتمال التثبيت

- عنوان لوحة الإدارة: `http://localhost:8787/admin`
- سيعرض معالج التثبيت عنوان الدخول ومعلومات الحساب
- يُنصح بإعادة تشغيل الخدمة لتفعيل الإعدادات: `php start.php restart -d`
- لإعادة التثبيت، احذف ملف `public/.installed` فقط

---

## التثبيت اليدوي

### متطلبات البيئة

| المكوّن | متطلب الإصدار | الوصف |
|------|---------|------|
| PHP | 8.1+ (موصى به 8.3) | يتطلب إضافات pcntl、pdo_mysql、redis、gd、mbstring |
| MySQL | 8.0+ | مجموعة أحرف utf8mb4 |
| Redis | 6.0+ | ذاكرة مؤقتة، تحديد معدل، Session |
| Composer | 2.x | إدارة تبعيات PHP |
| Elasticsearch | 8.x | بحث نص كامل (اختياري، عند تعطيله يستخدم استعلام القاعدة) |
| Flutter SDK | 3.x | لتطوير الواجهات فقط |

### فحص إضافات PHP

```bash
php -m | grep -E "pcntl|pdo_mysql|redis|gd|mbstring|curl|json|xml|dom"
```

---

## تهيئة قاعدة البيانات

### 1. إنشاء قاعدة البيانات

```bash
mysql -u root -p <<SQL
CREATE DATABASE IF NOT EXISTS property_management
  DEFAULT CHARSET utf8mb4
  COLLATE utf8mb4_unicode_ci;
SQL
```

### 2. استيراد سكربت التثبيت الموحد

```bash
mysql -u root -p property_management < docs/install.sql
```

`docs/install.sql` يحتوي كل الجداول الـ65 + بيانات بذرة صلاحيات RBAC، ويستخدم `CREATE TABLE IF NOT EXISTS` لضمان إمكانية التنفيذ المتكرر.

تحقق بعد التنفيذ:

```bash
mysql -u root -p property_management -e "SHOW TABLES;" | wc -l
# يجب أن يخرج: 66 (65 جدولًا + سطر العنوان)
```

---

## نشر لوحة الإدارة

لوحة الإدارة تعمل على `http://localhost:8787`، وتقدم API للخلفية الإدارية.

```bash
cd admin

# 1. إعداد متغيرات البيئة
cp .env.example .env
# عدّل .env: كلمة مرور قاعدة البيانات، مفاتيح JWT وغيرها

# 2. تثبيت التبعيات
composer install --no-dev --optimize-autoloader

# 3. تشغيل الخدمة
php start.php start -d
# -d تعني التشغيل في الخلفية، بدونها يعمل في المقدمة لمشاهدة السجلات

# 4. التحقق
curl http://localhost:8787/health
```

### بنود الإعداد الرئيسية (admin/.env)

| بند الإعداد | الوصف | متطلب بيئة الإنتاج |
|--------|------|-------------|
| `JWT_SECRET_KEY` | مفتاح توقيع JWT | سلسلة عشوائية 64+ بت |
| `HASHIDS_SALT` | قيمة ملح تشفير المعرّفات | سلسلة عشوائية، متطابقة مع service |
| `SNOWFLAKE_DATACENTER_ID` | معرّف مركز البيانات (0-31) | يجب التمييز عند نشر مراكز متعددة |
| `SNOWFLAKE_WORKER_ID` | معرّف عقدة العمل (0-31) | مختلف لكل جهاز في نفس المركز |
| `ENCRYPTION_KEY` | مفتاح تشفير نقل API | سلسلة عشوائية 32 بايت |
| `ENCRYPTABLE_KEY` | مفتاح تشفير حقول قاعدة البيانات | سلسلة عشوائية 32 بايت |
| `DB_PASSWORD` | كلمة مرور قاعدة البيانات | كلمة مرور قوية |

---

## نشر بوابة الأعمال

بوابة الأعمال تعمل على `http://localhost:8788`، وتقدم API لبوابة الملاك.

```bash
cd service

# 1. إعداد متغيرات البيئة
cp .env.example .env
# عدّل .env: كلمة مرور قاعدة البيانات، مفاتيح JWT وغيرها

# 2. تثبيت التبعيات
composer install --no-dev --optimize-autoloader

# 3. تشغيل الخدمة
php start.php start -d

# 4. التحقق
curl http://localhost:8788/health
```

> **ملاحظة:** admin و service يتشاركان نفس قاعدة البيانات. `HASHIDS_SALT` يجب أن يتطابق مع admin، وإلا لا يمكن فك تشفير المعرّفات المشفرة التي أنشأها admin في طرف service.

---

## النشر عبر Docker

### لوحة الإدارة

```bash
cd admin
cp .env.docker .env
# عدّل .env لمفاتيح الإنتاج

docker compose up -d
# يشمل: Nginx + PHP + MySQL + Redis + Elasticsearch
```

### بوابة الأعمال

```bash
cd service
cp .env.docker .env
# عدّل .env لمفاتيح الإنتاج

docker compose up -d
```

### تخطيط منافذ الخدمات

| الخدمة | admin | service | الوصف |
|------|-------|---------|------|
| التطبيق | 8787 | 8788 | webman HTTP |
| MySQL | 3306 | 3307 | تعيين منافذ الحاويات |
| Redis | 6379 | 6380 | تعيين منافذ الحاويات |
| Elasticsearch | 9200 | 9201 | تعيين منافذ الحاويات |
| Nginx | 80/443 | 80/443 | يحتاج نشرًا متباعدًا |

> عند نشر docker-compose اثنين على نفس المضيف، منافذ service مضبوطة مسبقًا بإزاحة لتجنب التعارض.

---

## الحسابات الافتراضية

| اسم المستخدم | كلمة المرور | الدور | الوصف |
|--------|------|------|------|
| admin | admin123 | مدير أعلى | يملك كل الصلاحيات |

> **في بيئة الإنتاج غيّر كلمة المرور الافتراضية فورًا.**

---

## التحقق من التثبيت

### 1. فحص الصحة

```bash
# لوحة الإدارة
curl http://localhost:8787/health

# بوابة الأعمال
curl http://localhost:8788/health
```

### 2. توثيق API

كل نقاط API ومعاملاتها موضحة في الوثيقة المستقلة [API.md](API.md). بعد تشغيل الخدمة يمكن أيضًا زيارة واجهة توثيق API التفاعلية المولدة تلقائيًا:

| الطرف | العنوان |
|----|------|
| لوحة الإدارة | http://localhost:8787/apidoc |
| بوابة الأعمال | http://localhost:8788/apidoc |

### 3. اختبار تسجيل الدخول

```bash
curl -X POST http://localhost:8787/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

### 4. تشغيل الاختبارات

```bash
# لوحة الإدارة
cd admin && php vendor/bin/phpunit

# بوابة الأعمال
cd service && php vendor/bin/phpunit
```

---

## الأسئلة الشائعة

### س: خطأ الإقلاع `Call to undefined function pcntl_fork()`

PHP تفتقد إضافة pcntl.

```bash
# Ubuntu/Debian
apt install php-pcntl

# Docker
docker-php-ext-install pcntl
```

### س: بعد تسجيل الدخول تظهر رسالة Token غير صالح

افحص تطابق الإعدادات التالية في `.env` لطرفي admin و service:
- `JWT_SECRET_KEY`
- `JWT_ALGORITHM`

### س: المعرّف المشفر غير متطابق بين الطرفين

تأكد أن قيمة `HASHIDS_SALT` في admin و service متطابقة تمامًا.

### س: شبكة حاويات Docker غير متصلة

استخدم اسم الحاوية بدل IP للاتصال (مثل `DB_HOST=mysql`).

### س: كيف أعيد ضبط قاعدة البيانات

```bash
mysql -u root -p -e "DROP DATABASE IF EXISTS property_management;"
mysql -u root -p -e "CREATE DATABASE property_management DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -p property_management < docs/install.sql
```

### س: كيف أهيئ HTTPS

في بيئة الإنتاج يُنصح باستخدام Nginx كوكيل عكسي لإنهاء TLS. الإعداد المرجعي في `admin/docs/nginx-security.conf`.

---

## الخطوات التالية

- [وثيقة تصميم البنية](ARCHITECTURE_DESIGN.md) — بنية النظام الطبقية وسلسلة تنفيذ الوسطيات
- [توثيق API](API.md) — مرجع الواجهات الكامل
- [وثيقة تصميم الوظائف](FEATURE_DESIGN.md) — مواصفات 34 وحدة وظيفية
- [مقارنة الإصدارات](EDITIONS.md) — فروقات إصدارات Lite / Standard / Full
