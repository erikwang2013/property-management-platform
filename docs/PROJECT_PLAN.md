# 物业管理系统 — 全面项目规划

> 生成日期：2026-08-16 · 来源：pmp-team 团队审计（auditor / security-auditor / planner）

## 一、现状审计结论

**功能面：与声明一致。** 22 业务模块 + 12 扩展功能全部完成，65 张表 / 178 API，admin 58 控制器 / 125 路由、service 17 控制器 / 53 路由，Flutter Web 管理后台 42 页 + 业主端 13 页，HarmonyOS 7 页。docs/ 14 份文档 + 35 张 SVG 均有代码支撑，未发现"声明未实现"的功能。

**测试：全绿。** admin 93 tests / 224 assertions、service 43 tests / 248 assertions（1 skip）。

**工程面已具备：** 双端 docker-compose、GitHub Actions CI（PHP 语法 + 双端 phpunit + composer audit + Flutter analyze）、Dependabot、Prometheus 指标端点。

**技术债（低危为主）：**
1. 日志堆积：service/workerman.log 9.3M、admin/runtime/logs 5.7M（已 gitignore，仅占盘）→ 需轮转
2. README 未单列 service 端 57 个模型的文档口径（64 仅指 admin 端）
3. 无 TODO/FIXME，.env 未入库，依赖版本无异常 — 干净

## 二、安全与质量差距（security-auditor）

**18 层防御：16/18 已验证存在**，实现与 SECURITY_ARCHITECTURE.md 一致（验证码、二次确认、poster、SecurityFilter、AES-256-CBC、JWT、会话限制、账号锁定、RBAC、限流、hashids、字段加密、脱敏、审计日志、CSP）。

**两个不符项（P1 均已修复）：**
1. ~~security-php 仅装在 service 端~~ → 已接入两端 SecurityFilter（admin + service 均有 4b 深度扫描层，SecurityGuard 懒初始化，block 时记录并升级）
2. ~~PDF 版权水印无实现~~ → 核实 ExportController 第 18 层水印已实现（ExportController.php:179,206），审计误报

**最高危：硬编码回退密钥（已修复）。** EncryptionService/加密配置全部改为 fail-fast（缺失或 change-me 即启动抛错），插件层 encryptable/jwt 的硬编码与随机回退已移除；.env 密钥为生成的真实随机值，CI 用 .env.example 拷贝加载。DB/Redis 密码仍为占位符，属部署凭据，由部署方注入。

**工程化短板（P1 已补齐）：** CI 新增 phpstan 作业（Level 5 + baseline）、双端 PHPUnit 覆盖率门禁（实测基线 admin 1.66% / service 3.21%，门禁防零插桩回归）、gitleaks 密钥泄漏扫描（.gitleaks.toml 放行环境模板）。

**高危模式核查：** eval( 仅 Redis::eval（安全）、exec 3 处（监控/安装控制器）、md5( 仅 token 黑名单哈希、SQL 全走 query builder — 无裸拼接风险。

## 三、战略定位

**功能完备期 → 工程化/商业化期。** 业务功能开发已收官（近期提交均为文档/审计/测试补全）。下一阶段投入方向：**CI/CD 与质量门禁、支付生产化、监控告警与备份恢复、多租户 SaaS 化、移动端补齐**。商业化包装已有基础（EDITIONS 三版本 + 安装向导 + 版权水印），缺的是让客户敢付钱的工程可信度。

## 四、分阶段路线图

### P1 工程化巩固（2-4 周）— 让系统"可信"

| 目标 | 关键任务 | 验收标准 |
|------|---------|---------|
| 质量门禁全绿、密钥可控、数据不丢 | ① CI 补全：Flutter analyze、service 测试、PHPUnit 覆盖率门禁、phpstan、gitleaks ② 密钥管理：.env 生成器 + JWT/DB 密钥轮换脚本 ③ 备份恢复：mysqldump 脚本 + 恢复演练手册 ④ ES 降级：队列写失败降级日志兜底 + 搜索降级 MySQL LIKE（延后）⑤ SQL 版本管理：全量迁移统一为 docs/install.sql 单一入口（原拆迁移方案已取消，2026-08-16 合并落地） | CI 全绿含覆盖率；恢复演练 30 分钟数据一致；ES 停服搜索可用；升级脚本可执行 |

### P2 商业化能力（4-8 周）— 让客户"敢买"

| 目标 | 关键任务 | 验收标准 |
|------|---------|---------|
| 支付闭环、可监控、可交付 | ① 支付生产化：微信/支付宝沙箱全流程（下单→回调幂等→退款→对账），凭证集中到 config/payment.php + env ② 监控告警：Prometheus+Grafana 编排 + 告警规则（5xx、ES/Redis 连接、队列堆积）+ 日志轮转 ③ 商业版控制：基于 EDITIONS 的版本开关（Lite/Standard/Full 路由分组激活）+ Demo 数据 ④ 安装向导覆盖支付/ES 配置 | 沙箱支付全流程通过（含重复回调幂等）；告警实测触发；三版本开关可演示；新环境 10 分钟装完 |

**P2 当前状态**：支付全链路代码完成（PaymentService 下单/回调幂等/退款/对账 + config/payment.php 凭证集中化 + PaymentServiceTest 纯函数覆盖），**沙箱联调待凭证**——取得 WECHAT_PAY_* / ALIPAY_* 沙箱凭证后运行 `scripts/payment_sandbox_smoke.php`（cd admin && php ../scripts/payment_sandbox_smoke.php）；监控编排完成（admin:9090 / service:9091 双 Prometheus 栈 + 告警规则），**告警实测待部署**——`scripts/verify_monitoring.sh` 本地可校验 YAML 语法、两端 /metrics 与规则加载，真实触发验证待部署后执行。

### P3 规模化（8-12 周）— 让系统"能卖多"

| 目标 | 关键任务 | 验收标准 |
|------|---------|---------|
| 多租户、性能达标、移动端补齐 | ① 多租户 SaaS：以集团管理为起点，erik_community 加 tenant_id + 中间件隔离（方案评审先行，独立库为演进方向）② 性能压测：wrk/k6 压登录/费用/仪表盘，慢查询 + Redis 缓存复查 ③ 移动端补齐：HarmonyOS 7 页扩至核心路径（缴费/报修/公告/访客/停车），Flutter 业主端移动适配 ④ 开放 API / Webhook（可选） | 租户越权测试通过；核心接口 P95 < 300ms；HarmonyOS 核心路径完成 |

## 五、Top 10 优先级行动项（按投入产出比）

| # | 行动项 | 影响 | 成本 | 风险 |
|---|--------|------|------|------|
| 1 | 密钥管理：env 生成器 + 轮换脚本 + 移除硬编码回退密钥（启动时校验非 change-me） | 高（安全合规） | 低 | 低 |
| 2 | CI 补全：Flutter analyze + service 测试 + 覆盖率门禁 + phpstan + gitleaks | 高（质量底线） | 低 | 低 |
| 3 | 备份脚本 + 恢复演练 | 高（数据不丢） | 低 | 低 |
| 4 | ES 降级兜底（MySQL LIKE） | 高（可用性） | 低 | 中（双查询路径维护） |
| 5 | 支付沙箱全流程 + 回调幂等验证 | 高（商业化必需） | 中 | 中（凭证/回调安全） |
| 6 | Prometheus + Grafana 告警 + 日志轮转 | 高（可运维） | 中 | 低 |
| 7 | SQL 迁移管理（全量合并回 install.sql 单一入口） | 中（可升级） | 低 | 低 |
| 8 | 多租户方案评审 + tenant_id 隔离 | 高（天花板） | 高 | 高（影响全部查询） |
| 9 | 压测 + 慢查询治理 | 中（性能） | 中 | 低 |
| 10 | 商业版授权开关 + Demo 数据 | 中（售前） | 中 | 低 |

## 六、风险与依赖

| 风险 | 现状 | 缓解建议 |
|------|------|---------|
| 单机部署无 HA | docker-compose 单机，MySQL/Redis/ES 同机 | 备份恢复演练（P1）+ 监控告警（P2）+ 扩容预案文档 |
| ES 硬依赖 | 搜索/索引同步全走 ES | 降级兜底（P1）+ 索引重建脚本 |
| 密钥管理 | 占位符 + 硬编码回退密钥，无轮换 | 生成器 + 轮换脚本；生产用环境变量注入 |
| 支付凭证散落 | 支付模块无集中配置、沙箱未验证 | 配置集中化（P2）+ 沙箱先行 |
| 迁移管理 | 单文件 install.sql（IF NOT EXISTS 幂等） | 已统一为单一全量入口；如需增量升级路径另议 |
| 测试覆盖偏结构 | 133 测试集中在 schema/安全/往返 | 覆盖率门禁 + 核心业务（费用/审批/SLA）补单测 |
| 移动端缺口 | HarmonyOS 仅 7 页，业主端无原生 App | P3 核心路径补齐；依赖：HarmonyOS 测试设备 |

## 七、团队分工（pmp-team）

| 角色 | 投入任务 |
|------|---------|
| 架构 | 多租户方案评审与 tenant_id 隔离设计（P3）、ES 降级架构、监控架构（P2）、支付回调幂等设计评审 |
| 后端 | 密钥生成/轮换脚本、ES 降级实现、支付配置集中化 + 沙箱联调、迁移脚本拆分、压测与慢查询治理 |
| Flutter 前端 | CI 集成 flutter analyze、业主端移动适配（P3）、版本开关 UI 配合 |
| HarmonyOS | 核心路径补齐：缴费/报修/公告/访客/停车（P3） |
| 测试 | 覆盖率门禁、支付沙箱用例（重复回调/退款/对账）、压测脚本、备份恢复演练执行 |
| 审查 | 支付与安全关键路径 review、gitleaks 入 CI、多租户越权测试审查 |
| 文档 | 部署/运维手册（含恢复演练）、多租户方案文档、监控配置手册、商业版交付手册 |

## 八、立即行动建议

按 P1 第 1-4 项先行（两周内见效）：密钥加固（含移除硬编码回退密钥）→ CI 补全 → 备份脚本 → ES 降级。这四项低成本、高风险敞口，优先消除"不敢上线"的顾虑。
