# डेटाबेस पुनर्स्थापना अभ्यास मैनुअल (Recovery Runbook)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> लागू: property-management-platform (admin पोर्टल + service पोर्टल, MySQL 8.0)
> [OPS_RUNBOOK.md](OPS_RUNBOOK.md) खंड 1 के साथ मिलकर पढ़ें: बैकअप जनरेशन、crontab、RPO/RTO OPS_RUNBOOK में देखें, यह दस्तावेज़ केवल "कैसे पुनर्स्थापित करें、कैसे सत्यापित करें" बताता है।

## 0. लक्ष्य

- **अभ्यास लक्ष्य: 30 मिनट में एक पूर्ण पुनर्स्थापना अभ्यास पूरा करें** (पुनर्स्थापना + सत्यापन), हर तिमाही कम से कम एक बार।
- किसी भी समय नवीनतम बैकअप लेकर, इस दस्तावेज़ के अनुसार खाली डेटाबेस या निर्दिष्ट समय बिंदु तक पुनर्स्थापित किया जा सके।

पूर्व शर्तें:

- बैकअप फ़ाइल उपलब्ध: `scripts/backup.sh` cron के अनुसार चल रहा है (OPS_RUNBOOK 1.2 देखें)।
- पुनर्स्थापना लक्ष्य वातावरण (अभ्यास मशीन या प्रोडक्शन मशीन) प्रोडक्शन के समरूप: एक ही docker-compose、समान संस्करण MySQL 8.0।
- पुनर्स्थापना से पहले पुष्टि करें: `gzip -t बैकअप फ़ाइल` पास हो; डिस्क खाली स्थान ≥ बैकअप आकार का 2 गुना।

## 1. परिदृश्य A: खाली डेटाबेस में पुनर्स्थापना (सबसे आम, अभ्यास का डिफ़ॉल्ट परिदृश्य)

लक्ष्य: बैकअप को एक नए खाली डेटाबेस में इम्पोर्ट करें, डेटा उपलब्धता सत्यापित करें।

```bash
cd /path/to/property-management-platform

# 1) नवीनतम बैकअप चुनें
ls -lt backups/backup_*.sql.gz | head

# 2) पूर्णता जांच (पास न हो तो पुराना बैकअप चुनें)
gzip -t backups/backup_20260816_020000.sql.gz && echo OK

# 3) पुष्टि करें कि लक्ष्य कंटेनर चल रहा है
docker compose -f admin/docker-compose.yml ps mysql

# 4) खाली डेटाबेस बनाएं (अभ्यास डेटाबेस नाम में _drill प्रत्यय, प्रोडक्शन डेटा को गलती से अधिलेखित न करने के लिए)
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot -e "CREATE DATABASE IF NOT EXISTS management_drill DEFAULT CHARACTER SET utf8mb4;"'

# 5) इम्पोर्ट करें (-T TTY बंद करता है, गैर-इंटरैक्टिव सुनिश्चित करता है; वास्तविक माप लगभग 1-5 मिनट)
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot --default-character-set=utf8mb4 management_drill' \
  < backups/backup_20260816_020000.sql.gz
```

> क्रेडेंशियल सूचना: `MYSQL_PWD` `admin/.env` के `DB_PASSWORD` से लें; प्रोडक्शन में shell इतिहास में सादा पाठ दिखाना निषिद्ध है, `--env-file admin/.env` या पर्यावरण चर इंजेक्ट करने की सलाह दी जाती है। इस मैनुअल के उदाहरण अभ्यास वातावरण के निर्धारित मान हैं।

## 2. परिदृश्य B: निर्दिष्ट समय बिंदु पर पुनर्स्थापना (binlog रीप्ले)

पूर्व शर्त: MySQL 8 डिफ़ॉल्ट रूप से binlog सक्षम है (`log_bin=ON`), बैकअप समय के बाद के सभी इंक्रीमेंटल बदलाव binlog में हैं। डेटा हानि ≤ नवीनतम बैकअप + binlog अवधारण अवधि (डिफ़ॉल्ट `binlog_expire_logs_seconds=2592000`, 30 दिन)।

विचार: पूर्ण पुनर्स्थापना → binlog प्रारंभ बिंदु खोजें → `mysqlbinlog` से लक्ष्य समय बिंदु तक रीप्ले करें।

```bash
# 1) binlog सक्षम है यह पुष्टि करें, लॉग फ़ाइलें सूचीबद्ध करें
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot -e "SHOW VARIABLES LIKE \"log_bin\"; SHOW BINARY LOGS;"'

# 2) पूर्ण पुनर्स्थापना (परिदृश्य A के चरण 4-5 के समान, खाली डेटाबेस में पुनर्स्थापित करें)

# 3) बैकअप के अनुरूप binlog प्रारंभ बिंदु खोजें: बैकअप फ़ाइल में दर्ज स्थिति (--master-data=2 होने पर)
#    यह स्क्रिप्ट --master-data के बिना है, प्रारंभ बिंदु "बैकअप प्रारंभ समय" माना जाता है, त्रुटि बैकअप अवधि के भीतर।
#    binlog को लक्ष्य समय बिंदु तक रीप्ले करें (उदाहरण: 2026-08-16 10:30:00 तक पुनर्स्थापित करें)
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysqlbinlog --stop-datetime="2026-08-16 10:30:00" /var/lib/mysql/binlog.000012 | mysql -uroot management_drill'
```

मुख्य बिंदु:

- binlog कंटेनर में पथ `/var/lib/mysql/binlog.0000NN`, `SHOW BINARY LOGS` के आउटपुट से मिलान करें।
- केवल "बैकअप प्रारंभ समय के बाद" का binlog रीप्ले करें; रीप्ले के तुरंत बाद सत्यापित करें (खंड 3 देखें), पुष्टि करें कि `max(updated_at)` अपेक्षा के अनुरूप है।
- सेकंड-सटीक गलत संचालन पुनर्स्थापना: पहले गलत संचालन कथन का पता लगाएं `mysqlbinlog /var/lib/mysql/binlog.0000NN | grep -n "गलत संचालन कुंजीशब्द"`, फिर `--stop-datetime` या `--stop-position` तय करें।

## 3. डेटा स्थिरता सत्यापन (पुनर्स्थापना के बाद अनिवार्य)

| जांच आइटम | कमांड | पास मानदंड |
|---|---|---|
| बैकअप फ़ाइल पूर्णता | `gzip -t <बैकअप>` | कोई त्रुटि नहीं |
| मुख्य टेबल पंक्ति संख्या | `SELECT COUNT(*) FROM management_admin_user;` | बैकअप से पहले दर्ज पंक्ति संख्या के अनुरूप |
| व्यवसाय टेबल स्पॉट चेक | `SELECT COUNT(*) FROM management_owner;`、`management_tenant`、`management_fee_bill`、`management_repair_order` | तीन से अधिक में मात्रा उचित (गैर-0 और बैकअप से पहले के अनुरूप) |
| एन्क्रिप्टेड फ़ील्ड डिक्रिप्ट योग्य | encryptable फ़ील्ड वाला एक रिकॉर्ड देखें (जैसे `management_owner` आधार कार्ड/फोन नंबर) | मान सही, एप्लिकेशन लॉग में decrypt त्रुटि नहीं |
| व्यवसाय स्मोक टेस्ट | लॉगिन、सूची API प्रत्येक 1 बार | 200 / सामान्य रिटर्न |

स्पॉट चेक स्क्रिप्ट उदाहरण (अभ्यास वातावरण):

```bash
docker compose -f admin/docker-compose.yml exec -T -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot management_drill -e "
    SELECT (SELECT COUNT(*) FROM management_admin_user) AS users,
           (SELECT COUNT(*) FROM management_owner) AS owners,
           (SELECT COUNT(*) FROM management_tenant) AS tenants,
           (SELECT COUNT(*) FROM management_fee_bill) AS fee_bills,
           (SELECT COUNT(*) FROM management_repair_order) AS repair_orders;"'
```

> पंक्ति संख्या स्थिरता: बैकअप से पहले उसी SQL से आधार रेखा दर्ज करें, पुनर्स्थापना के बाद तुलना करें; अभ्यास के समय आधार रेखा अभ्यास रिकॉर्ड में लिखें।

## 4. 30 मिनट अभ्यास समय सारणी

| समय | क्रिया | जिम्मेदार |
|---|---|---|
| 0-5 मिनट | बैकअप चुनें、`gzip -t`、खाली डेटाबेस बनाएं、आधार रेखा पंक्ति संख्या दर्ज करें | संचालन |
| 5-15 मिनट | परिदृश्य A पुनर्स्थापना इम्पोर्ट | संचालन |
| 15-25 मिनट | खंड 3 स्थिरता सत्यापन + व्यवसाय स्मोक टेस्ट | संचालन + व्यवसाय |
| 25-30 मिनट | परिणाम दर्ज करें、अभ्यास डेटाबेस साफ़ करें (`DROP DATABASE management_drill`)、OPS_RUNBOOK 1.4 का वास्तविक RTO अपडेट करें | संचालन |

## 5. विफलता प्रबंधन

| लक्षण | प्रबंधन |
|---|---|
| `gzip -t` विफल | बैकअप क्षतिग्रस्त, पुराना बैकअप चुनें, बड़ा RPO स्वीकार करें, और बैकअप cron सामान्य है या नहीं जांचें |
| इम्पोर्ट त्रुटि (वर्ण सेट/अनुमति) | पुष्टि करें `--default-character-set=utf8mb4` खाली डेटाबेस के वर्ण सेट से मेल खाता है; उपयोगकर्ता के पास टेबल बनाने की अनुमति है या नहीं पुष्टि करें |
| पंक्ति संख्या आधार रेखा से मेल नहीं | तुरंत अभ्यास रोकें, जांचें कि गलत डेटाबेस/गलत फ़ाइल इम्पोर्ट तो नहीं हुई; प्रोडक्शन पुनर्स्थापना परिदृश्य में आगे जांच करें और एप्लिकेशन रोलबैक करें |
| binlog रीप्ले के बाद भी डेटा कम | जांचें `--stop-datetime` बैकअप प्रारंभ समय से बाद का है या नहीं; पुष्टि करें रीप्ले बैकअप के बाद पहले binlog से शुरू हुआ |

## 6. अभ्यास रिकॉर्ड टेम्पलेट

```text
दिनांक: 2026-08-16
पुनर्स्थापना लक्ष्य: खाली डेटाबेस (परिदृश्य A) / समय बिंदु (परिदृश्य B)
बैकअप फ़ाइल: backups/backup_20260816_020000.sql.gz
आधार रेखा पंक्ति संख्या: management_admin_user=1, management_owner=42, management_fee_bill=128
पुनर्स्थापना समय: XX मिनट    सत्यापन समय: XX मिनट    कुल: XX मिनट (लक्ष्य ≤ 30)
परिणाम: पास / विफल (विफलता कारण और प्रबंधन संलग्न करें)
```
