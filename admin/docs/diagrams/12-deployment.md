# 部署拓扑

> **历史文档（2026-10-30）**：ES/Scout、HarmonyOS、Angular/React 前端，以及报修、投诉、访客、合同、财务、社区活动、能耗、消息通知、审批、投票、催缴、集团、问答、巡检、商城、人脸、大屏等模块已移除。当前功能与架构以 README.md / docs/ 目录为准。


```mermaid
flowchart TB
    subgraph dns["DNS/CDN"]
        domain["erik.xyz"]
    end

    subgraph web["Web服务器"]
        nginx["Nginx :443 HTTPS<br/>:80→443 redirect<br/>gzip on"]
        static["静态文件<br/>Flutter Web build/"]
    end

    subgraph app["应用服务器(可横向扩展)"]
        wm1["webman worker 1 :8787"]
        wm2["webman worker 2 :8787"]
        wm3["webman worker N :8787"]
    end

    subgraph data["数据层"]
        mysql[("MySQL 8.0<br/>主从复制<br/>management_前缀")]
        redis[("Redis 7.x<br/>哨兵模式<br/>poster:captcha:*")]
    end

    subgraph monitor["监控"]
        grafana["Grafana+Prometheus"]
    end

    domain --> nginx
    nginx --> static
    nginx --> wm1
    nginx --> wm2
    nginx --> wm3
    wm1 & wm2 & wm3 --> mysql
    wm1 & wm2 & wm3 --> redis
    wm1 & wm2 & wm3 --> grafana

    style nginx fill:#722ED1,color:#fff
    style wm1 fill:#1677FF,color:#fff
    style wm2 fill:#1677FF,color:#fff
    style wm3 fill:#1677FF,color:#fff
    style mysql fill:#1890FF,color:#fff
    style redis fill:#1890FF,color:#fff
```
