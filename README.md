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

### 环境要求

- PHP 8.1+
- MySQL 8.0+
- Redis 6.0+
- Composer 2.x
- Flutter SDK 3.x（前端开发）

### 1. 初始化数据库

```bash
# 创建数据库
mysql -u root -e "CREATE DATABASE IF NOT EXISTS property_management DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# 导入管理端数据表
mysql -u root property_management < admin/database/migrations/2026_05_16_000000_init_tables.sql
mysql -u root property_management < admin/database/migrations/2026_05_20_000001_seed_permissions.sql
mysql -u root property_management < admin/database/migrations/2026_05_21_000002_add_source_to_operation_log.sql
mysql -u root property_management < admin/database/migrations/2026_05_22_000001_property_batch1_tables.sql
```

### 2. 启动管理端

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
| [版本对比](docs/EDITIONS.md) | 基础版(Lite) / 标准版(Standard) / 完整版(Full) 功能与技术指标对比 |
| [架构设计文档](docs/ARCHITECTURE_DESIGN.md) | 系统分层架构、中间件执行链、安全纵深防御设计 |
| [架构文档](docs/ARCHITECTURE.md) | Mermaid 架构图（系统拓扑、请求生命周期、数据加密、部署） |
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
