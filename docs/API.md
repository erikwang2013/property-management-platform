# 接口文档 (API Reference)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## 概述

- 管理端 API 运行在 `http://localhost:8787`
- 业务端 API 运行在 `http://localhost:8788`
- 统一响应格式: `{"code": 0, "message": "success", "data": {...}}`
- 所有 ID 字段使用 hashids 编码传输
- 列表接口分页参数 `page_size` 上限为 100（超出按 100 处理）
- API 版本体现在接口路由中（当前 `/api/v1/*`），不通过请求头传递
- 语言通过请求头 `Accept-Language` 控制（`zh-CN` / `en-US`，默认 `zh-CN`）

### 在线 API 文档

启动服务后访问 `hg/apidoc` 自动生成的交互式文档：

| 端 | 地址 | 分组数 |
|----|------|--------|
| 管理端 | `http://localhost:8787/apidoc` | 10组（common/dashboard/system/property-core/property-aux/property-adv/extensions/export/import/upload） |
| 业主端 | `http://localhost:8788/apidoc` | 6组（公开接口/首页/费用/反馈/停车/个人） |

---

## 管理端 API (admin :8787)

### 公开接口 — 无需认证

#### POST /api/v1/captcha/generate
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

#### POST /api/v1/captcha/verify
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

#### POST /api/v1/auth/login
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

#### POST /api/v1/auth/refresh
刷新 Token。仅接受 `token_type=refresh` 的刷新令牌；access token 不能用于刷新。每次刷新会轮换 refresh token，旧 refresh token 立即失效（加入 Redis 黑名单）。

请求参数:
| 参数 | 类型 | 说明 |
|------|------|------|
| refresh_token | string | 刷新令牌 |

响应:
```json
{
  "code": 0,
  "data": { "access_token": "eyJ...", "refresh_token": "eyJ..." }
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
| POST | /admin/profile/logout | 退出登录（可选传 `refresh_token`，一并吊销） |

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

账单状态：`0` 未缴、`1` 部分缴、`2` 已缴、`3` 逾期、`4` 豁免。

#### 缴费记录

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/fee-payment | 列表 (?bill_id=&payment_method=&date_start=&date_end=) |
| POST | /admin/fee-payment/offline | 线下收款登记 |

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

#### 物业面板

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/dashboard/property | 物业统计（应收/入住率） |
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

#### 员工管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/staff | 列表 (?community_id=&status=) |
| POST | /admin/staff | 创建 |
| PUT | /admin/staff/{hashid} | 更新 |
| DELETE | /admin/staff/{hashid} | 删除 |
| POST | /admin/staff/batch/status | 批量启禁用 |

#### 支付管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /admin/payment-order | 订单列表 (?status=&channel=) |
| GET | /admin/payment-order/{hashid} | 订单详情（含账单信息） |
| POST | /admin/payment-order/create | 创建支付订单（{ bill_id, user_id, channel: wechat\|alipay, subject }），返回 order_number / pay_params / expire_at |
| POST | /admin/payment-order/reconcile | 对账（{ days=7 }，1–30 天），补齐漏单并重新入队未退溢缴款 |
| POST | /admin/payment-order/{hashid}/refund | 退款（{ amount, request_id }）；`request_id` 为幂等键，必填且不超过 64 字符 |
| GET | /admin/payment-order/statistics | 支付统计 |

退款支持部分退款，响应中的 `refund_amount` 为累计退款金额。订单响应含 `credited_amount`（实际入账金额）与 `overpaid_amount`（待退溢缴金额）；库表另有 `refund_request_id`（最近一次退款幂等键）。

支付回调：`POST /payment/wechat/callback`、`POST /payment/alipay/callback`（渠道验签 + 幂等）。

结算规则：在线支付入账金额以账单当前未缴金额为上限，超出部分进入自动退款队列 `payment_overpay_refund`；账单存在未过期的在线支付订单时，线下收款会被拒绝。

---

## 业务端 API (service :8788)

### 公开接口 — 无需认证

#### POST /api/v1/captcha/generate
获取点击验证码。（与管理端相同）

#### POST /api/v1/captcha/verify
校验点击验证码。（请求/响应与管理端相同）

#### POST /api/v1/auth/login
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

#### POST /api/v1/auth/register
业主注册。

请求参数:
| 参数 | 类型 | 说明 |
|------|------|------|
| phone | string | 手机号 |
| password | string | 密码（8-32 位，含大小写字母、数字和特殊字符 `@$!%*?&`） |
| name | string | 姓名 |
| captcha_key | string | 验证码 key |
| clicks | array | 点击坐标 |
| room_id | string | （可选）绑定房号 hashid |
| id_card_last4 | string | （可选）身份证后4位 |

#### POST /api/v1/auth/refresh
刷新 Token。仅接受 refresh 类型令牌；刷新后旧 refresh token 立即失效（轮换），access token 不能用于刷新。

---

### 业主端接口 — 需认证 (Bearer Token)

所有接口前缀 `/service`，需携带 `Authorization: Bearer {access_token}`。

#### 首页

**GET /service/v1/home**

响应:
```json
{
  "code": 0,
  "data": {
    "room_count": 2,
    "pending_amount": "1250.00",
    "pending_bill_count": 3,
    "announcements": [{ "id": "xB9k...", "title": "停水通知", "published_at": "2026-05-20 09:00" }]
  }
}
```

#### 我的房产

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /service/v1/rooms | 我的房产列表 |
| GET | /service/v1/room/{hashid} | 房产详情（含面积、朝向、产权、社区信息） |

#### 费用管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /service/v1/fees/bills | 账单列表 (?status=0未缴/1部分缴/2已缴/3逾期/4豁免) |
| GET | /service/v1/fees/bill/{hashid} | 账单详情（含费用类型、支付记录） |
| GET | /service/v1/fees/payments | 缴费记录 |
| POST | /service/v1/fees/pay | 在线缴费暂未接入支付网关（固定返回 503，请走管理端支付订单或线下缴费） |
| GET | /service/v1/fees/statistics | 费用统计 (?year=2026) |

#### 公告

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /service/v1/announcements | 公告列表 (?category=) |
| GET | /service/v1/announcement/{hashid} | 公告详情 |

#### 停车

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /service/v1/parking/vehicles | 我的车辆 |
| GET | /service/v1/parking/spaces | 我的车位 |
| GET | /service/v1/parking/records | 停车记录 |

#### 个人信息

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /service/v1/profile | 个人信息 |
| PUT | /service/v1/profile | 修改（{ name, email, gender, birthday }） |
| PUT | /service/v1/profile/password | 改密码（{ old_password, new_password }） |
| POST | /service/v1/profile/logout | 退出登录（可选传 `refresh_token`，一并吊销） |

---

## 开放 API — API Key 鉴权

入站对外只读接口，供第三方系统（物业平台对接等）调用。前缀 `/open`，全部只读。

### 鉴权方式

每个请求需携带请求头 `X-API-Key`，值为 `scripts/gen_api_key.php` 生成的 Key（64 位 hex，库中仅存 SHA-256 摘要）：

```bash
curl -H "X-API-Key: <你的Key>" http://localhost:8788/open/v1/announcements
```

- 缺失或错误的 Key 返回 `401`（`{"code":401,"message":"无效的API Key","data":[]}`）
- Key 管理：`php scripts/gen_api_key.php [--name=用途]` 生成；禁用/删除直接操作 `management_api_key` 表（`status=0` 即禁用，密钥立即失效）

### 端点

#### GET /open/v1/announcements — 公告列表

参数：`page`（默认 1）、`category`（可选）。响应结构与 `/service/v1/announcements` 一致。

```bash
curl -H "X-API-Key: <你的Key>" "http://localhost:8788/open/v1/announcements?page=1"
```

#### GET /open/v1/bills — 账单查询

参数：`bill_number`（必填，账单编号）。返回单个账单详情（含费用类型、房间号、欠费金额）。不存在返回 404。

```bash
curl -H "X-API-Key: <你的Key>" "http://localhost:8788/open/v1/bills?bill_number=B202608160001"
```

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
