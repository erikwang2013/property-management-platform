# ইন্টারফেস ডকুমেন্ট (API Reference)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## ওভারভিউ

- অ্যাডমিন প্যানেল API চলে `http://localhost:8787`-এ
- ব্যবসা পাশ API চলে `http://localhost:8788`-এ
- ইউনিফাইড রেসপন্স ফরম্যাট: `{"code": 0, "message": "success", "data": {...}}`
- সব ID ফিল্ড hashids এনকোডিংয়ে ট্রান্সমিট হয়
- API ভার্সন রিকোয়েস্ট হেডার `API-Version` দিয়ে নিয়ন্ত্রিত (ডিফল্ট `v1`)
- ভাষা রিকোয়েস্ট হেডার `Accept-Language` দিয়ে নিয়ন্ত্রিত (`zh-CN` / `en-US`, ডিফল্ট `zh-CN`)

### অনলাইন API ডকুমেন্ট

সার্ভিস চালু হলে `hg/apidoc` স্বয়ংক্রিয়ভাবে তৈরি ইন্টারঅ্যাক্টিভ ডকুমেন্ট অ্যাক্সেস করুন:

| পাশ | ঠিকানা | গ্রুপ সংখ্যা |
|----|------|--------|
| অ্যাডমিন প্যানেল | `http://localhost:8787/apidoc` | ১০ গ্রুপ (common/dashboard/system/property-core/property-aux/property-adv/extensions/export/import/upload) |
| মালিক পোর্টাল | `http://localhost:8788/apidoc` | ৯ গ্রুপ (পাবলিক ইন্টারফেস/হোম/ফি/মেরামত/ফিডব্যাক/পার্কিং/কার্যক্রম/ব্যক্তিগত/এক্সটেনশন) |

---

## অ্যাডমিন প্যানেল API (admin :8787)

### পাবলিক ইন্টারফেস — অথেনটিকেশন লাগবে না

#### POST /api/captcha/generate
ক্লিক ক্যাপচা পাওয়া।

রিকোয়েস্ট প্যারামিটার: নেই

রেসপন্স:
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
ক্লিক ক্যাপচা যাচাই।

রিকোয়েস্ট প্যারামিটার:
| প্যারামিটার | ধরন | ব্যাখ্যা |
|------|------|------|
| key | string | ক্যাপচা key, generate থেকে ফেরা |
| clicks | array | ক্লিক কোঅর্ডিনেট [{x, y}, ...] |

রেসপন্স:
```json
{
  "code": 0,
  "data": { "valid": true }
}
```

যাচাই ব্যর্থ হলে `code` হবে 422, `data.valid` হবে `false`।

#### POST /api/auth/login
অ্যাডমিন লগইন।

রিকোয়েস্ট প্যারামিটার:
| প্যারামিটার | ধরন | ব্যাখ্যা |
|------|------|------|
| username | string | ইউজারনেম |
| password | string | পাসওয়ার্ড |
| captcha_key | string | ক্যাপচা key |
| clicks | array | ক্লিক কোঅর্ডিনেট [{x, y}, ...] |

রেসপন্স:
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
Token রিফ্রেশ।

রিকোয়েস্ট প্যারামিটার:
| প্যারামিটার | ধরন | ব্যাখ্যা |
|------|------|------|
| refresh_token | string | রিফ্রেশ টোকেন |

রেসপন্স:
```json
{
  "code": 0,
  "data": { "access_token": "eyJ..." }
}
```

#### GET /health
হেলথ চেক।

#### GET /metrics
Prometheus মনিটরিং মেট্রিক।

#### GET /api/docs
OpenAPI ডকুমেন্ট।

---

### অ্যাডমিন প্যানেল ইন্টারফেস — অথেনটিকেশন প্রয়োজন (Bearer Token)

সব ইন্টারফেসের প্রিফিক্স `/admin`, `Authorization: Bearer {access_token}` বহন করতে হবে।

#### ড্যাশবোর্ড

**GET /admin/dashboard**
ড্যাশবোর্ড পরিসংখ্যান ডেটা পাওয়া।

#### অ্যাডমিন ব্যবহারকারী ব্যবস্থাপনা

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/user | ব্যবহারকারী তালিকা (?keyword=&status=&page=&page_size=) |
| POST | /admin/user | ব্যবহারকারী তৈরি |
| GET | /admin/user/{hashid} | ব্যবহারকারী বিস্তারিত |
| PUT | /admin/user/{hashid} | ব্যবহারকারী আপডেট |
| DELETE | /admin/user/{hashid} | ব্যবহারকারী মুছা (পাসওয়ার্ড নিশ্চিতকরণ লাগবে) |
| POST | /admin/user/batch/destroy | ব্যাচ মুছা |
| POST | /admin/user/batch/status | ব্যাচ সক্রিয়/নিষ্ক্রিয় |
| POST | /admin/import/users | Excel দিয়ে ব্যবহারকারী ইমপোর্ট |

#### রোল ও পারমিশন ব্যবস্থাপনা

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/role | রোল তালিকা |
| POST | /admin/role | রোল তৈরি |
| GET | /admin/role/{hashid} | রোল বিস্তারিত |
| PUT | /admin/role/{hashid} | রোল আপডেট |
| DELETE | /admin/role/{hashid} | রোল মুছা |
| GET | /admin/permission | পারমিশন তালিকা (ট্রি আকার) |
| POST | /admin/permission | পারমিশন তৈরি |
| PUT | /admin/permission/{hashid} | পারমিশন আপডেট |
| DELETE | /admin/permission/{hashid} | পারমিশন মুছা |

#### সিস্টেম কনফিগারেশন

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/config | কনফিগ তালিকা (?group=) |
| POST | /admin/config | কনফিগ তৈরি |
| PUT | /admin/config/{hashid} | কনফিগ আপডেট |
| DELETE | /admin/config/{hashid} | কনফিগ মুছা |

#### অপারেশন লগ

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/log | লগ তালিকা (?user_id=&action=&method=&source=&start_date=&end_date=) |

#### ব্যক্তিগত কেন্দ্র

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| PUT | /admin/profile | ব্যক্তিগত তথ্য পরিবর্তন |
| PUT | /admin/profile/password | পাসওয়ার্ড পরিবর্তন |
| POST | /admin/profile/logout | লগআউট |

#### এক্সপোর্ট

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| POST | /admin/export/excel | Excel এক্সপোর্ট ({ table, columns, conditions, title }) |
| POST | /admin/export/pdf | PDF এক্সপোর্ট ({ type, title, data }) |

---

### সম্পত্তি ব্যবস্থাপনা — অ্যাডমিন প্যানেল ইন্টারফেস

#### কমিউনিটি ব্যবস্থাপনা

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/community | তালিকা (?keyword=&status=) |
| POST | /admin/community | তৈরি |
| GET | /admin/community/{hashid} | বিস্তারিত |
| PUT | /admin/community/{hashid} | আপডেট |
| DELETE | /admin/community/{hashid} | মুছা (পাসওয়ার্ড লাগবে) |

#### ভবন ব্যবস্থাপনা

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/building | তালিকা (?community_id=&keyword=) |
| POST | /admin/building | তৈরি |
| GET | /admin/building/{hashid} | বিস্তারিত |
| PUT | /admin/building/{hashid} | আপডেট |
| DELETE | /admin/building/{hashid} | মুছা |

#### ইউনিট ব্যবস্থাপনা

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/unit | তালিকা (?building_id=) |
| POST | /admin/unit | তৈরি |
| GET | /admin/unit/{hashid} | বিস্তারিত |
| PUT | /admin/unit/{hashid} | আপডেট |
| DELETE | /admin/unit/{hashid} | মুছা |

#### হাউজিং টাইপ ব্যবস্থাপনা

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/room-type | তালিকা |
| POST | /admin/room-type | তৈরি |
| GET | /admin/room-type/{hashid} | বিস্তারিত |
| PUT | /admin/room-type/{hashid} | আপডেট |
| DELETE | /admin/room-type/{hashid} | মুছা |

#### সম্পত্তি ব্যবস্থাপনা

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/room | তালিকা (?community_id=&building_id=&unit_id=&status=) |
| POST | /admin/room | তৈরি |
| GET | /admin/room/{hashid} | বিস্তারিত |
| PUT | /admin/room/{hashid} | আপডেট |
| DELETE | /admin/room/{hashid} | মুছা |
| GET | /admin/room/tree | বাড়ির ট্রি (কমিউনিটি→ভবন→ইউনিট→বাড়ি) |

#### মালিক ব্যবস্থাপনা

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/owner | তালিকা (?keyword=&status=) |
| POST | /admin/owner | তৈরি |
| GET | /admin/owner/{hashid} | বিস্তারিত (বাঁধাই করা সম্পত্তিসহ) |
| PUT | /admin/owner/{hashid} | আপডেট |
| DELETE | /admin/owner/{hashid} | মুছা (পাসওয়ার্ড লাগবে) |
| POST | /admin/owner/batch/import | Excel ব্যাচ ইমপোর্ট |
| POST | /admin/owner/batch/destroy | ব্যাচ মুছা |

#### ভাড়াটে ব্যবস্থাপনা

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/tenant | তালিকা (?room_id=&status=) |
| POST | /admin/tenant | তৈরি |
| GET | /admin/tenant/{hashid} | বিস্তারিত |
| PUT | /admin/tenant/{hashid} | আপডেট |
| DELETE | /admin/tenant/{hashid} | মুছা |

#### ফি ধরন

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/fee-type | তালিকা |
| POST | /admin/fee-type | তৈরি |
| GET | /admin/fee-type/{hashid} | বিস্তারিত |
| PUT | /admin/fee-type/{hashid} | আপডেট |
| DELETE | /admin/fee-type/{hashid} | মুছা |

#### বিল ব্যবস্থাপনা

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/fee-bill | তালিকা (?community_id=&status=&due_date_start=&due_date_end=) |
| POST | /admin/fee-bill | বিল তৈরি |
| GET | /admin/fee-bill/{hashid} | বিস্তারিত |
| PUT | /admin/fee-bill/{hashid} | আপডেট |
| DELETE | /admin/fee-bill/{hashid} | মুছা |
| POST | /admin/fee-bill/batch/generate | ব্যাচে বিল তৈরি |

#### পরিশোধ রেকর্ড

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/fee-payment | তালিকা (?bill_id=&payment_method=&date_start=&date_end=) |
| POST | /admin/fee-payment/offline | অফলাইন আদায় নিবন্ধন |

#### মেরামতের অনুরোধ ব্যবস্থাপনা

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/repair | তালিকা (?status=&category=) |
| POST | /admin/repair | তৈরি |
| GET | /admin/repair/{hashid} | বিস্তারিত (অগ্রগতি রেকর্ডসহ) |
| PUT | /admin/repair/{hashid} | আপডেট |
| DELETE | /admin/repair/{hashid} | মুছা |
| PUT | /admin/repair/{id}/assign | কাজ বরাদ্দ ({ staff_id }) |
| POST | /admin/repair/{id}/progress | অগ্রগতি আপডেট ({ status_to, remark }) |

#### ঘোষণা ব্যবস্থাপনা

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/announcement | তালিকা (?community_id=&category=&is_published=) |
| POST | /admin/announcement | তৈরি |
| GET | /admin/announcement/{hashid} | বিস্তারিত |
| PUT | /admin/announcement/{hashid} | আপডেট |
| DELETE | /admin/announcement/{hashid} | মুছা |

#### পার্কিং ব্যবস্থাপনা

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/parking-space | তালিকা (?community_id=) |
| POST | /admin/parking-space | পার্কিং স্পট তৈরি |
| PUT | /admin/parking-space/{hashid} | আপডেট |
| DELETE | /admin/parking-space/{hashid} | মুছা |
| GET | /admin/parking-vehicle | তালিকা (?owner_id=&space_id=) |
| POST | /admin/parking-vehicle | যানবাহন তৈরি |
| PUT | /admin/parking-vehicle/{hashid} | আপডেট |
| DELETE | /admin/parking-vehicle/{hashid} | মুছা |
| GET | /admin/parking-record | পার্কিং রেকর্ড (?vehicle_id=&date_start=&date_end=) |

#### যন্ত্রপাতি ব্যবস্থাপনা

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/equipment | তালিকা (?community_id=&category=&status=) |
| POST | /admin/equipment | তৈরি |
| PUT | /admin/equipment/{hashid} | আপডেট |
| DELETE | /admin/equipment/{hashid} | মুছা |
| GET | /admin/equipment-maintenance | রক্ষণাবেক্ষণ রেকর্ড (?equipment_id=) |
| POST | /admin/equipment-maintenance | রক্ষণাবেক্ষণ তৈরি |

#### অভিযোগ প্রসেসিং

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/complaint | তালিকা (?type=&status=) |
| GET | /admin/complaint/{hashid} | বিস্তারিত |
| PUT | /admin/complaint/{id}/handle | প্রসেস ({ handler_remark }) |
| POST | /admin/complaint/{id}/visit | ফলো-আপ ({ visitor_remark }) |

#### দর্শনার্থী অনুমোদন

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/visitor | তালিকা (?status=) |
| PUT | /admin/visitor/{id}/approve | অনুমোদন |

#### চুক্তি ব্যবস্থাপনা

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/contract | তালিকা (?contract_type=&status=) |
| POST | /admin/contract | তৈরি |
| PUT | /admin/contract/{hashid} | আপডেট |
| DELETE | /admin/contract/{hashid} | মুছা |

#### আর্থিক ব্যবস্থাপনা

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/finance-income | আয় তালিকা (?income_type=&date_start=&date_end=) |
| POST | /admin/finance-income | আয় নিবন্ধন |
| GET | /admin/finance-expense | ব্যয় তালিকা |
| POST | /admin/finance-expense | ব্যয় নিবন্ধন |
| GET | /admin/finance/statistics | মাসিক আয়-ব্যয় পরিসংখ্যান (?year=) |

#### সম্পত্তি প্যানেল

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/dashboard/property | সম্পত্তি পরিসংখ্যান (প্রাপ্য/ভর্তির হার/মেরামত/অভিযোগ/আয়-ব্যয় ট্রেন্ড) |
| POST | /admin/export/property-excel | সম্পত্তি ডেটা Excel এক্সপোর্ট ({ type: owners|bills }) |

#### নিরাপত্তা টহল

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/security-patrol | তালিকা (?community_id=) |
| POST | /admin/security-patrol | রুট তৈরি |
| GET | /admin/patrol-record | রেকর্ড (?patrol_id=&staff_id=) |
| POST | /admin/patrol-record | রেকর্ড তৈরি |

#### পরিচ্ছন্নতা ব্যবস্থাপনা

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/cleaning-area | এলাকা তালিকা |
| POST | /admin/cleaning-area | এলাকা তৈরি |
| GET | /admin/cleaning-record | রেকর্ড (?area_id=) |
| POST | /admin/cleaning-record | রেকর্ড তৈরি |

#### সবুজায়ন ব্যবস্থাপনা

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/green-area | এলাকা তালিকা |
| POST | /admin/green-area | এলাকা তৈরি |
| GET | /admin/green-maintenance | যত্ন রেকর্ড (?area_id=) |
| POST | /admin/green-maintenance | রেকর্ড তৈরি |

#### কমিউনিটি কার্যক্রম

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/activity | তালিকা (?status=) |
| POST | /admin/activity | কার্যক্রম তৈরি |
| PUT | /admin/activity/{hashid} | আপডেট |
| DELETE | /admin/activity/{hashid} | মুছা |
| GET | /admin/activity-signup | নিবন্ধন তালিকা (?activity_id=) |
| PUT | /admin/activity-signup/{id}/checkin | চেক-ইন |

#### শক্তি ব্যবস্থাপনা

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/energy-meter | মিটার তালিকা (?room_id=&meter_type=) |
| POST | /admin/energy-meter | মিটার তৈরি |
| GET | /admin/energy-record | রিডিং রেকর্ড (?meter_id=&date_start=&date_end=) |
| POST | /admin/energy-record | রেকর্ড তৈরি |

#### কর্মচারী ব্যবস্থাপনা

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/staff | তালিকা (?community_id=&status=) |
| POST | /admin/staff | তৈরি |
| PUT | /admin/staff/{hashid} | আপডেট |
| DELETE | /admin/staff/{hashid} | মুছা |
| POST | /admin/staff/batch/status | ব্যাচ সক্রিয়/নিষ্ক্রিয় |

#### বার্তা বিজ্ঞপ্তি

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/notification-template | টেমপ্লেট তালিকা |
| POST | /admin/notification-template | টেমপ্লেট তৈরি |
| PUT | /admin/notification-template/{hashid} | টেমপ্লেট আপডেট |
| DELETE | /admin/notification-template/{hashid} | টেমপ্লেট মুছা |
| GET | /admin/notification | বার্তা তালিকা (?type=&is_read=) |
| POST | /admin/notification/send | ম্যানুয়াল বিজ্ঞপ্তি পাঠানো |

#### অনুমোদন ওয়ার্কফ্লো

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/approval-type | অনুমোদন ধরন তালিকা |
| POST | /admin/approval-type | অনুমোদন ধরন তৈরি |
| GET | /admin/approval | অনুমোদন তালিকা (?status=) |
| GET | /admin/approval/{hashid} | অনুমোদন বিস্তারিত |
| POST | /admin/approval | অনুমোদন জমা |
| PUT | /admin/approval/{hashid}/approve | অনুমোদন (পাস/প্রত্যাখ্যান) |

#### পেমেন্ট ব্যবস্থাপনা

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/payment-order | অর্ডার তালিকা |
| GET | /admin/payment-order/{hashid} | অর্ডার বিস্তারিত |
| POST | /admin/payment-order/{hashid}/refund | রিফান্ড |
| GET | /admin/payment/statistics | পেমেন্ট পরিসংখ্যান |

#### মালিক ভোট

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /admin/vote | ভোট তালিকা (?status=) |
| POST | /admin/vote | ভোট তৈরি |
| GET | /admin/vote/{hashid}/statistics | ভোট গণনা পরিসংখ্যান |
| PUT | /admin/vote/{hashid}/publish | ভোট প্রকাশ |
| PUT | /admin/vote/{hashid}/end | ভোট শেষ |

#### SLA ব্যবস্থাপনা · স্মার্ট আদায় · পরিদর্শন ব্যবস্থাপনা · মল ব্যবস্থাপনা · ফেসিয়াল ব্যবস্থাপনা · গ্রুপ ব্যবস্থাপনা · জ্ঞানভাণ্ডার

(সম্পূর্ণ এন্ডপয়েন্ট দেখুন `docs/API.md` ফাইলে)

---

## ব্যবসা পাশ API (service :8788)

### পাবলিক ইন্টারফেস — অথেনটিকেশন লাগবে না

#### POST /api/captcha/generate
ক্লিক ক্যাপচা পাওয়া। (অ্যাডমিন প্যানেলের সাথে একই)

#### POST /api/captcha/verify
ক্লিক ক্যাপচা যাচাই। (রিকোয়েস্ট/রেসপন্স অ্যাডমিন প্যানেলের সাথে একই)

#### POST /api/auth/login
মালিক লগইন।

রিকোয়েস্ট প্যারামিটার:
| প্যারামিটার | ধরন | ব্যাখ্যা |
|------|------|------|
| phone | string | মোবাইল নম্বর |
| password | string | পাসওয়ার্ড |
| captcha_key | string | ক্যাপচা key |
| clicks | array | ক্লিক কোঅর্ডিনেট |

রেসপন্স:
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
মালিক রেজিস্ট্রেশন।

রিকোয়েস্ট প্যারামিটার:
| প্যারামিটার | ধরন | ব্যাখ্যা |
|------|------|------|
| phone | string | মোবাইল নম্বর |
| password | string | পাসওয়ার্ড (অন্তত ৬ অক্ষর) |
| name | string | নাম |
| captcha_key | string | ক্যাপচা key |
| clicks | array | ক্লিক কোঅর্ডিনেট |
| room_id | string | (ঐচ্ছিক) বাঁধাই করার বাড়ির hashid |
| id_card_last4 | string | (ঐচ্ছিক) আইডি কার্ডের শেষ ৪ সংখ্যা |

#### POST /api/auth/refresh
Token রিফ্রেশ।

---

### মালিক পোর্টাল ইন্টারফেস — অথেনটিকেশন প্রয়োজন (Bearer Token)

সব ইন্টারফেসের প্রিফিক্স `/service`, `Authorization: Bearer {access_token}` বহন করতে হবে।

#### হোমপেজ

**GET /service/home**

রেসপন্স:
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

#### আমার সম্পত্তি

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /service/rooms | আমার সম্পত্তির তালিকা |
| GET | /service/room/{hashid} | সম্পত্তি বিস্তারিত (এলাকা, অভিমুখ, সম্পত্তি অধিকার, কমিউনিটি তথ্যসহ) |

#### ফি ব্যবস্থাপনা

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /service/fees/bills | বিল তালিকা (?status=0 অবৈতনিক/1 আংশিক/2 পরিশোধিত/3 বিলম্বিত) |
| GET | /service/fees/bill/{hashid} | বিল বিস্তারিত (ফি ধরন, পরিশোধ রেকর্ডসহ) |
| GET | /service/fees/payments | পরিশোধ রেকর্ড |
| POST | /service/fees/pay | অনলাইন ফি পরিশোধ ({ bill_id, payment_method, password }) |
| GET | /service/fees/statistics | ফি পরিসংখ্যান (?year=2026) |

#### মেরামতের অনুরোধ

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /service/repairs | মেরামত তালিকা (?status=) |
| GET | /service/repair/{hashid} | মেরামত বিস্তারিত (অগ্রগতি টাইমলাইনসহ) |
| POST | /service/repair | মেরামত জমা ({ room_id, category, urgency, description, images[], scheduled_at }) |
| DELETE | /service/repair/{hashid} | বাতিল (পাসওয়ার্ড লাগবে, { password }) |
| POST | /service/repair/{hashid}/rate | রেটিং ({ rating: 1-5, feedback }) |

#### অভিযোগ ও পরামর্শ

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /service/complaints | অভিযোগ তালিকা |
| GET | /service/complaint/{hashid} | অভিযোগ বিস্তারিত (প্রসেসিং অগ্রগতিসহ) |
| POST | /service/complaint | অভিযোগ জমা ({ type, category, title, content, is_anonymous, images[] }) |
| POST | /service/complaint/{hashid}/satisfaction | সন্তুষ্টি রেটিং ({ satisfaction: 1-5 }) |

#### ঘোষণা

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /service/announcements | ঘোষণা তালিকা (?category=) |
| GET | /service/announcement/{hashid} | ঘোষণা বিস্তারিত |

#### পার্কিং

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /service/parking/vehicles | আমার যানবাহন |
| GET | /service/parking/spaces | আমার পার্কিং স্পট |
| GET | /service/parking/records | পার্কিং রেকর্ড |

#### দর্শনার্থী

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /service/visitors | আমার দর্শনার্থী অ্যাপয়েন্টমেন্ট |
| POST | /service/visitor | অ্যাপয়েন্টমেন্ট তৈরি (প্রবেশ কোড জেনারেট) |
| PUT | /service/visitor/{hashid} | অ্যাপয়েন্টমেন্ট পরিবর্তন |
| DELETE | /service/visitor/{hashid} | অ্যাপয়েন্টমেন্ট বাতিল |

#### কমিউনিটি কার্যক্রম

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /service/activities | কার্যক্রম তালিকা (?status=) |
| GET | /service/activity/{hashid} | কার্যক্রম বিস্তারিত |
| POST | /service/activity/{hashid}/signup | নিবন্ধন |
| POST | /service/activity/{hashid}/cancel | নিবন্ধন বাতিল |

#### ব্যক্তিগত তথ্য

| মেথড | পাথ | ব্যাখ্যা |
|------|------|------|
| GET | /service/profile | ব্যক্তিগত তথ্য |
| PUT | /service/profile | পরিবর্তন ({ name, email, gender, birthday }) |
| PUT | /service/profile/password | পাসওয়ার্ড পরিবর্তন ({ old_password, new_password }) |
| POST | /service/profile/logout | লগআউট |

---

## ওপেন API — API Key অথেনটিকেশন

ইনবাউন্ড আউটওয়ার্ড রিড-অনলি ইন্টারফেস, তৃতীয় পক্ষের সিস্টেম (সম্পত্তি প্ল্যাটফর্ম ইন্টিগ্রেশন, ডেটা ড্যাশবোর্ড ইত্যাদি) কল করার জন্য। প্রিফিক্স `/open`, সম্পূর্ণ রিড-অনলি।

### অথেনটিকেশন পদ্ধতি

প্রতিটি রিকোয়েস্টে রিকোয়েস্ট হেডার `X-API-Key` বহন করতে হবে, মান `scripts/gen_api_key.php` দিয়ে তৈরি Key (৬৪ অক্ষর hex, ডেটাবেসে শুধু SHA-256 ডাইজেস্ট সংরক্ষিত):

```bash
curl -H "X-API-Key: <আপনারKey>" http://localhost:8788/open/announcements
```

- অনুপস্থিত বা ভুল Key-তে `401` ফেরে (`{"code":401,"message":"无效的API Key","data":[]}`)
- Key ব্যবস্থাপনা: `php scripts/gen_api_key.php [--name=ব্যবহার]` দিয়ে তৈরি; নিষ্ক্রিয়/মুছতে সরাসরি `erik_api_key` টেবিলে অপারেশন (`status=0` অর্থাৎ নিষ্ক্রিয়, কী অবিলম্বে অকার্যকর)

### এন্ডপয়েন্ট

#### GET /open/announcements — ঘোষণা তালিকা

প্যারামিটার: `page` (ডিফল্ট 1) `category` (ঐচ্ছিক)। রেসপন্স কাঠামো `/service/announcements`-এর সাথে একই।

```bash
curl -H "X-API-Key: <আপনারKey>" "http://localhost:8788/open/announcements?page=1"
```

#### GET /open/bills — বিল কোয়েরি

প্যারামিটার: `bill_number` (বাধ্যতামূলক, বিল নম্বর)। একক বিল বিস্তারিত ফেরে (ফি ধরন, বাড়ির নম্বর, বকেয়া পরিমাণসহ)। অস্তিত্ব না থাকলে 404।

```bash
curl -H "X-API-Key: <আপনারKey>" "http://localhost:8788/open/bills?bill_number=B202608160001"
```

#### GET /open/repairs — মেরামত অবস্থা কোয়েরি

প্যারামিটার: `order_number` (বাধ্যতামূলক, মেরামত অর্ডার নম্বর)। মেরামত অর্ডারের বর্তমান অবস্থা ও অগ্রগতি টাইমলাইন (`progress` অ্যারে) ফেরে। অস্তিত্ব না থাকলে 404।

```bash
curl -H "X-API-Key: <আপনারKey>" "http://localhost:8788/open/repairs?order_number=R202608160001"
```

---

## এরে কোড

| code | অর্থ | ব্যাখ্যা |
|------|------|------|
| 0 | সফল | স্বাভাবিক রেসপন্স |
| 400 | রিকোয়েস্ট ভুল | প্যারামিটার ফরম্যাট সঠিক নয় |
| 401 | অথেনটিকেটেড নয় | Token অনুপস্থিত/মেয়াদোত্তীর্ণ/অবৈধ/ব্ল্যাকলিস্টে |
| 403 | পারমিশন নেই | ব্যবহারকারীর রোলে প্রয়োজনীয় পারমিশন নেই / অ্যাকাউন্ট নিষ্ক্রিয় |
| 404 | অস্তিত্ব নেই | রিসোর্স পাওয়া যায়নি |
| 405 | মেথড অনুমোদিত নয় | GET/POST/PUT/DELETE/OPTIONS ছাড়া অন্য HTTP মেথড |
| 413 | রিকোয়েস্ট বডি অতিরিক্ত বড় | 10MB-র বেশি |
| 415 | অসমর্থিত মিডিয়া টাইপ | Content-Type JSON বা form-urlencoded নয় |
| 422 | যাচাই ব্যর্থ | ফর্ম প্যারামিটার নিয়ম মেনে চলে না / পাসওয়ার্ড নিশ্চিতকরণ ব্যর্থ / ক্যাপচা ভুল |
| 429 | রিকোয়েস্ট অতিরিক্ত ঘন | রেট লিমিট ট্রিগার / অ্যাকাউন্ট লক |
| 500 | সার্ভার ত্রুটি | অপ্রত্যাশিত এক্সেপশন |

## রেট লিমিট রেসপন্স হেডার

রেট লিমিট ট্রিগার হলে 429 ফেরে, রেসপন্স হেডারে থাকে:

| রেসপন্স হেডার | ব্যাখ্যা |
|--------|------|
| X-RateLimit-Limit | সীমিত সংখ্যা |
| X-RateLimit-Remaining | অবশিষ্ট সংখ্যা |
| X-RateLimit-Reset | রিসেট সময় (Unix টাইমস্ট্যাম্প) |
| Retry-After | পুনরায় চেষ্টার অপেক্ষার সেকেন্ড সংখ্যা |
