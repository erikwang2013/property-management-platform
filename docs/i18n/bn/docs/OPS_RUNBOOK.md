# অপারেশন ম্যানুয়াল (OPS Runbook)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> প্রযোজ্য: property-management-platform (admin পাশ + service পাশ, PHP 8.3 webman)

## 1. ডেটাবেস ব্যাকআপ ও রিকভারি

admin পাশ ও service পাশ একই MySQL ইনস্ট্যান্স ও ডেটাবেস `management` শেয়ার করে, একবার ব্যাকআপ করলেই হয়। ইউনিফাইড এন্ট্রি:

| ডেটাবেস নাম | ব্যাকআপ স্ক্রিপ্ট | ব্যাখ্যা |
|---|---|---|
| `management` | `scripts/backup.sh` | `admin/.env` থেকে কানেকশন পড়ে (`--container=` দিয়ে কন্টেইনার নাম ওভাররাইড করা যায়), ডিফল্ট কন্টেইনারে mysqldump |

আউটপুট `backups/backup_YYYYMMDD_HHMMSS.sql.gz`, ডিফল্টে সাম্প্রতিক ৭ দিন সংরক্ষণ (`--keep-days=` দিয়ে সামঞ্জস্য)।

### 1.1 ফুল ব্যাকআপ

```bash
cd /path/to/property-management-platform
bash scripts/backup.sh
```

### 1.2 শিডিউলড টাস্ক (crontab)

```cron
# প্রতিদিন 02:00 ফুল ব্যাকআপ
0 2 * * * cd /path/to/property-management-platform && bash scripts/backup.sh >> /var/log/pmp-backup.log 2>&1
```

প্রোডাকশন পরামর্শ: ব্যাকআপ ডিরেক্টরি আলাদা ডিস্ক/দূরবর্তী স্টোরেজে মাউন্ট করুন, এবং নিয়মিত ব্যাকআপ ফাইলের অখণ্ডতা পরীক্ষা করুন (`gzip -t` যাচাই)।

### 1.3 রিকভারি ড্রিল প্রক্রিয়া (প্রতি ত্রৈমাসিকে অন্তত একবার)

1. সাম্প্রতিকতম ব্যাকআপ নির্বাচন: `ls -t backups/backup_*.sql.gz`
2. **আলাদা পরিবেশে** (বা অস্থায়ী ডেটাবেসে) রিকভারি সম্পাদন: বিস্তারিত দেখুন [RECOVERY_RUNBOOK.md](RECOVERY_RUNBOOK.md) দৃশ্য A (খালি ডেটাবেস রিকভারি) ও দৃশ্য B (টাইম পয়েন্ট রিকভারি)।
3. যাচাই:
   - সারি সংখ্যা তুলনা: `SELECT COUNT(*) FROM management_user;` ব্যাকআপের আগের রেকর্ডের সাথে মিলে
   - এনক্রিপ্টেড ফিল্ড স্বাভাবিকভাবে ডিক্রিপ্ট হয়: encryptable ফিল্ড বিশিষ্ট একটি রেকর্ড দেখুন, মান সঠিক, লগে decrypt এরে নেই
   - ব্যবসা স্মোক: লগইন, লিস্ট ইন্টারফেস টানা স্বাভাবিক
4. ড্রিলের সময় ও ফলাফল রেকর্ড করুন (RTO মূল্যায়নের জন্য)।

> সম্পূর্ণ ড্রিল ম্যানুয়াল (খালি ডেটাবেস রিকভারি / টাইম পয়েন্ট রিকভারি / কনসিস্টেন্সি যাচাই / ৩০ মিনিট ড্রিল টাইমটেবল) দেখুন [RECOVERY_RUNBOOK.md](RECOVERY_RUNBOOK.md)।

### 1.4 RPO / RTO ব্যাখ্যা

- **RPO (যতটুকু ডেটা হারানো যাবে)**: ব্যাকআপ ফ্রিকোয়েন্সি দ্বারা নির্ধারিত। দৈনিক ফুল ব্যাকআপ → RPO ≤ ২৪ ঘণ্টা, অর্থাৎ সর্বোচ্চ সাম্প্রতিক এক দিনের ডেটা হারাতে পারে। ছোট RPO চাইলে ব্যাকআপ ফ্রিকোয়েন্সি বাড়ান (যেমন দিনে ২ বার) বা binlog ইনক্রিমেন্টাল ব্যাকআপ চালু করুন।
- **RTO (রিকভারিতে প্রয়োজনীয় সময়)**: ডেটাবেসের আকার ও রিকভারি গতির উপর নির্ভর করে, লক্ষ্য ≤ ১ ঘণ্টা (রিকভারি + যাচাই + সার্ভিস রিস্টার্ট)। প্রতিটি ড্রিলের পরে বাস্তব পরিমাপ মান আপডেট করুন।
- রিকভারি ব্যর্থ জরুরি: প্রথমে অ্যাপ্লিকেশন কোড রোলব্যাক, তারপর সাম্প্রতিকতম ব্যবহারযোগ্য ব্যাকআপ দিয়ে রিট্রাই; ব্যাকআপ নষ্ট হলে আগের ব্যাকআপ ব্যবহার করুন এবং বড় RPO মেনে নিন।

## 2. কী ম্যানেজমেন্ট

প্রজেক্ট ৫টি কী-এর উপর নির্ভর করে, সব `.env`-এ (admin ও service আলাদা, একই সেট ভাগ করবেন না):

| ভেরিয়েবল | দৈর্ঘ্য | ব্যবহার |
|---|---|---|
| `ENCRYPTION_KEY` | ৩২ বাইট | API ট্রান্সমিশন এনক্রিপশন (config/encryption.php) |
| `ENCRYPTABLE_KEY` | ৩২ বাইট | ডেটাবেস সংবেদনশীল ফিল্ড এনক্রিপশন (encryptable প্লাগইন, **ENCRYPTION_KEY-এর সাথে ভাগ করবেন না**) |
| `JWT_SECRET_KEY` | ৬৪ বিটের বেশি | JWT সাইনিং |
| `HASHIDS_SALT` | — | ID এনক্রিপশন/ডিক্রিপশন |
| `HASHIDS_ALT_SALT` | — | ID এনক্রিপশন/ডিক্রিপশন ব্যাকআপ |

### 2.1 কী তৈরি

```bash
# stdout-এ ৫টি KEY=VALUE আউটপুট, সরাসরি .env-তে অ্যাপেন্ড করা যায়
php scripts/gen_env_keys.php

# সরাসরি .env-তে লেখা: বিদ্যমান কী ওভাররাইট হয় না, শুধু অনুপস্থিত যোগ হয়
php scripts/gen_env_keys.php --file=.env
```

> .env-এর কোনো কী এখনও `change-me` প্লেসহোল্ডার হলে, প্রথমে সেই লাইন মুছুন তারপর চালান (প্লেসহোল্ডারকে "ইতিমধ্যে বিদ্যমান" ধরা হয়, ওভাররাইট হবে না)।

### 2.2 কী রোটেশন (encryptable)

```bash
bash scripts/rotate_keys.sh            # ডিফল্ট বর্তমান ডিরেক্টরির .env-এ অপারেশন
bash scripts/rotate_keys.sh /path/to/service/.env
```

স্ক্রিপ্ট স্বয়ংক্রিয়ভাবে সম্পন্ন করে: .env ব্যাকআপ → নতুন `ENCRYPTABLE_KEY` তৈরি → পুরনো key `ENCRYPTION_PREVIOUS_KEYS`-এ অ্যাপেন্ড (কমা-বিভাজিত, সাম্প্রতিক রোটেশন আগে) → নতুন key লেখা। তারপর প্রম্পট অনুযায়ী ম্যানুয়ালি: সার্ভিস রিস্টার্ট → ডিক্রিপশন যাচাই → নিশ্চিত হলে ব্যাকআপ মুছুন।

**`ENCRYPTION_PREVIOUS_KEYS` ব্যাখ্যা**: encryptable ডিক্রিপ্ট করার সময় প্রথমে বর্তমান `ENCRYPTABLE_KEY` ব্যবহার করে, ব্যর্থ হলে তালিকার ক্রম অনুযায়ী একে একে ঐতিহাসিক key চেষ্টা করে। তাই **রোটেশনের সময় পুরনো key অবশ্যই নতুন key কার্যকর হওয়ার আগে এই তালিকায় যোগ করতে হবে**, অন্যথায় রিস্টার্টের পর পুরনো ডেটা ডিক্রিপ্ট হবে না (ডেটা হারাবে না, .env রোলব্যাক করলেই পুনরুদ্ধার)। তালিকা শুধু বাড়ে কমে না, ঐতিহাসিক key মুছার আগে সব পুরনো ডেটা পুনরায় এনক্রিপ্ট হয়েছে কিনা নিশ্চিত করতে হবে।

**স্বয়ংক্রিয় ডেটা মাইগ্রেশন করা হয় না**: রোটেশনের পর পুরনো ডেটা এখনও পুরনো key দিয়ে এনক্রিপ্টেড, স্বাভাবিকভাবে পড়া-লেখা যায়। নতুন key দিয়ে বিদ্যমান ডেটা পুনরায় লিখতে চাইলে আলাদাভাবে ডেটা মাইগ্রেশন টাস্ক চালান (প্রতি টেবিল পড়া → লেখা ট্রিগারে পুনরায় এনক্রিপশন)।

### 2.3 Fail-fast স্টার্টআপ যাচাই

নিচের কনফিগ সার্ভিস স্টার্টআপে যাচাই করা হয়, কী **অনুপস্থিত বা এখনও `change-me` প্লেসহোল্ডার** হলে সরাসরি `RuntimeException` ছুড়ে স্টার্ট অস্বীকার করে (প্লেসহোল্ডার কী নিয়ে লাইভ যাওয়া রোধ):

| কনফিগ | যাচাই করা কী |
|---|---|
| `service/config/encryption.php` | `ENCRYPTION_KEY` |
| `service/config/encryptable.php`, `service/config/plugin/erikwang2013/encryptable/app.php` | `ENCRYPTABLE_KEY` |
| `service/config/jwt.php`, `service/config/plugin/erikwang2013/jwt/jwt.php` | `JWT_SECRET_KEY` |

স্টার্টআপ এরে উদাহরণ: `ENCRYPTABLE_KEY 未配置或仍为占位符, 请在 .env 中配置 32 字节随机密钥`।

**দৈনন্দিন অপারেশন চেকলিস্ট**:

1. নতুন পরিবেশ ডিপ্লয়: `cp .env.example .env` → `change-me` প্লেসহোল্ডার লাইন মুছুন → `php scripts/gen_env_keys.php --file=.env` → সার্ভিস স্টার্ট করে কী এরে নেই নিশ্চিত করুন।
2. নিয়মিত রোটেশন: 2.2 অনুযায়ী, ত্রৈমাসিকে একবার যথেষ্ট (বাধ্যতামূলক সময়সীমা নেই, লিক হলে অবিলম্বে রোটেট)।
3. ব্যাকআপের `.env.bak.*` প্লেইনটেক্সট কী থাকে, ডেটাবেস ব্যাকআপের সমান গুরুত্ব দিয়ে রাখুন (পারমিশন ৬০০, দূরবর্তী স্টোরেজ)।

## 3. মনিটরিং অ্যালার্ট (Prometheus + Grafana)

অর্কেস্ট্রেটেড `admin/docker-compose.yml`-এ (নতুন prometheus / grafana / redis-exporter তিনটি সার্ভিস), কনফিগ সব `admin/deploy/monitoring/`-এ:

```bash
cd admin
docker compose up -d prometheus grafana redis-exporter
# Prometheus: http://host:9090   Grafana: http://host:3000
# প্রথমবার Grafana লগইন: admin / ${GRAFANA_ADMIN_PASSWORD} (ডিফল্ট change-me-grafana-password)
```

- **ডেটা সোর্স**: Grafana স্টার্টআপে স্বয়ংক্রিয়ভাবে Prometheus ডেটা সোর্স কনফিগার করে (provisioning), প্যানেল UI-তে তৈরি হয়।
- **অ্যালার্ট রুল**: `deploy/monitoring/alerts.yml`, কভার:
  - `AppDown` (অ্যাপ্লিকেশন অপ্রাপ্য, পুরো সাইট 5xx-এর সমতুল্য) — critical
  - `MysqlDown` / `RedisDown` (অ্যাপ্লিকেশন পাশ প্রোব ব্যর্থ) — critical
  - `ElasticsearchDown` (ES নেটিভ `/_prometheus/metrics` ফেচ ব্যর্থ) + `ElasticsearchHealthYellow` (ক্লাস্টার সবুজ নয়) — critical/warning
  - `QueueBacklog` (scout সার্চ কিউ `queues:scout_*` জমা >১০০টি টানা ১০ মিনিট) — warning
- **ES পাসওয়ার্ড ইনজেকশন**: prometheus compose `secrets` দিয়ে `ELASTIC_PASSWORD` পড়ে (Docker Compose ≥ 2.24 লাগবে), কনফিগ ফাইলে পাসওয়ার্ড হার্ডকোড করা হয় না; সেট না থাকলে change-me প্লেসহোল্ডার ব্যবহার হয়, ES ফেচ ৪০১ হলে ElasticsearchDown ট্রিগার হয়।
- **রুল রিলোড**: alerts.yml বদলানোর পর `curl -X POST localhost:9090/-/reload` (prometheus-এ `--web.enable-lifecycle` লাগাতে হবে, ডিফল্টে না থাকলে কন্টেইনার রিস্টার্ট)।
- **লোকাল যাচাই**: `bash scripts/verify_monitoring.sh` — admin/service দুই পাশের অ্যালার্ট রুল YAML সিনট্যাক্স, দুই প্রান্তের `/metrics` (admin:8787 / service:8788) মেট্রিক আউটপুট curl, Prometheus (9090/9091) রুল লোড যাচাই করে; অ্যাপ্লিকেশন/Prometheus চলছে না হলে সংশ্লিষ্ট আইটেম SKIP দেখিয়ে exit 0 করে।

**অবস্থা**: admin ও service দুই পাশেই `/metrics` এন্ডপয়েন্ট আছে (MetricsController, অথেনটিকেশন ছাড়া)। MetricsCollector মিডলওয়্যার `code="all"|"5xx"` অনুযায়ী বাস্তব কাউন্ট জমা করে (admin আউটপুট `open_admin_http_requests_total`, service আউটপুট `property_service_http_requests_total`), দুই পাশের alerts.yml-এর `Http5xxRatio` রুল (5xx অনুপাত >৫% টানা ১০ মিনিট) সরাসরি কার্যকর। **অ্যালার্ট বাস্তবে পরীক্ষা করা বাকি**: রুল প্রস্তুত কিন্তু এখনও বাস্তব ডিপ্লয়মেন্ট পরিবেশে ট্রিগার যাচাই হয়নি (`verify_monitoring.sh` ও Prometheus লাইভের উপর নির্ভরশীল)।

## 4. লগ রোটেশন

- **কন্টেইনার লগ**: compose-এর সব সার্ভিসে `json-file` + `max-size 10m / max-file 3` কনফিগার করা, অতিরিক্ত কিছু করার দরকার নেই।
- **হোস্ট মেশিন অ্যাপ্লিকেশন লগ** (`runtime/*.log`, `service/workerman.log`): `admin/deploy/logrotate/pmp-app` ব্যবহার:

```bash
sudo cp admin/deploy/logrotate/pmp-app /etc/logrotate.d/pmp-app
# বাস্তব ডিপ্লয়মেন্ট পাথ অনুযায়ী ফাইলের ভেতরের পাথ বদলানোর পর কার্যকর; copytruncate webman-কে রিস্টার্ট ছাড়াই রোটেট করতে দেয়
sudo logrotate -d /etc/logrotate.d/pmp-app   # ট্রায়াল রান চেক
```

ডিফল্ট দৈনিক রোটেশন, ৩০ দিন সংরক্ষণ, gzip কম্প্রেশন।

## 5. ডিপ্লয়ের পর লোড টেস্ট স্মোক

ডিপ্লয় সম্পন্নের পর k6 দিয়ে লগইন চেইন ও মূল ব্যবসা ইন্টারফেসের অ্যাক্সেসযোগ্যতা স্মোক যাচাই করুন (কম রেট, পারফরম্যান্স টেস্ট নয়)। স্ক্রিপ্ট: `scripts/loadtest/smoke.js` (ডিফল্ট ২ VU, ৩০s, লগইন + dashboard, সবই `BASE_URL`/`VUS`/`DURATION`/`TOKEN` এনভায়রনমেন্ট ভেরিয়েবল ওভাররাইড সমর্থন করে)।

### 5.1 লোকাল স্মোক

```bash
cd /path/to/property-management-platform/scripts/loadtest

# শুধু লগইন চেইন প্রোব (token লাগবে না; 422 ক্যাপচা ভুল/429 রেট লিমিট দুটোই ডিফেন্স কার্যকর, অ্যাক্সেসযোগ্য গণ্য)
k6 run -e BASE_URL=http://127.0.0.1:8790 smoke.js

# অথেনটিকেশনসহ ব্যবসা ইন্টারফেস: ডিপ্লয় সার্ভারে টেস্ট JWT সই (admin/.env ও vendor নির্ভর) তারপর পাস
TOKEN=$(php mint-token.php)
k6 run -e BASE_URL=https://admin.example.com -e TOKEN="$TOKEN" smoke.js

# কাস্টম কনকারেন্সি/সময়
k6 run -e BASE_URL=https://admin.example.com -e TOKEN="$TOKEN" -e VUS=5 -e DURATION=60s smoke.js
```

ফুল লোড টেস্ট (login + dashboard + fee তিন স্ক্রিপ্ট) এখনও `bash scripts/loadtest/run.sh [BASE_URL] [VUS] [DURATION]` ব্যবহার।

### 5.2 CI স্মোক (GitHub Actions ম্যানুয়াল ট্রিগার)

রিপোজিটরি Actions পেজ → **Loadtest Smoke** → **Run workflow**:

| ইনপুট | বাধ্যতামূলক | ব্যাখ্যা |
|---|---|---|
| `target_url` | হ্যাঁ | পরীক্ষার পরিবেশের ঠিকানা, যেমন `https://admin.example.com` |
| `duration` | না | স্মোক সময়, ডিফল্ট `30s` |
| `token` | না | টেস্ট JWT; খালি রাখলে শুধু লগইন চেইন প্রোব |

token পাওয়া (ডিপ্লয় সার্ভারে রিপোজিটরি রুটে, `admin/.env` ও `admin/vendor/` লাগবে):

```bash
php scripts/loadtest/mint-token.php
```

> লক্ষ্য: token টেস্ট-বিশেষ JWT (ডিফল্ট erik অ্যাডমিন অ্যাকাউন্ট), workflow লগে প্লেইনটেক্সটে দেখা যাবে, অনুগ্রহ করে টেস্ট-বিশেষ অ্যাকাউন্ট দিয়ে সই করুন; প্রোডাকশনে প্রকাশ করা অসুবিধাজনক হলে 5.1 লোকাল স্মোক ব্যবহার করুন।
