# इंटरफ़ेस दस्तावेज़ (API Reference)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## अवलोकन

- एडमिन पैनल API `http://localhost:8787` पर चलता है
- व्यवसाय पोर्टल API `http://localhost:8788` पर चलता है
- एकीकृत प्रतिक्रिया प्रारूप: `{"code": 0, "message": "success", "data": {...}}`
- सभी ID फ़ील्ड hashids एन्कोडिंग से प्रसारित होती हैं
- API संस्करण अनुरोध हेडर `API-Version` से नियंत्रित होता है (डिफ़ॉल्ट `v1`)
- भाषा अनुरोध हेडर `Accept-Language` से नियंत्रित होती है (`zh-CN` / `en-US`, डिफ़ॉल्ट `zh-CN`)

### ऑनलाइन API दस्तावेज़

सेवा प्रारंभ करने के बाद `hg/apidoc` से स्वतः जनरेटेड इंटरैक्टिव दस्तावेज़ देखें:

| पोर्टल | पता | समूह संख्या |
|----|------|--------|
| एडमिन पैनल | `http://localhost:8787/apidoc` | 10 समूह (common/dashboard/system/property-core/property-aux/property-adv/extensions/export/import/upload) |
| मालिक पोर्टल | `http://localhost:8788/apidoc` | 9 समूह (सार्वजनिक इंटरफ़ेस/होम/शुल्क/मरम्मत/फीडबैक/पार्किंग/गतिविधि/व्यक्तिगत/विस्तार) |

---

## एडमिन पैनल API (admin :8787)

### सार्वजनिक इंटरफ़ेस — प्रमाणीकरण आवश्यक नहीं

#### POST /api/captcha/generate
क्लिक कैप्चा प्राप्त करें।

अनुरोध पैरामीटर: कोई नहीं

प्रतिक्रिया:
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

#### POST /api/captcha/verify
क्लिक कैप्चा सत्यापित करें।

अनुरोध पैरामीटर:
| पैरामीटर | प्रकार | विवरण |
|------|------|------|
| key | string | कैप्चा key, generate द्वारा लौटाया गया |
| clicks | array | क्लिक निर्देशांक [{x, y}, ...] |

प्रतिक्रिया:
```json
{
  "code": 0,
  "data": { "valid": true }
}
```

सत्यापन विफल होने पर `code` 422 और `data.valid` `false` होता है।

#### POST /api/auth/login
एडमिन लॉगिन।

अनुरोध पैरामीटर:
| पैरामीटर | प्रकार | विवरण |
|------|------|------|
| username | string | उपयोगकर्ता नाम |
| password | string | पासवर्ड |
| captcha_key | string | कैप्चा key |
| clicks | array | क्लिक निर्देशांक [{x, y}, ...] |

प्रतिक्रिया:
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

#### POST /api/auth/refresh
Token रीफ्रेश करें।

अनुरोध पैरामीटर:
| पैरामीटर | प्रकार | विवरण |
|------|------|------|
| refresh_token | string | रीफ्रेश टोकन |

प्रतिक्रिया:
```json
{
  "code": 0,
  "data": { "access_token": "eyJ..." }
}
```

#### GET /health
स्वास्थ्य जांच।

#### GET /metrics
Prometheus मॉनिटरिंग मेट्रिक्स।

#### GET /api/docs
OpenAPI दस्तावेज़।

---

### एडमिन पैनल इंटरफ़ेस — प्रमाणीकरण आवश्यक (Bearer Token)

सभी इंटरफ़ेस उपसर्ग `/admin`, साथ ले जाना आवश्यक `Authorization: Bearer {access_token}`।

#### डैशबोर्ड

**GET /admin/dashboard**
डैशबोर्ड सांख्यिकी डेटा प्राप्त करें।

#### एडमिन उपयोगकर्ता प्रबंधन

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/user | उपयोगकर्ता सूची (?keyword=&status=&page=&page_size=) |
| POST | /admin/user | उपयोगकर्ता बनाएं |
| GET | /admin/user/{hashid} | उपयोगकर्ता विवरण |
| PUT | /admin/user/{hashid} | उपयोगकर्ता अपडेट करें |
| DELETE | /admin/user/{hashid} | उपयोगकर्ता हटाएं (पासवर्ड पुष्टि आवश्यक) |
| POST | /admin/user/batch/destroy | बैच हटाना |
| POST | /admin/user/batch/status | बैच सक्षम-अक्षम |
| POST | /admin/import/users | Excel से उपयोगकर्ता इम्पोर्ट |

#### भूमिका अनुमति प्रबंधन

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/role | भूमिका सूची |
| POST | /admin/role | भूमिका बनाएं |
| GET | /admin/role/{hashid} | भूमिका विवरण |
| PUT | /admin/role/{hashid} | भूमिका अपडेट करें |
| DELETE | /admin/role/{hashid} | भूमिका हटाएं |
| GET | /admin/permission | अनुमति सूची (ट्री) |
| POST | /admin/permission | अनुमति बनाएं |
| PUT | /admin/permission/{hashid} | अनुमति अपडेट करें |
| DELETE | /admin/permission/{hashid} | अनुमति हटाएं |

#### सिस्टम कॉन्फ़िग

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/config | कॉन्फ़िग सूची (?group=) |
| POST | /admin/config | कॉन्फ़िग बनाएं |
| PUT | /admin/config/{hashid} | कॉन्फ़िग अपडेट करें |
| DELETE | /admin/config/{hashid} | कॉन्फ़िग हटाएं |

#### ऑपरेशन लॉग

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/log | लॉग सूची (?user_id=&action=&method=&source=&start_date=&end_date=) |

#### व्यक्तिगत केंद्र

| विधि | पथ | विवरण |
|------|------|------|
| PUT | /admin/profile | व्यक्तिगत जानकारी संशोधित करें |
| PUT | /admin/profile/password | पासवर्ड बदलें |
| POST | /admin/profile/logout | लॉगआउट |

#### निर्यात

| विधि | पथ | विवरण |
|------|------|------|
| POST | /admin/export/excel | Excel निर्यात ({ table, columns, conditions, title }) |
| POST | /admin/export/pdf | PDF निर्यात ({ type, title, data }) |

---

### संपत्ति प्रबंधन — एडमिन पैनल इंटरफ़ेस

#### समुदाय प्रबंधन

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/community | सूची (?keyword=&status=) |
| POST | /admin/community | बनाएं |
| GET | /admin/community/{hashid} | विवरण |
| PUT | /admin/community/{hashid} | अपडेट करें |
| DELETE | /admin/community/{hashid} | हटाएं (पासवर्ड आवश्यक) |

#### भवन प्रबंधन

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/building | सूची (?community_id=&keyword=) |
| POST | /admin/building | बनाएं |
| GET | /admin/building/{hashid} | विवरण |
| PUT | /admin/building/{hashid} | अपडेट करें |
| DELETE | /admin/building/{hashid} | हटाएं |

#### इकाई प्रबंधन

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/unit | सूची (?building_id=) |
| POST | /admin/unit | बनाएं |
| GET | /admin/unit/{hashid} | विवरण |
| PUT | /admin/unit/{hashid} | अपडेट करें |
| DELETE | /admin/unit/{hashid} | हटाएं |

#### रूम प्रकार प्रबंधन

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/room-type | सूची |
| POST | /admin/room-type | बनाएं |
| GET | /admin/room-type/{hashid} | विवरण |
| PUT | /admin/room-type/{hashid} | अपडेट करें |
| DELETE | /admin/room-type/{hashid} | हटाएं |

#### संपत्ति प्रबंधन

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/room | सूची (?community_id=&building_id=&unit_id=&status=) |
| POST | /admin/room | बनाएं |
| GET | /admin/room/{hashid} | विवरण |
| PUT | /admin/room/{hashid} | अपडेट करें |
| DELETE | /admin/room/{hashid} | हटाएं |
| GET | /admin/room/tree | हाउस ट्री (समुदाय→भवन→इकाई→घर) |

#### मालिक प्रबंधन

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/owner | सूची (?keyword=&status=) |
| POST | /admin/owner | बनाएं |
| GET | /admin/owner/{hashid} | विवरण (बंधी संपत्ति सहित) |
| PUT | /admin/owner/{hashid} | अपडेट करें |
| DELETE | /admin/owner/{hashid} | हटाएं (पासवर्ड आवश्यक) |
| POST | /admin/owner/batch/import | Excel बैच इम्पोर्ट |
| POST | /admin/owner/batch/destroy | बैच हटाना |

#### किरायेदार प्रबंधन

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/tenant | सूची (?room_id=&status=) |
| POST | /admin/tenant | बनाएं |
| GET | /admin/tenant/{hashid} | विवरण |
| PUT | /admin/tenant/{hashid} | अपडेट करें |
| DELETE | /admin/tenant/{hashid} | हटाएं |

#### शुल्क प्रकार

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/fee-type | सूची |
| POST | /admin/fee-type | बनाएं |
| GET | /admin/fee-type/{hashid} | विवरण |
| PUT | /admin/fee-type/{hashid} | अपडेट करें |
| DELETE | /admin/fee-type/{hashid} | हटाएं |

#### बिल प्रबंधन

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/fee-bill | सूची (?community_id=&status=&due_date_start=&due_date_end=) |
| POST | /admin/fee-bill | बिल बनाएं |
| GET | /admin/fee-bill/{hashid} | विवरण |
| PUT | /admin/fee-bill/{hashid} | अपडेट करें |
| DELETE | /admin/fee-bill/{hashid} | हटाएं |
| POST | /admin/fee-bill/batch/generate | बैच बिल जनरेशन |

#### भुगतान रिकॉर्ड

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/fee-payment | सूची (?bill_id=&payment_method=&date_start=&date_end=) |
| POST | /admin/fee-payment/offline | ऑफलाइन संग्रह पंजीकरण |

#### मरम्मत प्रबंधन

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/repair | सूची (?status=&category=) |
| POST | /admin/repair | बनाएं |
| GET | /admin/repair/{hashid} | विवरण (प्रगति रिकॉर्ड सहित) |
| PUT | /admin/repair/{hashid} | अपडेट करें |
| DELETE | /admin/repair/{hashid} | हटाएं |
| PUT | /admin/repair/{id}/assign | कार्य सौंपना ({ staff_id }) |
| POST | /admin/repair/{id}/progress | प्रगति अपडेट करें ({ status_to, remark }) |

#### घोषणा प्रबंधन

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/announcement | सूची (?community_id=&category=&is_published=) |
| POST | /admin/announcement | बनाएं |
| GET | /admin/announcement/{hashid} | विवरण |
| PUT | /admin/announcement/{hashid} | अपडेट करें |
| DELETE | /admin/announcement/{hashid} | हटाएं |

#### पार्किंग प्रबंधन

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/parking-space | सूची (?community_id=) |
| POST | /admin/parking-space | पार्किंग स्थल बनाएं |
| PUT | /admin/parking-space/{hashid} | अपडेट करें |
| DELETE | /admin/parking-space/{hashid} | हटाएं |
| GET | /admin/parking-vehicle | सूची (?owner_id=&space_id=) |
| POST | /admin/parking-vehicle | वाहन बनाएं |
| PUT | /admin/parking-vehicle/{hashid} | अपडेट करें |
| DELETE | /admin/parking-vehicle/{hashid} | हटाएं |
| GET | /admin/parking-record | पार्किंग रिकॉर्ड (?vehicle_id=&date_start=&date_end=) |

#### उपकरण प्रबंधन

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/equipment | सूची (?community_id=&category=&status=) |
| POST | /admin/equipment | बनाएं |
| PUT | /admin/equipment/{hashid} | अपडेट करें |
| DELETE | /admin/equipment/{hashid} | हटाएं |
| GET | /admin/equipment-maintenance | रखरखाव रिकॉर्ड (?equipment_id=) |
| POST | /admin/equipment-maintenance | रखरखाव बनाएं |

#### शिकायत प्रसंस्करण

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/complaint | सूची (?type=&status=) |
| GET | /admin/complaint/{hashid} | विवरण |
| PUT | /admin/complaint/{id}/handle | प्रसंस्करण ({ handler_remark }) |
| POST | /admin/complaint/{id}/visit | फॉलो-अप ({ visitor_remark }) |

#### अतिथि अनुमोदन

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/visitor | सूची (?status=) |
| PUT | /admin/visitor/{id}/approve | अनुमोदन पास |

#### अनुबंध प्रबंधन

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/contract | सूची (?contract_type=&status=) |
| POST | /admin/contract | बनाएं |
| PUT | /admin/contract/{hashid} | अपडेट करें |
| DELETE | /admin/contract/{hashid} | हटाएं |

#### वित्त प्रबंधन

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/finance-income | आय सूची (?income_type=&date_start=&date_end=) |
| POST | /admin/finance-income | आय पंजीकरण |
| GET | /admin/finance-expense | व्यय सूची |
| POST | /admin/finance-expense | व्यय पंजीकरण |
| GET | /admin/finance/statistics | मासिक आय-व्यय सांख्यिकी (?year=) |

#### संपत्ति पैनल

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/dashboard/property | संपत्ति सांख्यिकी (प्राप्य/अधिभोग दर/मरम्मत/शिकायत/आय-व्यय रुझान) |
| POST | /admin/export/property-excel | संपत्ति डेटा Excel निर्यात ({ type: owners|bills }) |

#### सुरक्षा गश्त

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/security-patrol | सूची (?community_id=) |
| POST | /admin/security-patrol | गश्त मार्ग बनाएं |
| GET | /admin/patrol-record | रिकॉर्ड (?patrol_id=&staff_id=) |
| POST | /admin/patrol-record | रिकॉर्ड बनाएं |

#### सफाई प्रबंधन

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/cleaning-area | क्षेत्र सूची |
| POST | /admin/cleaning-area | क्षेत्र बनाएं |
| GET | /admin/cleaning-record | रिकॉर्ड (?area_id=) |
| POST | /admin/cleaning-record | रिकॉर्ड बनाएं |

#### हरियाली प्रबंधन

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/green-area | क्षेत्र सूची |
| POST | /admin/green-area | क्षेत्र बनाएं |
| GET | /admin/green-maintenance | रखरखाव रिकॉर्ड (?area_id=) |
| POST | /admin/green-maintenance | रिकॉर्ड बनाएं |

#### सामुदायिक गतिविधि

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/activity | सूची (?status=) |
| POST | /admin/activity | गतिविधि बनाएं |
| PUT | /admin/activity/{hashid} | अपडेट करें |
| DELETE | /admin/activity/{hashid} | हटाएं |
| GET | /admin/activity-signup | पंजीकरण सूची (?activity_id=) |
| PUT | /admin/activity-signup/{id}/checkin | चेक-इन |

#### ऊर्जा प्रबंधन

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/energy-meter | मीटर सूची (?room_id=&meter_type=) |
| POST | /admin/energy-meter | मीटर बनाएं |
| GET | /admin/energy-record | रीडिंग रिकॉर्ड (?meter_id=&date_start=&date_end=) |
| POST | /admin/energy-record | रिकॉर्ड बनाएं |

#### कर्मचारी प्रबंधन

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/staff | सूची (?community_id=&status=) |
| POST | /admin/staff | बनाएं |
| PUT | /admin/staff/{hashid} | अपडेट करें |
| DELETE | /admin/staff/{hashid} | हटाएं |
| POST | /admin/staff/batch/status | बैच सक्षम-अक्षम |

#### संदेश सूचना

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/notification-template | टेम्पलेट सूची |
| POST | /admin/notification-template | टेम्पलेट बनाएं |
| PUT | /admin/notification-template/{hashid} | टेम्पलेट अपडेट करें |
| DELETE | /admin/notification-template/{hashid} | टेम्पलेट हटाएं |
| GET | /admin/notification | संदेश सूची (?type=&is_read=) |
| POST | /admin/notification/send | मैन्युअल सूचना भेजें |

#### अनुमोदन वर्कफ़्लो

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/approval-type | अनुमोदन प्रकार सूची |
| POST | /admin/approval-type | अनुमोदन प्रकार बनाएं |
| GET | /admin/approval | अनुमोदन सूची (?status=) |
| GET | /admin/approval/{hashid} | अनुमोदन विवरण |
| POST | /admin/approval | अनुमोदन सबमिट करें |
| PUT | /admin/approval/{hashid}/approve | अनुमोदन (पास/अस्वीकृत) |

#### भुगतान प्रबंधन

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/payment-order | ऑर्डर सूची |
| GET | /admin/payment-order/{hashid} | ऑर्डर विवरण |
| POST | /admin/payment-order/{hashid}/refund | रिफंड |
| GET | /admin/payment/statistics | भुगतान सांख्यिकी |

#### मालिक मतदान

| विधि | पथ | विवरण |
|------|------|------|
| GET | /admin/vote | मतदान सूची (?status=) |
| POST | /admin/vote | मतदान बनाएं |
| GET | /admin/vote/{hashid}/statistics | मतगणना सांख्यिकी |
| PUT | /admin/vote/{hashid}/publish | मतदान प्रकाशित करें |
| PUT | /admin/vote/{hashid}/end | मतदान समाप्त करें |

#### SLA प्रबंधन · स्मार्ट वसूली · निरीक्षण प्रबंधन · मॉल प्रबंधन · चेहरा प्रबंधन · समूह प्रबंधन · ज्ञान आधार

（पूर्ण एंडपॉइंट `docs/API.md` फ़ाइल देखें）

---

## व्यवसाय पोर्टल API (service :8788)

### सार्वजनिक इंटरफ़ेस — प्रमाणीकरण आवश्यक नहीं

#### POST /api/captcha/generate
क्लिक कैप्चा प्राप्त करें। (एडमिन पैनल के समान)

#### POST /api/captcha/verify
क्लिक कैप्चा सत्यापित करें। (अनुरोध/प्रतिक्रिया एडमिन पैनल के समान)

#### POST /api/auth/login
मालिक लॉगिन।

अनुरोध पैरामीटर:
| पैरामीटर | प्रकार | विवरण |
|------|------|------|
| phone | string | मोबाइल नंबर |
| password | string | पासवर्ड |
| captcha_key | string | कैप्चा key |
| clicks | array | क्लिक निर्देशांक |

प्रतिक्रिया:
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

#### POST /api/auth/register
मालिक पंजीकरण।

अनुरोध पैरामीटर:
| पैरामीटर | प्रकार | विवरण |
|------|------|------|
| phone | string | मोबाइल नंबर |
| password | string | पासवर्ड (कम से कम 6 अक्षर) |
| name | string | नाम |
| captcha_key | string | कैप्चा key |
| clicks | array | क्लिक निर्देशांक |
| room_id | string | (वैकल्पिक) बंधा हुआ रूम नंबर hashid |
| id_card_last4 | string | (वैकल्पिक) आईडी कार्ड अंतिम 4 अंक |

#### POST /api/auth/refresh
Token रीफ्रेश करें।

---

### मालिक पोर्टल इंटरफ़ेस — प्रमाणीकरण आवश्यक (Bearer Token)

सभी इंटरफ़ेस उपसर्ग `/service`, साथ ले जाना आवश्यक `Authorization: Bearer {access_token}`।

#### होम

**GET /service/home**

प्रतिक्रिया:
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

#### मेरी संपत्ति

| विधि | पथ | विवरण |
|------|------|------|
| GET | /service/rooms | मेरी संपत्ति सूची |
| GET | /service/room/{hashid} | संपत्ति विवरण (क्षेत्रफल, दिशा, स्वामित्व, समुदाय जानकारी सहित) |

#### शुल्क प्रबंधन

| विधि | पथ | विवरण |
|------|------|------|
| GET | /service/fees/bills | बिल सूची (?status=0अवैतनिक/1आंशिक भुगतान/2भुगतान किया/3अतिदेय) |
| GET | /service/fees/bill/{hashid} | बिल विवरण (शुल्क प्रकार, भुगतान रिकॉर्ड सहित) |
| GET | /service/fees/payments | भुगतान रिकॉर्ड |
| POST | /service/fees/pay | ऑनलाइन भुगतान ({ bill_id, payment_method, password }) |
| GET | /service/fees/statistics | शुल्क सांख्यिकी (?year=2026) |

#### मरम्मत

| विधि | पथ | विवरण |
|------|------|------|
| GET | /service/repairs | मरम्मत सूची (?status=) |
| GET | /service/repair/{hashid} | मरम्मत विवरण (प्रगति टाइमलाइन सहित) |
| POST | /service/repair | मरम्मत सबमिट करें ({ room_id, category, urgency, description, images[], scheduled_at }) |
| DELETE | /service/repair/{hashid} | रद्द करें (पासवर्ड आवश्यक, { password }) |
| POST | /service/repair/{hashid}/rate | रेटिंग ({ rating: 1-5, feedback }) |

#### शिकायत सुझाव

| विधि | पथ | विवरण |
|------|------|------|
| GET | /service/complaints | शिकायत सूची |
| GET | /service/complaint/{hashid} | शिकायत विवरण (प्रसंस्करण प्रगति सहित) |
| POST | /service/complaint | शिकायत सबमिट करें ({ type, category, title, content, is_anonymous, images[] }) |
| POST | /service/complaint/{hashid}/satisfaction | संतुष्टि मूल्यांकन ({ satisfaction: 1-5 }) |

#### घोषणा

| विधि | पथ | विवरण |
|------|------|------|
| GET | /service/announcements | घोषणा सूची (?category=) |
| GET | /service/announcement/{hashid} | घोषणा विवरण |

#### पार्किंग

| विधि | पथ | विवरण |
|------|------|------|
| GET | /service/parking/vehicles | मेरे वाहन |
| GET | /service/parking/spaces | मेरी पार्किंग |
| GET | /service/parking/records | पार्किंग रिकॉर्ड |

#### अतिथि

| विधि | पथ | विवरण |
|------|------|------|
| GET | /service/visitors | मेरे अतिथि आरक्षण |
| POST | /service/visitor | आरक्षण बनाएं (पास कोड जनरेट करें) |
| PUT | /service/visitor/{hashid} | आरक्षण संशोधित करें |
| DELETE | /service/visitor/{hashid} | आरक्षण रद्द करें |

#### सामुदायिक गतिविधि

| विधि | पथ | विवरण |
|------|------|------|
| GET | /service/activities | गतिविधि सूची (?status=) |
| GET | /service/activity/{hashid} | गतिविधि विवरण |
| POST | /service/activity/{hashid}/signup | पंजीकरण |
| POST | /service/activity/{hashid}/cancel | पंजीकरण रद्द करें |

#### व्यक्तिगत जानकारी

| विधि | पथ | विवरण |
|------|------|------|
| GET | /service/profile | व्यक्तिगत जानकारी |
| PUT | /service/profile | संशोधित करें ({ name, email, gender, birthday }) |
| PUT | /service/profile/password | पासवर्ड बदलें ({ old_password, new_password }) |
| POST | /service/profile/logout | लॉगआउट |

---

## ओपन API — API Key प्रमाणीकरण

इनबाउंड बाहरी केवल-पढ़ने योग्य इंटरफ़ेस, तीसरे पक्ष की प्रणालियों (संपत्ति प्लेटफ़ॉर्म एकीकरण, डेटा स्क्रीन आदि) के कॉल के लिए। उपसर्ग `/open`, सभी केवल-पढ़ने योग्य।

### प्रमाणीकरण विधि

प्रत्येक अनुरोध में हेडर `X-API-Key` ले जाना आवश्यक है, मान `scripts/gen_api_key.php` द्वारा जनरेटेड Key (64 बिट hex, डेटाबेस में केवल SHA-256 डाइजेस्ट संग्रहीत):

```bash
curl -H "X-API-Key: <आपका Key>" http://localhost:8788/open/announcements
```

- अनुपलब्ध या गलत Key पर `401` लौटता है (`{"code":401,"message":"无效的API Key","data":[]}`)
- Key प्रबंधन: `php scripts/gen_api_key.php [--name=उपयोग]` से जनरेट करें; अक्षम/हटाना सीधे `erik_api_key` टेबल पर कार्य (`status=0` अर्थात अक्षम, कुंजी तुरंत अमान्य)

### एंडपॉइंट

#### GET /open/announcements — घोषणा सूची

पैरामीटर: `page` (डिफ़ॉल्ट 1)、`category` (वैकल्पिक)। प्रतिक्रिया संरचना `/service/announcements` के अनुरूप।

```bash
curl -H "X-API-Key: <आपका Key>" "http://localhost:8788/open/announcements?page=1"
```

#### GET /open/bills — बिल क्वेरी

पैरामीटर: `bill_number` (आवश्यक, बिल नंबर)। एकल बिल विवरण लौटाता है (शुल्क प्रकार, रूम नंबर, बकाया राशि सहित)। मौजूद न होने पर 404 लौटता है।

```bash
curl -H "X-API-Key: <आपका Key>" "http://localhost:8788/open/bills?bill_number=B202608160001"
```

#### GET /open/repairs — मरम्मत स्थिति क्वेरी

पैरामीटर: `order_number` (आवश्यक, मरम्मत ऑर्डर नंबर)। मरम्मत ऑर्डर की वर्तमान स्थिति और प्रगति टाइमलाइन लौटाता है (`progress` ऐरे)। मौजूद न होने पर 404 लौटता है।

```bash
curl -H "X-API-Key: <आपका Key>" "http://localhost:8788/open/repairs?order_number=R202608160001"
```

---

## त्रुटि कोड

| code | अर्थ | विवरण |
|------|------|------|
| 0 | सफल | सामान्य प्रतिक्रिया |
| 400 | अनुरोध त्रुटि | पैरामीटर प्रारूप सही नहीं |
| 401 | प्रमाणित नहीं | Token अनुपलब्ध/समाप्त/अमान्य/ब्लैकलिस्ट में |
| 403 | कोई अनुमति नहीं | उपयोगकर्ता भूमिका में आवश्यक अनुमति नहीं / खाता अक्षम |
| 404 | मौजूद नहीं | संसाधन नहीं मिला |
| 405 | विधि अनुमत नहीं | गैर GET/POST/PUT/DELETE/OPTIONS HTTP विधि |
| 413 | अनुरोध निकाय बड़ा | 10MB से अधिक |
| 415 | असमर्थित मीडिया प्रकार | Content-Type JSON या form-urlencoded नहीं |
| 422 | सत्यापन विफल | फ़ॉर्म पैरामीटर नियमों के अनुरूप नहीं / पासवर्ड पुष्टि विफल / कैप्चा गलत |
| 429 | बहुत सारे अनुरोध | रेट लिमिट ट्रिगर / खाता लॉक |
| 500 | सर्वर त्रुटि | अप्रत्याशित अपवाद |

## रेट लिमिट प्रतिक्रिया हेडर

रेट लिमिट ट्रिगर होने पर 429 लौटता है, प्रतिक्रिया हेडर में शामिल:

| प्रतिक्रिया हेडर | विवरण |
|--------|------|
| X-RateLimit-Limit | सीमा संख्या |
| X-RateLimit-Remaining | शेष संख्या |
| X-RateLimit-Reset | रीसेट समय (Unix टाइमस्टैम्प) |
| Retry-After | अनुशंसित पुनः प्रयास प्रतीक्षा सेकंड |
