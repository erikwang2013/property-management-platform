# 아키텍처 설계 문서 (Architecture Design)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## 1. 시스템 아키텍처 개요

부동산 관리 시스템은 「이중 백엔드 + 다중 프론트엔드」 계층 아키텍처를 채택합니다. 관리자측（admin）과 입주민 포털（service）은 독립된 두 개의 webman v2 프로젝트로, 공유 MySQL 데이터베이스를 통해 협력합니다. 프론트엔드는 Flutter Web（PC 관리 콘솔 스타일）과 HarmonyOS 모바일을 포함합니다.

### 설계 목표

- **독립 배포**: admin과 service는 각각 독립적으로 시작/중지, 독립 확장/축소, 독립 키 관리
- **데이터 공유**: 동일한 MySQL 데이터베이스 공유, 데이터 동기화 문제 방지
- **통일 규범**: 두 프로젝트가 동일한 코드 규범, 설정 스타일, 보안 정책 준수
- **PC 우선 Web측**: Flutter Web을 데스크톱 관리 콘솔 스타일로 설계（사이드바 + 상단 바 + 콘텐츠 영역）

## 2. 계층 아키텍처

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

## 3. 미들웨어 실행 체인

### 관리자 (admin)
```
Cors → SecurityFilter(方法检查→405) → RateLimit(限流) 
  → AdminAuth(JWT验证) → AdminPermission(RBAC鉴权)
    → OperationLog(操作记录) → Controller
```

### 입주민 포털 (service)
```
Cors → SecurityFilter(方法检查→405) → RateLimit(限流)
  → ApiVersion(版本校验) → Controller           # /api/* 公开接口
  → ServiceAuth(JWT业主认证) → Controller       # /service/* 认证接口
```

### 전역 미들웨어 설명

| 미들웨어 | 위치 | 역할 |
|--------|------|------|
| Cors | 전역 최우선 | CORS 헤더 처리 |
| SecurityFilter | 전역 | HTTP 메서드 화이트리스트, XSS/SQL 인젝션/경로 탐색/명령 인젝션/CSRF 공격 차단, IP 블랙리스트 |
| RateLimit | 전역 | Redis 슬라이딩 윈도우 속도 제한（Lua 원자화）, 기본 60회/분 |
| ApiVersion | /api 라우트 | 요청 헤더 API-Version 검증, 버전 번호 주입 |
| AdminAuth | /admin 라우트 | JWT Token 검증, adminId 주입 |
| AdminPermission | /admin 라우트 | RBAC method.path 권한 검증（Redis 60s 캐시）|
| OperationLog | /admin 라우트 | POST/PUT/DELETE 작업 자동 기록（출처측 감지 포함） |
| ServiceAuth | /service 라우트 | JWT Token 검증, ownerId 주입 |

## 4. ID 전체 라이프사이클

```
生成: SnowflakeService::generate()
      datacenter_id(5bit) + worker_id(5bit) + timestamp(41bit) + sequence(12bit)
      → BIGINT(18) 例: 1750123456789

存储: MySQL erik_* 表
      id BIGINT UNSIGNED NOT NULL（非自增）
      敏感字段 encryptable cast → AES-256-CBC 加密存储

传输: HashidsService::encode(bigint) → hashid 字符串 例: aB3xK9mW2pQ7rT5v
      API 请求/响应中的所有 ID 字段统一使用 hashid

解码: HashidsService::decode(hashid) → BIGINT
      无效 hashid 抛出 InvalidArgumentException
```

## 5. 데이터 암호화 계층

### 전송 계층（encryption）
- AES-256-CBC 암호화
- 클라이언트가 민감 데이터 전송 전 암호화, 서버 수신 후 복호화
- 독립 키 `ENCRYPTION_KEY`

### 저장 계층（encryptable）
- Model `$casts` 메커니즘 자동 암호화/복호화
- 민감 필드: phone, email, id_card, emergency_contact, emergency_phone
- 독립 키 `ENCRYPTABLE_KEY`
- 쓰기 시 자동 암호화 저장, 읽기 시 자동 복호화

### 표시 계층（마스킹）
- 휴대폰 번호: `138****1234`
- 이메일: `a***@example.com`
- 주민등록번호: `********`
- Excel/PDF 내보내기 자동 마스킹

## 6. 인증과 권한

### JWT 인증
- 알고리즘: HS256
- access_token: 2시간 유효기간
- refresh_token: 14일 유효기간
- 동시성 제한: 동일 사용자 최대 3개 유효 Token, 초과 시 가장 오래된 Token 블랙리스트 등록
- 계정 잠금: 연속 5회 로그인 실패 시 15분 잠금

### RBAC 권한 모델
- 사용자 → 역할 → 권한（다대다）
- 권한 유형: type=1(메뉴) / type=2(버튼) / type=3(API)
- 권한 식별 형식: `{method}.{path}` 예: `get.admin/user`
- 슈퍼 관리자 식별: `*`（모든 권한 검사 생략）
- 권한 트리: 자기 참조 parent_id로 무한 계층 지원

## 7. 심층 방어（18층）

```
第1层  点击验证码      → 登录/注册强制人机验证
第2层  密码二次确认    → 敏感操作（删除/缴费/合同终止）必须输入密码
第3层  poster随机验证  → 高频敏感操作随机弹出验证码
第4层  security-php    → 请求周期内自动安全扫描
第5层  SecurityFilter  → XSS/SQL注入/路径遍历/命令注入/CSRF 攻击拦截
第6层  传输安全        → HTTPS + AES-256-CBC
第7层  JWT 认证        → HS256，2h过期 + refresh token
第8层  并发控制        → 同一用户最多3个Token，超出黑名单
第9层  账号锁定        → 连续5次失败锁定15分钟
第10层 RBAC 鉴权       → method.path 粒度权限控制
第11层 限流保护        → Redis 滑动窗口 Lua原子化
第12层 ID 保护         → Hashids 编码，不可逆推真实ID
第13层 请求体加密      → AES-256-CBC 敏感字段
第14层 存储加密        → encryptable DB字段加密
第15层 展示脱敏        → 手机号/邮箱/身份证脱敏
第16层 审计追溯        → OperationLog 全量记录（含来源측 source 自动检测）
第17层 HTTP 头防护     → CSP + X-Permitted-Cross-Domain-Policies
第18层 出口保护        → PDF 版权水印（不可移除）+ Excel 敏感数据脱敏
```

## 8. 속도 제한 정책

Redis Sorted Set 슬라이딩 윈도우 알고리즘 기반, Lua 스크립트로 원자적 실행:

| 인터페이스 | 제한 |
|------|------|
| 기본 | 60회/분/IP/라우트 |
| POST /api/auth/login | 10회/분 |
| POST /api/auth/register | 5회/분 |

초과 시 429 + `X-RateLimit-Limit/Remaining/Reset/Retry-After` 응답 헤더 반환.

## 9. API 버전 정책

- 버전은 요청 헤더 `API-Version`으로 제어（기본 `v1`）, URL에 표시하지 않음
- 지원하지 않는 버전은 400 반환
- 컨트롤러는 버전별로 구성: `app/api/{version}/controller/`
- 새 버전은 디렉토리를 만들고 `ApiVersion` 미들웨어에 등록만 하면 됨

## 10. 배포 아키텍처

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
│ 管理后台API │    │ 业主측API    │
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

### Docker Compose 서비스

| 서비스 | 이미지 | 설명 |
|------|------|------|
| nginx | nginx:alpine | 리버스 프록시 + 정적 파일 |
| admin | Dockerfile 빌드 | PHP 8.3 + OPcache |
| service | Dockerfile 빌드 | PHP 8.3 + OPcache |
| mysql | mysql:8.0 | 데이터 볼륨 영속화 |
| redis | redis:7-alpine | 캐시/속도 제한/Session |
| elasticsearch | elasticsearch:8.x | 전문 검색 |

## 11. 국제화 설계 (i18n)

### 언어 파일 구조

시스템은 간체 중국어（zh_CN）와 영어（en）를 지원하며, 기본은 중국어.

**PHP 백엔드:**
```
resource/translations/
├── zh_CN/
│   └── messages.php    # 中文语言包（42+翻译键）
└── en/
    └── messages.php    # 英文语言包
```

symfony/translation 드라이버 사용, 설정은 `config/translation.php`:
- `locale`: `zh_CN`
- `fallback_locale`: `['zh_CN', 'en']`
- `path`: `resource/translations`

컨트롤러에서 `$this->__('key')`로 번역 획득:
```php
return $this->success([], $this->__('create_success'));
return $this->fail($this->__('community.name_required'), 422);
```

`__()` 메서드는 내부적으로 webman의 `trans()` 전역 함수를 호출하며, 번역이 없으면 key 자체를 반환.

**Flutter Web:**
```
apps/flutter/lib/i18n/
└── messages.dart       # AppTranslations extends GetX Translations
```

GetX `Translations` 사용, 101개 번역 키. `.tr` 확장으로 사용:
```dart
Text('login_btn'.tr)   // 中文: "登 录", 英文: "Login"
Text('phone_hint'.tr)  // "请输入手机号" / "Enter phone number"
```

언어 전환:
```dart
Get.updateLocale(Locale('zh', 'CN'));  // 切换中文
Get.updateLocale(Locale('en', 'US'));  // 切换英文
```

### 번역 키 분류

| 분류 | PHP 키 예시 | Flutter 키 예시 |
|------|-----------|---------------|
| 공통 | `success`, `fail`, `not_found` | `confirm`, `cancel`, `save` |
| 인증 | `auth.login_success`, `auth.*` | `login_btn`, `phone_hint` |
| 단지 | `community.name_required` | - |
| 요금 | `fee.bill_not_found`, `fee.*` | `fee_management`, `bill_status` |
| 수리 접수 | `repair.not_found`, `repair.*` | `repair_submit`, `urgency_normal` |
| 민원 | `complaint.submit_success` | `complaint_type`, `type_complaint` |
| 개인 | - | `profile`, `change_password` |

**HarmonyOS:** `resources/base/element/string.json` + `resources/en_US/element/string.json` 리소스 한정자 사용（HarmonyOS 프로젝트 생성 시 동시 구현）.

## 12. 테스트 전략

### TDD 테스트 흐름

프로젝트는 TDD（테스트 주도 개발）흐름을 따릅니다: 레드→그린→리팩터링.

```
RED: 先写测试，观察失败
  ↓
GREEN: 写最小代码使测试通过
  ↓
REFACTOR: 清理代码，保持测试绿
```

### 테스트 커버리지

| 계층 | 테스트 프레임워크 | 테스트 내용 |
|----|---------|---------|
| 기반 서비스 | PHPUnit | Snowflake ID 생성, Hashids 인코딩/디코딩, 응답 형식 |
| 데이터베이스 | PHPUnit + PDO | 테이블 구조 검증（BIGINT 기본 키, 비자동 증가, erik_ 접두사） |
| 국제화 | PHPUnit | 번역 파일 존재성, 중영 키 일치성 |
| API 엔드포인트 | PHPUnit | 헬스 체크, 응답 형식 |
| 미들웨어 | 통합 테스트 | JWT 인증, 속도 제한, 권한 |

### 테스트 실행

```bash
cd admin && php vendor/bin/phpunit    # 管理측: 60 tests, 164 assertions
cd service && php vendor/bin/phpunit  # 业务측: 18 tests, 45 assertions, 100% pass
```

## 13. 프론트엔드 아키텍처

### Flutter Web（PC 데스크톱 스타일）

```
apps/flutter/lib/
├── main.dart                    # 入口，初始化 ApiService + AuthService
├── app.dart                     # GetMaterialApp，路由表 + 主题 + i18n
├── config/
│   ├── api_config.dart          # API 측点常量（指向 service :8788）
│   └── theme.dart               # Material 3 主题（Ant Design 色系）
├── services/
│   ├── api_service.dart         # Dio 单例 + JWT 拦截器 + 401 自动刷新
│   ├── auth_service.dart        # 登录/登出/Token 持久化
│   └── storage_service.dart     # shared_preferences 封装
├── i18n/
│   └── messages.dart            # GetX Translations（101键，zh_CN/en）
├── pages/
│   ├── login/                   # PC 风格登录页（居中 Card + 表单验证）
│   ├── home/                    # 仪表盘（4个 StatCard + 公告列表）
│   ├── fee/                     # 账单列表 / 详情 / 缴费弹窗
│   ├── repair/                  # 报修列表 / 提交 / 详情 + 评价
│   └── profile/                 # 个人信息 / 修改密码 / 退出
└── widgets/
    └── stat_card.dart           # 统计卡片组件（图标 + 标题 + 数值）
```

### HarmonyOS 모바일

```
apps/harmonyos/entry/src/main/ets/
├── services/
│   ├── ApiService.ets           # @ohos.net.http 封装，Bearer Token
│   └── AuthService.ets          # 登录/登出（Preference 持久化）
├── model/
│   └── Models.ets               # TypeScript 接口定义
├── pages/
│   ├── LoginPage.ets            # 手机号 + 密码登录
│   └── HomePage.ets             # 仪表盘（统计卡片 + 公告列表）
└── resources/
    ├── base/element/string.json # 中文资源
    └── en_US/element/string.json# 英文资源
```

### 기술 선정

| 계층 | Flutter Web | HarmonyOS |
|----|------------|-----------|
| 상태 관리 | GetX | @State + @Prop |
| HTTP | Dio + JWT 인터셉터 | @ohos.net.http |
| 영속화 | shared_preferences | @ohos.data.preferences |
| 차트 | fl_chart | Web 컴포넌트 + ECharts |
| 국제화 | GetX Translations | resource 한정자 |
| 라우팅 | GetX named routes | router.pushUrl/replaceUrl |

## 14. 확장 기능 아키텍처

### 메시지 알림 센터
메시지 템플릿 → 알림 생성 → 다중 채널 발송（앱 내/문자/이메일/푸시）

### 승인 워크플로
승인 유형 설정 → 인스턴스 제출 → 단계 진행（통과/반려）→ 다음 승인자 알림

### 결제 흐름
결제 주문 생성 → 제3자 결제 → 비동기 콜백 → 청구서 상태 업데이트 → 결제 로그 기록

### 입주민 투표
투표 공개 → 입주민 투표（면적 가중치）→ 실시간 집계 → 결과 통계

### SLA 자동 승격
SLA 규칙 매칭 → 정기 초과 확인 → 자동 승격 → 벌금 기록

### 스마트 납부 독촉
독촉 전략 매칭 → 연체 감지 → 자동 독촉 작업 생성 → 독촉 액션 실행

### 순찰 관리
작업 배정 → 모바일 GPS 출석 → 사진 업로드 → 이상 표시 → 완료 통계

### 그룹 관리
그룹 → 단지 연결 → 단지 간 데이터 집계（부동산/입주민/수금/수리 접수）

## 15. API 문서

`hg/apidoc`로 컨트롤러 주석에서 인터페이스 문서를 자동 생성하며, 기능별로 그룹화됩니다.

**관리자** (`http://localhost:8787/apidoc`): 10개 그룹 — 57개 컨트롤러 주석 주입（Base/Docs/Install은 그룹 미지정）

| 그룹 | 수량 | 컨트롤러 |
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

**입주민 포털** (`http://localhost:8788/apidoc`): 9개 그룹 — 17개 컨트롤러 주석 주입

| 그룹 | 수량 | 컨트롤러 |
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

### 주석 규범

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

### 공통 정의 블록

| 블록명 | 내용 |
|------|------|
| `pagination` | page/page_size 페이징 파라미터 |
| `searchParams` | keyword/status 검색 필터 |
| `dateRange` | start_date/end_date 날짜 범위 |
| `passwordConfirm` | password 비밀번호 확인 |

## 16. 통일 응답 형식

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

| code | 의미 |
|------|------|
| 0 | 성공 |
| 400 | 파라미터 오류 |
| 401 | 인증되지 않음 |
| 403 | 권한 없음 |
| 404 | 존재하지 않음 |
| 422 | 검증 실패 |
| 429 | 요청이 너무 빈번함 |
| 500 | 서버 오류 |
