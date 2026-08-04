# 系统架构图 (System Architecture Diagram)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

以下 Mermaid 图表在 GitHub / GitLab / VS Code 中自动渲染。

---

## 1. 系统全景架构

```mermaid
graph TB
    subgraph CLIENTS["🖥️ 客户端层 (Client Layer)"]
        direction LR
        FW["Flutter Web<br/>PC 管理后台<br/>:3000"]
        SW["Flutter Web<br/>PC 业主端<br/>:3001"]
        HM["HarmonyOS App<br/>手机/平板"]
    end

    subgraph GATEWAY["🔀 网关层 (Gateway)"]
        NGINX["Nginx<br/>HTTPS · Gzip · 静态资源<br/>反向代理 · 负载均衡"]
    end

    subgraph APP["⚙️ 应用层 (Application Layer)"]
        direction LR
        subgraph ADMIN["admin webman :8787"]
            A_MW["中间件链<br/>SecurityFilter → RateLimit<br/>→ Auth → RBAC → AuditLog"]
            A_CTL["控制器 46个<br/>通用管理 · 22业务模块<br/>12扩展功能"]
            A_SVC["服务层<br/>Snowflake · Hashids<br/>Encryption · Scout"]
        end
        subgraph SVC["service webman :8788"]
            S_MW["中间件链<br/>SecurityFilter → RateLimit<br/>→ Auth"]
            S_CTL["控制器 17个<br/>业主端全部 API"]
            S_SVC["服务层<br/>Snowflake · Hashids<br/>Encryption"]
        end
    end

    subgraph DATA["💾 数据层 (Data Layer)"]
        direction LR
        MySQL[("MySQL 8.0<br/>64张表 · erik_ 前缀<br/>BIGINT 非自增主键")]
        Redis[("Redis 7.x<br/>缓存 · 限流<br/>Session")]
        ES[("Elasticsearch 8.x<br/>全文检索<br/>erik_ 索引前缀")]
    end

    subgraph SECURITY["🛡️ 安全层 (18层纵深防御)"]
        direction LR
        S1["验证码"] --> S2["密码确认"] --> S3["随机验证"] --> S4["安全扫描"]
        S5["攻击拦截"] --> S6["传输加密"] --> S7["JWT认证"] --> S8["会话限制"]
        S9["账号锁定"] --> S10["RBAC鉴权"] --> S11["限流保护"] --> S12["ID保护"]
        S13["请求加密"] --> S14["存储加密"] --> S15["展示脱敏"] --> S16["审计追溯"]
        S17["CSP防护"] --> S18["版权水印"]
    end

    CLIENTS --> GATEWAY
    GATEWAY --> ADMIN & SVC
    ADMIN --> MySQL & Redis & ES
    SVC --> MySQL & Redis & ES
    APP -.-> SECURITY
```

---

## 2. 分层架构详图

```mermaid
graph TD
    subgraph ROUTE["路由层"]
        R["config/route.php<br/>URL → Controller 映射<br/>admin 100+ · service 50+ 路由"]
    end

    subgraph MW["中间件链 (Middleware Chain)"]
        direction TB
        MW1["① SecurityFilter<br/>XSS · SQL注入 · CSRF 拦截"]
        MW2["② RateLimit<br/>Redis 滑动窗口限流"]
        MW3["③ ApiVersion<br/>API 版本校验"]
        MW4["④ Auth<br/>JWT Token 校验 · 会话限制"]
        MW5["⑤ Permission<br/>RBAC method.path 粒度鉴权"]
        MW6["⑥ OperationLog<br/>全量操作审计 · 8平台来源"]
    end

    subgraph CTL["控制器层"]
        C1["通用管理<br/>Dashboard · User · Role · Permission<br/>SystemConfig · File"]
        C2["核心业务 (10模块)<br/>Community · Building · Unit · Room<br/>Owner · Tenant · Fee · Repair · Announcement"]
        C3["辅助业务 (6模块)<br/>Parking · Equipment · Complaint<br/>Visitor · Contract · Finance"]
        C4["运营管理 (6模块)<br/>Patrol · Cleaning · Green<br/>Activity · Energy · Staff"]
        C5["扩展功能 (12模块)<br/>Notification · Approval · Payment · Vote<br/>SLA · Collection · Inspection · Mall<br/>Face · Group · Knowledge · DataScreen"]
    end

    subgraph MODEL["模型层"]
        M1["Eloquent ORM<br/>58个 Model"]
        M2["encryptable 自动加解密<br/>敏感字段 AES-256-CBC"]
        M3["webman-scout<br/>ES 自动索引同步"]
    end

    subgraph INFRA["基础设施"]
        I1["MySQL PDO"]
        I2["Redis Client"]
        I3["ES HTTP Client"]
    end

    R --> MW1 --> MW2 --> MW3 --> MW4 --> MW5 --> MW6
    MW6 --> C1 & C2 & C3 & C4 & C5
    C1 & C2 & C3 & C4 & C5 --> M1 --> M2 & M3
    M2 & M3 --> I1 & I2 & I3
```

---

## 3. 部署架构

```mermaid
graph TB
    subgraph EDGE["边缘层"]
        DNS["DNS<br/>erik.xyz"]
        CDN["CDN<br/>静态资源加速"]
    end

    subgraph DMZ["DMZ 区"]
        NGX["Nginx :443<br/>SSL 终止 · Gzip 压缩<br/>静态文件: Flutter Web build/"]
    end

    subgraph APPZONE["应用区 (可横向扩展)"]
        direction LR
        A1["admin webman<br/>:8787<br/>管理后台 API"]
        A2["admin webman<br/>:8787<br/>(副本)"]
        S1["service webman<br/>:8788<br/>业主端 API"]
        S2["service webman<br/>:8788<br/>(副本)"]
    end

    subgraph DATAZONE["数据区"]
        direction LR
        MYSQL[("MySQL 8.0<br/>主库")]
        MYSQL_R[("MySQL 8.0<br/>只读副本")]
        REDIS[("Redis 7.x<br/>缓存集群")]
        ES[("Elasticsearch 8.x<br/>搜索集群")]
    end

    subgraph MONITOR["监控区"]
        PROM["Prometheus<br/>指标采集"]
        GRAF["Grafana<br/>可视化面板"]
    end

    DNS --> CDN
    CDN --> NGX
    NGX --> A1 & A2 & S1 & S2
    A1 & A2 --> MYSQL & REDIS & ES
    S1 & S2 --> MYSQL_R & REDIS & ES
    MYSQL --> MYSQL_R
    A1 & A2 & S1 & S2 -.-> PROM
    PROM --> GRAF
```
