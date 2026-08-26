# ডেটাবেস রিকভারি ড্রিল ম্যানুয়াল (Recovery Runbook)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> প্রযোজ্য: property-management-platform (admin পাশ + service পাশ, MySQL 8.0)
> [OPS_RUNBOOK.md](OPS_RUNBOOK.md) এর ১ম অনুচ্ছেদের সাথে মিলিয়ে পড়ুন: ব্যাকআপ তৈরি, crontab, RPO/RTO দেখুন OPS_RUNBOOK-এ, এই ডকুমেন্ট শুধু "কীভাবে রিকভারি, কীভাবে যাচাই" নিয়ে।

## 0. লক্ষ্য

- **ড্রিল লক্ষ্য: ৩০ মিনিটে একটি সম্পূর্ণ রিকভারি ড্রিল সম্পন্ন** (রিকভারি + যাচাই), প্রতি ত্রৈমাসিকে অন্তত একবার।
- যেকোনো মুহূর্তে সাম্প্রতিকতম ব্যাকআপ নিয়ে, এই ডকুমেন্ট অনুযায়ী খালি ডেটাবেস বা নির্দিষ্ট টাইম পয়েন্টে রিকভারি করা যায়।

পূর্বশর্ত:

- ব্যাকআপ ফাইল ব্যবহারযোগ্য: `scripts/backup.sh` cron অনুযায়ী চলছে (দেখুন OPS_RUNBOOK 1.2)।
- রিকভারি টার্গেট পরিবেশ (ড্রিল মেশিন বা প্রোডাকশন মেশিন) প্রোডাকশনের সাথে সমগঠন: একই docker-compose, একই ভার্সন MySQL 8.0।
- রিকভারির আগে নিশ্চিত: `gzip -t 备份文件` পাস; ডিস্ক অবশিষ্ট স্থান ≥ ব্যাকআপ ভলিউমের ২ গুণ।

## 1. দৃশ্য A: খালি ডেটাবেসে রিকভারি (সবচেয়ে সাধারণ, ড্রিলের ডিফল্ট দৃশ্য)

লক্ষ্য: ব্যাকআপ একটি সম্পূর্ণ নতুন খালি ডেটাবেসে ইমপোর্ট, ডেটা ব্যবহারযোগ্যতা যাচাই।

```bash
cd /path/to/property-management-platform

# 1) সাম্প্রতিকতম ব্যাকআপ নির্বাচন
ls -lt backups/backup_*.sql.gz | head

# 2) অখণ্ডতা পরীক্ষা (পাস না করলে আগের ব্যাকআপ বেছে নিন)
gzip -t backups/backup_20260816_020000.sql.gz && echo OK

# 3) টার্গেট কন্টেইনার চলছে কিনা নিশ্চিত
docker compose -f admin/docker-compose.yml ps mysql

# 4) খালি ডেটাবেস তৈরি (ড্রিল ডেটাবেসের নামে _drill সাফিক্স, প্রোডাকশন ডেটা ভুলভাবে ওভাররাইট এড়াতে)
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot -e "CREATE DATABASE IF NOT EXISTS property_management_drill DEFAULT CHARACTER SET utf8mb4;"'

# 5) ইমপোর্ট (-T TTY বন্ধ, নন-ইন্টারঅ্যাক্টিভ নিশ্চিত; বাস্তবে প্রায় ১-৫ মিনিট)
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot --default-character-set=utf8mb4 property_management_drill' \
  < backups/backup_20260816_020000.sql.gz
```

> ক্রেডেনশিয়াল নোট: `MYSQL_PWD` নেওয়া হয় `admin/.env`-এর `DB_PASSWORD`; প্রোডাকশনে shell হিস্টোরিতে প্লেইনটেক্সট নিষিদ্ধ, `--env-file admin/.env` বা এনভায়রনমেন্ট ভেরিয়েবল ইনজেকশন ব্যবহারের পরামর্শ। এই ম্যানুয়ালের উদাহরণ ড্রিল পরিবেশের সম্মত মান।

## 2. দৃশ্য B: নির্দিষ্ট টাইম পয়েন্টে রিকভারি (binlog রিপ্লে)

পূর্বশর্ত: MySQL 8 ডিফল্টভাবে binlog চালু (`log_bin=ON`), ব্যাকআপ মুহূর্তের পরে সব ইনক্রিমেন্ট binlog-এ থাকে। ডেটা ক্ষতি ≤ সাম্প্রতিক ব্যাকআপ + binlog সংরক্ষণকাল (ডিফল্ট `binlog_expire_logs_seconds=2592000`, ৩০ দিন)।

ধারণা: ফুল রিকভারি → binlog শুরুর পয়েন্ট খুঁজুন → `mysqlbinlog` দিয়ে টার্গেট টাইম পয়েন্টে রিপ্লে।

```bash
# 1) binlog চালু আছে নিশ্চিত, লগ ফাইল তালিকাভুক্ত করুন
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot -e "SHOW VARIABLES LIKE \"log_bin\"; SHOW BINARY LOGS;"'

# 2) ফুল রিকভারি (দৃশ্য A-এর ৪-৫ ধাপের মতো, খালি ডেটাবেসে রিকভারি)

# 3) ব্যাকআপের সাথে মিলে যাওয়া binlog শুরুর পয়েন্ট খুঁজুন: ব্যাকআপ ফাইলে রেকর্ড করা পজিশন (--master-data=2 হলে)
#    এই স্ক্রিপ্টে --master-data নেই, শুরুর পয়েন্ট "ব্যাকআপ শুরু হওয়ার সময়", ত্রুটি ব্যাকআপ সময়ের মধ্যে।
#    binlog টার্গেট টাইম পয়েন্টে রিপ্লে (উদাহরণ: 2026-08-16 10:30:00 এ রিকভারি)
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysqlbinlog --stop-datetime="2026-08-16 10:30:00" /var/lib/mysql/binlog.000012 | mysql -uroot property_management_drill'
```

মূল পয়েন্ট:

- binlog কন্টেইনারে পাথ `/var/lib/mysql/binlog.0000NN`, `SHOW BINARY LOGS` আউটপুট থেকে মিলিয়ে নিন।
- শুধু "ব্যাকআপ শুরু হওয়ার সময়ের পরে" binlog রিপ্লে; রিপ্লের পর অবিলম্বে যাচাই করুন (৩য় অনুচ্ছেদ দেখুন), `max(updated_at)` প্রত্যাশা অনুযায়ী আছে নিশ্চিত।
- সেকেন্ড-নির্ভুল ভুল অপারেশন রিকভারি: প্রথমে ভুল অপারেশন স্টেটমেন্ট খুঁজুন `mysqlbinlog /var/lib/mysql/binlog.0000NN | grep -n "误操作关键字"`, তারপর `--stop-datetime` বা `--stop-position` ঠিক করুন।

## 3. ডেটা কনসিস্টেন্সি যাচাই (রিকভারির পরে অবশ্যই)

| পরীক্ষা আইটেম | কমান্ড | পাসের মানদণ্ড |
|---|---|---|
| ব্যাকআপ ফাইল অখণ্ডতা | `gzip -t <ব্যাকআপ>` | কোনো এরে নেই |
| মূল টেবিল সারি সংখ্যা | `SELECT COUNT(*) FROM erik_admin_user;` | ব্যাকআপের আগের রেকর্ডের সারি সংখ্যার সাথে মেলে |
| ব্যবসা টেবিল নমুনা | `SELECT COUNT(*) FROM erik_owner;`, `erik_tenant`, `erik_fee_bill`, `erik_repair_order` | তিনটির বেশি মাত্রা যুক্তিসঙ্গত (অ-শূন্য ও ব্যাকআপের আগের সাথে মেলে) |
| এনক্রিপ্টেড ফিল্ড ডিক্রিপ্টযোগ্য | encryptable ফিল্ড বিশিষ্ট রেকর্ড দেখুন (যেমন `erik_owner`-এর আইডি কার্ড/মোবাইল) | মান সঠিক, অ্যাপ্লিকেশন লগে decrypt এরে নেই |
| ব্যবসা স্মোক | লগইন, লিস্ট ইন্টারফেস প্রতিটি ১ বার | 200 / স্বাভাবিক রিটার্ন |

নমুনা চেক স্ক্রিপ্ট (ড্রিল পরিবেশ):

```bash
docker compose -f admin/docker-compose.yml exec -T -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot property_management_drill -e "
    SELECT (SELECT COUNT(*) FROM erik_admin_user) AS users,
           (SELECT COUNT(*) FROM erik_owner) AS owners,
           (SELECT COUNT(*) FROM erik_tenant) AS tenants,
           (SELECT COUNT(*) FROM erik_fee_bill) AS fee_bills,
           (SELECT COUNT(*) FROM erik_repair_order) AS repair_orders;"'
```

> সারি সংখ্যা কনসিস্টেন্সি: ব্যাকআপের আগে একই SQL দিয়ে বেসলাইন রেকর্ড করুন, রিকভারির পরে তুলনা; ড্রিলের সময় বেসলাইন ড্রিল রেকর্ডে লিখুন।

## 4. ৩০ মিনিট ড্রিল টাইমটেবল

| সময় | কাজ | দায়িত্ব |
|---|---|---|
| 0-5 min | ব্যাকআপ নির্বাচন, `gzip -t`, খালি ডেটাবেস তৈরি, বেসলাইন সারি সংখ্যা রেকর্ড | অপারেশন |
| 5-15 min | দৃশ্য A রিকভারি ইমপোর্ট | অপারেশন |
| 15-25 min | ৩য় অনুচ্ছেদ কনসিস্টেন্সি যাচাই + ব্যবসা স্মোক | অপারেশন + ব্যবসা |
| 25-30 min | ফলাফল রেকর্ড, ড্রিল ডেটাবেস পরিষ্কার (`DROP DATABASE property_management_drill`), OPS_RUNBOOK 1.4 বাস্তব RTO আপডেট | অপারেশন |

## 5. ব্যর্থতা হ্যান্ডলিং

| লক্ষণ | হ্যান্ডলিং |
|---|---|
| `gzip -t` ব্যর্থ | ব্যাকআপ নষ্ট, আগের ব্যাকআপে বদলান, বড় RPO মেনে নিন, এবং ব্যাকআপ cron স্বাভাবিক আছে কিনা পরীক্ষা করুন |
| ইমপোর্ট এরে (ক্যারেক্টার সেট/পারমিশন) | `--default-character-set=utf8mb4` ও খালি ডেটাবেসের ক্যারেক্টার সেট মিল আছে নিশ্চিত; ব্যবহারকারীর টেবিল তৈরি পারমিশন আছে নিশ্চিত |
| সারি সংখ্যা বেসলাইনের সাথে মেলে না | অবিলম্বে ড্রিল বন্ধ, ভুল ডেটাবেস/ভুল ফাইল ইমপোর্ট হয়েছে কিনা পরীক্ষা; প্রোডাকশন রিকভারি দৃশ্যে আরও তদন্ত করে অ্যাপ্লিকেশন রোলব্যাক |
| binlog রিপ্লের পরও ডেটা ঘাটতি | `--stop-datetime` ব্যাকআপ শুরুর সময়ের পরে কিনা পরীক্ষা; রিপ্লে ব্যাকআপের পরের প্রথম binlog থেকে শুরু হয়েছে নিশ্চিত |

## 6. ড্রিল রেকর্ড টেমপ্লেট

```text
তারিখ: 2026-08-16
রিকভারি টার্গেট: খালি ডেটাবেস (দৃশ্য A) / টাইম পয়েন্ট (দৃশ্য B)
ব্যাকআপ ফাইল: backups/backup_20260816_020000.sql.gz
বেসলাইন সারি সংখ্যা: erik_admin_user=1, erik_owner=42, erik_fee_bill=128
রিকভারি সময়: XX মিনিট    যাচাই সময়: XX মিনিট    মোট: XX মিনিট (লক্ষ্য ≤ ৩০)
ফলাফল: পাস / ব্যর্থ (ব্যর্থতার কারণ ও হ্যান্ডলিং সহ)
```
