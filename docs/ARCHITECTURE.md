# 架构文档 (Architecture)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

> 以下 Mermaid 图表在 GitHub / GitLab / VS Code 中可自动渲染。其他环境请使用 [Mermaid Live Editor](https://mermaid.live/) 查看。

---

## 1. 系统拓扑架构

```mermaid
flowchart TB
    subgraph "客户端层"
        A1["Flutter Web<br/>PC 管理后台<br/>(Port 3000)"]
        A2["Flutter Web<br/>PC 业主端<br/>(Port 3001)"]
        A3["HarmonyOS ArkTS<br/>手机/平板客户端"]
    end

    subgraph "网关层 (Nginx)"
        B1["Nginx Edge Node<br/>反向代理 + HTTPS + Gzip<br/>静态文件服务"]
    end

    subgraph "应用层"
        C1["admin webman :8787<br/>管理后台 API<br/>JWT + RBAC"]
        C2["service webman :8788<br/>业主端 API<br/>JWT 认证"]
    end

    subgraph "存储层"
        D1[("MySQL 8.0<br/>主存储<br/>表前缀 erik_")]
        D2[("Elasticsearch 8.x<br/>全文检索")]
        D3[("Redis 7.x<br/>缓存/限流/Session")]
    end

    A1 & A2 & A3 --> B1
    B1 --> C1 & C2
    C1 & C2 --> D1 & D2 & D3
```

---

## 2. 后端分层架构

```mermaid
flowchart TD
    subgraph "路由层 Route"
        R1["config/route.php<br/>URL → Controller 映射"]
    end

    subgraph "中间件层 Middleware"
        M_SF["SecurityFilter<br/>攻击拦截<br/>XSS/SQL注入/CSRF"]
        M_RL["RateLimit<br/>Redis 滑动窗口限流"]
        M0["ApiVersion<br/>API 版本校验"]
        M1["AdminAuth / ServiceAuth<br/>JWT Token 校验"]
        M2["AdminPermission<br/>RBAC 鉴权<br/>method.path 粒度"]
        M_OP["OperationLog<br/>操作日志记录"]
    end

    subgraph "控制器层 Controller"
        CT["Dashboard / User / Role / Permission<br/>Community / Room / Owner / Fee<br/>Repair / Complaint / Announcement"]
    end

    subgraph "服务层 Service"
        S["HashidsService / SnowflakeService<br/>EncryptionService"]
    end

    subgraph "模型层 Model"
        MD["Eloquent ORM<br/>encryptable 自动加解密<br/>scout ES 同步"]
    end

    subgraph "驱动层 Driver"
        D["MySQL PDO / ES HTTP / Redis"]
    end

    R1 --> M_SF --> M_RL --> M0 --> M1 --> M2 --> M_OP --> CT
    CT --> S --> MD --> D
```

---

## 3. 请求生命周期

```mermaid
sequenceDiagram
    participant C as 客户端
    participant MW_SF as SecurityFilter
    participant MW_RL as RateLimit
    participant MW_AUTH as Auth 中间件
    participant CTL as Controller
    participant SVC as Service
    participant MDL as Model
    participant DB as MySQL

    C->>MW_SF: HTTPS 请求

    alt 非标准 HTTP 方法 (TRACE/CONNECT/PATCH...)
        MW_SF-->>C: 405 Method Not Allowed
    else 攻击检测触发 (XSS/SQL注入...)
        MW_SF-->>C: 403 Forbidden
    else 方法合法且无攻击
        MW_SF->>MW_RL: 通过
    end

    alt 限流触发
        MW_RL-->>C: 429 + Retry-After
    else 未超限
        MW_RL->>MW_AUTH: 通过
    end

    alt Token 缺失或无效
        MW_AUTH-->>C: 401 Unauthorized
    else Token 有效
        MW_AUTH->>MW_AUTH: jwt()->verify(token)
        MW_AUTH->>CTL: 注入 userId
    end

    CTL->>CTL: 参数验证 + decodeId(hashid)
    CTL->>CTL: 敏感操作 confirmPassword()
    CTL->>MDL: Model 查询/写入
    MDL->>MDL: encryptable 自动加解密
    MDL->>DB: SQL
    DB-->>MDL: 结果
    MDL-->>CTL: Model
    CTL->>SVC: encodeId(id) → hashid
    CTL->>CTL: 构建 JSON 响应
    CTL-->>C: 200 { code: 0, data: {...} }
```

---

## 4. 认证流程（含点击验证码）

```mermaid
sequenceDiagram
    participant U as 用户
    participant CL as 客户端
    participant SV as 服务端
    participant CAP as Captcha Service

    Note over U,CAP: === 获取验证码 ===
    CL->>SV: POST /api/captcha/generate
    SV->>CAP: captcha_create('click')
    CAP-->>SV: { key, image(base64), targets }
    SV-->>CL: 200 { key, image }

    Note over U,CAP: === 用户操作 ===
    CL->>CL: 渲染验证码图片
    U->>CL: 依次点击图中文字位置

    Note over U,CAP: === 登录 ===
    CL->>SV: POST /api/auth/login { phone, password, captcha_key, clicks }
    SV->>CAP: captcha_verify(key, 'click', clicks)
    alt 验证码错误
        SV-->>CL: 422 验证码错误
    else 验证码正确
        SV->>SV: Owner::where('phone', ...)
        SV->>SV: password_verify()
        alt 凭证错误
            SV-->>CL: 401 手机号或密码错误
        else 凭证正确
            SV->>SV: jwt()->create({sub, phone})
            SV-->>CL: 200 { access_token, refresh_token, owner }
        end
    end
```

---

## 5. RBAC 权限模型

```mermaid
flowchart LR
    subgraph "用户 User"
        U1["admin<br/>(超级管理员)"]
        U2["editor<br/>(编辑)"]
        U3["viewer<br/>(只读)"]
    end

    subgraph "角色 Role"
        R1["super_admin<br/>权限标识: *"]
        R2["editor<br/>权限标识: get.*, post.*"]
        R3["viewer<br/>权限标识: get.*"]
    end

    subgraph "权限 Permission (树)"
        P1["dashboard<br/>(菜单)"]
        P2["user<br/>(菜单)"]
        P3["get.admin/user<br/>(API)"]
        P4["post.admin/user<br/>(API)"]
        P5["delete.admin/user<br/>(API)"]
        P6["Community CRUD<br/>(API)"]
    end

    U1 --> R1
    U2 --> R2
    U3 --> R3
    R1 -->|"* 全权限"| P1 & P2 & P3 & P4 & P5 & P6
    R2 --> P1 & P2 & P3 & P4
    R3 --> P1 & P3
```

---

## 6. ID 全生命周期

```mermaid
flowchart LR
    subgraph "1. 生成"
        G1["SnowflakeService::generate()"]
        G2["BIGINT(18)<br/>例: 1750123456789"]
        G1 --> G2
    end

    subgraph "2. 存储"
        S1["MySQL erik_* 表<br/>id BIGINT UNSIGNED NOT NULL"]
        S2["敏感字段<br/>encryptable cast<br/>AES-256-CBC 加密"]
        G2 --> S1 --> S2
    end

    subgraph "3. 传输"
        T1["HashidsService::encode()"]
        T2["hashid 字符串<br/>例: aB3xK9mW2pQ7rT5v"]
        S1 --> T1 --> T2
    end

    subgraph "4. 解码"
        R1["HashidsService::decode()"]
        R2["BIGINT"]
        T2 --> R1 --> R2
    end
```

---

## 7. 数据加密分层

```mermaid
flowchart TB
    subgraph "传输层 (encryption)"
        E1["客户端发送敏感数据"]
        E2["AES-256-CBC 加密"]
        E3["API 传输密文"]
        E4["服务端解密处理"]
        E1 --> E2 --> E3 --> E4
    end

    subgraph "存储层 (encryptable)"
        D1["Model casts<br/>phone => Encryptable"]
        D2["写入自动加密"]
        D3["MySQL VARCHAR(500) 存储密文"]
        D4["读取自动解密"]
        D1 --> D2 --> D3 --> D4
    end

    subgraph "展示层 (mask)"
        M1["phone: 138****1234"]
        M2["email: a***@example.com"]
        D4 --> M1 & M2
    end

    E4 --> D1
```

---

## 8. 数据库 ER 关系（第1批）

```mermaid
erDiagram
    erik_community {
        BIGINT id PK "Snowflake"
        VARCHAR name "小区名称"
        VARCHAR address "详细地址"
        TINYINT status "0停用1正常"
    }

    erik_building {
        BIGINT id PK
        BIGINT community_id FK
        VARCHAR name "楼栋名称"
        TINYINT building_type "1塔楼2板楼3别墅4商业"
        INT floor_count "总层数"
    }

    erik_unit {
        BIGINT id PK
        BIGINT building_id FK
        VARCHAR name "单元名称"
    }

    erik_room {
        BIGINT id PK
        BIGINT community_id FK
        BIGINT building_id FK
        BIGINT unit_id FK
        VARCHAR room_number "房号"
        DECIMAL area_total "总面积"
        TINYINT status "0空置1已售2出租3自住"
    }

    erik_owner {
        BIGINT id PK
        VARCHAR name "姓名"
        VARCHAR phone "手机号加密"
        VARCHAR password "bcrypt"
        TINYINT status "0迁出1入住"
    }

    erik_room_owner {
        BIGINT id PK
        BIGINT room_id FK
        BIGINT owner_id FK
        TINYINT relation_type "1所有权2使用权3共有"
    }

    erik_fee_bill {
        BIGINT id PK
        BIGINT room_id FK
        BIGINT owner_id FK
        BIGINT fee_type_id FK
        DECIMAL amount "账单金额"
        TINYINT status "0未缴1部分缴2已缴3逾期"
    }

    erik_fee_payment {
        BIGINT id PK
        BIGINT bill_id FK
        BIGINT owner_id FK
        DECIMAL amount "支付金额"
        TINYINT payment_method "1微信2支付宝3现金"
    }

    erik_repair_order {
        BIGINT id PK
        BIGINT room_id FK
        BIGINT owner_id FK
        TINYINT category "1水电2门窗..."
        TINYINT status "0待派单1已派单2维修中3已完成"
    }

    erik_announcement {
        BIGINT id PK
        BIGINT community_id FK
        VARCHAR title "标题"
        TEXT content "内容"
        TINYINT is_published "0草稿1已发布"
    }

    erik_community ||--o{ erik_building : "community_id"
    erik_building ||--o{ erik_unit : "building_id"
    erik_community ||--o{ erik_room : "community_id"
    erik_building ||--o{ erik_room : "building_id"
    erik_unit ||--o{ erik_room : "unit_id"
    erik_room ||--o{ erik_room_owner : "room_id"
    erik_owner ||--o{ erik_room_owner : "owner_id"
    erik_room ||--o{ erik_fee_bill : "room_id"
    erik_owner ||--o{ erik_fee_bill : "owner_id"
    erik_fee_bill ||--o{ erik_fee_payment : "bill_id"
    erik_room ||--o{ erik_repair_order : "room_id"
    erik_owner ||--o{ erik_repair_order : "owner_id"
    erik_community ||--o{ erik_announcement : "community_id"
```

---

## 9. 部署拓扑

```mermaid
flowchart TB
    subgraph "DNS / CDN"
        DNS["erik.xyz"]
    end

    subgraph "Web 服务器"
        NGX["Nginx<br/>:443 HTTPS / Gzip<br/>静态文件: Flutter Web"]
    end

    subgraph "应用服务器 (可横向扩展)"
        WM1["admin webman :8787"]
        WM2["service webman :8788"]
    end

    subgraph "数据层"
        MYSQL["MySQL 8.0<br/>erik_ 前缀"]
        ES["Elasticsearch 8.x"]
        REDIS["Redis 7.x<br/>缓存/限流/Session"]
    end

    subgraph "监控"
        MON["Prometheus + Grafana<br/>GET /metrics"]
    end

    DNS --> NGX
    NGX --> WM1 & WM2
    WM1 & WM2 --> MYSQL & ES & REDIS
    WM1 & WM2 --> MON
```

---

## 10. 安全纵深防御全景

```mermaid
flowchart TB
    L1["第1层: 点击验证码<br/>登录/注册强制"] --> L2
    L2["第2层: 密码二次确认<br/>删除/缴费敏感操作"] --> L3
    L3["第3层: poster 随机验证<br/>高频敏感操作"] --> L4
    L4["第4层: security-php 扫描<br/>请求周期安全检测"] --> L5
    L5["第5层: SecurityFilter<br/>XSS/SQL注入/CSRF拦截"] --> L6
    L6["第6层: HTTPS + AES-256-CBC"] --> L7
    L7["第7层: JWT HS256<br/>2h过期 + 14d刷新"] --> L8
    L8["第8层: 并发会话限制<br/>最多3个Token"] --> L9
    L9["第9层: 账号锁定<br/>5次失败15分钟"] --> L10
    L10["第10层: RBAC 鉴权<br/>method.path 粒度"] --> L11
    L11["第11层: 限流保护<br/>Redis滑动窗口"] --> L12
    L12["第12层: Hashids ID保护<br/>不可逆推真实ID"] --> L13
    L13["第13层: 请求体加密<br/>AES-256-CBC"] --> L14
    L14["第14层: 存储加密<br/>encryptable DB字段"] --> L15
    L15["第15层: 展示脱敏<br/>138****1234"] --> L16
    L16["第16层: 审计追溯<br/>OperationLog全量记录"] --> L17
    L17["第17层: CSP头防护<br/>X-Permitted-Cross-Domain"] --> L18
    L18["第18层: PDF版权水印<br/>不可移除"]
```
