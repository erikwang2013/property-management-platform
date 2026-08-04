# 物业管理系统 (Property Management Platform)

[English](README_EN.md) | 中文

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

全栈物业管理系统，覆盖22个业务模块 + 12个扩展功能（消息通知/审批工作流/支付/投票/SLA/催缴/巡检/商城/人脸/集团/智能问答）。管理员端（admin）和业主端（service）分离部署，前端覆盖 Flutter Web（PC 管理后台风格）与 HarmonyOS 移动端。

## 项目结构

```
property-management-platform/
├── admin/                         # 管理员端 webman v2 项目
│   ├── app/
│   │   ├── admin/controller/      # 管理端控制器
│   │   ├── api/v1/controller/     # 公开 API 控制器
│   │   ├── common/                # 公共工具类
│   │   ├── middleware/            # 中间件（认证/鉴权/限流/安全）
│   │   ├── model/                 # 数据模型（Eloquent ORM）
│   │   ├── queue/                 # 队列任务
│   │   └── process/               # 进程管理
│   ├── apps/
│   │   ├── flutter/               # 管理后台 Flutter Web（PC 风格）
│   │   └── harmonyos/             # 管理后台 HarmonyOS App
│   ├── config/                    # 配置文件（含中文注释）
│   ├── database/
│   │   ├── migrations/            # SQL 迁移文件
│   │   └── backup/                # 数据库备份脚本
│   ├── resource/
│   │   └── translations/          # 国际化语言文件（zh_CN / en）
│   ├── docs/                      # 管理端文档
│   ├── tests/                     # 单元测试
│   └── public/                    # Web 入口
├── service/                       # 业主业务端 webman v2 项目
│   ├── app/
│   │   ├── api/v1/controller/     # 业主端 API 控制器
│   │   ├── common/                # 公共工具类
│   │   ├── middleware/            # 中间件
│   │   ├── model/                 # 数据模型
│   │   └── process/               # 进程管理
│   ├── config/                    # 配置文件
│   ├── resource/
│   │   └── translations/          # 国际化语言文件
│   └── database/migrations/       # SQL 迁移文件
├── apps/
│   ├── flutter/                   # 业主端 Flutter Web（PC 风格）
│   └── harmonyos/                 # 业主端 HarmonyOS App
└── docs/                          # 项目文档
    ├── ARCHITECTURE.md
    ├── ARCHITECTURE_DESIGN.md
    ├── ARCHITECTURE_DIAGRAM.md    # 系统架构图
    ├── FLOWCHART.md               # 业务流程图
    ├── FUNCTION_DIAGRAM.md        # 功能模块图
    ├── LIFECYCLE_DIAGRAM.md       # 生命周期图
    ├── SECURITY_ARCHITECTURE.md   # 安全架构图
    ├── API.md
    ├── FEATURES.md
    └── FEATURE_DESIGN.md
```

## 项目规模

| 层 | 数量 | 详情 |
|----|------|------|
| 数据库表 | 64张 | 全部 `erik_` 前缀，BIGINT 非自增主键 |
| PHP 模型 | 58个 | 含 encryptable 加密字段 |
| admin 控制器 | 46个 | 通用管理 + 22个物业模块 + 12个扩展功能 |
| service 控制器 | 17个 | 业主端全部 API |
| API 路由 | 150+ | admin 100+ + service 50+ |
| Flutter 页面 | 10个 | 登录/首页/费用(3)/报修(3)/个人中心/公告 |
| HarmonyOS | 完整骨架 | 服务层 + 认证 + 登录/首页页面 |
| 测试 | 18/18 通过 | 45断言，100% 通过率 |

## 系统架构与设计图

> 以下为概要图，详细图表见 [架构图](docs/ARCHITECTURE_DIAGRAM.md) · [流程图](docs/FLOWCHART.md) · [功能图](docs/FUNCTION_DIAGRAM.md) · [生命周期图](docs/LIFECYCLE_DIAGRAM.md) · [安全架构图](docs/SECURITY_ARCHITECTURE.md)

### 系统全景架构

<img src="docs/images/readme_architecture.svg" alt="系统全景架构" width="100%">

### 核心业务流程

<img src="docs/images/readme_business_flow.svg" alt="核心业务流程" width="100%">

### 功能模块总览

<img src="docs/images/readme_modules.svg" alt="功能模块总览" width="100%">

### 数据实体生命周期

<img src="docs/images/readme_lifecycle.svg" alt="数据实体生命周期" width="100%">

### 18层安全纵深防御

<img src="docs/images/readme_security.svg" alt="18层安全纵深防御" width="100%">

## 功能模块（22大模块 + 12扩展）

| 批次 | 模块 | 状态 |
|------|------|------|
| 第1批 | 小区、楼栋、单元、户型、房产、业主、租户、费用、报修、公告（10模块） | ✅ 全部完成 |
| 第2批 | 停车、设备、投诉、访客、合同、财务 + 面板可视化 + Excel/PDF导出（8模块） | ✅ 全部完成 |
| 第3批 | 安保巡逻、保洁、绿化、社区活动、能耗、员工（6模块） | ✅ 全部完成 |
| 扩展 | 消息通知、审批工作流、支付集成、业主投票、SLA自动升级、数据大屏、智能催缴、巡检移动端、社区商城、人脸识别、多小区集团管理、智能问答（12模块） | ✅ 全部完成 |
| 第3批 | 安保巡逻、保洁、绿化、社区活动、能耗、员工（6模块） | ✅ 全部完成 |

## 技术栈

### 后端
- **框架**: webman v2 (workerman/webman)
- **语言**: PHP 8.3+
- **数据库**: MySQL 8.0+，表前缀 `erik_`，主键 BIGINT 非自增
- **搜索引擎**: Elasticsearch 8.x
- **缓存**: Redis 7.x

### 核心依赖
| 包名 | 用途 |
|------|------|
| `erikwang2013/snowflake-php` | 全局唯一 BIGINT 主键生成 |
| `erikwang2013/hashids` | API 层 ID 加解密 |
| `erikwang2013/jwt-webman` | JWT 认证（HS256） |
| `erikwang2013/encryption` | API 传输敏感数据 AES-256-CBC 加密 |
| `erikwang2013/encryptable` | 数据库敏感字段加解密 |
| `erikwang2013/webman-scout` | Elasticsearch 数据同步与全文检索 |
| `erikwang2013/season` | 国家旗帜数据 |
| `erikwang2013/security-php` | 安全工具检测 |
| `erikwang2013/poster-php` | 敏感操作随机验证码 |
| `phpoffice/phpspreadsheet` | Excel 导出 |
| `barryvdh/laravel-dompdf` | PDF 导出 |
| `hg/apidoc` | API 接口文档自动生成 |

### 前端
- **Flutter 3.x** + GetX（含 i18n） + Dio + fl_chart — PC 风格 Web 管理后台
- **HarmonyOS ArkTS** + @ohos.net.http — 移动端 App

### API 文档

启动服务后访问 apidoc 自动生成的接口文档：

| 端 | 地址 | 分组 |
|----|------|------|
| 管理端 | `http://localhost:8787/apidoc` | 7组（通用/仪表盘/系统管理/核心业务/辅助业务/高级功能/扩展功能） |
| 业主端 | `http://localhost:8788/apidoc` | 9组（公开接口/首页/费用/报修/反馈/停车/活动/个人/扩展） |

### 国际化

- **PHP 后端**: symfony/translation，语言文件位于 `resource/translations/{zh_CN,en}/messages.php`
- **Flutter Web**: GetX `Translations`，`apps/flutter/lib/i18n/messages.dart`
- **默认语言**: 简体中文（zh_CN），支持英语（en）切换
- **请求头**: 支持通过 `Accept-Language` 请求头控制响应语言

## 安全体系（18层纵深防御）

1. 点击验证码 → 2. 密码二次确认 → 3. poster 随机验证 → 4. security-php 安全扫描 → 5. SecurityFilter 攻击拦截 → 6. HTTPS + AES-256-CBC 传输加密 → 7. JWT HS256 认证 → 8. 并发会话限制(最多3个) → 9. 账号锁定(5次失败/15分钟) → 10. RBAC 权限鉴权(method.path 粒度) → 11. Redis 滑动窗口限流 → 12. Hashids ID 保护 → 13. 请求体敏感字段加密 → 14. DB 字段加密存储 → 15. 展示层数据脱敏 → 16. 操作日志全量审计(8平台来源端) → 17. CSP 头防护 → 18. PDF 版权水印

## 代码规范

- 所有新建文件头包含版权声明：`Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz`
- 全局函数/类引用使用 `use` 导入，不加前置 `\`
- 配置文件包含中文注释说明每个配置项
- 主键 ID 使用 BIGINT UNSIGNED NOT NULL，由 snowflake-php 应用层生成
- API 传输 ID 使用 hashids 加解密

## 快速开始

### 方式一：Web 安装向导（推荐）

启动管理端后访问 `http://localhost:8787/install`，通过界面完成数据库配置和后台管理员账户创建。

```bash
cd admin
cp .env.example .env
composer install
php start.php start -d
# 访问 http://localhost:8787/install 完成安装
```

详见 [安装指南](docs/INSTALL.md)。

### 方式二：手动安装

#### 环境要求

- PHP 8.1+
- MySQL 8.0+
- Redis 6.0+
- Composer 2.x
- Flutter SDK 3.x（前端开发）

#### 1. 初始化数据库

```bash
mysql -u root -e "CREATE DATABASE IF NOT EXISTS property_management DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root property_management < docs/install.sql
```

#### 2. 启动管理端

```bash
cd admin
cp .env.example .env
# 编辑 .env 修改数据库密码等配置
composer install
php start.php start -d
# 管理端运行在 http://localhost:8787
```

### 3. 启动业务端

```bash
cd service
cp .env.example .env
# 编辑 .env 修改数据库密码等配置
composer install
php start.php start -d
# 业务端运行在 http://localhost:8788
```

### 4. 启动前端（开发）

```bash
cd apps/flutter
flutter pub get
flutter run -d chrome
```

### 5. 运行测试

```bash
# 管理端测试
cd admin && php vendor/bin/phpunit

# 业务端测试
cd service && php vendor/bin/phpunit
```

| 项目 | 测试数 | 断言数 | 通过率 |
|------|--------|--------|--------|
| admin | 60 | 164 | 93.3% (4个预存配置问题) |
| service | 18 | 45 | 100% |
| **合计** | **78** | **209** | — |

service 测试覆盖: Snowflake ID、Hashids 编解码、响应格式、数据库 Schema、i18n 翻译文件

### Docker 部署

```bash
cd admin
cp .env.docker .env
docker-compose up -d
# 包含 Nginx + PHP + MySQL + Redis + Elasticsearch
```

## 部署拓扑

```
Nginx (:443) → admin webman (:8787) + service webman (:8788) → MySQL + Redis + Elasticsearch
静态文件: Flutter Web build/
```

## 默认管理员

| 用户名 | 密码 | 角色 |
|--------|------|------|
| admin | admin123 | 超级管理员 |

> 生产环境请立即修改默认密码。

## 文档索引

| 文档 | 说明 |
|------|------|
| [安装指南](docs/INSTALL.md) | 从零部署指南，含数据库初始化、Docker 部署、常见问题 |
| [合并安装脚本](docs/install.sql) | 全部 65 张表 + RBAC 权限种子数据，一键导入 |
| [版本对比](docs/EDITIONS.md) | 基础版(Lite) / 标准版(Standard) / 完整版(Full) 功能与技术指标对比 |
| [架构设计文档](docs/ARCHITECTURE_DESIGN.md) | 系统分层架构、中间件执行链、安全纵深防御设计 |
| [架构文档](docs/ARCHITECTURE.md) | Mermaid 架构图（系统拓扑、请求生命周期、数据加密、部署） |
| [系统架构图](docs/ARCHITECTURE_DIAGRAM.md) | 全景架构、分层详图、部署架构（Mermaid 可视化） |
| [业务流程图](docs/FLOWCHART.md) | 认证流程、费用管理、报修处理、房产管理、投诉、访客 |
| [功能模块图](docs/FUNCTION_DIAGRAM.md) | 34模块全景、依赖关系、管理后台功能树、业主端功能地图 |
| [生命周期图](docs/LIFECYCLE_DIAGRAM.md) | 请求生命周期、实体生命周期、Token生命周期、CRUD全流程 |
| [安全架构图](docs/SECURITY_ARCHITECTURE.md) | 18层纵深防御全景、攻击面防护矩阵、加密全链路、审计追溯体系 |
| [功能设计文档](docs/FEATURE_DESIGN.md) | 34模块功能规格说明 |
| [功能文档](docs/FEATURES.md) | 功能清单与模块概览 |
| [接口文档](docs/API.md) | 全部 API 端点与参数说明 |

## 支持项目

感谢您的支持！

| <img src="admin/docs/weixinpay.png" width="130" height="130" alt="微信支付"> | <img src="admin/docs/alipay.png" width="130" height="130" alt="支付宝"> |
|:---:|:---:|
| 微信支付 | 支付宝 |

欢迎支持本项目！

## License

MIT License. See [LICENSE](LICENSE) for details.
