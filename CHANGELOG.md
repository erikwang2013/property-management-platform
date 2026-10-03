# Changelog

## v1.5.0 (2026-10-03)

### 新增
- **React 管理端（重新设计版）**：React 19 + Vite + Ant Design 6 + TanStack Query 5 + Zustand，13 模块 / 16 路由（登录、值班台、报表中心、小区、房产、业主、账单、缴费、报修、投诉、用户、角色权限、系统配置 / 操作日志 / 个人中心，含 404）
- **Angular 管理端（重新设计版）**：Angular 20（standalone + signals）+ NG-ZORRO + 自封装 ECharts，同样的 13 模块 / 16 路由
- 两端共用「小筑」设计语言（靛蓝 + 琥珀），为重新设计而非 Flutter 版移植；通用列表组件归一后端**三种分页形状**（Laravel 分页器 / `page`+`limit` / 无分页）后喂表格

### 修复
- **后端分页忽略 `?page=N`**：illuminate 的 `Paginator::$currentPageResolver` 全局未注册（`resolveCurrentPage()` 恒返默认 1），7 个业务模块（小区 / 房产 / 业主 / 账单 / 缴费 / 报修 / 投诉）列表恒返回第 1 页（total / 总页数正常）；service 端依赖 resolver 的 4 处同样受影响。新增 `admin/app/common/PaginationBootstrap.php` 与 `service/app/common/PaginationBootstrap.php`，并在两端 `config/bootstrap.php` 注册。验证边界：admin 端新增 `tests/PaginationBootstrapTest.php`（3 例 15 断言）通过、`php start.php restart -d` 启动无 bootstrap 告警；**service 端仅 `php -l` 通过，未做启动验证；两端均未用真实数据端到端验证翻页**
- **`/admin/report` 路由从未注册**：`ReportController` 存在但 `config/route.php` 从未注册该路径（`git log -S` 证实历史上也不存在），Flutter 存量端与 React / Angular 三端同调此路径，报表中心自 v1.2.0 起在真后端恒 404；已在 `/admin` 路由组补注册。验证边界：重启后无 token 请求由 404 HTML 变为 `{"code":401,"message":"未登录"}`（路由与中间件链生效），**带 token 真实取数未验证（DB 不可连）**；全量核对 156 处 `@Apidoc\Url` 注解未发现其他未注册接口，属孤例
- **报修接口员工 ID 对外统一为 hashid**：`staff_id` 编码后返回并新增 `staff_name`（一次 join），`assign` / `update` 改为接收 hashid（无效判 422）。此前该字段混用「原始数字 ID」与「员工列表的 hashid」两个不可互转的 ID 空间，前端无法显示维修人员姓名、派单也拿不到可提交的 ID。验证边界：仅 `php -l` + 重启后路由注册 + 无测试依赖旧契约；join 与编解码未经真实数据端到端验证（本机 DB 不可连）

### 变更
- **移除商业版本档位机制**：项目只保留 main 单一版本；删除 `lite` / `standard` / `full` 三个 git 分支（本地与 origin）、移除 `edition_supports()` 路由门控（admin / service 两侧路由改为无条件注册）、删除 `config/edition.php`、`EditionFeatureTest`、`EDITIONS` 环境变量与 `docs/EDITIONS.md`（含 12 语言镜像）。行为影响：`EDITIONS` 此前未设置、默认 full，故移除后路由注册范围与现状完全一致（非功能变更）
- **双端收尾裁决落地**（2026-10-03，已写入共享规格 `admin/apps/README.md` §1.3）：汇总卡措辞两端统一为「应收合计（元）/实收合计（元）/欠费合计（元）」（React 改齐，重建后产物锚点更新）；图表系列色序写死 8 位（前 5 位语义色 + 第 6–8 位扩展色 `#8B5CF6` / `#0EA5E9` / primary-dark，**不做 5 色循环截断**）；「颜色只走五档语义 token」明确只管页面模板/组件内联，样式表字面量豁免；汇总卡单位后缀、顶栏面包屑、`/reports` DOM 节点数三处差异裁定「记录不判定」

### 宠物接入
- React / Angular 两端各六处接线：`public/favicon.svg`（与 `docs/images/favicon.svg` 同源，MD5 一致）、登录页全身像（160px）+ 问候气泡、侧栏 28px 图标标记、值班台欢迎卡、列表空态插图、404 页
- 浏览器标签图标部署点由四个增至六个（新增 `admin/apps/react/public/`、`admin/apps/angular/public/`）

### 测试
- React：`pnpm build`（tsc -b + vite）零错误，`pnpm test` **7 文件 47/47** 通过（终版当场复跑）；无头浏览器逐页截图核对（登录页走真后端验证码），13 模块 / 16 路由全部渲染，宠物六处齐全；首轮 3 项规格偏差（卡片阴影、登录页大号控件圆角、表格行高）修复后复验通过
- Angular：`pnpm build`（ng build）零错误，`ng test` 38/38 通过；首轮验收 9 页运行时白屏（NG0201）与 4 项样式偏差已修复，15 个页面（13 路由 + 系统三页签 + 404）全部出图；终验中另发现并修复两处独立缺陷（见下条），已修复并经交互级复验通过
- Angular 终验修复的两处独立缺陷（两种成因、两种修法）：① **账单编辑页主线程冻结** —— 直接成因不是 locale，而是模板方法绑定在每次变更检测新建 `Date` 实例，触发 `NgModel` 身份判定变化与 `writeValue()` 内 `markForCheck()` 形成自循环，已用 `DateValueCache` 复用实例断环；② **日期本地化缺陷（NG0701，工程未 `registerLocaleData` zh）** 导致报表日期区间不可用，已注册 locale + `LOCALE_ID` 治根。复验：账单日期面板开 → 选 → 保存（PUT 带 `start_date`，主线程无卡死）、报表按日期区间出数
- 双端验证码点击坐标映射实测通过（点渲染区换算提交与期望坐标误差：Angular 0/0，React ≤1px 容差内）
- 双端新增页面级挂载冒烟测试（逐路由渲染，随 `pnpm test` / `ng test` 常跑）；破坏态复现（React 摘 Provider、Angular 摘 NzModalService 注册）下 `build` 仍 exit 0 —— 此类运行时崩溃 build 拦不住，冒烟测试是必要防线
- 边界：本机 MySQL 不可连，登录后页面截图均基于请求拦截桩数据，图表数据与导出未做端到端验证；后端分页修复仅有 admin 单测级证据（见「修复」）

## v1.4.0 (2026-09-26)

### 新增
- **项目宠物「小筑」**：手绘 SVG 楼宇管家（靛蓝 `#4F46E5` + 暖橙 `#F59E0B`），含全身像与 16px 可辨识的图标标记，语言无关可被 13 种语言共用
- **四类手绘 SVG 设计图（中英双版）**：项目结构 / 架构设计 / 功能设计 / 生命周期，统一视觉体系（`docs/images/design_*.svg` 与 `design_*_en.svg`）

### 宠物接入
- `admin/public/favicon.svg` + `service/public/favicon.svg` + `apps/flutter/web/favicon.svg` + `admin/apps/flutter/web/favicon.svg`（新增，四处同源）+ 安装向导 `<link rel="icon">`
- 安装向导 step1~3 + 已安装页：宠物头像 + 分步引导气泡
- 404 / 504 错误页：新增 `admin/public/{404,504}.html` 与 service 同名副本，全部资源内联（后端宕机仍可显示）
- Flutter Web 登录页（业主端 + 管理端）：`flutter_svg` + `assets/pet_xiaozhu.svg` 替换原 `Icons.apartment` / `Icons.admin_panel_settings`
- 架构图「横切关注点」栏内嵌宠物形象
- 图标标记补全瞳孔：原 `favicon.svg` 只有白色眼球，在 32px 下呈空白眼；补齐深色瞳孔并收小双眼，与架构图内嵌标记一致

### 运维
- `admin/docs/nginx-security.conf` + `service/docs/nginx-security.conf` 增加 `error_page 404 / 500 502 503 504`，并注明后端宕机时改用磁盘 alias 的做法

### 文档
- 根 README / README_EN：新增「项目宠物 · 小筑」章节 + 简介接入宠物说明；原有 Mermaid 缩略图（架构/功能/生命周期）替换为手绘 SVG 图组
- 12 语言 i18n README：接入宠物图 + 本地化简介句，图表替换为共享英文版图（复用各语言既有标题，未新增翻译）
- docs/ARCHITECTURE_DESIGN / FEATURE_DESIGN / ARCHITECTURE_DIAGRAM / FUNCTION_DIAGRAM / LIFECYCLE_DIAGRAM 五篇接入总图与宠物插图
- 12 语言 i18n 文档镜像（`docs/i18n/*/docs/`）同步：ARCHITECTURE_DESIGN / ARCHITECTURE_DIAGRAM / FEATURE_DESIGN / FUNCTION_DIAGRAM / LIFECYCLE_DIAGRAM 五篇 × 12 语言 = 60 篇接入宠物与新图；标题沿用各语言既有译文，图片走共享的 `docs/images/`（无新增翻译、无图片副本）
- admin README（中英）：接入宠物图并说明本端已接入位置
- docs/INSTALL.md：安装向导章节接入宠物；新增品牌错误页 Nginx 接线说明
- apps/flutter/README.md：补充资产说明与「三处副本需同步」提示
- admin/apps/flutter/README.md：新增资产章节（原先仅为脚手架默认内容）

### 测试
- 业主端 Flutter `flutter analyze` 无问题；`flutter test` 9/9 通过（登录页宠物尺寸调至 96px 高以适配 600px 测试视口，修复 22px 溢出）
- 管理端 Flutter `flutter analyze` 无问题；`flutter test` 通过
- 错误页与安装向导经无头浏览器截图核对；全部 SVG 通过 XML 合法性校验，无失效图片引用

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
