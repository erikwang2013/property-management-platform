# 系统拓扑架构

> **历史文档（2026-10-30）**：ES/Scout、HarmonyOS、Angular/React 前端，以及报修、投诉、访客、合同、财务、社区活动、能耗、消息通知、审批、投票、催缴、集团、问答、巡检、商城、人脸、大屏等模块已移除。当前功能与架构以 README.md / docs/ 目录为准。


```mermaid
flowchart TB
    subgraph clients["客户端层"]
        flutter["Flutter Web<br/>PC管理后台"]
    end

    subgraph gateway["网关层"]
        nginx["Nginx<br/>HTTPS反向代理<br/>Gzip压缩"]
    end

    subgraph app["应用层 - webman v2"]
        auth["AdminAuth<br/>JWT验证"]
        perm["AdminPermission<br/>RBAC鉴权"]
        admin["管理端Controller<br/>Dashboard/User/Role/Permission"]
        public["公开Controller<br/>Captcha/Auth"]
        common["Common Services<br/>Hashids/Snowflake/Encryption"]
    end

    subgraph storage["存储层"]
        mysql[("MySQL 8.0<br/>主存储 - management_前缀")]
        redis[("Redis<br/>Session/缓存/Captcha")]
    end

    flutter --> nginx
    nginx --> auth
    auth --> perm
    perm --> admin
    auth --> public
    admin --> common
    public --> common
    admin --> mysql
    public --> mysql
    auth --> redis
    public --> redis

    style flutter fill:#1677FF,color:#fff
    style nginx fill:#722ED1,color:#fff
    style auth fill:#FA8C16,color:#fff
    style perm fill:#FA8C16,color:#fff
    style common fill:#52C41A,color:#fff
    style mysql fill:#1890FF,color:#fff
    style redis fill:#1890FF,color:#fff
```
