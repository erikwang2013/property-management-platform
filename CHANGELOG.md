# Changelog

## v1.4.0 (2026-09-26)

### 新增
- **项目宠物「小筑」**：手绘 SVG 楼宇管家（靛蓝 `#4F46E5` + 暖橙 `#F59E0B`），含全身像与 16px 可辨识的图标标记，语言无关可被 13 种语言共用
- **四类手绘 SVG 设计图（中英双版）**：项目结构 / 架构设计 / 功能设计 / 生命周期，统一视觉体系（`docs/images/design_*.svg` 与 `design_*_en.svg`）

### 宠物接入
- `admin/public/favicon.svg` + `service/public/favicon.svg`（新增）+ 安装向导 `<link rel="icon">`
- 安装向导 step1~3 + 已安装页：宠物头像 + 分步引导气泡
- 404 / 504 错误页：新增 `admin/public/{404,504}.html` 与 service 同名副本，全部资源内联（后端宕机仍可显示）
- Flutter Web 登录页：`flutter_svg` + `assets/pet_xiaozhu.svg` 替换原 `Icons.apartment`
- 架构图「横切关注点」栏内嵌宠物形象

### 运维
- `admin/docs/nginx-security.conf` + `service/docs/nginx-security.conf` 增加 `error_page 404 / 500 502 503 504`，并注明后端宕机时改用磁盘 alias 的做法

### 文档
- 根 README / README_EN：新增「项目宠物 · 小筑」章节 + 简介接入宠物说明；原有 Mermaid 缩略图（架构/功能/生命周期）替换为手绘 SVG 图组
- 12 语言 i18n README：接入宠物图 + 本地化简介句，图表替换为共享英文版图（复用各语言既有标题，未新增翻译）
- docs/ARCHITECTURE_DESIGN / FEATURE_DESIGN / ARCHITECTURE_DIAGRAM / FUNCTION_DIAGRAM / LIFECYCLE_DIAGRAM 五篇接入总图与宠物插图
- 12 语言 i18n 文档镜像（`docs/i18n/*/docs/`）同步：ARCHITECTURE_DESIGN / ARCHITECTURE_DIAGRAM / FEATURE_DESIGN / FUNCTION_DIAGRAM / LIFECYCLE_DIAGRAM 五篇 × 12 语言 = 60 篇接入宠物与新图；标题沿用各语言既有译文，图片走共享的 `docs/images/`（无新增翻译、无图片副本）
- admin README（中英）：接入宠物图并说明本端已接入位置
- docs/INSTALL.md：安装向导章节接入宠物；新增品牌错误页 Nginx 接线说明
- apps/flutter/README.md：补充资产说明与「两处副本需同步」提示

### 测试
- Flutter `flutter analyze` 无问题；`flutter test` 9/9 通过（登录页宠物尺寸调至 96px 高以适配 600px 测试视口，修复 22px 溢出）

## v1.3.0 (2026-09-04)

### 变更
- **API 版本迁入接口路由**：版本号从请求头 `API-Version` 移入 URL（管理端 `/api/v1/*`；业主端 `/api/v1/*`、`/service/v1/*`、`/open/v1/*`），不再读取版本头
- 删除 admin / service 两端 `ApiVersion` 中间件（`config/route.php` 路由组直接绑定版本化控制器）
- 未知版本路径（如 `/api/v9/*`）由 FastRoute 直接返回 404（原版本头方案返回 400）
- CORS 允许头移除 `API-Version`；Redis 限流敏感路径键同步为 `/api/v1/auth/login|register`
- `hg/apidoc` 全局参数与 OpenAPI 文档（DocsController）移除 `API-Version` 安全方案与参数

### 客户端适配
- HarmonyOS `ApiService` 统一在路径首段后插入版本段（`versioned()` 助手，15+ 页面零改动）
- loadtest 脚本（login/smoke）路径与请求头同步更新

### 文档
- 根 docs（API/ARCHITECTURE/ARCHITECTURE_DESIGN/INSTALL/MOBILE_GAPS）+ 12 语言 i18n 镜像 + admin CLAUDE/README（中英）+ admin/docs 全量同步 URL 版本方案

### 测试
- admin 258 / service 198 用例全绿；修复限流测试残留 Redis key（`_api_v1_auth_login`）与遗留 ApiVersion 断言

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
