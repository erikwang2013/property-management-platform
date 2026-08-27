# আর্কিটেকচার ডিজাইন ডকুমেন্ট (Architecture Design)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## 1. সিস্টেম আর্কিটেকচার ওভারভিউ

সম্পত্তি ব্যবস্থাপনা সিস্টেম "ডুয়াল ব্যাকএন্ড + মাল্টি ফ্রন্টএন্ড" লেয়ার্ড আর্কিটেকচার গ্রহণ করে। অ্যাডমিন প্যানেল (admin) ও মালিক ব্যবসা পাশ (service) দুটি আলাদা webman v2 প্রজেক্ট, শেয়ার্ড MySQL ডেটাবেস দিয়ে সমন্বিতভাবে কাজ করে। ফ্রন্টএন্ড Flutter Web (PC ম্যানেজমেন্ট ব্যাকএন্ড স্টাইল) ও HarmonyOS মোবাইল পাশ কভার করে।

### ডিজাইন লক্ষ্য

- **স্বাধীন ডিপ্লয়মেন্ট**: admin ও service প্রত্যেকে আলাদাভাবে চালু/বন্ধ, আলাদা স্কেল, আলাদা কী ম্যানেজমেন্ট
- **শেয়ার্ড ডেটা**: একই MySQL ডেটাবেস শেয়ার, ডেটা সিঙ্ক সমস্যা এড়ায়
- **ইউনিফাইড স্ট্যান্ডার্ড**: দুটি প্রজেক্ট একই কোড স্ট্যান্ডার্ড, কনফিগ স্টাইল, নিরাপত্তা নীতি অনুসরণ করে
- **PC-ফার্স্ট ওয়েব পাশ**: Flutter Web ডেস্কটপ ম্যানেজমেন্ট ব্যাকএন্ড স্টাইলে ডিজাইন করা (সাইডবার + টপবার + কনটেন্ট এরিয়া)

## 2. লেয়ার্ড আর্কিটেকচার

```
┌─────────────────────────────────────────────────────────────┐
│                        路由层 (Route Layer)                   │
│   config/route.php — URL → Controller 映射 + 中间件绑定       │
├─────────────────────────────────────────────────────────────┤
│                       中间件层 (Middleware Layer)              │
│   SecurityFilter → RateLimit → ApiVersion → Auth → Permission │
├─────────────────────────────────────────────────────────────┤
│                      控制器层 (Controller Layer)               │
│   BaseController → 请求验证 → ID编解码 → 业务逻辑 → 响应格式化  │
├─────────────────────────────────────────────────────────────┤
│                        服务层 (Service Layer)                  │
│   HashidsService | SnowflakeService | EncryptionService       │
├─────────────────────────────────────────────────────────────┤
│                        模型层 (Model Layer)                    │
│   Eloquent ORM + encryptable 自动加解密 + scout ES 同步        │
├─────────────────────────────────────────────────────────────┤
│                        驱动层 (Driver Layer)                   │
│   MySQL PDO | Elasticsearch HTTP | Redis                      │
└─────────────────────────────────────────────────────────────┘
```

## 3. মিডলওয়্যার এক্সিকিউশন চেইন

### অ্যাডমিন প্যানেল (admin)
```
Cors → SecurityFilter(方法检查→405) → RateLimit(限流) 
  → AdminAuth(JWT验证) → AdminPermission(RBAC鉴权)
    → OperationLog(操作记录) → Controller
```

### ব্যবসা পাশ (service)
```
Cors → SecurityFilter(方法检查→405) → RateLimit(限流)
  → ApiVersion(版本校验) → Controller           # /api/* 公开接口
  → ServiceAuth(JWT业主认证) → Controller       # /service/* 认证接口
```

### গ্লোবাল মিডলওয়্যার ব্যাখ্যা

| মিডলওয়্যার | অবস্থান | দায়িত্ব |
|--------|------|------|
| Cors | গ্লোবাল প্রথম | ক্রস-অরিজিন রিসোর্স শেয়ারিং হেডার প্রসেসিং |
| SecurityFilter | গ্লোবাল | HTTP মেথড হোয়াইটলিস্ট, XSS/SQL ইনজেকশন/পাথ ট্রাভার্সাল/কমান্ড ইনজেকশন/CSRF অ্যাটাক ইন্টারসেপ্ট, IP ব্ল্যাকলিস্ট |
| RateLimit | গ্লোবাল | Redis স্লাইডিং উইন্ডো রেট লিমিট (Lua অ্যাটমিক), ডিফল্ট ৬০ বার/মিনিট |
| ApiVersion | /api রুট | রিকোয়েস্ট হেডার API-Version যাচাই, ভার্সন নম্বর ইনজেক্ট |
| AdminAuth | /admin রুট | JWT Token যাচাই, adminId ইনজেক্ট |
| AdminPermission | /admin রুট | RBAC method.path পারমিশন যাচাই (Redis 60s ক্যাশে) |
| OperationLog | /admin রুট | POST/PUT/DELETE অপারেশন স্বয়ংক্রিয় রেকর্ড (উৎস পাশ সনাক্তসহ) |
| ServiceAuth | /service রুট | JWT Token যাচাই, ownerId ইনজেক্ট |

## 4. ID সম্পূর্ণ লাইফসাইকেল

```
生成: SnowflakeService::generate()
      datacenter_id(5bit) + worker_id(5bit) + timestamp(41bit) + sequence(12bit)
      → BIGINT(18) 例: 1750123456789

存储: MySQL erik_* 表
      id BIGINT UNSIGNED NOT NULL (非自增) 
      敏感字段 encryptable cast → AES-256-CBC 加密存储

传输: HashidsService::encode(bigint) → hashid 字符串 例: aB3xK9mW2pQ7rT5v
      API 请求/响应中的所有 ID 字段统一使用 hashid

解码: HashidsService::decode(hashid) → BIGINT
      无效 hashid 抛出 InvalidArgumentException
```

## 5. ডেটা এনক্রিপশন লেয়ারিং

### ট্রান্সমিশন লেয়ার (encryption)
- AES-256-CBC এনক্রিপশন
- ক্লায়েন্ট সংবেদনশীল ডেটা পাঠানোর আগে এনক্রিপ্ট করে, সার্ভার গ্রহণের পর ডিক্রিপ্ট করে
- আলাদা কী `ENCRYPTION_KEY`

### স্টোরেজ লেয়ার (encryptable)
- Model `$casts` মেকানিজম স্বয়ংক্রিয় এনক্রিপশন/ডিক্রিপশন
- সংবেদনশীল ফিল্ড: phone, email, id_card, emergency_contact, emergency_phone
- আলাদা কী `ENCRYPTABLE_KEY`
- লেখার সময় স্বয়ংক্রিয়ভাবে সাইফারটেক্সটে এনক্রিপ্ট, পড়ার সময় স্বয়ংক্রিয়ভাবে প্লেইনটেক্সটে ডিক্রিপ্ট

### ডিসপ্লে লেয়ার (ডিমাস্কিং)
- মোবাইল: `138****1234`
- ইমেইল: `a***@example.com`
- আইডি কার্ড: `********`
- Excel/PDF এক্সপোর্ট স্বয়ংক্রিয় ডিমাস্কিং

## 6. প্রমাণীকরণ ও পারমিশন

### JWT প্রমাণীকরণ
- অ্যালগরিদম: HS256
- access_token: ২ ঘণ্টা বৈধতা
- refresh_token: ১৪ দিন বৈধতা
- কনকারেন্সি সীমা: একই ব্যবহারকারীর সর্বোচ্চ ৩টি বৈধ Token, বেশি হলে সবচেয়ে পুরনো Token ব্ল্যাকলিস্টে
- অ্যাকাউন্ট লক: টানা ৫ বার লগইন ব্যর্থে ১৫ মিনিট লক

### RBAC পারমিশন মডেল
- ব্যবহারকারী → রোল → পারমিশন (মাল্টি-টু-মাল্টি)
- পারমিশন ধরন: type=1(মেনু) / type=2(বাটন) / type=3(API)
- পারমিশন চিহ্ন ফরম্যাট: `{method}.{path}` উদাহরণ: `get.admin/user`
- সুপার অ্যাডমিন চিহ্ন: `*` (সব পারমিশন চেক স্কিপ)
- পারমিশন ট্রি: সেলফ-রেফারেন্স parent_id অসীম লেভেল সমর্থন

## 7. নিরাপত্তা গভীর প্রতিরক্ষা (১৮ স্তর)

```
第1层  点击验证码      → 登录/注册强制人机验证
第2层  密码二次确认    → 敏感操作 (删除/缴费/合同终止) 必须输入密码
第3层  poster随机验证  → 高频敏感操作随机弹出验证码
第4层  security-php    → 请求周期内自动安全扫描
第5层  SecurityFilter  → XSS/SQL注入/路径遍历/命令注入/CSRF 攻击拦截
第6层  传输安全        → HTTPS + AES-256-CBC
第7层  JWT 认证        → HS256, 2h过期 + refresh token
第8层  并发控制        → 同一用户最多3个Token, 超出黑名单
第9层  账号锁定        → 连续5次失败锁定15分钟
第10层 RBAC 鉴权       → method.path 粒度权限控制
第11层 限流保护        → Redis 滑动窗口 Lua原子化
第12层 熔断保护        → Redis 熔断器（支付/回调快速失败+半开探测）
第13层 ID 保护         → Hashids 编码, 不可逆推真实ID
第14层 请求体加密      → AES-256-CBC 敏感字段
第15层 存储加密        → encryptable DB字段加密
第16层 展示脱敏        → 手机号/邮箱/身份证脱敏
第17层 审计追溯        → OperationLog 全量记录 (含来源端 source 自动检测) 
第18层 HTTP 头防护     → CSP + X-Permitted-Cross-Domain-Policies
第19层 出口保护        → PDF 版权水印 (不可移除) + Excel 敏感数据脱敏
```

## 8. রেট লিমিট কৌশল

Redis Sorted Set স্লাইডিং উইন্ডো অ্যালগরিদম, Lua স্ক্রিপ্ট অ্যাটমিক এক্সিকিউশন:

| ইন্টারফেস | সীমা |
|------|------|
| ডিফল্ট | ৬০ বার/মিনিট/IP/রুট |
| POST /api/auth/login | ১০ বার/মিনিট |
| POST /api/auth/register | ৫ বার/মিনিট |

সীমা অতিক্রমে 429 + `X-RateLimit-Limit/Remaining/Reset/Retry-After` রেসপন্স হেডার।

## 9. API ভার্সন কৌশল

- ভার্সন রিকোয়েস্ট হেডার `API-Version` দিয়ে নিয়ন্ত্রিত (ডিফল্ট `v1`), URL-তে প্রকাশ পায় না
- অসমর্থিত ভার্সনে 400 ফেরে
- কন্ট্রোলার ভার্সন অনুযায়ী সংগঠিত: `app/api/{version}/controller/`
- নতুন ভার্সন যোগ করতে শুধু ডিরেক্টরি তৈরি করে `ApiVersion` মিডলওয়্যারে রেজিস্টার করুন

## 10. ডিপ্লয়মেন্ট আর্কিটেকচার

```
┌─────────────────────────────────────┐
│            CloudFlare DNS + CDN      │
└────────────────┬────────────────────┘
                 │
┌────────────────▼────────────────────┐
│          Nginx (:443)                │
│   反向代理 + Gzip + SSL 终结         │
│   静态文件: Flutter Web build/       │
└──────┬──────────────────┬───────────┘
       │                  │
┌──────▼──────┐    ┌──────▼──────┐
│ admin webman│    │service webman│
│ :8787       │    │ :8788       │
│ 管理后台API │    │ 业主端API    │
└──────┬──────┘    └──────┬──────┘
       │                  │
       └────────┬─────────┘
                │
┌───────────────┼───────────────────┐
│               │                   │
┌▼──────┐  ┌────▼───┐  ┌──────────▼┐
│MySQL  │  │ Redis  │  │Elasticsearch│
│:3306  │  │ :6379  │  │ :9200      │
└───────┘  └────────┘  └────────────┘
```

### Docker Compose সার্ভিস

| সার্ভিস | ইমেজ | ব্যাখ্যা |
|------|------|------|
| nginx | nginx:alpine | রিভার্স প্রক্সি + স্ট্যাটিক ফাইল |
| admin | Dockerfile দিয়ে তৈরি | PHP 8.3 + OPcache |
| service | Dockerfile দিয়ে তৈরি | PHP 8.3 + OPcache |
| mysql | mysql:8.0 | ডেটা ভলিউম স্থায়ীকরণ |
| redis | redis:7-alpine | ক্যাশে/রেট লিমিট/Session |
| elasticsearch | elasticsearch:8.x | ফুল-টেক্সট সার্চ |

## 11. আন্তর্জাতিকীকরণ ডিজাইন (i18n)

### ভাষা ফাইল কাঠামো

সিস্টেম সরলীকৃত চীনা (zh_CN) ও ইংরেজি (en) সমর্থন করে, ডিফল্ট চীনা।

**PHP ব্যাকএন্ড:**
```
resource/translations/
├── zh_CN/
│   └── messages.php    # 中文语言包 (42+翻译键) 
└── en/
    └── messages.php    # 英文语言包
```

symfony/translation ড্রাইভার, কনফিগ `config/translation.php`-এ:
- `locale`: `zh_CN`
- `fallback_locale`: `['zh_CN', 'en']`
- `path`: `resource/translations`

কন্ট্রোলারে `$this->__('key')` দিয়ে ট্রান্সলেশন পাওয়া যায়:
```php
return $this->success([], $this->__('create_success'));
return $this->fail($this->__('community.name_required'), 422);
```

`__()` মেথড ভেতরে webman-এর `trans()` গ্লোবাল ফাংশন কল করে, ট্রান্সলেশন না থাকলে key নিজেই ফেরত দেয়।

**Flutter Web:**
```
apps/flutter/lib/i18n/
└── messages.dart       # AppTranslations extends GetX Translations
```

GetX `Translations` ব্যবহার, ১০১টি ট্রান্সলেশন কী। `.tr` এক্সটেনশন দিয়ে ব্যবহার:
```dart
Text('login_btn'.tr)   // 中文: "登 录", 英文: "Login"
Text('phone_hint'.tr)  // "请输入手机号" / "Enter phone number"
```

ভাষা পরিবর্তন:
```dart
Get.updateLocale(Locale('zh', 'CN'));  // 切换中文
Get.updateLocale(Locale('en', 'US'));  // 切换英文
```

### ট্রান্সলেশন কী শ্রেণিবিভাগ

| শ্রেণি | PHP কী উদাহরণ | Flutter কী উদাহরণ |
|------|-----------|---------------|
| সাধারণ | `success`, `fail`, `not_found` | `confirm`, `cancel`, `save` |
| প্রমাণীকরণ | `auth.login_success`, `auth.*` | `login_btn`, `phone_hint` |
| কমিউনিটি | `community.name_required` | - |
| ফি | `fee.bill_not_found`, `fee.*` | `fee_management`, `bill_status` |
| মেরামত | `repair.not_found`, `repair.*` | `repair_submit`, `urgency_normal` |
| অভিযোগ | `complaint.submit_success` | `complaint_type`, `type_complaint` |
| ব্যক্তিগত | - | `profile`, `change_password` |

**HarmonyOS:** `resources/base/element/string.json` + `resources/en_US/element/string.json` রিসোর্স কোয়ালিফায়ার ব্যবহার (HarmonyOS প্রজেক্ট তৈরি করার সময় সমান্তরালভাবে বাস্তবায়িত)।

## 12. টেস্ট কৌশল

### TDD টেস্ট প্রক্রিয়া

প্রজেক্ট TDD (টেস্ট-ড্রিভেন ডেভেলপমেন্ট) প্রক্রিয়া অনুসরণ করে: লাল→সবুজ→রিফ্যাক্টর।

```
RED: 先写测试, 观察失败
  ↓
GREEN: 写最小代码使测试通过
  ↓
REFACTOR: 清理代码, 保持测试绿
```

### টেস্ট কভারেজ

| স্তর | টেস্ট ফ্রেমওয়ার্ক | টেস্ট বিষয়বস্তু |
|----|---------|---------|
| বেস সার্ভিস | PHPUnit | Snowflake ID তৈরি, Hashids এনকোড/ডিকোড, রেসপন্স ফরম্যাট |
| ডেটাবেস | PHPUnit + PDO | টেবিল কাঠামো যাচাই (BIGINT প্রাইমারি কী, নন-অটো-ইনক্রিমেন্ট, erik_ প্রিফিক্স) |
| আন্তর্জাতিকীকরণ | PHPUnit | ট্রান্সলেশন ফাইল অস্তিত্ব, চীনা-ইংরেজি কী সামঞ্জস্য |
| API এন্ডপয়েন্ট | PHPUnit | হেলথ চেক, রেসপন্স ফরম্যাট |
| মিডলওয়্যার | ইন্টিগ্রেশন টেস্ট | JWT প্রমাণীকরণ, রেট লিমিট, পারমিশন |

### টেস্ট চালানো

```bash
cd admin && php vendor/bin/phpunit    # 管理端: 60 tests, 164 assertions
cd service && php vendor/bin/phpunit  # 业务端: 18 tests, 45 assertions, 100% pass
```

## 13. ফ্রন্টএন্ড আর্কিটেকচার

### Flutter Web (PC ডেস্কটপ স্টাইল)

```
apps/flutter/lib/
├── main.dart                    # 入口, 初始化 ApiService + AuthService
├── app.dart                     # GetMaterialApp, 路由表 + 主题 + i18n
├── config/
│   ├── api_config.dart          # API 端点常量 (指向 service :8788) 
│   └── theme.dart               # Material 3 主题 (Ant Design 色系) 
├── services/
│   ├── api_service.dart         # Dio 单例 + JWT 拦截器 + 401 自动刷新
│   ├── auth_service.dart        # 登录/登出/Token 持久化
│   └── storage_service.dart     # shared_preferences 封装
├── i18n/
│   └── messages.dart            # GetX Translations (101键, zh_CN/en) 
├── pages/
│   ├── login/                   # PC 风格登录页 (居中 Card + 表单验证) 
│   ├── home/                    # 仪表盘 (4个 StatCard + 公告列表) 
│   ├── fee/                     # 账单列表 / 详情 / 缴费弹窗
│   ├── repair/                  # 报修列表 / 提交 / 详情 + 评价
│   └── profile/                 # 个人信息 / 修改密码 / 退出
└── widgets/
    └── stat_card.dart           # 统计卡片组件 (图标 + 标题 + 数值) 
```

### HarmonyOS মোবাইল পাশ

```
apps/harmonyos/entry/src/main/ets/
├── services/
│   ├── ApiService.ets           # @ohos.net.http 封装, Bearer Token
│   └── AuthService.ets          # 登录/登出 (Preference 持久化) 
├── model/
│   └── Models.ets               # TypeScript 接口定义
├── pages/
│   ├── LoginPage.ets            # 手机号 + 密码登录
│   └── HomePage.ets             # 仪表盘 (统计卡片 + 公告列表) 
└── resources/
    ├── base/element/string.json # 中文资源
    └── en_US/element/string.json# 英文资源
```

### প্রযুক্তি নির্বাচন

| স্তর | Flutter Web | HarmonyOS |
|----|------------|-----------|
| স্টেট ম্যানেজমেন্ট | GetX | @State + @Prop |
| HTTP | Dio + JWT ইন্টারসেপ্টর | @ohos.net.http |
| স্থায়ীকরণ | shared_preferences | @ohos.data.preferences |
| চার্ট | fl_chart | Web কম্পোনেন্ট + ECharts |
| আন্তর্জাতিকীকরণ | GetX Translations | resource কোয়ালিফায়ার |
| রাউটিং | GetX named routes | router.pushUrl/replaceUrl |

## 14. এক্সটেনশন ফাংশন আর্কিটেকচার

### বার্তা বিজ্ঞপ্তি কেন্দ্র
বার্তা টেমপ্লেট → বিজ্ঞপ্তি তৈরি → মাল্টি-চ্যানেল প্রেরণ (App ভেতরে/এসএমএস/ইমেইল/পুশ)

### অনুমোদন ওয়ার্কফ্লো
অনুমোদন ধরন কনফিগ → ইনস্ট্যান্স জমা → ধাপ ট্রানজিশন (পাস/প্রত্যাখ্যান) → পরবর্তী অনুমোদকের বিজ্ঞপ্তি

### পেমেন্ট প্রক্রিয়া
পেমেন্ট অর্ডার তৈরি → তৃতীয় পক্ষ পেমেন্ট → অ্যাসিঙ্ক কলব্যাক → বিল অবস্থা আপডেট → পেমেন্ট লগ রেকর্ড

### মালিক ভোট
ভোট প্রকাশ → মালিক ভোট (এলাকা-ভারিত) → রিয়েল-টাইম ভোট গণনা → ফলাফল পরিসংখ্যান

### SLA স্বয়ংক্রিয় আপগ্রেড
SLA নিয়ম ম্যাচ → শিডিউল টাইমআউট চেক → স্বয়ংক্রিয় আপগ্রেড → জরিমানা রেকর্ড

### স্মার্ট আদায়
আদায় কৌশল ম্যাচ → বকেয়া সনাক্ত → স্বয়ংক্রিয় আদায় টাস্ক তৈরি → আদায় ক্রিয়া সম্পাদন

### পরিদর্শন ব্যবস্থাপনা
টাস্ক বিতরণ → মোবাইল GPS চেক-ইন → ছবি আপলোড → অস্বাভাবিকতা চিহ্ন → সমাপ্তি পরিসংখ্যান

### গ্রুপ ব্যবস্থাপনা
গ্রুপ → কমিউনিটি সম্পর্ক → ক্রস-কমিউনিটি ডেটা সামারি (সম্পত্তি/মালিক/আদায়/মেরামত)

## 15. API ডকুমেন্টেশন

`hg/apidoc` দিয়ে কন্ট্রোলার অ্যানোটেশন থেকে স্বয়ংক্রিয় ইন্টারফেস ডকুমেন্ট তৈরি, ফাংশন অনুযায়ী গ্রুপ করা।

**অ্যাডমিন প্যানেল** (`http://localhost:8787/apidoc`): ১০ গ্রুপ — ৫৭টি কন্ট্রোলারে অ্যানোটেশন ইনজেক্ট (Base/Docs/Install গ্রুপবিহীন)

| গ্রুপ | সংখ্যা | কন্ট্রোলার |
|------|------|--------|
| `common` | 2 | Auth, Captcha |
| `dashboard` | 3 | Dashboard, Metrics, Health |
| `export` | 1 | Export |
| `import` | 1 | Import |
| `upload` | 1 | Upload |
| `system` | 6 | User, Role, Permission, Config, Log, Profile |
| `property-core` | 12 | Community, Building, Unit, RoomType, Room, Owner, Tenant, FeeType, FeeBill, FeePayment, Repair, Announcement |
| `property-aux` | 9 | Parking(3), Equipment(2), Complaint, Visitor, Contract, Finance |
| `property-adv` | 11 | Activity(2), Patrol(2), Cleaning(2), Green(2), Energy(2), Staff |
| `extensions` | 11 | Notification, Approval, Payment, Vote, Sla, Collection, Inspection, Mall, Face, Group, Knowledge |

**ব্যবসা পাশ** (`http://localhost:8788/apidoc`): ৯ গ্রুপ — ১৭টি কন্ট্রোলারে অ্যানোটেশন ইনজেক্ট

| গ্রুপ | সংখ্যা | কন্ট্রোলার |
|------|------|--------|
| `public` | 2 | Auth, Captcha |
| `home` | 2 | Home, Room |
| `fee` | 1 | Fee |
| `repair` | 1 | Repair |
| `feedback` | 2 | Complaint, Announcement |
| `parking` | 2 | Parking, Visitor |
| `activity` | 1 | Activity |
| `profile` | 1 | Profile |
| `extensions` | 5 | Notification, Vote, Mall, Knowledge, Face |

### অ্যানোটেশন স্ট্যান্ডার্ড

```php
/**
 * 小区列表
 * @Apidoc\Method("GET")
 * @Apidoc\Url("/admin/community")
 * @Apidoc\Group("property-core")
 * @Apidoc\Sort(1)
 * @Apidoc\Param("keyword", type="string", require=false, desc="搜索关键词")
 * @Apidoc\Param(ref="pagination")
 * @Apidoc\Returned("id", type="string", desc="hashid")
 */
```

### সাধারণ ডেফিনিশন ব্লক

| ব্লক নাম | বিষয়বস্তু |
|------|------|
| `pagination` | page/page_size পেজিনেশন প্যারামিটার |
| `searchParams` | keyword/status সার্চ ফিল্টার |
| `dateRange` | start_date/end_date তারিখ রেঞ্জ |
| `passwordConfirm` | password পাসওয়ার্ড নিশ্চিতকরণ |

## 16. ইউনিফাইড রেসপন্স ফরম্যাট

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

| code | অর্থ |
|------|------|
| 0 | সফল |
| 400 | প্যারামিটার ভুল |
| 401 | অথেনটিকেটেড নয় |
| 403 | পারমিশন নেই |
| 404 | অস্তিত্ব নেই |
| 422 | যাচাই ব্যর্থ |
| 429 | রিকোয়েস্ট অতিরিক্ত ঘন |
| 500 | সার্ভার ত্রুটি |
