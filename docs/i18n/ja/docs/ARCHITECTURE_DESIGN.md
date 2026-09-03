# アーキテクチャ設計ドキュメント（Architecture Design）

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## 1. システムアーキテクチャ概要

不動産管理システムは「デュアルバックエンド + マルチフロントエンド」の階層アーキテクチャを採用しています。管理画面（admin）と所有者業務端（service）は独立した 2 つの webman v2 プロジェクトで、共有の MySQL データベースで連携します。フロントエンドは Flutter Web（PC 管理画面スタイル）と HarmonyOS モバイル端をカバーします。

### 設計目標

- **独立デプロイ**: admin と service はそれぞれ独立して起動・停止、独立してスケール、独立して鍵管理
- **データ共有**: 同一の MySQL データベースを共用し、データ同期問題を回避
- **統一規範**: 両プロジェクトが同じコード規範、設定スタイル、セキュリティポリシーに従う
- **PC 優先の Web 端**: Flutter Web はデスクトップ管理画面スタイルで設計（サイドバー + トップバー + コンテンツエリア）

## 2. 階層アーキテクチャ

```
┌─────────────────────────────────────────────────────────────┐
│                        路由层 (Route Layer)                   │
│   config/route.php — URL → Controller 映射 + 中间件绑定       │
├─────────────────────────────────────────────────────────────┤
│                       中间件层 (Middleware Layer)              │
│   SecurityFilter → RateLimit → Auth → Permission               │
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

## 3. ミドルウェア実行チェーン

### 管理画面 (admin)
```
Cors → SecurityFilter(方法检查→405) → RateLimit(限流) 
  → AdminAuth(JWT验证) → AdminPermission(RBAC鉴权)
    → OperationLog(操作记录) → Controller
```

### 業務端 (service)
```
Cors → SecurityFilter(方法检查→405) → RateLimit(限流)
  → Controller（URL 版本路由）           # /api/v1/* 公开接口
  → ServiceAuth(JWT业主认证) → Controller       # /service/v1/* 认证接口
```

### グローバルミドルウェアの説明

| ミドルウェア | 位置 | 役割 |
|--------|------|------|
| Cors | グローバル先頭 | クロスオリジンリソース共有ヘッダー処理 |
| SecurityFilter | グローバル | HTTP メソッドホワイトリスト、XSS/SQL インジェクション/パストラバーサル/コマンドインジェクション/CSRF 攻撃のブロック、IP ブラックリスト |
| RateLimit | グローバル | Redis スライディングウィンドウレート制限（Lua アトミック）、デフォルト 60 回/分 |
| AdminAuth | /admin ルート | JWT Token 検証、adminId を注入 |
| AdminPermission | /admin ルート | RBAC method.path 権限検証（Redis 60 秒キャッシュ）|
| OperationLog | /admin ルート | POST/PUT/DELETE 操作の自動記録（送信元端の検出含む） |
| ServiceAuth | /service ルート | JWT Token 検証、ownerId を注入 |

## 4. ID のライフサイクル全体

```
生成: SnowflakeService::generate()
      datacenter_id(5bit) + worker_id(5bit) + timestamp(41bit) + sequence(12bit)
      → BIGINT(18) 例: 1750123456789

存储: MySQL management_* 表
      id BIGINT UNSIGNED NOT NULL（非自增）
      敏感字段 encryptable cast → AES-256-CBC 加密存储

传输: HashidsService::encode(bigint) → hashid 字符串 例: aB3xK9mW2pQ7rT5v
      API 请求/响应中的所有 ID 字段统一使用 hashid

解码: HashidsService::decode(hashid) → BIGINT
      无效 hashid 抛出 InvalidArgumentException
```

## 5. データ暗号化の階層

### 転送層（encryption）
- AES-256-CBC 暗号化
- クライアントは機密データ送信前に暗号化、サーバーは受信後に復号
- 独立鍵 `ENCRYPTION_KEY`

### 保存層（encryptable）
- Model `$casts` メカニズムで自動暗号化/復号
- 機密フィールド：phone, email, id_card, emergency_contact, emergency_phone
- 独立鍵 `ENCRYPTABLE_KEY`
- 書き込み時に自動で暗号文へ、読み取り時に自動で平文へ

### 表示層（マスキング）
- 携帯番号: `138****1234`
- メール: `a***@example.com`
- 身分証: `********`
- Excel/PDF エクスポートは自動マスキング

## 6. 認証と権限

### JWT 認証
- アルゴリズム: HS256
- access_token: 2 時間有効
- refresh_token: 14 日有効
- 同時制限: 同一ユーザーの有効 Token は最大 3 つ、超過時は最古の Token をブラックリスト登録
- アカウントロック: 連続 5 回ログイン失敗で 15 分ロック

### RBAC 権限モデル
- ユーザー → ロール → 権限（多対多）
- 権限タイプ: type=1(メニュー) / type=2(ボタン) / type=3(API)
- 権限識別子の形式: `{method}.{path}` 例: `get.admin/user`
- スーパー管理者識別子: `*`（すべての権限チェックをスキップ）
- 権限ツリー: 自己参照 parent_id で無限階層をサポート

## 7. 多層防御（18 層）

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
第12层 熔断保护        → Redis 熔断器（支付/回调快速失败+半开探测）
第13层 ID 保护         → Hashids 编码，不可逆推真实ID
第14层 请求体加密      → AES-256-CBC 敏感字段
第15层 存储加密        → encryptable DB字段加密
第16层 展示脱敏        → 手机号/邮箱/身份证脱敏
第17层 审计追溯        → OperationLog 全量记录（含来源端 source 自动检测）
第18层 HTTP 头防护     → CSP + X-Permitted-Cross-Domain-Policies
第19层 出口保护        → PDF 版权水印（不可移除）+ Excel 敏感数据脱敏
```

## 8. レート制限戦略

Redis Sorted Set スライディングウィンドウアルゴリズムに基づき、Lua スクリプトでアトミック実行：

| インターフェース | 制限 |
|------|------|
| デフォルト | 60 回/分/IP/ルート |
| POST /api/v1/auth/login | 10 回/分 |
| POST /api/v1/auth/register | 5 回/分 |

超過時は 429 + `X-RateLimit-Limit/Remaining/Reset/Retry-After` レスポンスヘッダーを返します。

## 9. API バージョン戦略

- バージョンはAPIルート自体に含める（例: `/api/v1/*`、`/service/v1/*`）、リクエストヘッダーではない
- 存在しないバージョンのパスはルーターから直接 404（ミドルウェア不要）
- コントローラはバージョン別に編成: `app/api/{version}/controller/`
- 新バージョンの追加は `/{namespace}/v{version}` ルートグループを登録するだけ（コントローラは `app/api/v1/controller/` 配下）；存在しないバージョンのパスは FastRoute が 404 を返す

## 10. デプロイアーキテクチャ

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

### Docker Compose サービス

| サービス | イメージ | 説明 |
|------|------|------|
| nginx | nginx:alpine | リバースプロキシ + 静的ファイル |
| admin | Dockerfile ビルド | PHP 8.3 + OPcache |
| service | Dockerfile ビルド | PHP 8.3 + OPcache |
| mysql | mysql:8.0 | データボリューム永続化 |
| redis | redis:7-alpine | キャッシュ/レート制限/Session |
| elasticsearch | elasticsearch:8.x | 全文検索 |

## 11. 国際化設計 (i18n)

### 言語ファイル構造

システムは簡体中文（zh_CN）と英語（en）をサポート、デフォルトは中文。

**PHP バックエンド:**
```
resource/translations/
├── zh_CN/
│   └── messages.php    # 中文语言包（42+翻译键）
└── en/
    └── messages.php    # 英文语言包
```

symfony/translation で駆動、設定は `config/translation.php`：
- `locale`: `zh_CN`
- `fallback_locale`: `['zh_CN', 'en']`
- `path`: `resource/translations`

コントローラでは `$this->__('key')` で翻訳を取得：
```php
return $this->success([], $this->__('create_success'));
return $this->fail($this->__('community.name_required'), 422);
```

`__()` メソッドは内部で webman の `trans()` グローバル関数を呼び出し、翻訳が存在しない場合は key 自体を返します。

**Flutter Web:**
```
apps/flutter/lib/i18n/
└── messages.dart       # AppTranslations extends GetX Translations
```

GetX `Translations` を使用、101 個の翻訳キー。`.tr` 拡張で使用：
```dart
Text('login_btn'.tr)   // 中文: "登 录", 英文: "Login"
Text('phone_hint'.tr)  // "请输入手机号" / "Enter phone number"
```

言語切替：
```dart
Get.updateLocale(Locale('zh', 'CN'));  // 切换中文
Get.updateLocale(Locale('en', 'US'));  // 切换英文
```

### 翻訳キーの分類

| 分類 | PHP キー例 | Flutter キー例 |
|------|-----------|---------------|
| 汎用 | `success`, `fail`, `not_found` | `confirm`, `cancel`, `save` |
| 認証 | `auth.login_success`, `auth.*` | `login_btn`, `phone_hint` |
| コミュニティ | `community.name_required` | - |
| 料金 | `fee.bill_not_found`, `fee.*` | `fee_management`, `bill_status` |
| 修理依頼 | `repair.not_found`, `repair.*` | `repair_submit`, `urgency_normal` |
| 苦情 | `complaint.submit_success` | `complaint_type`, `type_complaint` |
| 個人 | - | `profile`, `change_password` |

**HarmonyOS:** `resources/base/element/string.json` + `resources/en_US/element/string.json` のリソース限定子を使用（HarmonyOS プロジェクト作成時に同時実装）。

## 12. テスト戦略

### TDD テストフロー

プロジェクトは TDD（テスト駆動開発）フローに従います：レッド → グリーン → リファクタ。

```
RED: 先写测试，观察失败
  ↓
GREEN: 写最小代码使测试通过
  ↓
REFACTOR: 清理代码，保持测试绿
```

### テストカバレッジ

| 層 | テストフレームワーク | テスト内容 |
|----|---------|---------|
| 基礎サービス | PHPUnit | Snowflake ID 生成、Hashids エンコード/デコード、レスポンス形式 |
| データベース | PHPUnit + PDO | テーブル構造検証（BIGINT 主キー、非自增、management_ プレフィックス） |
| 国際化 | PHPUnit | 翻訳ファイルの存在性、中英キー一致性 |
| API エンドポイント | PHPUnit | ヘルスチェック、レスポンス形式 |
| ミドルウェア | 統合テスト | JWT 認証、レート制限、権限 |

### テスト実行

```bash
cd admin && php vendor/bin/phpunit    # 管理端: 60 tests, 164 assertions
cd service && php vendor/bin/phpunit  # 业务端: 18 tests, 45 assertions, 100% pass
```

## 13. フロントエンドアーキテクチャ

### Flutter Web（PC デスクトップスタイル）

```
apps/flutter/lib/
├── main.dart                    # 入口，初始化 ApiService + AuthService
├── app.dart                     # GetMaterialApp，路由表 + 主题 + i18n
├── config/
│   ├── api_config.dart          # API 端点常量（指向 service :8788）
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

### HarmonyOS モバイル端

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

### 技術選定

| 層 | Flutter Web | HarmonyOS |
|----|------------|-----------|
| 状態管理 | GetX | @State + @Prop |
| HTTP | Dio + JWT インターセプタ | @ohos.net.http |
| 永続化 | shared_preferences | @ohos.data.preferences |
| チャート | fl_chart | Web コンポーネント + ECharts |
| 国際化 | GetX Translations | resource 限定子 |
| ルーティング | GetX named routes | router.pushUrl/replaceUrl |

## 14. 拡張機能アーキテクチャ

### メッセージ通知センター
メッセージテンプレート → 通知生成 → マルチチャネル送信（アプリ内/ショートメッセージ/メール/プッシュ）

### 承認ワークフロー
承認タイプ設定 → インスタンス提出 → ステップ遷移（承認/却下）→ 次の承認者へ通知

### 決済フロー
決済注文作成 → 第三者決済 → 非同期コールバック → 請求書ステータス更新 → 決済ログ記録

### 所有者投票
投票公開 → 所有者投票（面積加重）→ リアルタイム開票 → 結果統計

### SLA 自動エスカレーション
SLA ルールマッチング → 定期タイムアウトチェック → 自動エスカレーション → 罰金記録

### スマート督促
督促戦略マッチング → 滞納検出 → 督促タスクの自動生成 → 督促アクション実行

### 巡回点検管理
タスク配信 → モバイル端 GPS 打刻 → 写真アップロード → 異常マーク → 完了統計

### グループ管理
グループ → コミュニティ関連付け → 跨区データ集計（不動産/所有者/料金/修理依頼）

## 15. API ドキュメント

`hg/apidoc` でコントローラアノテーションからインターフェースドキュメントを自動生成し、機能別にグループ化。

**管理画面** (`http://localhost:8787/apidoc`): 10 グループ — 57 個のコントローラがアノテーション注入（Base/Docs/Install は未グループ）

| グループ | 件数 | コントローラ |
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

**業務端** (`http://localhost:8788/apidoc`): 9 グループ — 17 個のコントローラがアノテーション注入

| グループ | 件数 | コントローラ |
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

### アノテーション規範

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

### 汎用定義ブロック

| ブロック名 | 内容 |
|------|------|
| `pagination` | page/page_size ページングパラメータ |
| `searchParams` | keyword/status 検索フィルタ |
| `dateRange` | start_date/end_date 日付範囲 |
| `passwordConfirm` | password パスワード確認 |

## 16. 統一レスポンス形式

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

| code | 意味 |
|------|------|
| 0 | 成功 |
| 400 | パラメータエラー |
| 401 | 未認証 |
| 403 | 権限なし |
| 404 | 存在しない |
| 422 | 検証失敗 |
| 429 | リクエストが頻繁すぎる |
| 500 | サーバーエラー |
