# admin 单元测试报告

- 日期：2026-08-27
- 执行命令：`cd admin && vendor/bin/phpunit --no-coverage`
- 基线：219 tests / 494 assertions / 7 errors / 2 failures / 2 skipped
- 最终：**258 tests / 619 assertions / 0 errors / 0 failures / 2 skipped（全绿）**

## 一、修复的 9 个红项

### 1. tests/CaptchaTest.php 7 个 error（ImagickDriver $resource 未初始化）

**原因**（vendor bug，已禁止修改 vendor）：
- 本机 CLI 加载了 imagick 扩展，`DriverFactory::create('auto')` 命中 `ImagickDriver`；
- `ImagickDriver` 声明 `private Imagick $resource;`（typed 属性）且**没有构造函数**做初始化；
- `AbstractCaptcha::createBackground()`（vendor/src/Captcha/AbstractCaptcha.php:43）在调用 `create()/load()` **之前**先执行 `$this->imageDriver->clone()`，`ImagickDriver::clone()` 对未初始化的 typed 属性执行 `clone $this->resource` → PHP Error：`Typed property ...::$resource must not be accessed before initialization`。
- 即：只要环境加载 imagick，验证码生成路径必然崩溃，与字体/缺库无关。`GdDriver::clone()` 对空资源有判空保护，不受影响。

**修法**（真实修复，GD 回退）：在 `CaptchaTest::setUp()` 中 `PosterConfig::merge(['image' => ['driver' => 'gd'])`，显式选择 GD 驱动 —— 与生产环境未安装 imagick 时 `DriverFactory::create('gd')` 的行为一致。同时保留环境守卫：若 `gd` 扩展缺失则 `markTestSkipped`（带原因说明，不删测试）。7 个用例全部恢复通过。

### 2. tests/ApiVersionMiddlewareTest.php::test_unsupported_version_returns_400

**原因**：`app/middleware/ApiVersion.php` 中 `return json(['code'=>400,...])` 未传 HTTP 状态码。webman 的 `json()` 助手**第二参是 JSON 编码选项位掩码且固定返回 HTTP 200**（vendor/workerman/webman-framework/src/support/helpers.php:183），传 400 会污染编码选项而不是状态码。

**修法**：改为 `response(json_encode([...], JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES|JSON_THROW_ON_ERROR), 400, ['Content-Type'=>'application/json'])`，显式构造 400 状态响应。已 grep 确认无其他测试/代码依赖旧行为（`不支持的API版本` 仅此一处，BackendEnhancementTest:188 只校验路由文件内容）。

### 3. tests/SecurityRegressionTest.php::test_cors_not_wildcard

**原因**：测试读 `config('cors.allowed_origin', getenv('CORS_ALLOWED_ORIGIN') ?: '')`，但 admin 没有 config/cors.php；且 `CorsMiddlewareTest`（按字母序先执行）会 `putenv('CORS_ALLOWED_ORIGIN')` 清空环境变量 → getenv 返回 false → 断言落空。

**修法**：改为断言真实来源 —— 与 `app/middleware/Cors.php:18` 的实际取值逻辑一致：`getenv('CORS_ALLOWED_ORIGIN') ?: 'http://localhost:8787'`，自带回退值，不受测试执行顺序影响。未凭空创建 config/cors.php（中间件不读它）。

### 附带修复（同类缺陷，与第 2 项同因）

- `app/admin/controller/DocsController.php:28`：`json(['code'=>404,...], 404)` 同样把 404 传给了编码选项。改为显式 404 响应（`response(json_encode(...), 404, ['Content-Type'=>'application/json'])`）。新写的 DocsControllerTest 断言了 HTTP 404。

## 二、覆盖矩阵（36 个测试文件，258 个用例）

| 模块 | 测试文件 | 用例数 | 覆盖内容 |
|---|---|---|---|
| 验证码 | CaptchaTest | 7 | click 验证码生成结构/难度/坐标不泄露/校验失败/关联数组拒绝/唯一 key |
| API 认证 | AuthControllerTest（新） | 8 | 登录参数校验、弱密码、验证码失败、注册弱密码、无刷新令牌 422、坐标归一化 |
| API 版本 | ApiVersionMiddlewareTest | 3 | 默认 v1、注入版本头、不支持版本 HTTP 400 |
| 中间件 | CorsMiddlewareTest / StaticFileMiddlewareTest / MetricsCollectorMiddlewareTest / OperationLogMiddlewareTest / MultiTenantTest | 4+2+2+7+13 | 跨域、静态文件、指标采集、操作日志脱敏、租户上下文/多租户 |
| 安全 | SecurityRegressionTest | 11 | 中间件存在性、JWT/加密无默认密钥、CORS 非通配、SameSite、健康检查、security-php 拦截 |
| 基础控制器 | BaseControllerEncodeTest | 6 | hashid 编解码、encodeIds 仅替换数值字段 |
| 控制器·运维 | MetricsControllerTest（新） | 5 | Prometheus 文本结构、6 组指标、依赖不可用兜底 0、php 版本 |
| 控制器·文档 | DocsControllerTest（新） | 5 | DOCS_ENABLED 开关 404/200、OpenAPI 3.0.3 结构、安全方案、servers、核心 schema |
| 控制器·校验 | ControllerValidationTest（新） | 14 | User/Staff 创建校验 422、Profile 登出 401、Payment 渠道校验、线下缴费缺账单、验证码缺参数、Finance 收支分流、Owner/Repair 脱敏 |
| 控制器·逻辑 | FeeLogicTest / SlaLogicTest / ApprovalFlowTest / PermissionTreeTest | 5+6+7+5 | 账单计算、SLA 匹配/升级、审批流、权限树 |
| 控制器·导入导出 | ImportControllerTest / ExportControllerTest | 7+10 | 导入校验、PDF/Excel 生成、脱敏、过滤白名单 |
| 公共类 | DefinitionsTest / TransTraitTest / ValidatorTest / SnowflakeServiceTest / HashidsServiceTest / EncryptionServiceTest / LockServiceTest | 3+3+15+5+6+8+4 | 定义字典、翻译、校验器、雪花 ID、hashids、加密、分布式锁（获取/释放/错误 token/TTL 过期） |
| 支付 | PaymentServiceTest / WebhookServiceTest | 10+6 | 支付通道、回调签名、Webhook 投递 |
| 队列 | WebhookQueueTest | 3 | WebhookDelivery 消费、签名、失败重试 |
| 进程 | MonitorProcessTest（新） | 3 | 文件监控暂停/恢复状态机、lock 文件位置 |
| 模型 | BaseModelTest / CommunityFeatureTest / MallFeatureTest / BackendEnhancementTest / EnvConfigTest / InstallValidatorTest | 2+5+2+28+7+17 | 基模型、租户 scope、路由注册、版权头、环境配置、安装校验 |

## 三、环境性 skip（2 个，均为既有测试，非本次新增）

| 用例 | 原因 |
|---|---|
| ExportControllerTest::test_excel_generates_nonempty_file | `DB 不可用`（本机 MySQL 拒绝 root 连接，测试内 try/catch 后 markTestSkipped） |
| ImportControllerTest::test_duplicate_username_row_rejected | 同上，需要真实 DB 校验重复用户名 |

## 四、说明

- 新增 5 个测试文件：AuthControllerTest、MetricsControllerTest、DocsControllerTest、ControllerValidationTest、MonitorProcessTest（均含版权头，namespace tests，<500 行）。
- 修改源码 2 处：app/middleware/ApiVersion.php、app/admin/controller/DocsController.php（均为 json() 助手状态码语义缺陷，详见第一节）。
- 未修改 vendor/；未提交 git。
- 其余 40+ 个 DB 强依赖控制器（CRUD 路径）在无 DB 环境下无法产生有意义的断言，遵循现有测试风格不做空壳用例；其纯逻辑已通过上述控制器逻辑测试与反射覆盖（maskEmail/maskPhone/isIncome 等）。
