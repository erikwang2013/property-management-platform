# संचालन मैनुअल (OPS Runbook)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> लागू: property-management-platform (admin एंड + service एंड, PHP 8.3 webman)

## 1. डेटाबेस बैकअप और पुनर्स्थापना

admin एंड और service एंड समान MySQL इंस्टेंस और डेटाबेस `management` साझा करते हैं, एक बार बैकअप पर्याप्त है। एकीकृत प्रवेश:

| डेटाबेस नाम | बैकअप स्क्रिप्ट | विवरण |
|---|---|---|
| `management` | `scripts/backup.sh` | `admin/.env` से कनेक्शन पढ़ता है (`--container=` से कंटेनर नाम ओवरराइड कर सकते हैं), डिफ़ॉल्ट कंटेनर के भीतर mysqldump |

आउटपुट `backups/backup_YYYYMMDD_HHMMSS.sql.gz`, डिफ़ॉल्ट रूप से हाल के 7 दिन रखता है (`--keep-days=` समायोज्य)।

### 1.1 पूर्ण बैकअप

```bash
cd /path/to/property-management-platform
bash scripts/backup.sh
```

### 1.2 नियत कार्य (crontab)

```cron
# 每天 02:00 全量备份
0 2 * * * cd /path/to/property-management-platform && bash scripts/backup.sh >> /var/log/pmp-backup.log 2>&1
```

प्रोडक्शन सुझाव: बैकअप डायरेक्टरी को स्वतंत्र डिस्क/दूरस्थ स्टोरेज पर माउंट करें, और नियमित रूप से बैकअप फ़ाइल पूर्णता की स्पॉट जांच करें (`gzip -t` सत्यापन)।

### 1.3 पुनर्स्थापना अभ्यास प्रवाह (हर तिमाही कम से कम एक बार)

1. हाल की बैकअप चुनें: `ls -t backups/backup_*.sql.gz`
2. **स्वतंत्र वातावरण** (या अस्थायी डेटाबेस) में पुनर्स्थापना करें: विवरण [RECOVERY_RUNBOOK.md](RECOVERY_RUNBOOK.md) परिदृश्य A (खाली डेटाबेस पुनर्स्थापना) और परिदृश्य B (समय बिंदु पुनर्स्थापना) देखें।
3. सत्यापन:
   - पंक्ति संख्या तुलना: `SELECT COUNT(*) FROM management_user;` बैकअप से पहले के रिकॉर्ड से मेल खाती है
   - एन्क्रिप्टेड फ़ील्ड सामान्य रूप से डिक्रिप्ट होती है: encryptable फ़ील्ड वाला एक रिकॉर्ड देखें, मान सही, लॉग में decrypt त्रुटि नहीं
   - व्यवसाय स्मोक: लॉगिन, सूची इंटरफ़ेस सामान्य
4. अभ्यास समय और परिणाम रिकॉर्ड करें (RTO मूल्यांकन के लिए)।

> पूर्ण अभ्यास मैनुअल (खाली डेटाबेस पुनर्स्थापना / समय बिंदु पुनर्स्थापना / स्थिरता सत्यापन / 30 मिनट अभ्यास समय सारणी) [RECOVERY_RUNBOOK.md](RECOVERY_RUNBOOK.md) में देखें।

### 1.4 RPO / RTO विवरण

- **RPO (डेटा हानि सीमा)**: बैकअप आवृत्ति से निर्धारित। दैनिक पूर्ण बैकअप → RPO ≤ 24 घंटे, अर्थात अधिकतम पिछले एक दिन का डेटा खो सकता है। छोटा RPO चाहिए तो बैकअप आवृत्ति बढ़ाएं (जैसे दिन में 2 बार) या binlog इंक्रीमेंटल बैकअप सक्षम करें।
- **RTO (पुनर्स्थापना समय)**: डेटाबेस आकार और पुनर्स्थापना गति पर निर्भर, लक्ष्य ≤ 1 घंटा (पुनर्स्थापना + सत्यापन + सेवा पुनरारंभ)। हर अभ्यास के बाद वास्तविक माप मान अपडेट करें।
- पुनर्स्थापना विफलता आपातकाल: पहले एप्लिकेशन कोड रोलबैक करें, फिर हाल के उपलब्ध बैकअप से पुनः प्रयास करें; बैकअप क्षतिग्रस्त हो तो पुराना बैकअप उपयोग करें और बड़ा RPO स्वीकारें।

## 2. कुंजी प्रबंधन

प्रोजेक्ट 5 कुंजियों पर निर्भर है, सभी `.env` में (admin और service अलग-अलग स्वतंत्र, एक ही सेट साझा न करें):

| वेरिएबल | लंबाई | उपयोग |
|---|---|---|
| `ENCRYPTION_KEY` | 32 बाइट | API ट्रांसमिशन एन्क्रिप्शन (config/encryption.php) |
| `ENCRYPTABLE_KEY` | 32 बाइट | डेटाबेस संवेदनशील फ़ील्ड एन्क्रिप्शन (encryptable प्लगइन, **ENCRYPTION_KEY के साथ साझा न करें**) |
| `JWT_SECRET_KEY` | 64+ अक्षर | JWT हस्ताक्षर |
| `HASHIDS_SALT` | — | ID एन्क्रिप्शन/डिक्रिप्शन |
| `HASHIDS_ALT_SALT` | — | ID एन्क्रिप्शन/डिक्रिप्शन बैकअप |

### 2.1 कुंजी जनरेशन

```bash
# 5 KEY=VALUE stdout पर आउटपुट, सीधे .env में जोड़ सकते हैं
php scripts/gen_env_keys.php

# सीधे .env में लिखें: मौजूदा कुंजी ओवरराइट नहीं, केवल अनुपलब्ध जोड़े
php scripts/gen_env_keys.php --file=.env
```

> यदि .env में कोई कुंजी अभी भी `change-me` प्लेसहोल्डर है, तो पहले उस पंक्ति को हटाकर फिर चलाएं (प्लेसहोल्डर "मौजूदा" माना जाता है, ओवरराइट नहीं होगा)।

### 2.2 कुंजी रोटेशन (encryptable)

```bash
bash scripts/rotate_keys.sh            # डिफ़ॉल्ट रूप से वर्तमान डायरेक्टरी का .env
bash scripts/rotate_keys.sh /path/to/service/.env
```

स्क्रिप्ट स्वतः: .env बैकअप → नया `ENCRYPTABLE_KEY` जनरेट → पुरानी key `ENCRYPTION_PREVIOUS_KEYS` में जोड़ें (कॉमा से अलग, हाल की रोटेशन सबसे आगे) → नई key लिखें। फिर संकेतों के अनुसार मैन्युअल: सेवा पुनरारंभ → डिक्रिप्शन सत्यापन → पुष्टि के बाद बैकअप हटाएं।

**`ENCRYPTION_PREVIOUS_KEYS` विवरण**: encryptable डिक्रिप्ट करते समय पहले वर्तमान `ENCRYPTABLE_KEY` प्रयास करता है, विफल होने पर सूची क्रम से एक-एक करके पुरानी key प्रयास करता है। इसलिए **रोटेशन के समय पुरानी key को नई key प्रभावी होने से पहले सूची में जोड़ना चाहिए**, अन्यथा पुनरारंभ के बाद पुराना डेटा डिक्रिप्ट नहीं हो सकता (डेटा नहीं खोएगा, .env रोलबैक करें तो ठीक हो जाएगा)। सूची केवल बढ़ती है घटती नहीं, पुरानी key हटाने से पहले पुष्टि करें कि सभी पुराना डेटा पुनः एन्क्रिप्ट हो चुका है।

**स्वचालित डेटा माइग्रेशन नहीं करता**: रोटेशन के बाद पुराना डेटा अभी भी पुरानी key से एन्क्रिप्टेड, सामान्य रूप से पढ़ा-लिखा जा सकता है। नई key से मौजूदा डेटा दोबारा लिखना हो तो अलग से डेटा माइग्रेशन कार्य चलाएं (टेबल-दर-टेबल पढ़ें → लिखने पर पुनः एन्क्रिप्शन ट्रिगर)।

### 2.3 Fail-fast प्रारंभ सत्यापन

निम्न कॉन्फ़िग सेवा प्रारंभ के समय सत्यापित होते हैं, कुंजी **अनुपलब्ध या अभी भी `change-me` प्लेसहोल्डर** होने पर सीधे `RuntimeException` फेंककर प्रारंभ अस्वीकार कर देते हैं (प्लेसहोल्डर कुंजी के साथ लाइव जाने से रोकने के लिए):

| कॉन्फ़िग | सत्यापित कुंजी |
|---|---|
| `service/config/encryption.php` | `ENCRYPTION_KEY` |
| `service/config/encryptable.php`、`service/config/plugin/erikwang2013/encryptable/app.php` | `ENCRYPTABLE_KEY` |
| `service/config/jwt.php`、`service/config/plugin/erikwang2013/jwt/jwt.php` | `JWT_SECRET_KEY` |

प्रारंभ त्रुटि उदाहरण: `ENCRYPTABLE_KEY 未配置或仍为占位符，请在 .env 中配置 32 字节随机密钥`।

**दैनिक संचालन चेकलिस्ट**:

1. नया वातावरण तैनाती: `cp .env.example .env` → `change-me` प्लेसहोल्डर पंक्तियां हटाएं → `php scripts/gen_env_keys.php --file=.env` → सेवा प्रारंभ करके पुष्टि करें कि कुंजी त्रुटि नहीं।
2. नियमित रोटेशन: 2.2 के अनुसार, तिमाही एक बार पर्याप्त (कोई अनिवार्य अवधि नहीं, लीक होने पर तुरंत रोटेट करें)।
3. बैकअप `.env.bak.*` में प्लेनटेक्स्ट कुंजियां होती हैं, डेटाबेस बैकअप के बराबर मानें (अनुमति 600, दूरस्थ स्थान पर रखें)।

## 3. मॉनिटरिंग अलर्ट (Prometheus + Grafana)

`admin/docker-compose.yml` में ऑर्केस्ट्रेटेड (prometheus / grafana / redis-exporter तीन नई सेवाएं), कॉन्फ़िग सभी `admin/deploy/monitoring/` में:

```bash
cd admin
docker compose up -d prometheus grafana redis-exporter
# Prometheus: http://host:9090   Grafana: http://host:3000
# पहली बार Grafana लॉगिन: admin / ${GRAFANA_ADMIN_PASSWORD}（डिफ़ॉल्ट change-me-grafana-password）
```

- **डेटा स्रोत**: Grafana प्रारंभ के समय स्वतः Prometheus डेटा स्रोत कॉन्फ़िगर करता है (provisioning), पैनल UI में बनाए जाते हैं।
- **अलर्ट नियम**: `deploy/monitoring/alerts.yml`, कवरेज:
  - `AppDown` (एप्लिकेशन अनुपलब्ध, पूरे साइट के 5xx के बराबर) — critical
  - `MysqlDown` / `RedisDown` (एप्लिकेशन साइड प्रोब विफल) — critical
  - `ElasticsearchDown` (ES नेटिव `/_prometheus/metrics` स्क्रेप विफल) + `ElasticsearchHealthYellow` (क्लस्टर ग्रीन नहीं) — critical/warning
  - `QueueBacklog` (scout सर्च कतार `queues:scout_*` >100 आइटम जमा 10 मिनट तक) — warning
- **ES पासवर्ड इंजेक्शन**: prometheus compose `secrets` से `ELASTIC_PASSWORD` पढ़ता है (Docker Compose ≥ 2.24 आवश्यक), कॉन्फ़िग फ़ाइल में पासवर्ड हार्डकोड नहीं; सेट न होने पर change-me प्लेसहोल्डर उपयोग, ES स्क्रेप 401 पर ElasticsearchDown ट्रिगर होगा।
- **नियम रीलोड**: alerts.yml बदलने के बाद `curl -X POST localhost:9090/-/reload` (prometheus में `--web.enable-lifecycle` जोड़ना होगा, डिफ़ॉल्ट नहीं है तो कंटेनर पुनरारंभ करें)।
- **स्थानीय सत्यापन**: `bash scripts/verify_monitoring.sh` — admin/service दोनों ओर अलर्ट नियम YAML सिंटैक्स जांच, दोनों ओर `/metrics` (admin:8787 / service:8788) मेट्रिक आउटपुट curl, Prometheus (9090/9091) नियम लोड; एप्लिकेशन/Prometheus चल नहीं रहा तो संबंधित आइटम SKIP दिखाकर exit 0।

**स्थिति**: admin और service दोनों में `/metrics` एंडपॉइंट है (MetricsController, बिना प्रमाणीकरण)। MetricsCollector मिडलवेयर `code="all"|"5xx"` के अनुसार वास्तविक संचयी गणना करता है (admin आउटपुट `open_admin_http_requests_total`, service आउटपुट `property_service_http_requests_total`), दोनों ओर alerts.yml की `Http5xxRatio` नियम (5xx अनुपात >5% 10 मिनट तक) सीधे प्रभावी हो सकती है। **अलर्ट वास्तविक परीक्षण तैनाती पर लंबित**: नियम तैयार है लेकिन अभी तक वास्तविक तैनाती वातावरण में ट्रिगर सत्यापन नहीं हुआ (`verify_monitoring.sh` और Prometheus ऑनलाइन पर निर्भर)।

## 4. लॉग रोटेशन

- **कंटेनर लॉग**: compose में सभी सेवाओं में `json-file` + `max-size 10m / max-file 3` कॉन्फ़िग है, अतिरिक्त प्रसंस्करण आवश्यक नहीं।
- **होस्ट एप्लिकेशन लॉग** (`runtime/*.log`、`service/workerman.log`): `admin/deploy/logrotate/pmp-app` उपयोग:

```bash
sudo cp admin/deploy/logrotate/pmp-app /etc/logrotate.d/pmp-app
# वास्तविक तैनाती पथ के अनुसार फ़ाइल में पथ संशोधित करें; copytruncate से webman बिना पुनरारंभ रोटेट होता है
sudo logrotate -d /etc/logrotate.d/pmp-app   # 试运行检查
```

डिफ़ॉल्ट दैनिक रोटेशन, 30 दिन रखता है, gzip कंप्रेशन।

## 5. तैनाती के बाद स्मोक टेस्ट

तैनाती पूर्ण होने के बाद k6 से लॉगिन चेन और मुख्य व्यवसाय इंटरफ़ेस पहुंच सत्यापित करें (कम रेट, प्रदर्शन परीक्षण नहीं)। स्क्रिप्ट: `scripts/loadtest/smoke.js` (डिफ़ॉल्ट 2 VU、30s, लॉगिन + dashboard, सभी `BASE_URL`/`VUS`/`DURATION`/`TOKEN` पर्यावरण वेरिएबल से ओवरराइड समर्थित)।

### 5.1 स्थानीय स्मोक

```bash
cd /path/to/property-management-platform/scripts/loadtest

# केवल लॉगिन चेन जांच (token आवश्यक नहीं; 422 कैप्चा गलत/429 रेट लिमिट दोनों रक्षा प्रभावी, पहुंच मानी जाती है)
k6 run -e BASE_URL=http://127.0.0.1:8790 smoke.js

# प्रमाणीकरण व्यवसाय इंटरफ़ेस सहित: तैनाती सर्वर पर परीक्षण JWT जारी करें (admin/.env और vendor पर निर्भर) फिर पास करें
TOKEN=$(php mint-token.php)
k6 run -e BASE_URL=https://admin.example.com -e TOKEN="$TOKEN" smoke.js

# कस्टम कॉन्करेंसी/अवधि
k6 run -e BASE_URL=https://admin.example.com -e TOKEN="$TOKEN" -e VUS=5 -e DURATION=60s smoke.js
```

पूर्ण परीक्षण (login + dashboard + fee तीन स्क्रिप्ट) फिर भी `bash scripts/loadtest/run.sh [BASE_URL] [VUS] [DURATION]` उपयोग।

### 5.2 CI स्मोक (GitHub Actions मैन्युअल ट्रिगर)

रिपॉजिटरी Actions पेज → **Loadtest Smoke** → **Run workflow**:

| इनपुट | आवश्यक | विवरण |
|---|---|---|
| `target_url` | हां | परीक्षण वातावरण पता, जैसे `https://admin.example.com` |
| `duration` | नहीं | स्मोक अवधि, डिफ़ॉल्ट `30s` |
| `token` | नहीं | परीक्षण JWT; खाली छोड़ने पर केवल लॉगिन चेन जांच |

token प्राप्त करना (तैनाती सर्वर रिपॉजिटरी रूट में चलाएं, `admin/.env` और `admin/vendor/` आवश्यक):

```bash
php scripts/loadtest/mint-token.php
```

> ध्यान दें: token परीक्षण-विशेष JWT है (डिफ़ॉल्ट erik एडमिन खाता), workflow लॉग में प्लेनटेक्स्ट दिखेगा, कृपया परीक्षण-विशेष खाते से जारी करें; प्रोडक्शन में उजागर करना असुविधाजनक हो तो 5.1 स्थानीय स्मोक उपयोग करें।
