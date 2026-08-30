# Changelog

## v1.2.0 (2026-08-31)

### 新增功能
- **管理端报表中心**：日期范围筛选（近30天/近90天/本年）+ 汇总卡片（应收/实收/欠费/收缴率/入住率）+ 收支趋势柱状图 + 缴费方式分布饼图 + 报修/投诉/访客状态分布 + 欠费排行 TOP10 + PDF 导出（Redis 5m 缓存）
- **业主起始页统计**：新增 待处理投诉 / 进行中活动 / 进行中投票 / 未读消息 统计卡片，Flutter Web 与 HarmonyOS 双端同步
- **一键安装**：根 README 增加 `bash scripts/deploy.sh` 一键部署说明

### 文档
- 根 README / README_EN / admin README（中英）增加 一键安装 + 使用说明 章节
- 功能模块表新增「平台功能」行（报表中心 + 起始页统计）
- 功能图（function_overview / function_admin_tree / readme_modules 中英）重新渲染，加入报表中心节点
- docs/FEATURES.md 新增 报表中心 + 业主端模块 章节
- 12 语言 i18n README 全量同步（一键安装 + 使用说明 + 功能行）

## v1.0.0 (2026-08-04)

### 管理后台 (admin)
- JWT 认证 + RBAC 权限鉴权（method.path 粒度）
- 仪表盘实时统计（Redis 5m 缓存）
- 用户/角色/权限 CRUD + 批量操作 + Excel 导入
- 34 个业务模块：小区/楼栋/单元/房产/业主/租户/费用/报修/公告/停车/设备/投诉/访客/合同/财务/安防/保洁/绿化/活动/能耗/员工/通知/审批/支付/投票/SLA/催缴/巡检/商城/人脸/集团/智能问答
- 57 个 Flutter Web 页面（PC 管理后台风格）
- 操作审计日志（8 平台来源检测 + 敏感字段脱敏）
- 18 层纵深防御：XSS/SQL注入/CSRF/限流/CSP/HSTS/IP黑名单
- Web 安装向导（三步部署）
- Docker Compose 生产编排 + GitHub Actions CI/CD
- Prometheus 监控指标端点

### 业主端 (service)
- JWT 业主认证 + 并发会话限制
- 房产管理/费用查询/在线缴费/报修提交
- 公告查看/投诉建议
- 23 个 Flutter Web 页面
- 7 个 HarmonyOS 页面
- 独立 Docker 编排（端口偏移，与 admin 共存）

### 安全
- 管理员端 90 个测试，业主端 43 个测试
- Dependabot 自动依赖更新
- Docker 非 root 运行 + Redis 密码认证 + ES 安全启用
- Nginx 安全配置参考

### 生态
- 中英文 README + 安装指南 + API 文档
- 架构/功能/安全设计文档
- Mermaid 架构图/流程图/功能图/生命周期图/安全架构图
