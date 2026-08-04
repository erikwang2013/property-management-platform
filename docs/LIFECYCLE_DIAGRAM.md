# 生命周期图 (Lifecycle Diagram)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

以下 Mermaid 图表在 GitHub / GitLab / VS Code 中自动渲染。

---

## 1. 请求生命周期

```mermaid
sequenceDiagram
    participant Client as 客户端
    participant Nginx as Nginx :443
    participant SF as SecurityFilter
    participant RL as RateLimit
    participant Auth as Auth 中间件
    participant RBAC as RBAC 鉴权
    participant Log as AuditLog
    participant CTL as Controller
    participant SVC as Service
    participant Model as Model
    participant DB as MySQL/Redis/ES

    Client->>Nginx: HTTPS 请求
    Nginx->>SF: 转发请求

    rect rgb(255, 230, 230)
        Note over SF: 安全检测
        SF->>SF: XSS/SQL注入/CSRF 检测
        alt 攻击检测触发
            SF-->>Client: 403 Forbidden
        end
    end

    rect rgb(230, 240, 255)
        Note over RL: 限流检测
        RL->>RL: Redis 滑动窗口计数
        alt 超过限流阈值
            RL-->>Client: 429 Too Many Requests
        end
    end

    rect rgb(230, 255, 230)
        Note over Auth: 身份认证
        Auth->>Auth: JWT Token 校验
        alt Token 无效/过期
            Auth-->>Client: 401 Unauthorized
        end
        Auth->>Auth: 检查并发会话 (≤3)
    end

    rect rgb(255, 255, 230)
        Note over RBAC: 权限鉴权
        RBAC->>RBAC: method.path 权限匹配
        alt 无权限
            RBAC-->>Client: 403 Forbidden
        end
    end

    CTL->>CTL: 参数验证
    CTL->>CTL: decodeId(hashid → BIGINT)
    CTL->>SVC: 调用服务层
    SVC->>Model: ORM 操作
    Model->>Model: encryptable 自动加解密
    Model->>DB: 执行查询
    DB-->>Model: 返回结果
    Model-->>SVC: 数据模型
    SVC-->>CTL: 处理结果
    CTL->>CTL: encodeId(BIGINT → hashid)
    CTL->>CTL: 构建 JSON 响应

    rect rgb(240, 240, 240)
        Note over Log: 操作审计
        Log->>Log: 记录操作日志<br/>(用户/IP/路径/参数/来源端)
    end

    CTL-->>Client: 200 { code: 0, data: {...} }
```

---

## 2. 数据实体生命周期 — 业主 (Owner)

```mermaid
stateDiagram-v2
    [*] --> 注册: POST /api/auth/register
    注册 --> 待审核: 提交手机号/密码/房产信息
    待审核 --> 已激活: 管理员审核通过
    待审核 --> 已拒绝: 管理员审核拒绝
    已拒绝 --> [*]

    已激活 --> 正常: 完成信息补全
    正常 --> 迁出: 退租/售房
    迁出 --> 正常: 重新入住
    正常 --> 锁定: 5次登录失败
    锁定 --> 正常: 15分钟后自动解锁
    正常 --> 禁用: 管理员禁用
    禁用 --> 正常: 管理员启用
    迁出 --> [*]: 注销账户
    禁用 --> [*]: 注销账户

    note right of 正常: 可进行缴费/报修/投诉等操作
    note right of 锁定: 禁止登录 15 分钟
```

---

## 3. 数据实体生命周期 — 费用账单 (Fee Bill)

```mermaid
stateDiagram-v2
    [*] --> 未缴: 管理员批量生成账单
    未缴 --> 部分缴: 业主部分支付
    部分缴 --> 已缴: 支付剩余金额
    未缴 --> 已缴: 一次性全额支付
    未缴 --> 逾期: 超过缴费截止日期
    部分缴 --> 逾期: 超过缴费截止日期
    逾期 --> 催缴: SLA 自动升级
    催缴 --> 已缴: 缴纳欠费+滞纳金
    已缴 --> [*]

    note right of 未缴: 推送缴费提醒
    note right of 逾期: 自动计算滞纳金
    note right of 催缴: 生成催缴通知单
```

---

## 4. 数据实体生命周期 — 报修工单 (Repair Order)

```mermaid
stateDiagram-v2
    [*] --> 待派单: 业主提交报修
    待派单 --> 已派单: 管理员指定维修工
    已派单 --> 维修中: 维修工接单
    维修中 --> 待验收: 维修完成/提交报告
    待验收 --> 已完成: 业主验收通过
    待验收 --> 维修中: 业主验收不通过
    已完成 --> 已评价: 业主提交评价
    已评价 --> [*]

    待派单 --> 已取消: 业主取消
    已派单 --> 已取消: 管理员取消
    已取消 --> [*]

    note right of 待派单: 自动通知管理员
    note right of 维修中: 可上传维修前后照片
    note right of 已评价: 评分 1-5 星
```

---

## 5. JWT Token 生命周期

```mermaid
sequenceDiagram
    participant User as 用户
    participant Server as 服务端
    participant Redis as Redis

    Note over User,Redis: === 登录 ===
    User->>Server: POST /api/auth/login
    Server->>Server: 验证凭证
    Server->>Server: jwt()->create({ sub, phone })
    Note over Server: access_token: 2h 过期<br/>refresh_token: 14d 过期
    Server->>Redis: 存储 Token (最多3个)
    Server-->>User: { access_token, refresh_token }

    Note over User,Redis: === 正常请求 ===
    loop 每次 API 请求
        User->>Server: Authorization: Bearer {access_token}
        Server->>Server: jwt()->verify(token)
        alt Token 有效
            Server-->>User: 正常响应
        else Token 过期
            Server-->>User: 401 Token Expired
        end
    end

    Note over User,Redis: === 刷新 ===
    User->>Server: POST /api/auth/refresh { refresh_token }
    Server->>Server: 验证 refresh_token
    Server->>Redis: 更新 Token
    Server-->>User: { new_access_token, new_refresh_token }

    Note over User,Redis: === 登出 ===
    User->>Server: POST /api/auth/logout
    Server->>Redis: 删除 Token
    Server-->>User: 200 已登出
```

---

## 6. 数据库记录完整生命周期

```mermaid
flowchart TB
    subgraph CREATE["1️⃣ 创建"]
        C1["生成 Snowflake ID<br/>BIGINT(18) 全局唯一"]
        C2["填充业务数据"]
        C3["encryptable 加密敏感字段"]
        C4["INSERT INTO erik_*"]
        C5["webman-scout 同步 ES 索引"]
        C1 --> C2 --> C3 --> C4 --> C5
    end

    subgraph READ["2️⃣ 读取"]
        R1["接收请求 → decodeId(hashid)"]
        R2["Model::find() / query()"]
        R3["encryptable 自动解密"]
        R4["encodeId() → hashid 返回"]
        R5["敏感字段脱敏展示"]
        R1 --> R2 --> R3 --> R4 --> R5
    end

    subgraph UPDATE["3️⃣ 更新"]
        U1["权限校验 (RBAC)"]
        U2["敏感操作 → confirmPassword()"]
        U3["Model::update()"]
        U4["encryptable 自动加密新值"]
        U5["ES 索引自动更新"]
        U6["OperationLog 记录变更"]
        U1 --> U2 --> U3 --> U4 --> U5 --> U6
    end

    subgraph DELETE["4️⃣ 删除"]
        D1["权限校验 (RBAC)"]
        D2["敏感操作 → confirmPassword()"]
        D3["poster 随机验证码"]
        D4["软删除 / 硬删除"]
        D5["ES 索引同步删除"]
        D6["OperationLog 记录"]
        D1 --> D2 --> D3 --> D4 --> D5 --> D6
    end

    CREATE --> READ
    READ --> UPDATE
    UPDATE --> READ
    UPDATE --> DELETE
```
