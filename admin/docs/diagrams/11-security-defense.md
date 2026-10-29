# 安全纵深防御

> **历史文档（2026-10-30）**：ES/Scout、HarmonyOS、Angular/React 前端，以及报修、投诉、访客、合同、财务、社区活动、能耗、消息通知、审批、投票、催缴、集团、问答、巡检、商城、人脸、大屏等模块已移除。当前功能与架构以 README.md / docs/ 目录为准。


```mermaid
flowchart TB
    l1["第1层: 人机验证<br/>点击验证码ClickCaptcha<br/>登录/注册强制校验"]
    l2["第2层: 操作确认<br/>密码二次确认<br/>DELETE操作必须"]
    l3["第3层: 传输安全<br/>HTTPS + JWT Bearer<br/>AES-256-CBC"]
    l4["第4层: 身份认证<br/>JWT HS256<br/>access_token 2h<br/>refresh_token 14d"]
    l5["第5层: 权限鉴权<br/>RBAC method.path粒度<br/>超级管理员*"]
    l6["第6层: 数据保护<br/>ID:Hashids加密<br/>请求:Encryption加密<br/>存储:Encryptable加密<br/>导出:脱敏+版权"]
    l7["第7层: 审计追溯<br/>OperationLog<br/>用户/IP/时间/参数"]

    l1 --> l2 --> l3 --> l4 --> l5 --> l6 --> l7

    style l1 fill:#1677FF,color:#fff
    style l2 fill:#1677FF,color:#fff
    style l3 fill:#FA8C16,color:#fff
    style l4 fill:#FA8C16,color:#fff
    style l5 fill:#52C41A,color:#fff
    style l6 fill:#722ED1,color:#fff
    style l7 fill:#FF4D4F,color:#fff
```
