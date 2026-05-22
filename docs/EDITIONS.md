# 版本对比 (Editions Comparison)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

物业管理系统分为三个版本：基础版（Lite）、标准版（Standard）、完整版（Full），逐级累进。

---

## 总览

| 指标 | 基础版 (Lite) | 标准版 (Standard) | 完整版 (Full) |
|------|:-----------:|:---------------:|:-----------:|
| 数据库表 | **21** | **31** | **65** |
| Eloquent 模型 | 19 | 30 | 58 |
| 管理端控制器 | 17 | 28 | 47 |
| 业主端控制器 | 9 | 12 | 17 |
| API 路由 | 35 | 70 | 178 |
| 业务模块 | 10 | 18 | 34 |
| 安全层 | 18 层 | 18 层 | 18 层 |

---

## 功能模块对比

### 基础版 (Lite) — 第1批

核心物业管理，含管理后台通用系统 + 10个核心业务模块。

| 分类 | 模块 | 数据表 |
|------|------|--------|
| 管理后台 | 用户管理、角色权限、系统配置、操作日志 | erik_admin_user, erik_admin_role, erik_admin_permission, erik_admin_user_role, erik_admin_role_permission, erik_system_config, erik_operation_log |
| 基础设施 | 小区、楼栋、单元、户型 | erik_community, erik_building, erik_unit, erik_room_type |
| 房产管理 | 房产、业主、租户、房产-业主关联 | erik_room, erik_owner, erik_tenant, erik_room_owner |
| 费用管理 | 费用类型、账单、缴费记录 | erik_fee_type, erik_fee_bill, erik_fee_payment |
| 工单服务 | 报修、报修进度 | erik_repair_order, erik_repair_progress |
| 信息发布 | 公告通知 | erik_announcement |

**管理端**: 仪表盘、用户/角色/权限/配置/日志 CRUD、小区/楼栋/单元/户型/房产/业主/租户/费用/报修/公告 CRUD

**业主端**: 注册/登录、首页、我的房产、账单缴费、报修提交/评价、公告查看、个人信息

---

### 标准版 (Standard) — 第1批 + 第2批

在基础版之上增加6个辅助业务模块 + 面板可视化 + 数据导出。

| 新增模块 | 数据表 |
|---------|--------|
| 停车管理 | erik_parking_space, erik_parking_vehicle, erik_parking_record |
| 设备管理 | erik_equipment, erik_equipment_maintenance |
| 投诉建议 | erik_complaint |
| 访客管理 | erik_visitor |
| 合同管理 | erik_contract |
| 财务管理 | erik_finance_income, erik_finance_expense |
| 面板可视化 | 物业统计面板（应收/入住率/报修/投诉/收支趋势） |
| 数据导出 | 业主/账单 Excel 导出 + PDF 导出 |

**管理端新增**: 停车位/车辆CRUD、设备台账+维保、投诉处理+回访、访客审批、合同管理、收支管理+统计

**业主端新增**: 我的车辆/车位、停车记录、访客预约/通行码

---

### 完整版 (Full) — 第1批 + 第2批 + 第3批 + 扩展

在标准版之上增加高级模块 + 12个扩展功能。

| 新增模块 | 数据表 |
|---------|--------|
| **第3批** | |
| 安保巡逻 | erik_security_patrol, erik_patrol_record |
| 保洁管理 | erik_cleaning_area, erik_cleaning_record |
| 绿化管理 | erik_green_area, erik_green_maintenance |
| 社区活动 | erik_community_activity, erik_activity_signup |
| 能耗管理 | erik_energy_meter, erik_energy_record |
| 员工管理 | erik_staff |
| **扩展功能** | |
| 消息通知 | erik_notification_template, erik_notification |
| 审批工作流 | erik_approval_type, erik_approval, erik_approval_record |
| 支付集成 | erik_payment_order |
| 业主投票 | erik_vote, erik_vote_option, erik_vote_record |
| SLA自动升级 | erik_sla_rule, erik_sla_record |
| 智能催缴 | erik_collection_strategy, erik_collection_record |
| 巡检移动端 | erik_inspection_task, erik_inspection_checkpoint |
| 社区商城 | erik_mall_category, erik_mall_product, erik_mall_order |
| 人脸识别 | erik_face_info |
| 集团管理 | erik_group, erik_group_community |
| 智能问答 | erik_knowledge_base, erik_chat_record |

**管理端新增**: 巡逻路线+记录、保洁区域+记录、绿化区域+养护、社区活动管理、能耗仪表+抄表、员工管理、通知模板+发送、审批引擎、支付订单+退款、投票管理+SLA规则+催缴策略+巡检任务+商城管理+人脸审核+集团管理+知识库

**业主端新增**: 社区活动报名、停车/访客预约、消息通知、投票+计票、浏览商品+下单、智能问答、人脸注册

---

## 技术指标对比

| 指标 | 基础版 | 标准版 | 完整版 |
|------|:------:|:------:|:------:|
| 数据库表 | 21 | 31 | 65 |
| 模型文件 | 19 | 30 | 58 |
| admin 控制器 | 17 | 28 | 47 |
| service 控制器 | 9 | 12 | 17 |
| admin 路由 | 45 | 80 | 123 |
| service 路由 | 20 | 35 | 55 |
| Flutter 页面 | 4 | 7 | 10 |
| HarmonyOS 页面 | 2 | 3 | 5 |
| 中间件 | 7 | 8 | 9 |
| PHP 测试 | 18 | 18 | 18 |

---

## 安全体系（三版通用）

18 层纵深防御：验证码 → 密码确认 → 随机验证 → 安全扫描 → 攻击拦截 → HTTPS + AES-256-CBC → JWT → 会话控制 → 账号锁定 → RBAC → 限流 → ID保护 → 请求加密 → 存储加密 → 展示脱敏 → 审计 → CSP → 版权水印

---

## 迁移路径

```
基础版 (Lite)
  │
  │  + 6辅助模块 + 面板 + 导出
  ▼
标准版 (Standard)
  │
  │  + 6高级模块 + 12扩展功能
  ▼
完整版 (Full)
```

升级只需执行对应批次的 SQL 迁移文件，无需数据迁移或破坏性变更。
