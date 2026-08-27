# service 单元测试补盲报告

> 时间：2026-08-27　|　测试目标：`/home/wwwroot/property-management-platform/service`（webman v2 + PHP 8.3 + Eloquent）
> 验证命令：`cd service && vendor/bin/phpunit --no-coverage`

## 一、最终结果

| 指标 | 基线（任务开始时） | 最终 | 说明 |
|------|-------------------|------|------|
| 测试数 | 101 | **201** | 新增 100 个用例 |
| 断言数 | — | **661** | |
| 失败 | 0 | **0** | 连续两遍运行确认 |
| 跳过 | 13 | **1** | 仅剩 1 个应用缺陷门控跳过（见第四节） |

新增测试文件 21 个（全部含版权头、`namespace tests`、< 500 行），覆盖全部 19 个控制器、全部 6 个中间件、核心模型、全部 common 服务类。

## 二、覆盖矩阵（模块 → 测试文件 → 用例数）

### 控制器层（19/19 全覆盖，105 用例）

| 模块 | 测试文件 | 用例数 | 覆盖要点 |
|------|----------|--------|----------|
| 访客 | VisitorControllerTest | 11 | 提交校验（缺姓名/电话/无效房间）、pass_code 6 位、更新越权 404、取消预约（密码确认/状态机/已到访不可取消） |
| 活动 | ActivityControllerTest | 10 | 报名校验、未开始/已满 422、重复报名拒绝、取消流程、详情 |
| 投诉 | ComplaintControllerTest | 9 | 提交校验、详情 404/越权、满意度（仅已处理、评分 1-5 边界、落库） |
| 个人中心 | ProfileControllerTest | 8 | 资料查询（隐藏 password/id_card）、更新、改密（空/错旧/过短/成功）、登出 401 |
| 商城 | MallControllerTest | 6 | 下单校验（缺商品/数量 0/负/缺地址/无效 hashid）；mall 表未迁移，仅校验路径 |
| 报修 | RepairControllerTest | 6 | 校验路径（DB 门控） |
| 缴费 | FeeControllerTest | 6 | 账单查询结构、状态校验 |
| 认证 | AuthControllerTest | 6 | 注册/登录校验路径 |
| 停车 | ParkingControllerTest | 5 | 车辆/记录/车位查询结构、plate+entry_time 字段 |
| 验证码 | CaptchaControllerTest | 5 | generate 返回 key + PNG（双层 base64 解码断言）、verify 缺参/未知 key/错误坐标 422 |
| 公告 | AnnouncementControllerTest | 5 | 详情（未发布 404）、分页结构、分类过滤 |
| 投票 | VoteControllerTest | 3 | 无效 hashid 404；vote 表未迁移，仅校验路径 |
| 房间 | RoomControllerTest | 3 | 校验路径（DB 门控） |
| 指标 | MetricsControllerTest | 3 | Prometheus 文本格式、db_up/redis_up |
| 知识库 | KnowledgeControllerTest | 3 | 提问校验（空/空白/缺参 422）；表未迁移 |
| 首页 | HomeControllerTest | 2 | 聚合结构（room_count、pending_amount、announcements） |
| 人脸 | FaceControllerTest | 2 | 缺图/空图 422；face_info 表未迁移 |
| 通知 | NotificationControllerTest | 2 | 无效 hashid 404；表未迁移 |
| OpenAPI | OpenApiTest | 10 | 真实 HTTP 探测（X-API-Key 401/放行、bills/repairs 参数校验、404） |

### 中间件层（6/6 全覆盖，19 用例）

| 中间件 | 测试文件 | 用例数 | 覆盖要点 |
|--------|----------|--------|----------|
| ApiKeyAuth / ApiVersion / ServiceAuth | MiddlewareAuthTest | 10 | 缺/错/超长 key 401、禁用 key 401、v2 400、缺 token 401、无效 token 401 |
| Cors / OperationLog / MetricsCollector / RateLimit | MiddlewareWebTest | 9 | OPTIONS 204+头、安全头、GET 不写日志、POST 脱敏落库、filterSensitive、计数器增减、限流放行/第 11 次 429 |

### 模型层（5 用例）

| 测试文件 | 用例数 | 覆盖要点 |
|----------|--------|----------|
| ModelTest | 5 | BaseModel 非自增、Room 软删除（find/withTrashed）、Owner 加密字段往返（库中非明文）、hidden 属性 |

### common 层（43 用例）

| 测试文件 | 用例数 | 覆盖要点 |
|----------|--------|----------|
| ValidatorTest | 15 | 身份证/手机号/密码强度/金额等规则 |
| EncryptionServiceTest | 9 | 传输加解密往返、失败路径 |
| HashidsServiceTest | 5 | 编码/解码往返、无效输入 |
| BaseControllerTest | 5 | success/fail 统一结构、confirmPassword |
| LockServiceTest | 4 | 互斥、释放后可重获、错 token 不误删、TTL 过期可重获 |
| SnowflakeServiceTest | 3 | 唯一性、时间/机器位 |
| DefinitionsTest | 2 | apidoc 注解类与方法存在 |

### 安全/特性回归（29 用例）

| 测试文件 | 用例数 | 覆盖要点 |
|----------|--------|----------|
| SecurityFilterTest | 6 | XSS/SQL 注入/路径遍历/命令注入拦截 |
| SecurityFeatureTest / AuthFeatureTest / FeeFeatureTest / EditionFeatureTest | 13 | 特性级回归 |
| I18nTest | 3 | 错误消息文案 |
| DatabaseSchemaTest | 3 | install.sql 表/列与模型一致性 |
| ApiResponseTest | 4 | /health 真实 HTTP + 统一响应结构 |

## 三、13 个基线跳过的根因分析

| 数量 | 跳过原因 | 根因 | 处置 |
|------|----------|------|------|
| 12 | "DB 不可用" | `service/.env` 的 `DB_PASSWORD` 为过期值（非空但错误）；MySQL 实际在运行，root@127.0.0.1 接受空密码 | 修复 `.env`（置空密码，gitignored 不入库）→ 12 个跳过全部转为真实用例 |
| 1 | "Service not running on port 8788"（OpenApiTest HTTP 探测） | 8788 端口被同机 sibling 项目 social-service 占用，property service 未启动 | 以 `SERVER_LISTEN=http://0.0.0.0:8792` 启动本服务；测试支持 `OPEN_API_TEST_PORT` 环境变量（`.env` 设 8792），`ApiResponseTest` 同步支持 → 转为真实 HTTP 断言 |

结论：13 个跳过全部为环境配置问题，无一为合理保留项，已全部修复为真实用例。

## 四、当前唯一跳过（如实标注）

`ModelTest::test_room_decimal_cast` —— 应用缺陷门控，非环境跳过：

> **裸 `decimal` cast 缺陷**：`Room`/`FeeBill`/`FeePayment`/`RoomOwner`/`Tenant` 等 10+ 模型的 `$casts` 使用无位数的 `'decimal'`，在 Eloquent 11+ 序列化时 `toScale(null)` 直接 TypeError，任何非空 decimal 字段读取即崩（区别于 `'decimal:2'` 的正常用法）。属应用级 bug，测试无法绕过，修复（统一改 `'decimal:2'`）后取消跳过。

## 五、补盲过程中发现并处理的应用问题

| # | 问题 | 影响 | 处置 |
|---|------|------|------|
| 1 | `ActivitySignup`/`ParkingRecord` 开启 Eloquent 时间戳，但 `management_activity_signup`/`management_parking_record` 表无 `updated_at` 列（install.sql 同） | 写路径必然 1054 崩溃（生产同故障） | 模型 `$timestamps = false`（已修） |
| 2 | `Visitor::$fillable` 缺 `'id'` | `Visitor::create(['id' => …])` 静默丢弃主键 → 1364 | fillable 补 `'id'`（已修） |
| 3 | `ApiVersion` 中间件 `json()` 第二参被当编码选项传，HTTP 状态码未生效 | v2 请求应 400 实返回 200 | 修正参数（已修） |
| 4 | vendor `ImagickDriver::clone()` 在资源未初始化时崩溃（vendor bug，禁改 vendor）；`auto` 驱动在装有 Imagick 的环境必选 Imagick | `/api/captcha/generate` 500 | 测试内强制 GD 驱动 + `.env` 设 `POSTER_IMAGE_DRIVER=gd`；**生产根治需在 `config/bootstrap.php` 注册 `CaptchaPlugin`（将 env 驱动 merge 进 poster 配置）或强制 gd，并线工程师已按约定还原该注册项，此点记录为生产待办** |
| 5 | batch3 表未迁移：`management_notification`/`vote*`/`face_info`/`mall_*`/`knowledge_base`/`chat_record` 在 `docs/install.sql` 有定义，dev 库未建 | 对应 6 个控制器无法测业务写路径 | 对应用例覆盖参数校验/无效 ID 路径，未伪造业务断言；迁移后补测 |
| 6 | 裸 `decimal` cast（见第四节） | 读取即崩 | 记录待修，1 用例门控跳过 |
| 7 | `LockServiceTest` TTL 用例与并线 phpunit 进程共享 Redis key 偶发互扰 | 偶发失败 | key 按进程隔离（`getmypid()` 后缀），语义不变 |

## 六、环境备注（未提交、不入库）

- `service/.env`（gitignored）：`DB_PASSWORD=` 置空、`POSTER_IMAGE_DRIVER=gd`、`OPEN_API_TEST_PORT=8792`
- 本服务运行于 8792 端口（8788 被 social sibling 占用，勿改）
- 未提交 git；未修改 `vendor/`；测试文件全部位于 `service/tests/` 且被现有 `phpunit.xml` 自动收集
