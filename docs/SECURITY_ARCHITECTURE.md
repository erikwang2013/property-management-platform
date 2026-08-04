# 安全架构图 (Security Architecture Diagram)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

以下 Mermaid 图表在 GitHub / GitLab / VS Code 中自动渲染。

---

## 1. 18层纵深防御全景

```mermaid
flowchart TB
    subgraph ACCESS["🔐 接入层 (Access Layer)"]
        direction LR
        L1["① 点击验证码<br/>captcha_create('click')<br/>登录/注册强制"]
        L2["② 密码二次确认<br/>confirmPassword()<br/>删除/缴费敏感操作"]
        L3["③ poster 随机验证<br/>高频敏感操作<br/>独立验证码通道"]
        L4["④ security-php 扫描<br/>请求周期安全检测<br/>恶意行为识别"]
    end

    subgraph GATE["🛡️ 网关层 (Gateway Layer)"]
        direction LR
        L5["⑤ SecurityFilter<br/>XSS · SQL注入 · CSRF<br/>非标准HTTP方法拦截"]
        L6["⑥ HTTPS + AES-256-CBC<br/>传输层加密<br/>erikwang2013/encryption"]
    end

    subgraph AUTH["🔑 认证层 (Auth Layer)"]
        direction LR
        L7["⑦ JWT HS256<br/>access_token: 2h<br/>refresh_token: 14d"]
        L8["⑧ 并发会话限制<br/>最多3个Token<br/>Redis 会话管理"]
        L9["⑨ 账号锁定<br/>5次失败/15分钟<br/>Redis 失败计数"]
    end

    subgraph AUTHZ["⚖️ 鉴权层 (AuthZ Layer)"]
        direction LR
        L10["⑩ RBAC 鉴权<br/>method.path 粒度<br/>超级管理员 * 跳过"]
        L11["⑪ 限流保护<br/>Redis 滑动窗口<br/>可配置阈值"]
    end

    subgraph DATA["🔒 数据层 (Data Layer)"]
        direction LR
        L12["⑫ Hashids ID 保护<br/>不可逆推真实ID<br/>API 传输 hashid"]
        L13["⑬ 请求体加密<br/>AES-256-CBC<br/>敏感字段加密传输"]
        L14["⑭ 存储加密<br/>encryptable cast<br/>DB 字段自动加解密"]
        L15["⑮ 展示脱敏<br/>138****1234<br/>a***@example.com"]
    end

    subgraph AUDIT["📝 审计层 (Audit Layer)"]
        direction LR
        L16["⑯ 操作日志全量审计<br/>8平台来源端自动检测<br/>用户/IP/路径/参数"]
        L17["⑰ CSP 头防护<br/>X-Permitted-Cross-Domain<br/>浏览器安全策略"]
        L18["⑱ PDF 版权水印<br/>不可移除<br/>Dompdf 渲染"]
    end

    ACCESS --> GATE --> AUTH --> AUTHZ --> DATA --> AUDIT
```

---

## 2. 请求安全处理链路

```mermaid
sequenceDiagram
    participant C as 客户端
    participant CAP as 验证码服务
    participant SF as SecurityFilter
    participant RL as RateLimit
    participant JWT as JWT Auth
    participant RBAC as RBAC 鉴权
    participant ENC as Encryption
    participant DB as 数据库
    participant LOG as AuditLog

    Note over C,LOG: === 请求入口 ===

    C->>CAP: ① 获取点击验证码
    CAP-->>C: { key, image(base64), targets }
    C->>C: ② 用户输入密码确认
    C->>C: ③ poster 随机验证

    rect rgb(255, 235, 235)
        Note over SF: ④⑤⑥ 安全网关
        C->>SF: HTTPS + AES-256-CBC 加密请求
        SF->>SF: XSS/SQL注入/CSRF 检测
        SF->>SF: 非标准HTTP方法拦截
        alt 攻击触发
            SF-->>C: 403/405
        end
    end

    rect rgb(235, 245, 255)
        Note over RL,JWT: ⑦⑧⑨ 认证检测
        SF->>RL: 滑动窗口限流检测
        alt 超限
            RL-->>C: 429
        end
        RL->>JWT: JWT Token 校验
        JWT->>JWT: 会话数检查 (≤3)
        JWT->>JWT: 账号锁定检查
        alt 认证失败
            JWT-->>C: 401/423
        end
    end

    rect rgb(255, 250, 235)
        Note over RBAC: ⑩⑪ 权限鉴权
        JWT->>RBAC: method.path 权限匹配
        RBAC->>RBAC: 超级管理员 * 跳过
        alt 无权限
            RBAC-->>C: 403
        end
    end

    rect rgb(235, 255, 235)
        Note over ENC,DB: ⑫⑬⑭⑮ 数据处理
        RBAC->>ENC: decodeId(hashid → BIGINT)
        ENC->>ENC: 请求体敏感字段解密
        ENC->>DB: encryptable 自动加解密
        DB-->>ENC: 查询结果
        ENC->>ENC: encodeId(BIGINT → hashid)
        ENC->>ENC: 敏感字段脱敏展示
    end

    rect rgb(240, 240, 240)
        Note over LOG: ⑯⑰⑱ 审计追溯
        ENC->>LOG: 操作日志记录
        LOG->>LOG: CSP 响应头注入
        LOG->>LOG: PDF 水印嵌入
    end

    ENC-->>C: 安全响应
```

---

## 3. 数据加密全链路

```mermaid
flowchart LR
    subgraph TX["传输加密"]
        direction TB
        T1["客户端原始数据"]
        T2["AES-256-CBC 加密<br/>erikwang2013/encryption"]
        T3["HTTPS 传输密文"]
        T4["服务端 AES-256-CBC 解密"]
        T1 --> T2 --> T3 --> T4
    end

    subgraph ID["ID 保护"]
        direction TB
        I1["BIGINT 原始 ID<br/>1750123456789"]
        I2["Hashids::encode()"]
        I3["hashid 字符串<br/>aB3xK9mW2pQ7rT5v"]
        I4["Hashids::decode()"]
        I5["BIGINT 原始 ID"]
        I1 --> I2 --> I3 --> I4 --> I5
    end

    subgraph DB["存储加密"]
        direction TB
        D1["Eloquent Model"]
        D2["encryptable cast<br/>写入自动加密"]
        D3["MySQL VARCHAR(500)<br/>存储密文"]
        D4["encryptable cast<br/>读取自动解密"]
        D1 --> D2 --> D3 --> D4
    end

    subgraph DISPLAY["展示脱敏"]
        direction TB
        M1["手机号<br/>13812341234"]
        M2["脱敏处理"]
        M3["138****1234"]
        M1 --> M2 --> M3
    end

    TX --> ID --> DB --> DISPLAY
```

---

## 4. 认证与授权模型

```mermaid
flowchart TB
    subgraph LOGIN["登录认证"]
        direction TB
        LG1["POST /api/auth/login<br/>{ phone, password, captcha }"]
        LG2{"验证码校验"}
        LG3["❌ 422 验证码错误"]
        LG4{"账号状态检查"}
        LG5["❌ 423 账号锁定"]
        LG6{"密码校验"}
        LG7["❌ 401 凭证错误"]
        LG8["✅ 生成 JWT Token"]
        LG1 --> LG2
        LG2 -->|"失败"| LG3
        LG2 -->|"通过"| LG4
        LG4 -->|"锁定"| LG5
        LG4 -->|"正常"| LG6
        LG6 -->|"错误"| LG7
        LG6 -->|"正确"| LG8
    end

    subgraph RBAC["RBAC 鉴权模型"]
        direction LR
        U["👤 User<br/>admin / editor / viewer"] --> R["🎭 Role<br/>super_admin / editor / viewer"]
        R --> P["🔑 Permission<br/>method.path 粒度"]
        P --> API["POST admin/user<br/>GET admin/user<br/>DELETE admin/user"]
    end

    subgraph TOKEN["Token 生命周期"]
        direction TB
        TK1["access_token<br/>⏰ 2h 过期"]
        TK2["refresh_token<br/>⏰ 14d 过期"]
        TK3["并发限制<br/>👥 最多3个"]
        TK4["登出销毁<br/>🗑️ Redis 删除"]
        TK1 --> TK3
        TK2 --> TK3
        TK3 --> TK4
    end

    LOGIN --> RBAC --> TOKEN
```

---

## 5. 攻击面防护矩阵

```mermaid
graph TB
    subgraph THREATS["威胁类型"]
        direction LR
        T1["XSS<br/>跨站脚本"]
        T2["SQL注入<br/>数据库攻击"]
        T3["CSRF<br/>跨站请求伪造"]
        T4["暴力破解<br/>密码枚举"]
        T5["DDoS<br/>流量攻击"]
        T6["数据泄露<br/>敏感信息"]
        T7["ID枚举<br/>遍历攻击"]
        T8["重放攻击<br/>请求重放"]
    end

    subgraph DEFENSE["防护措施"]
        direction LR
        D1["SecurityFilter<br/>输入过滤 · 输出编码"]
        D2["SecurityFilter<br/>参数化查询 · PDO预处理"]
        D3["SecurityFilter<br/>Token校验 · SameSite"]
        D4["账号锁定<br/>5次/15min · 验证码"]
        D5["RateLimit<br/>Redis滑动窗口限流"]
        D6["encryptable + encryption<br/>传输+存储双重加密"]
        D7["Hashids<br/>ID 不可逆编码"]
        D8["JWT过期 · Nonce<br/>时间戳校验"]
    end

    T1 --> D1
    T2 --> D2
    T3 --> D3
    T4 --> D4
    T5 --> D5
    T6 --> D6
    T7 --> D7
    T8 --> D8
```

---

## 6. 审计追溯体系

```mermaid
flowchart LR
    subgraph EVENT["事件来源"]
        direction TB
        E1["管理员操作<br/>POST/PUT/DELETE"]
        E2["业主操作<br/>缴费/报修/投诉"]
        E3["系统事件<br/>登录失败/限流触发"]
        E4["安全事件<br/>攻击拦截/账号锁定"]
    end

    subgraph RECORD["审计记录"]
        direction TB
        R1["user_id<br/>操作用户"]
        R2["ip + user_agent<br/>请求来源"]
        R3["method + path<br/>操作目标"]
        R4["params<br/>请求参数(已脱敏)"]
        R5["platform<br/>8平台来源端"]
        R6["created_at<br/>操作时间"]
    end

    subgraph OUTPUT["审计输出"]
        direction TB
        O1["📊 管理后台<br/>日志查询/筛选"]
        O2["📈 Prometheus<br/>安全指标采集"]
        O3["📋 Excel/PDF<br/>审计报表导出"]
    end

    E1 & E2 & E3 & E4 --> R1 & R2 & R3 & R4 & R5 & R6
    R1 & R2 & R3 & R4 & R5 & R6 --> O1 & O2 & O3
```
