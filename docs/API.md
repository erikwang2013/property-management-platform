# 接口文档 (API Reference)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## 概述

- 管理端 API 运行在 `http://localhost:8787`
- 业务端 API 运行在 `http://localhost:8788`
- 统一响应格式: `{"code": 0, "message": "success", "data": {...}}`
- 所有 ID 字段使用 hashids 编码传输
- API 版本通过请求头 `API-Version` 控制（默认 `v1`）
- 语言通过请求头 `Accept-Language` 控制（`zh-CN` / `en-US`，默认 `zh-CN`）

### 在线 API 文档

启动服务后访问 `hg/apidoc` 自动生成的交互式文档：

| 端 | 地址 | 分组数 |
|----|------|--------|
| 管理端 | `http://localhost:8787/apidoc` | 7组（通用/仪表盘/系统管理/核心业务/辅助业务/高级功能/扩展功能） |
| 业主端 | `http://localhost:8788/apidoc` | 9组（公开接口/首页/费用/报修/反馈/停车/活动/个人/扩展） |

---

## 管理端 API (admin :8787)

### 公开接口 — 无需认证

#### POST /api/captcha/generate
获取点击验证码。

请求参数: 无

响应:
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
校验点击验证码。

请求参数:
| 参数 | 类型 | 说明 |
|------|------|------|
| key | string | 验证码 key，由 generate 返回 |
| clicks | array | 点击坐标 [{x, y}, ...] |

响应:
```json
{
  "code": 0,
  "data": { "valid": true }
}
```

验证失败时 `code` 为 422，`data.valid` 为 `false`。

#### POST /api/auth/login
管理员登录。

请求参数:
| 参数 | 类型 | 说明 |
|------|------|------|
| username | string | 用户名 |
| password | string | 密码 |
| captcha_key | string | 验证码 key |
| clicks | array | 点击坐标 [{x, y}, ...] |

响应:
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
刷新 Token。

请求参数:
| 参数 | 类型 | 说明 |
|------|------|------|
| refresh_token | string | 刷新令牌 |

响应:
```json
{
  "code": 0,
  "data": { "access_token": "eyJ..." }
}
```

#### GET /health
健康检查。

#### GET /metrics
Prometheus 监控指标。

#### GET /api/docs
OpenAPI 文档。

---

### 管理端接口 — 需认证 (Bearer Token)

所有接口前缀 `/admin`，需携带 `Authorization: Bearer {access_token}`。

#### 仪表盘

**GET /admin/dashboard**
获取仪表盘统计数据。

#### 管理员用户管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/user | 用户列表 (?keyword=&status=&page=&page_size=) |
| POST | /admin/user | 创建用户 |
| GET | /admin/user/{hashid} | 用户详情 |
| PUT | /admin/user/{hashid} | 更新用户 |
| DELETE | /admin/user/{hashid} | 删除用户（需密码确认） |
| POST | /admin/user/batch/destroy | 批量删除 |
| POST | /admin/user/batch/status | 批量启禁用 |
| POST | /admin/import/users | Excel 导入用户 |

#### 角色权限管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/role | 角色列表 |
| POST | /admin/role | 创建角色 |
| GET | /admin/role/{hashid} | 角色详情 |
| PUT | /admin/role/{hashid} | 更新角色 |
| DELETE | /admin/role/{hashid} | 删除角色 |
| GET | /admin/permission | 权限列表（树形） |
| POST | /admin/permission | 创建权限 |
| PUT | /admin/permission/{hashid} | 更新权限 |
| DELETE | /admin/permission/{hashid} | 删除权限 |

#### 系统配置

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/config | 配置列表 (?group=) |
| POST | /admin/config | 创建配置 |
| PUT | /admin/config/{hashid} | 更新配置 |
| DELETE | /admin/config/{hashid} | 删除配置 |

#### 操作日志

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/log | 日志列表 (?user_id=&action=&method=&source=&start_date=&end_date=) |

#### 个人中心

| 方法 | 路径 | 说明 |
|------|------|------|
| PUT | /admin/profile | 修改个人信息 |
| PUT | /admin/profile/password | 修改密码 |
| POST | /admin/profile/logout | 退出登录 |

#### 导出

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /admin/export/excel | 导出 Excel ({ table, columns, conditions, title }) |
| POST | /admin/export/pdf | 导出 PDF ({ type, title, data }) |

---

### 物业管理 — 管理端接口

#### 小区管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/community | 列表 (?keyword=&status=) |
| POST | /admin/community | 创建 |
| GET | /admin/community/{hashid} | 详情 |
| PUT | /admin/community/{hashid} | 更新 |
| DELETE | /admin/community/{hashid} | 删除（需密码） |

#### 楼栋管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/building | 列表 (?community_id=&keyword=) |
| POST | /admin/building | 创建 |
| GET | /admin/building/{hashid} | 详情 |
| PUT | /admin/building/{hashid} | 更新 |
| DELETE | /admin/building/{hashid} | 删除 |

#### 单元管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/unit | 列表 (?building_id=) |
| POST | /admin/unit | 创建 |
| GET | /admin/unit/{hashid} | 详情 |
| PUT | /admin/unit/{hashid} | 更新 |
| DELETE | /admin/unit/{hashid} | 删除 |

#### 户型管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/room-type | 列表 |
| POST | /admin/room-type | 创建 |
| GET | /admin/room-type/{hashid} | 详情 |
| PUT | /admin/room-type/{hashid} | 更新 |
| DELETE | /admin/room-type/{hashid} | 删除 |

#### 房产管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/room | 列表 (?community_id=&building_id=&unit_id=&status=) |
| POST | /admin/room | 创建 |
| GET | /admin/room/{hashid} | 详情 |
| PUT | /admin/room/{hashid} | 更新 |
| DELETE | /admin/room/{hashid} | 删除 |
| GET | /admin/room/tree | 房屋树（小区→楼栋→单元→房屋） |

#### 业主管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/owner | 列表 (?keyword=&status=) |
| POST | /admin/owner | 创建 |
| GET | /admin/owner/{hashid} | 详情（含绑定房产） |
| PUT | /admin/owner/{hashid} | 更新 |
| DELETE | /admin/owner/{hashid} | 删除（需密码） |
| POST | /admin/owner/batch/import | Excel 批量导入 |
| POST | /admin/owner/batch/destroy | 批量删除 |

#### 租户管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/tenant | 列表 (?room_id=&status=) |
| POST | /admin/tenant | 创建 |
| GET | /admin/tenant/{hashid} | 详情 |
| PUT | /admin/tenant/{hashid} | 更新 |
| DELETE | /admin/tenant/{hashid} | 删除 |

#### 费用类型

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/fee-type | 列表 |
| POST | /admin/fee-type | 创建 |
| GET | /admin/fee-type/{hashid} | 详情 |
| PUT | /admin/fee-type/{hashid} | 更新 |
| DELETE | /admin/fee-type/{hashid} | 删除 |

#### 账单管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/fee-bill | 列表 (?community_id=&status=&due_date_start=&due_date_end=) |
| POST | /admin/fee-bill | 创建账单 |
| GET | /admin/fee-bill/{hashid} | 详情 |
| PUT | /admin/fee-bill/{hashid} | 更新 |
| DELETE | /admin/fee-bill/{hashid} | 删除 |
| POST | /admin/fee-bill/batch/generate | 批量生成账单 |

#### 缴费记录

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/fee-payment | 列表 (?bill_id=&payment_method=&date_start=&date_end=) |
| POST | /admin/fee-payment/offline | 线下收款登记 |

#### 报修管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/repair | 列表 (?status=&category=) |
| POST | /admin/repair | 创建 |
| GET | /admin/repair/{hashid} | 详情（含进度记录） |
| PUT | /admin/repair/{hashid} | 更新 |
| DELETE | /admin/repair/{hashid} | 删除 |
| PUT | /admin/repair/{id}/assign | 派单（{ staff_id }） |
| POST | /admin/repair/{id}/progress | 更新进度（{ status_to, remark }） |

#### 公告管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/announcement | 列表 (?community_id=&category=&is_published=) |
| POST | /admin/announcement | 创建 |
| GET | /admin/announcement/{hashid} | 详情 |
| PUT | /admin/announcement/{hashid} | 更新 |
| DELETE | /admin/announcement/{hashid} | 删除 |

#### 停车管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/parking-space | 列表 (?community_id=) |
| POST | /admin/parking-space | 创建车位 |
| PUT | /admin/parking-space/{hashid} | 更新 |
| DELETE | /admin/parking-space/{hashid} | 删除 |
| GET | /admin/parking-vehicle | 列表 (?owner_id=&space_id=) |
| POST | /admin/parking-vehicle | 创建车辆 |
| PUT | /admin/parking-vehicle/{hashid} | 更新 |
| DELETE | /admin/parking-vehicle/{hashid} | 删除 |
| GET | /admin/parking-record | 停车记录 (?vehicle_id=&date_start=&date_end=) |

#### 设备管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/equipment | 列表 (?community_id=&category=&status=) |
| POST | /admin/equipment | 创建 |
| PUT | /admin/equipment/{hashid} | 更新 |
| DELETE | /admin/equipment/{hashid} | 删除 |
| GET | /admin/equipment-maintenance | 维保记录 (?equipment_id=) |
| POST | /admin/equipment-maintenance | 创建维保 |

#### 投诉处理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/complaint | 列表 (?type=&status=) |
| GET | /admin/complaint/{hashid} | 详情 |
| PUT | /admin/complaint/{id}/handle | 处理（{ handler_remark }） |
| POST | /admin/complaint/{id}/visit | 回访（{ visitor_remark }） |

#### 访客审批

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/visitor | 列表 (?status=) |
| PUT | /admin/visitor/{id}/approve | 审批通过 |

#### 合同管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/contract | 列表 (?contract_type=&status=) |
| POST | /admin/contract | 创建 |
| PUT | /admin/contract/{hashid} | 更新 |
| DELETE | /admin/contract/{hashid} | 删除 |

#### 财务管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/finance-income | 收入列表 (?income_type=&date_start=&date_end=) |
| POST | /admin/finance-income | 登记收入 |
| GET | /admin/finance-expense | 支出列表 |
| POST | /admin/finance-expense | 登记支出 |
| GET | /admin/finance/statistics | 月度收支统计 (?year=) |

#### 物业面板

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/dashboard/property | 物业统计（应收/入住率/报修/投诉/收支趋势） |
| POST | /admin/export/property-excel | 物业数据 Excel 导出（{ type: owners|bills }） |

#### 安保巡逻

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/security-patrol | 列表 (?community_id=) |
| POST | /admin/security-patrol | 创建路线 |
| GET | /admin/patrol-record | 记录 (?patrol_id=&staff_id=) |
| POST | /admin/patrol-record | 创建记录 |

#### 保洁管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/cleaning-area | 区域列表 |
| POST | /admin/cleaning-area | 创建区域 |
| GET | /admin/cleaning-record | 记录 (?area_id=) |
| POST | /admin/cleaning-record | 创建记录 |

#### 绿化管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/green-area | 区域列表 |
| POST | /admin/green-area | 创建区域 |
| GET | /admin/green-maintenance | 养护记录 (?area_id=) |
| POST | /admin/green-maintenance | 创建记录 |

#### 社区活动

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/activity | 列表 (?status=) |
| POST | /admin/activity | 创建活动 |
| PUT | /admin/activity/{hashid} | 更新 |
| DELETE | /admin/activity/{hashid} | 删除 |
| GET | /admin/activity-signup | 报名列表 (?activity_id=) |
| PUT | /admin/activity-signup/{id}/checkin | 签到 |

#### 能耗管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/energy-meter | 仪表列表 (?room_id=&meter_type=) |
| POST | /admin/energy-meter | 创建仪表 |
| GET | /admin/energy-record | 抄表记录 (?meter_id=&date_start=&date_end=) |
| POST | /admin/energy-record | 创建记录 |

#### 员工管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/staff | 列表 (?community_id=&status=) |
| POST | /admin/staff | 创建 |
| PUT | /admin/staff/{hashid} | 更新 |
| DELETE | /admin/staff/{hashid} | 删除 |
| POST | /admin/staff/batch/status | 批量启禁用 |

#### 消息通知

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/notification-template | 模板列表 |
| POST | /admin/notification-template | 创建模板 |
| PUT | /admin/notification-template/{hashid} | 更新模板 |
| DELETE | /admin/notification-template/{hashid} | 删除模板 |
| GET | /admin/notification | 消息列表 (?type=&is_read=) |
| POST | /admin/notification/send | 手动发送通知 |

#### 审批工作流

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/approval-type | 审批类型列表 |
| POST | /admin/approval-type | 创建审批类型 |
| GET | /admin/approval | 审批列表 (?status=) |
| GET | /admin/approval/{hashid} | 审批详情 |
| POST | /admin/approval | 提交审批 |
| PUT | /admin/approval/{hashid}/approve | 审批（通过/驳回） |

#### 支付管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/payment-order | 订单列表 |
| GET | /admin/payment-order/{hashid} | 订单详情 |
| POST | /admin/payment-order/{hashid}/refund | 退款 |
| GET | /admin/payment/statistics | 支付统计 |

#### 业主投票

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/vote | 投票列表 (?status=) |
| POST | /admin/vote | 创建投票 |
| GET | /admin/vote/{hashid}/statistics | 计票统计 |
| PUT | /admin/vote/{hashid}/publish | 发布投票 |
| PUT | /admin/vote/{hashid}/end | 结束投票 |

#### SLA管理 · 智能催缴 · 巡检管理 · 商城管理 · 人脸管理 · 集团管理 · 知识库

（完整端点参见 `docs/API.md` 文件）

---

## 业务端 API (service :8788)

### 公开接口 — 无需认证

#### POST /api/captcha/generate
获取点击验证码。（与管理端相同）

#### POST /api/captcha/verify
校验点击验证码。（请求/响应与管理端相同）

#### POST /api/auth/login
业主登录。

请求参数:
| 参数 | 类型 | 说明 |
|------|------|------|
| phone | string | 手机号 |
| password | string | 密码 |
| captcha_key | string | 验证码 key |
| clicks | array | 点击坐标 |

响应:
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
业主注册。

请求参数:
| 参数 | 类型 | 说明 |
|------|------|------|
| phone | string | 手机号 |
| password | string | 密码（至少6位） |
| name | string | 姓名 |
| captcha_key | string | 验证码 key |
| clicks | array | 点击坐标 |
| room_id | string | （可选）绑定房号 hashid |
| id_card_last4 | string | （可选）身份证后4位 |

#### POST /api/auth/refresh
刷新 Token。

---

### 业主端接口 — 需认证 (Bearer Token)

所有接口前缀 `/service`，需携带 `Authorization: Bearer {access_token}`。

#### 首页

**GET /service/home**

响应:
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

#### 我的房产

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /service/rooms | 我的房产列表 |
| GET | /service/room/{hashid} | 房产详情（含面积、朝向、产权、社区信息） |

#### 费用管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /service/fees/bills | 账单列表 (?status=0未缴/1部分缴/2已缴/3逾期) |
| GET | /service/fees/bill/{hashid} | 账单详情（含费用类型、支付记录） |
| GET | /service/fees/payments | 缴费记录 |
| POST | /service/fees/pay | 在线缴费（{ bill_id, payment_method, password }） |
| GET | /service/fees/statistics | 费用统计 (?year=2026) |

#### 报修

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /service/repairs | 报修列表 (?status=) |
| GET | /service/repair/{hashid} | 报修详情（含进度时间线） |
| POST | /service/repair | 提交报修（{ room_id, category, urgency, description, images[], scheduled_at }） |
| DELETE | /service/repair/{hashid} | 取消（需密码，{ password }） |
| POST | /service/repair/{hashid}/rate | 评价（{ rating: 1-5, feedback }） |

#### 投诉建议

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /service/complaints | 投诉列表 |
| GET | /service/complaint/{hashid} | 投诉详情（含处理进度） |
| POST | /service/complaint | 提交投诉（{ type, category, title, content, is_anonymous, images[] }） |
| POST | /service/complaint/{hashid}/satisfaction | 满意度评价（{ satisfaction: 1-5 }） |

#### 公告

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /service/announcements | 公告列表 (?category=) |
| GET | /service/announcement/{hashid} | 公告详情 |

#### 停车

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /service/parking/vehicles | 我的车辆 |
| GET | /service/parking/spaces | 我的车位 |
| GET | /service/parking/records | 停车记录 |

#### 访客

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /service/visitors | 我的访客预约 |
| POST | /service/visitor | 创建预约（生成通行码） |
| PUT | /service/visitor/{hashid} | 修改预约 |
| DELETE | /service/visitor/{hashid} | 取消预约 |

#### 社区活动

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /service/activities | 活动列表 (?status=) |
| GET | /service/activity/{hashid} | 活动详情 |
| POST | /service/activity/{hashid}/signup | 报名参加 |
| POST | /service/activity/{hashid}/cancel | 取消报名 |

#### 个人信息

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /service/profile | 个人信息 |
| PUT | /service/profile | 修改（{ name, email, gender, birthday }） |
| PUT | /service/profile/password | 改密码（{ old_password, new_password }） |
| POST | /service/profile/logout | 退出登录 |

---

## 错误码

| code | 含义 | 说明 |
|------|------|------|
| 0 | 成功 | 正常响应 |
| 400 | 请求错误 | 参数格式不正确 |
| 401 | 未认证 | Token 缺失/过期/无效/被加入黑名单 |
| 403 | 无权限 | 用户角色不包含所需权限 / 账号被禁用 |
| 404 | 不存在 | 资源未找到 |
| 405 | 方法不允许 | 非 GET/POST/PUT/DELETE/OPTIONS 的 HTTP 方法 |
| 413 | 请求体过大 | 超过 10MB |
| 415 | 不支持的媒体类型 | Content-Type 不是 JSON 或 form-urlencoded |
| 422 | 验证失败 | 表单参数不符合规则 / 密码确认失败 / 验证码错误 |
| 429 | 请求过多 | 触发限流 / 账号锁定 |
| 500 | 服务端错误 | 未预期异常 |

## 限流响应头

触发限流时返回 429，响应头包含：

| 响应头 | 说明 |
|--------|------|
| X-RateLimit-Limit | 限制次数 |
| X-RateLimit-Remaining | 剩余次数 |
| X-RateLimit-Reset | 重置时间（Unix 时间戳） |
| Retry-After | 建议重试等待秒数 |
