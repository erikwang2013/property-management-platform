# 多租户 SaaS 方案评审 (Multi-Tenant Plan)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> 状态: 评审稿 (P3-① 先行任务) | 日期: 2026-08-16

## 1. 现状盘点

### 1.1 表结构分类（65 张表，docs/install.sql 验证）

| 类别 | 表 | 说明 |
|------|-----|------|
| 全局/平台表 | erik_admin_user / admin_role / admin_permission / admin_user_role / admin_role_permission、erik_system_config、erik_operation_log | 鉴权、配置、审计，天然平台级，不挂租户 |
| 社区维度表 | erik_community 及经 community_id 归属的 40+ 张业务表（building/unit/room/owner/fee_*/repair_order/parking_*/announcement 等） | 通过 community_id 间接归属租户 |
| 集团关联表 | erik_group（集团）、erik_group_community（集团↔小区） | 当前为**可选关联**，无租户语义，跨区汇总靠 join |
| 平台扩展表 | erik_notification_template、erik_knowledge_base、erik_mall_*、erik_face_info 等 | 部分为平台级，部分社区级，需个案确认 |
| 易混淆表 | **erik_tenant（租客表）** | ⚠️ 语义冲突：是"房屋租客"（room_id/owner_id 维度），**不是** SaaS 租户 |

### 1.2 鉴权链路（admin 端，代码验证）

```
全局中间件: Cors → SecurityFilter → RateLimit
路由组中间件: AdminAuth(JWT → $request->adminId) → AdminPermission(RBAC method.path) → OperationLog → Controller
```

- `AdminAuth` 已建立 request 注入模式（`$request->adminId`），租户上下文可完全复刻
- `AdminPermission` 为平台级 RBAC，与租户隔离**正交**，可叠加
- service 业主端：JWT 持 owner_id，数据经 room_owner → room.community_id 天然受限，跨租户风险低

### 1.3 关键结论

- 无任何现成 SaaS 租户模型；`erik_tenant` 名称已被租客占用，新概念必须避名
- 全部控制器直接 Eloquent 查询，无 repository 层、无全局作用域 —— 隔离改造需在模型层做
- config/database.php 单连接，但 illuminate/database 原生支持多 connection（为独立库演进预留）

## 2. 方案对比与推荐

| 方案 | 机制 | 改造量 | 运维成本 | 适用 |
|------|------|--------|----------|------|
| **A. 共享库 + tenant_id 行隔离（推荐）** | 租户表 + 业务表 tenant_id 列 + Eloquent 全局作用域过滤 | 中（2 表加列 + 中间件 + 全局作用域 + 存量回填） | 低（单库备份/迁移不变） | 中小物业，单租户 <500 万行 |
| B. 独立库（每租户一库） | 连接路由 + 跨库聚合 | 高（连接管理/跨库报表/迁移×N/备份×N） | 高 | 大型集团、合规隔离要求 |
| C. 混合（敏感库独立 + 共享） | A+B 组合 | 高 | 高 | 支付/人脸等强隔离场景 |

**推荐 A，B 为演进方向。** 理由：

1. 现有 65 表统一在单库，A 的 tenant_id 数据模型不阻碍未来拆库（过滤粒度从行变库即可，A 方案下租户 ID 已全局建模）
2. 业务数据全部经 community_id 归属，tenant_id 只需加在**顶层表**，中间 40 张业务表由访问路径保证，避免逐表加列
3. 双端（admin/service）共享同一数据模型，A 的改造集中在 admin 端运行层
4. 单机部署现状下 B 的备份/迁移复杂度不可承受

## 3. 隔离点设计

### 3.1 数据模型（最小集）

- 新建 `erik_platform_tenant`（避免与租客表 erik_tenant 冲突）：id/name/status/created_at 等
- `erik_community` 加 `tenant_id BIGINT NOT NULL DEFAULT 0`，索引 `(tenant_id, community_id)`
- `erik_admin_user` 加 `tenant_id BIGINT NOT NULL DEFAULT 0`（0 = 平台超级管理员）
- 业务中间表（building/room/fee_bill 等 40 张）**不加列**，经 community_id 归属

### 3.2 运行层三件套

1. **TenantContext 中间件**：JWT payload 增加 `tenant_id` 声明 → `$request->tenantId`（复刻 AdminAuth 注入模式）；登录/安装/平台级路由（user/role/permission/config）放行清单
2. **TenantScope 全局作用域**：对 Community 及平台级业务模型挂 Eloquent 全局作用域，按 `$request->tenantId` 自动过滤；`find()` 同样被作用域约束，天然防跨租户单条直查
3. **Tenant::for() 显式上下文**：定时任务/队列/导入无 HTTP 请求，用闭包包裹显式指定租户；缺失上下文时 **fail-closed**（拒绝查询），不允许无过滤静默放行

### 3.3 越权防护测试要点（验收矩阵）

| 用例 | 预期 |
|------|------|
| 租户 A 管理员 list 租户 B 的 community/building/fee_bill | 返回空或仅 A 数据 |
| 租户 A 管理员 find/update/delete 租户 B 的单条记录（直查 id） | 403 / 空数据 / 拒绝 |
| 平台管理员（tenant_id=0）跨租户操作 | 放行（平台级能力） |
| service 业主跨社区操作（缴费/报修） | 拒绝（community 归属校验） |
| 定时任务/队列未指定租户上下文 | fail-closed 报错而非无过滤 |

## 4. 演进路径（分步迁移）

| 步骤 | 内容 | 验收 |
|------|------|------|
| 1. 数据层 | 建 platform_tenant 表 + community/admin_user 加列 + 幂等迁移 + 默认租户初始化并回填存量数据 | 每个 community 必挂租户，孤儿数据报告清零 |
| 2. 运行层 | TenantContext 中间件 + TenantScope + Tenant::for() 工具 + 路由放行清单 | 单租户回归：全量 133 测试通过 |
| 3. 试点模块 | 集团管理 → 小区 → 业主 → 费用（账单）四个模块先启用隔离 | 越权测试矩阵通过 |
| 4. 全量铺开 | 按批次（第1批核心 → 第2批辅助 → 扩展模块）逐模块启用 | 全部模块越权矩阵通过 |
| 5. 演进 | 单租户数据 >500 万行或合规要求时评估拆库（B 方案），A 的数据模型不阻塞 | 拆库方案评审 |

数据迁移策略：存量数据全部归入"默认租户"（迁移脚本创建），不删不改业务数据；迁移脚本幂等，可重复执行。

## 5. 风险清单

| 风险 | 影响面 | 缓解 / 回滚 |
|------|--------|-------------|
| 58+17 控制器查询路径改造量大 | 全量业务接口 | 全局作用域覆盖 ~80% 列表/详情；raw query 与批量导入走 Tenant::for()；按批次灰度 |
| 全局作用域误伤平台级查询（仪表盘跨区汇总） | 仪表盘/报表 | 平台级接口显式 Tenant::without() 或 tenant_id=0 旁路 |
| 定时任务/队列无请求上下文 | 催缴/SLA/通知等后台任务 | Tenant::for() 显式包裹 + fail-closed |
| 存量数据回填错误 | 全部存量数据 | 幂等脚本 + 回填校验 + 干跑模式 |
| 索引/性能影响 | 高频表（fee_bill/room/owner） | (tenant_id, community_id) 联合索引；慢查询日志复查 |
| 133 测试回归 | 全量 | scope 注入后先跑全量回归再启试点 |
| 命名混淆（erik_tenant 租客 vs SaaS 租户） | 开发认知 | 新表命名 platform_tenant，文档显式声明 |
| **回滚方案** | — | 全局作用域可在配置开关一键关闭（恢复单租户语义），数据列保留不删，无破坏性变更 |

## 6. 评审结论

**建议立即做**：
- 共享库 + tenant_id 行隔离（方案 A），新建 `erik_platform_tenant` 表，community/admin_user 加列
- TenantContext 中间件 + TenantScope 全局作用域 + Tenant::for() 工具
- 试点顺序：集团 → 小区 → 业主 → 费用
- 前置依赖：已完成 — 多租户表/列/回填已内联进 docs/install.sql（2026-08-16 合并落地，单一建库入口）

**建议缓做**：
- 独立库隔离（B）：仅在单租户 >500 万行或合规要求时启动，数据模型已预留
- 混合方案（C）：支付/人脸等强隔离场景若客户明确提出再评估

**不建议做**：
- Schema 级隔离（MySQL 无独立 schema 语义，成本等同独立库）
- 动态多库路由（单机部署下无收益）
- 租户级个性化 schema/字段（YAGNI）
- 复用/改造 erik_tenant 租客表充当 SaaS 租户（语义冲突，破坏租客业务）
