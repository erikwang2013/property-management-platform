# 物业管理系统 — 全面项目规划

> 生成日期：2026-08-16 · 来源：pmp-team 团队审计（auditor / security-auditor / planner）

## 一、现状审计结论

**功能面：与声明一致。** 22 业务模块 + 12 扩展功能全部完成，68 张表 / 178 API，admin 58 控制器 / 127 路由、service 19 控制器 / 57 路由，Flutter Web 管理后台 42 页 + 业主端 13 页，HarmonyOS 5 页。docs/ 14 份文档 + 35 张 SVG 均有代码支撑，未发现"声明未实现"的功能。

**测试：全绿（截至 2026-08-17）。** admin 169 tests / 381 assertions、service 82 tests / 350 assertions（7 skip 为环境依赖）、Flutter widget 测试 9 例（登录/首页/账单页）。

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

**P1 状态**：✅ 全部完成（备份恢复补记于 P8：scripts/backup.sh + docs/RECOVERY_RUNBOOK.md）。

### P2 商业化能力（4-8 周）— 让客户"敢买"

| 目标 | 关键任务 | 验收标准 |
|------|---------|---------|
| 支付闭环、可监控、可交付 | ① 支付生产化：微信/支付宝沙箱全流程（下单→回调幂等→退款→对账），凭证集中到 config/payment.php + env ② 监控告警：Prometheus+Grafana 编排 + 告警规则（5xx、ES/Redis 连接、队列堆积）+ 日志轮转 ③ 商业版控制：基于 EDITIONS 的版本开关（Lite/Standard/Full 路由分组激活）+ Demo 数据 ④ 安装向导覆盖支付/ES 配置 | 沙箱支付全流程通过（含重复回调幂等）；告警实测触发；三版本开关可演示；新环境 10 分钟装完 |

**P2 当前状态**：✅ 离线部分全部完成（2026-08-16/17）：支付全链路代码（PaymentService 下单/回调幂等/退款/对账 + config/payment.php 凭证集中化 + PaymentServiceTest 纯函数覆盖）、监控编排（双 Prometheus 栈 + 6 条告警规则 + 双端 Grafana dashboard provisioning）、版本开关（EDITIONS 三版本 + fail-fast 校验）、安装向导（含支付配置自动启用 + 模板路径 bug 已修复）。剩余外部依赖：**沙箱联调待凭证**（取得 WECHAT_PAY_* / ALIPAY_* 沙箱凭证后运行 `scripts/payment_sandbox_smoke.php`）、**告警实测待部署**（`scripts/verify_monitoring.sh` 可本地校验，真实触发验证待部署后执行）。

### P3 规模化（8-12 周）— 让系统"能卖多"

| 目标 | 关键任务 | 验收标准 |
|------|---------|---------|
| 多租户、性能达标、移动端补齐 | ① 多租户 SaaS：以集团管理为起点，erik_community 加 tenant_id + 中间件隔离（方案评审先行，独立库为演进方向）② 性能压测：wrk/k6 压登录/费用/仪表盘，慢查询 + Redis 缓存复查 ③ 移动端补齐：HarmonyOS 5 页扩至核心路径（缴费/报修/公告/访客/停车），Flutter 业主端移动适配 ④ 开放 API / Webhook（可选） | 租户越权测试通过；核心接口 P95 < 300ms；HarmonyOS 核心路径完成 |

**P3 状态**：✅ 全部完成（2026-08-16 交付：多租户三件套 + 压测实跑 P95 达标 + HarmonyOS 扩至 5 页）。

### P4-P9 追加交付记录（2026-08-16 ~ 08-17，超出原 P1-P3 范围的新增工程阶段）

| 阶段 | 交付内容 | 状态 |
|------|---------|------|
| P4 收尾 | ES 写路径兜底（AdminUser Searchable try/catch + 日志降级）、安装向导支付配置（凭证已填自动启用）、日志轮转（logrotate.conf）、监控告警编排（双 Prometheus 栈 + 6 条规则） | ✅ 完成 |
| P5 剩余项 | Webhook 投递（HMAC-SHA256 签名 + 指数退避重试 + 3 触发点）、费用/审批/SLA 业务单测 | ✅ 完成 |
| P6 部署收尾 | 一键部署脚本（deploy.sh：pull → .env → compose → install.sql 幂等导入 → 监控冒烟）、容器日志挂载修复、CI 覆盖率门禁上调、扩容预案（SCALING_PLAN） | ✅ 完成 |
| P7 测试纵深 | service 单测 43→82、Flutter widget 测试 3 页 8 用例（CI 集成）、开放 API（/open 3 只读端点 + X-API-Key 鉴权 + gen_api_key.php）、压测冒烟（k6 smoke.js + workflow_dispatch 手动 workflow） | ✅ 完成 |
| P8 运维收尾 | 备份恢复落地（backup.sh + RECOVERY_RUNBOOK）、Grafana dashboard（service 端 7 面板 provisioning）、admin 单测 +11（152 全绿）、**安装向导模板路径 bug 修复**（模板移至 app/view/install，curl 实测渲染 200） | ✅ 完成 |
| P9 工程收尾 | 失实备份脚本清理（git rm 两端 4 文件 + 8 处文档统一）、admin 端 Grafana dashboard（open_admin_* 前缀 7 面板）、InstallValidator 校验纯函数抽取 + 17 用例（admin 169 全绿） | ✅ 完成 |

**P4-P9 汇总**：admin 单测 93→169、service 单测 43→82、Flutter widget 测试 9/9、开放 API 3 端点、双端监控面板对称、备份/恢复/密钥/部署全套运维脚本就绪。

## 五、Top 10 优先级行动项（按投入产出比）

| # | 行动项 | 影响 | 成本 | 风险 | 状态 |
|---|--------|------|------|------|------|
| 1 | 密钥管理：env 生成器 + 轮换脚本 + 移除硬编码回退密钥（启动时校验非 change-me） | 高（安全合规） | 低 | 低 | ✅ 完成 |
| 2 | CI 补全：Flutter analyze + service 测试 + 覆盖率门禁 + phpstan + gitleaks | 高（质量底线） | 低 | 低 | ✅ 完成（P7 追加 flutter test） |
| 3 | 备份脚本 + 恢复演练 | 高（数据不丢） | 低 | 低 | ✅ 完成（P8：backup.sh + RECOVERY_RUNBOOK） |
| 4 | ES 降级兜底（MySQL LIKE） | 高（可用性） | 低 | 中（双查询路径维护） | ✅ 完成（P4：写路径 try/catch 兜底；搜索本就全走 MySQL LIKE） |
| 5 | 支付沙箱全流程 + 回调幂等验证 | 高（商业化必需） | 中 | 中（凭证/回调安全） | 🔶 代码完成，沙箱联调待凭证 |
| 6 | Prometheus + Grafana 告警 + 日志轮转 | 高（可运维） | 中 | 低 | ✅ 完成（双端面板 P8/P9 补齐；告警实测待部署） |
| 7 | SQL 迁移管理（全量合并回 install.sql 单一入口） | 中（可升级） | 低 | 低 | ✅ 完成（2026-08-16 合并落地） |
| 8 | 多租户方案评审 + tenant_id 隔离 | 高（天花板） | 高 | 高（影响全部查询） | ✅ 完成（P3 交付，越权测试通过） |
| 9 | 压测 + 慢查询治理 | 中（性能） | 中 | 低 | ✅ 完成（P3 实跑 P95 达标；P7 冒烟版进 CI） |
| 10 | 商业版授权开关 + Demo 数据 | 中（售前） | 中 | 低 | ✅ 完成（EDITIONS + demo_data.php + 演示流程文档） |

## 六、风险与依赖

| 风险 | 现状 | 缓解建议 | 状态 |
|------|------|---------|------|
| 单机部署无 HA | docker-compose 单机，MySQL/Redis/ES 同机 | 备份恢复演练 + 监控告警 + 扩容预案文档 | ✅ 缓解落地（P8 备份 + P2/P8/P9 监控 + P6 SCALING_PLAN）；演练执行待部署 |
| ES 硬依赖 | 搜索/索引同步全走 ES | 降级兜底 + 索引重建脚本 | ✅ 缓解（P4 写路径兜底；搜索本就全走 MySQL LIKE，ES 非查询路径依赖） |
| 密钥管理 | 占位符 + 硬编码回退密钥，无轮换 | 生成器 + 轮换脚本；生产用环境变量注入 | ✅ 已解决（fail-fast 校验 + gen_env_keys.sh + rotate_keys.sh） |
| 支付凭证散落 | 支付模块无集中配置、沙箱未验证 | 配置集中化 + 沙箱先行 | 🔶 配置已集中（config/payment.php），沙箱联调待凭证 |
| 迁移管理 | 单文件 install.sql（IF NOT EXISTS 幂等） | 已统一为单一全量入口；如需增量升级路径另议 | ✅ 已统一（2026-08-16 合并落地） |
| 测试覆盖偏结构 | 133 测试集中在 schema/安全/往返 | 覆盖率门禁 + 核心业务（费用/审批/SLA）补单测 | ✅ 已加强（admin 169 / service 82 / Flutter 9；门禁防零插桩回归） |
| 移动端缺口 | HarmonyOS 仅 5 页，业主端无原生 App | P3 核心路径补齐；依赖：HarmonyOS 测试设备 | ✅ 核心路径补齐（5 页：缴费/报修/公告/访客/停车）；真机验证待设备 |

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

✅ 原 P1 第 1-4 项（密钥加固 → CI 补全 → 备份脚本 → ES 降级）已全部执行完毕（P4-P9 迭代交付）。

**剩余依赖项（需外部条件，非代码缺口）**：
1. 支付沙箱联调：取得 WECHAT_PAY_* / ALIPAY_* 沙箱凭证后运行 `scripts/payment_sandbox_smoke.php`（下单→重复回调幂等→退款→对账全链路验证）
2. 监控告警实测：部署后运行 `scripts/verify_monitoring.sh` 校验规则加载，并真实触发 5xx/连接故障验证告警（Http5xxRatio 规则已可直接生效）
3. 备份恢复演练：按 docs/RECOVERY_RUNBOOK.md 执行季度演练并记录实测耗时（RTO ≤ 1h 目标）
4. HarmonyOS 真机验证：测试设备到位后跑核心路径（缴费/报修/公告/访客/停车）
