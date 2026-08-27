# دليل التشغيل (OPS Runbook)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> ينطبق على: property-management-platform (طرف admin + طرف service، PHP 8.3 webman)

## 1. النسخ الاحتياطي واستعادة قاعدة البيانات

طرفا admin و service يتشاركان نفس مثيل MySQL وقاعدة `management`، نسخة واحدة تكفي. المدخل الموحد:

| اسم القاعدة | سكربت النسخ | الوصف |
|---|---|---|
| `management` | `scripts/backup.sh` | يقرأ الاتصال من `admin/.env` (يمكن تجاوز اسم الحاوية بـ `--container=`)، افتراضيًا mysqldump داخل الحاوية |

الناتج `backups/backup_YYYYMMDD_HHMMSS.sql.gz`، الاحتفاظ الافتراضي بآخر 7 أيام (`--keep-days=` قابل للتعديل).

### 1.1 النسخ الاحتياطي الكامل

```bash
cd /path/to/property-management-platform
bash scripts/backup.sh
```

### 1.2 المهام المجدولة (crontab)

```cron
# نسخ احتياطي كامل كل يوم 02:00
0 2 * * * cd /path/to/property-management-platform && bash scripts/backup.sh >> /var/log/pmp-backup.log 2>&1
```

نصيحة الإنتاج: اربط دليل النسخ الاحتياطي بقرص مستقل/تخزين خارج الموقع، وافحص سلامة ملفات النسخ دوريًا (تحقق `gzip -t`).

### 1.3 سير تمرين الاستعادة (مرة ربع سنويًا على الأقل)

1. اختر أحدث نسخة احتياطية: `ls -t backups/backup_*.sql.gz`
2. نفّذ الاستعادة في **بيئة مستقلة** (أو قاعدة مؤقتة): انظر [RECOVERY_RUNBOOK.md](RECOVERY_RUNBOOK.md) السيناريو أ (استعادة قاعدة فارغة) والسيناريو ب (استعادة نقطة زمنية).
3. التحقق:
   - مقارنة الصفوف: `SELECT COUNT(*) FROM management_user;` مطابق لما سُجل قبل النسخ
   - فك تشفير الحقول المشفرة طبيعي: استعلام سجل يحتوي حقول encryptable، القيمة صحيحة، والسجلات بلا أخطاء decrypt
   - فحص مبدئي للأعمال: تسجيل الدخول وواجهة سحب القائمة تعملان
4. سجّل زمن ونتيجة التمرين (لتقييم RTO).

> الدليل الكامل للتمرين (استعادة قاعدة فارغة / استعادة نقطة زمنية / تحقق الاتساق / جدول تمرين 30 دقيقة) في [RECOVERY_RUNBOOK.md](RECOVERY_RUNBOOK.md).

### 1.4 شرح RPO / RTO

- **RPO (كمية البيانات القابلة للفقد)**: يحددها تواتر النسخ. نسخ كامل يومي ← RPO ≤ 24 ساعة، أي فقدان يوم واحد كحد أقصى. يمكن تقليل RPO بزيادة التواتر (مثل مرتين يوميًا) أو تفعيل النسخ الاحتياطي التدريجي عبر binlog.
- **RTO (الزمن اللازم للاستعادة)**: يعتمد على حجم القاعدة وسرعة الاستعادة، الهدف ≤ ساعة واحدة (استعادة + تحقق + إعادة تشغيل الخدمة). حدّث القيمة المقاسة فعليًا بعد كل تمرين.
- طوارئ فشل الاستعادة: ارجع بكود التطبيق أولًا، ثم أعد المحاولة بأحدث نسخة متاحة؛ إن تلف النسخ استخدم نسخة أقدم واقبل RPO أكبر.

## 2. إدارة المفاتيح

المشروع يعتمد على 5 مفاتيح، كلها في `.env` (admin و service مستقلان، لا تشارك نفس المجموعة):

| المتغير | الطول | الاستخدام |
|---|---|---|
| `ENCRYPTION_KEY` | 32 بايت | تشفير نقل API (config/encryption.php) |
| `ENCRYPTABLE_KEY` | 32 بايت | تشفير الحقول الحساسة في قاعدة البيانات (إضافة encryptable، **لا تشاركه مع ENCRYPTION_KEY**) |
| `JWT_SECRET_KEY` | 64+ بت | توقيع JWT |
| `HASHIDS_SALT` | — | تشفير/فك تشفير المعرّفات |
| `HASHIDS_ALT_SALT` | — | احتياطي تشفير/فك تشفير المعرّفات |

### 2.1 توليد المفاتيح

```bash
# يخرج 5 مفاتيح KEY=VALUE إلى stdout، يمكن إلحاقها مباشرة بـ .env
php scripts/gen_env_keys.php

# الكتابة مباشرة في .env: المفاتيح الموجودة لا تُستبدل، يُضاف الناقص فقط
php scripts/gen_env_keys.php --file=.env
```

> إذا كان أي مفتاح في .env ما زال placeholder `change-me`، احذف السطر أولًا ثم شغّل (الـ placeholder يُعتبر «موجودًا» ولن يُستبدل).

### 2.2 تدوير المفاتيح (encryptable)

```bash
bash scripts/rotate_keys.sh            # افتراضيًا يعمل على .env في الدليل الحالي
bash scripts/rotate_keys.sh /path/to/service/.env
```

السكربت يُكمل تلقائيًا: نسخ .env احتياطيًا ← توليد `ENCRYPTABLE_KEY` جديد ← إلحاق المفتاح القديم بـ `ENCRYPTION_PREVIOUS_KEYS` (مفصولة بفواصل، الأحدث تدويرًا أولًا) ← كتابة المفتاح الجديد. ثم يدويًا حسب التعليمات: أعد تشغيل الخدمة ← تحقق من فك التشفير ← احذف النسخ الاحتياطي بعد التأكيد.

**شرح `ENCRYPTION_PREVIOUS_KEYS`**: عند فك تشفير encryptable يُجرّب أولًا `ENCRYPTABLE_KEY` الحالي، وعند الفشل تُجرَّب المفاتيح التاريخية واحدًا تلو الآخر حسب ترتيب القائمة. لذلك **عند التدوير يجب إضافة المفتاح القديم إلى القائمة قبل تفعيل المفتاح الجديد**، وإلا لا يمكن فك تشفير البيانات القديمة بعد إعادة التشغيل (البيانات لا تضيع، ارجع بـ .env للاستعادة). القائمة تزداد ولا تنقص، وقبل حذف مفتاح تاريخي يجب التأكد من إتمام إعادة تشفير كل البيانات القديمة.

**لا ترحيل بيانات تلقائي**: بعد التدوير تبقى البيانات القديمة مشفرة بالمفتاح القديم وتُقرأ وتُكتب بشكل طبيعي. إذا أردت إعادة كتابة بيانات المخزون بالمفتاح الجديد، نفّذ مهمة ترحيل بيانات منفصلة (قراءة جدول بجدول ← كتابة تُطلق إعادة التشفير).

### 2.3 تحقق Fail-fast عند الإقلاع

هذه الإعدادات تُتحقق عند إقلاع الخدمة، والمفتاح **الناقص أو ما زال placeholder `change-me`** يلقي `RuntimeException` مباشرةً ويرفض الإقلاع (منعًا للانتشار بمفاتيح placeholder):

| الإعداد | المفتاح المُتحقق منه |
|---|---|
| `service/config/encryption.php` | `ENCRYPTION_KEY` |
| `service/config/encryptable.php`、`service/config/plugin/erikwang2013/encryptable/app.php` | `ENCRYPTABLE_KEY` |
| `service/config/jwt.php`、`service/config/plugin/erikwang2013/jwt/jwt.php` | `JWT_SECRET_KEY` |

مثال خطأ الإقلاع: `ENCRYPTABLE_KEY 未配置或仍为占位符，请在 .env 中配置 32 字节随机密钥`.

**قائمة العمليات اليومية**:

1. نشر بيئة جديدة: `cp .env.example .env` ← احذف أسطر placeholder `change-me` ← `php scripts/gen_env_keys.php --file=.env` ← أعد تشغيل الخدمة وتأكد من عدم وجود أخطاء مفاتيح.
2. التدوير الروتيني: وفق 2.2، مرة ربع سنويًا تكفي (لا فترة إلزامية، عند التسريب دَوِّر فورًا).
3. ملفات `.env.bak.*` الاحتياطية تحوي مفاتيح نصية، عاملها كبيانات القاعدة الاحتياطية (صلاحيات 600، تخزين خارج الموقع).

## 3. مراقبة الإنذار (Prometheus + Grafana)

التنسيق في `admin/docker-compose.yml` (أضيفت ثلاث خدمات prometheus / grafana / redis-exporter)، الإعدادات كلها في `admin/deploy/monitoring/`:

```bash
cd admin
docker compose up -d prometheus grafana redis-exporter
# Prometheus: http://host:9090   Grafana: http://host:3000
# أول تسجيل دخول Grafana: admin / ${GRAFANA_ADMIN_PASSWORD} (افتراضيًا change-me-grafana-password)
```

- **مصدر البيانات**: Grafana يهيئ مصدر بيانات Prometheus تلقائيًا عند الإقلاع (provisioning)، اللوحات تُنشأ في الواجهة.
- **قواعد الإنذار**: `deploy/monitoring/alerts.yml`، تغطي:
  - `AppDown` (التطبيق غير قابل للوصول، ما يعادل 5xx للموقع كله) — critical
  - `MysqlDown` / `RedisDown` (فشل فحص من جهة التطبيق) — critical
  - `ElasticsearchDown` (فشل جلب `/_prometheus/metrics` الأصلي لـ ES) + `ElasticsearchHealthYellow` (العنقود غير أخضر) — critical/warning
  - `QueueBacklog` (تراكم قائمة انتظار البحث scout `queues:scout_*` > 100 عنصرًا لمدة 10 دقائق) — warning
- **حقن كلمة مرور ES**: prometheus يقرأ `ELASTIC_PASSWORD` عبر compose `secrets` (يتطلب Docker Compose ≥ 2.24)، ملف الإعداد لا يكتب كلمة المرور؛ عند عدم الضبط يستخدم placeholder change-me، و401 عند جلب ES يُطلق ElasticsearchDown.
- **إعادة تحميل القواعد**: بعد تعديل alerts.yml نفّذ `curl -X POST localhost:9090/-/reload` (prometheus يحتاج `--web.enable-lifecycle`، إن لم يُضف افتراضيًا أعد تشغيل الحاوية).
- **تحقق محلي**: `bash scripts/verify_monitoring.sh` — يفحص صيغة YAML لقواعد الإنذار في طرفي admin/service، وcurl لنقطتي `/metrics` (admin:8787 / service:8788) لمخرجات المقاييس، وتحميل قواعد Prometheus (9090/9091)؛ عند عدم تشغيل التطبيق/Prometheus يعرض البند SKIP ويخرج بـ exit 0.

**الحالة**: طرفا admin و service كلاهما له نقطة `/metrics` (MetricsController، بلا مصادقة). وسيطة MetricsCollector تحسب التراكم الفعلي حسب `code="all"|"5xx"` (admin يخرج `open_admin_http_requests_total`، service يخرج `property_service_http_requests_total`)، وقاعدة `Http5xxRatio` في alerts.yml للطرفين (نسبة 5xx > 5% لمدة 10 دقائق) قابلة للتفعيل المباشر. **اختبار الإنذار الفعلي بانتظار النشر**: القواعد جاهزة لكن لم تُشغَّل للتحقق في بيئة نشر حقيقية (يعتمد على `verify_monitoring.sh` وإطلاق Prometheus).

## 4. تدوير السجلات

- **سجلات الحاويات**: كل الخدمات في compose مهيأة بـ `json-file` + `max-size 10m / max-file 3`، لا حاجة لمعالجة إضافية.
- **سجلات تطبيق المضيف** (`runtime/*.log`、`service/workerman.log`): استخدم `admin/deploy/logrotate/pmp-app`:

```bash
sudo cp admin/deploy/logrotate/pmp-app /etc/logrotate.d/pmp-app
# عدّل المسار في الملف حسب مسار النشر الفعلي ليفعُل؛ copytruncate يجعل webman يدوّر بلا إعادة تشغيل
sudo logrotate -d /etc/logrotate.d/pmp-app   # تشغيل تجريبي للفحص
```

افتراضيًا تدوير يومي، احتفاظ 30 يومًا، ضغط gzip.

## 5. فحص تحميل مبدئي بعد النشر

بعد اكتمال النشر استخدم k6 لفحص سلسلة تسجيل الدخول ووصول واجهات الأعمال الرئيسية (معدل منخفض، ليس اختبار أداء). السكربت: `scripts/loadtest/smoke.js` (افتراضيًا 2 VU و30s، تسجيل الدخول + dashboard، وكلاهما يدعم تجاوز متغيرات البيئة `BASE_URL`/`VUS`/`DURATION`/`TOKEN`).

### 5.1 فحص مبدئي محلي

```bash
cd /path/to/property-management-platform/scripts/loadtest

# فحص سلسلة تسجيل الدخول فقط (بلا token؛ 422 خطأ رمز تحقق/429 تحديد معدل كلاهما دفاع فعال، يُعتبر وصولًا)
k6 run -e BASE_URL=http://127.0.0.1:8790 smoke.js

# واجهات أعمال بمصادقة: على خادم النشر أصدر JWT لاختبار التحميل (يعتمد على admin/.env و vendor) ثم مرره
TOKEN=$(php mint-token.php)
k6 run -e BASE_URL=https://admin.example.com -e TOKEN="$TOKEN" smoke.js

# تزامن/مدة مخصصة
k6 run -e BASE_URL=https://admin.example.com -e TOKEN="$TOKEN" -e VUS=5 -e DURATION=60s smoke.js
```

الفحص الكامل (السكربتات الثلاثة login + dashboard + fee) ما زال عبر `bash scripts/loadtest/run.sh [BASE_URL] [VUS] [DURATION]`.

### 5.2 فحص مبدئي في CI (تشغيل يدوي GitHub Actions)

صفحة Actions في المستودع → **Loadtest Smoke** → **Run workflow**:

| المدخل | إلزامي | الوصف |
|---|---|---|
| `target_url` | نعم | عنوان البيئة المُختبرة، مثل `https://admin.example.com` |
| `duration` | لا | مدة الفحص، افتراضيًا `30s` |
| `token` | لا | JWT لاختبار التحميل؛ تركه فارغًا يفحص سلسلة تسجيل الدخول فقط |

الحصول على token (نفّذ في جذر المستودع على خادم النشر، يتطلب `admin/.env` و `admin/vendor/`):

```bash
php scripts/loadtest/mint-token.php
```

> ملاحظة: token هو JWT مخصص لاختبار التحميل (افتراضيًا حساب مدير erik)، سيظهر نصيًا في سجلات workflow، فاستخدم حسابًا مخصصًا للاختبار؛ إن تعذر كشفه في الإنتاج استخدم الفحص المحلي 5.1.
