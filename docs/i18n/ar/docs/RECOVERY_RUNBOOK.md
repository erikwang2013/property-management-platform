# دليل تمرين استعادة قاعدة البيانات (Recovery Runbook)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> ينطبق على: property-management-platform (طرف admin + طرف service، MySQL 8.0)
> يُقرأ مع القسم 1 من [OPS_RUNBOOK.md](OPS_RUNBOOK.md): توليد النسخ الاحتياطي وcrontab وRPO/RTO في OPS_RUNBOOK، وهذه الوثيقة تشرح فقط «كيف نستعيد وكيف نتحقق».

## 0. الهدف

- **هدف التمرين: إتمام تمرين استعادة كامل في 30 دقيقة** (استعادة + تحقق)، مرة واحدة ربع سنويًا على الأقل.
- في أي لحظة يمكن أخذ أحدث نسخة احتياطية والاستعادة وفق هذه الوثيقة إلى قاعدة فارغة أو إلى نقطة زمنية محددة.

الشروط المسبقة:

- ملف النسخ الاحتياطي متاح: `scripts/backup.sh` يعمل عبر cron (انظر OPS_RUNBOOK 1.2).
- بيئة هدف الاستعادة (جهاز تمرين أو جهاز إنتاج) متجانسة مع الإنتاج: نفس docker-compose، نفس إصدار MySQL 8.0.
- تأكيد قبل الاستعادة: `gzip -t ملف النسخ` ينجح؛ المساحة الحرة للقرص ≥ ضعف حجم النسخ الاحتياطي.

## 1. السيناريو أ: الاستعادة إلى قاعدة فارغة (الأكثر استخدامًا، السيناريو الافتراضي للتمرين)

الهدف: استيراد النسخ الاحتياطي إلى قاعدة فارغة جديدة تمامًا، والتحقق من قابلية استخدام البيانات.

```bash
cd /path/to/property-management-platform

# 1) اختر أحدث نسخة احتياطية
ls -lt backups/backup_*.sql.gz | head

# 2) فحص السلامة (إن لم ينجح اختر نسخة أقدم)
gzip -t backups/backup_20260816_020000.sql.gz && echo OK

# 3) تأكد أن حاوية الهدف تعمل
docker compose -f admin/docker-compose.yml ps mysql

# 4) أنشئ قاعدة فارغة (لاحقة _drill لاسم قاعدة التمرين، تجنبًا لاستبدال بيانات الإنتاج خطأً)
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot -e "CREATE DATABASE IF NOT EXISTS property_management_drill DEFAULT CHARACTER SET utf8mb4;"'

# 5) الاستيراد (-T يغلق TTY، لضمان عدم التفاعل؛ قياس فعلي نحو 1-5 دقائق)
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot --default-character-set=utf8mb4 property_management_drill' \
  < backups/backup_20260816_020000.sql.gz
```

> ملاحظة الاعتمادات: `MYSQL_PWD` يؤخذ من `DB_PASSWORD` في `admin/.env`؛ في الإنتاج يُمنع ظهوره كنص صريح في سجل shell، يُنصح باستخدام `--env-file admin/.env` أو حقن متغيرات البيئة. أمثلة هذا الدليل لقيم متفق عليها في بيئة التمرين.

## 2. السيناريو ب: الاستعادة إلى نقطة زمنية محددة (إعادة تشغيل binlog)

الشرط المسبق: MySQL 8 يفعّل binlog افتراضيًا (`log_bin=ON`)، والزيادات بعد لحظة النسخ كلها في binlog. فقدان البيانات ≤ آخر نسخة احتياطية + فترة الاحتفاظ بـ binlog (افتراضيًا `binlog_expire_logs_seconds=2592000`، 30 يومًا).

الفكرة: استعادة كاملة ← إيجاد نقطة بداية binlog ← إعادة تشغيل `mysqlbinlog` حتى النقطة الزمنية المستهدفة.

```bash
# 1) تأكد من تفعيل binlog واعرض ملفات السجل
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot -e "SHOW VARIABLES LIKE \"log_bin\"; SHOW BINARY LOGS;"'

# 2) استعادة كاملة (نفس الخطوتين 4-5 في السيناريو أ، إلى قاعدة فارغة)

# 3) إيجاد نقطة بداية binlog المقابلة للنسخ: الموقع المسجل داخل ملف النسخ (عند --master-data=2)
#    هذا السكربت لا يحمل --master-data، نقطة البداية تستخدم «لحظة بدء النسخ»، والخطأ ضمن مدة النسخ.
#    أعد تشغيل binlog حتى النقطة الزمنية المستهدفة (مثال: الاستعادة إلى 2026-08-16 10:30:00)
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysqlbinlog --stop-datetime="2026-08-16 10:30:00" /var/lib/mysql/binlog.000012 | mysql -uroot property_management_drill'
```

النقاط المهمة:

- binlog داخل الحاوية في المسار `/var/lib/mysql/binlog.0000NN`، طابقه مع مخرجات `SHOW BINARY LOGS`.
- أعد تشغيل فقط binlog «بعد لحظة بدء النسخ»؛ تحقق فورًا بعد الإعادة (انظر القسم 3)، وتأكد أن `max(updated_at)` مطابق للتوقع.
- استعادة عملية خاطئة بدقة الثواني: حدد أولًا جملة العملية الخاطئة `mysqlbinlog /var/lib/mysql/binlog.0000NN | grep -n "كلمة مفتاحية للعملية الخاطئة"`، ثم قرر `--stop-datetime` أو `--stop-position`.

## 3. التحقق من اتساق البيانات (إلزامي بعد الاستعادة)

| بند الفحص | الأمر | معيار النجاح |
|---|---|---|
| سلامة ملف النسخ | `gzip -t <نسخ>` | بلا أخطاء |
| عدد صفوف الجداول الرئيسية | `SELECT COUNT(*) FROM erik_admin_user;` | مطابق لعدد الصفوف المسجل قبل النسخ |
| عينة من جداول الأعمال | `SELECT COUNT(*) FROM erik_owner;`、`erik_tenant`、`erik_fee_bill`、`erik_repair_order` | ثلاثة جداول فأكثر بكميات معقولة (غير صفر ومطابقة لما قبل النسخ) |
| قابلية فك تشفير الحقول المشفرة | استعلام سجل يحتوي حقول encryptable (مثل هوية/هاتف `erik_owner`) | القيمة صحيحة، وسجلات التطبيق بلا أخطاء decrypt |
| فحص مبدئي للأعمال | تسجيل دخول + واجهة سحب قائمة مرة واحدة لكلٍّ | 200 / إرجاع طبيعي |

مثال سكربت العينة (بيئة التمرين):

```bash
docker compose -f admin/docker-compose.yml exec -T -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot property_management_drill -e "
    SELECT (SELECT COUNT(*) FROM erik_admin_user) AS users,
           (SELECT COUNT(*) FROM erik_owner) AS owners,
           (SELECT COUNT(*) FROM erik_tenant) AS tenants,
           (SELECT COUNT(*) FROM erik_fee_bill) AS fee_bills,
           (SELECT COUNT(*) FROM erik_repair_order) AS repair_orders;"'
```

> اتساق الصفوف: سجّل خط الأساس بنفس SQL قبل النسخ، وقارن بعد الاستعادة؛ في التمرين اكتب خط الأساس في سجل التمرين.

## 4. جدول زمني لتمرين 30 دقيقة

| الوقت | الإجراء | المسؤول |
|---|---|---|
| 0-5 دقائق | اختيار النسخ، `gzip -t`، إنشاء قاعدة فارغة، تسجيل خط الأساس للصفوف | التشغيل |
| 5-15 دقيقة | استعادة سيناريو أ والاستيراد | التشغيل |
| 15-25 دقيقة | تحقق اتساق القسم 3 + فحص مبدئي للأعمال | التشغيل + الأعمال |
| 25-30 دقيقة | تسجيل النتيجة، تنظيف قاعدة التمرين (`DROP DATABASE property_management_drill`)، تحديث RTO المقاس فعليًا في OPS_RUNBOOK 1.4 | التشغيل |

## 5. معالجة الفشل

| العرض | المعالجة |
|---|---|
| فشل `gzip -t` | النسخ تالف، خذ نسخًا أقدم، اقبل RPO أكبر، وافحص ما إذا كان cron النسخ الاحتياطي طبيعيًا |
| خطأ استيراد (مجموعة أحرف/صلاحيات) | تأكد أن `--default-character-set=utf8mb4` متوافق مع مجموعة أحرف القاعدة الفارغة؛ تأكد أن المستخدم لديه صلاحية إنشاء الجداول |
| الصفوف لا تطابق خط الأساس | أوقف التمرين فورًا، افحص إن استُوردت قاعدة/ملف خاطئ؛ في سيناريو استعادة الإنتاج تابع التحقيق وارجع بالتطبيق |
| البيانات ما زالت ناقصة بعد إعادة تشغيل binlog | افحص أن `--stop-datetime` ليس أبكر من لحظة بدء النسخ؛ تأكد أن الإعادة بدأت من أول binlog بعد النسخ |

## 6. قالب سجل التمرين

```text
التاريخ: 2026-08-16
هدف الاستعادة: قاعدة فارغة (سيناريو أ) / نقطة زمنية (سيناريو ب)
ملف النسخ: backups/backup_20260816_020000.sql.gz
خط الأساس للصفوف: erik_admin_user=1, erik_owner=42, erik_fee_bill=128
زمن الاستعادة: XX دقيقة    زمن التحقق: XX دقيقة    الإجمالي: XX دقيقة (الهدف ≤ 30)
النتيجة: ناجح / فاشل (مع سبب الفشل والمعالجة)
```
