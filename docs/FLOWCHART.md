# 业务流程图 (Business Flowchart)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

以下 Mermaid 图表在 GitHub / GitLab / VS Code 中自动渲染。

---

## 1. 用户认证流程

```mermaid
sequenceDiagram
    actor User as 用户
    participant Client as 客户端
    participant Server as 服务端
    participant DB as 数据库
    participant Redis as Redis

    Note over User,Redis: === 登录流程 ===

    Client->>Server: POST /api/captcha/generate
    Server->>Redis: 生成点击验证码
    Redis-->>Server: { key, image }
    Server-->>Client: 200 { key, image(base64) }

    User->>Client: 点击图中文字
    Client->>Server: POST /api/auth/login { phone, password, captcha_key, clicks }

    Server->>Redis: 校验验证码
    alt 验证码错误
        Server-->>Client: 422 验证码错误
    else 验证码正确
        Server->>DB: 查询用户
        DB-->>Server: 用户信息
        alt 账号锁定 (5次失败/15min)
            Server-->>Client: 423 账号已锁定
        else 凭证错误
            Server->>Redis: 记录失败次数
            Server-->>Client: 401 手机号或密码错误
        else 凭证正确
            Server->>Redis: 检查并发会话 (≤3)
            Server->>Server: jwt()->create({ sub, phone })
            Server-->>Client: 200 { access_token, refresh_token, user }
        end
    end
```

---

## 2. 核心业务流程 — 费用管理

```mermaid
flowchart TB
    subgraph BILL["📋 账单生成"]
        direction TB
        B1["管理员设置费用类型<br/>(物业费/水费/电费/燃气费)"]
        B2["选择目标范围<br/>(小区/楼栋/单元/房产)"]
        B3["批量生成账单<br/>Snowflake ID × N"]
        B4["账单状态: 未缴"]
        B1 --> B2 --> B3 --> B4
    end

    subgraph PAY["💳 缴费流程"]
        direction TB
        P1["业主查看账单列表"]
        P2["选择账单 → 确认金额"]
        P3{"选择支付方式"}
        P4["微信支付"]
        P5["支付宝"]
        P6["线下收款<br/>(管理员代收)"]
        P7["生成支付订单<br/>回调验签"]
        P8["更新账单状态: 已缴"]
        P1 --> P2 --> P3
        P3 --> P4 & P5 & P6
        P4 & P5 --> P7 --> P8
        P6 --> P8
    end

    subgraph OVERDUE["⚠️ 逾期处理"]
        direction TB
        O1["定时任务扫描逾期账单"]
        O2["计算滞纳金"]
        O3["推送催缴通知"]
        O4["SLA 自动升级"]
        O1 --> O2 --> O3 --> O4
    end

    B4 --> P1
    P8 -.->|"未按时缴费"| O1
    O4 -.->|"重新进入"| P1
```

---

## 3. 报修处理流程

```mermaid
stateDiagram-v2
    [*] --> 待派单: 业主提交报修
    待派单 --> 已派单: 管理员派单给维修工
    已派单 --> 维修中: 维修工接单
    维修中 --> 待验收: 维修完成
    待验收 --> 已完成: 业主验收通过
    待验收 --> 维修中: 业主验收不通过
    已完成 --> 已评价: 业主评价
    已评价 --> [*]

    note right of 待派单: 自动通知管理员
    note right of 已派单: 短信/App通知维修工
    note right of 维修中: 可上传维修照片
    note right of 已完成: 记录维修费用
```

---

## 4. 房产管理流程

```mermaid
flowchart LR
    subgraph SETUP["🏘️ 基础数据建立"]
        direction TB
        S1["创建小区<br/>Community"] --> S2["创建楼栋<br/>Building"]
        S2 --> S3["创建单元<br/>Unit"]
        S3 --> S4["创建户型<br/>RoomType"]
        S4 --> S5["创建房产<br/>Room"]
    end

    subgraph BIND["👤 业主绑定"]
        direction TB
        B1["创建业主<br/>Owner"] --> B2["绑定房产关系<br/>RoomOwner"]
        B2 --> B3{"关系类型"}
        B3 --> B4["所有权"]
        B3 --> B5["使用权"]
        B3 --> B6["共有权"]
    end

    subgraph MANAGE["📊 日常管理"]
        direction TB
        M1["费用账单关联"]
        M2["报修工单关联"]
        M3["停车位关联"]
        M4["投诉建议关联"]
    end

    S5 --> B1
    B2 --> M1 & M2 & M3 & M4
```

---

## 5. 投诉建议处理流程

```mermaid
sequenceDiagram
    actor Owner as 业主
    participant Svc as service API
    participant Admin as admin API
    actor Staff as 管理员

    Owner->>Svc: 提交投诉 { type, content, images }
    Svc->>Svc: 生成投诉记录
    Svc-->>Owner: 200 提交成功

    Svc->>Admin: 通知新投诉
    Admin-->>Staff: 待处理提醒

    Staff->>Admin: 受理投诉 → 状态: 处理中
    Admin->>Admin: 分配处理人
    Staff->>Admin: 处理完成 → 填写处理结果
    Admin-->>Svc: 同步状态

    Svc-->>Owner: 推送处理结果

    Owner->>Svc: 确认/不满意
    alt 不满意
        Svc->>Admin: 退回重新处理
        Admin-->>Staff: 重新处理通知
    else 满意
        Svc->>Svc: 状态: 已完成
        Owner->>Svc: 评价 (1-5星)
    end
```

---

## 6. 访客通行流程

```mermaid
flowchart TB
    A["业主提交访客预约<br/>{ 访客姓名, 手机号, 来访时间, 车牌号 }"] --> B{"管理员审批"}
    B -->|"通过"| C["生成通行码<br/>(二维码/数字码)"]
    B -->|"拒绝"| D["通知业主拒绝原因"]
    C --> E["推送通行码给访客"]
    E --> F["访客到达 → 出示通行码"]
    F --> G{"门禁验证"}
    G -->|"有效"| H["放行 + 记录"]
    G -->|"无效/过期"| I["拒绝 + 通知业主"]
    H --> J["访客离开 → 签退"]
    J --> K["记录存档"]
```
