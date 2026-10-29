# ID 全生命周期

> **历史文档（2026-10-30）**：ES/Scout、HarmonyOS、Angular/React 前端，以及报修、投诉、访客、合同、财务、社区活动、能耗、消息通知、审批、投票、催缴、集团、问答、巡检、商城、人脸、大屏等模块已移除。当前功能与架构以 README.md / docs/ 目录为准。


```mermaid
flowchart LR
    subgraph gen["1.生成"]
        g1["SnowflakeService::generate()"]
        g2["datacenter_id(5bit) + worker_id(5bit)<br/>+ timestamp(41bit) + sequence(12bit)"]
        g3["BIGINT(18)<br/>例: 1750123456789"]
        g1 --> g2 --> g3
    end

    subgraph store["2.存储"]
        s1["MySQL management_* 表<br/>id BIGINT UNSIGNED NOT NULL"]
        s2["敏感字段 encryptable cast<br/>AES-128-ECB 加密存储"]
        g3 --> s1 --> s2
    end

    subgraph transfer["3.传输"]
        t1["HashidsService::encode(bigint)"]
        t2["hashid字符串<br/>例: aB3xK9mW2pQ7rT5v"]
        s1 --> t1 --> t2
    end

    subgraph reverse["4.反向解码"]
        r1["HashidsService::decode(hashid)"]
        r2["BIGINT"]
        t2 --> r1 --> r2
    end

    style g1 fill:#1677FF,color:#fff
    style s2 fill:#FA8C16,color:#fff
    style t1 fill:#52C41A,color:#fff
    style r1 fill:#722ED1,color:#fff
```
