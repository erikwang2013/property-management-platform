# 贡献指南

## 项目结构

```
property-management-platform/
├── admin/          # 管理后台（webman v2 + Flutter）
├── service/        # 业主业务端（webman v2 + Flutter）
├── docs/           # 项目级文档
└── scripts/        # 工具脚本
```

## 开发环境

- PHP 8.3+
- MySQL 8.0
- Redis 7.2
- Composer 2.x
- Flutter 3.x（前端开发）

## 快速开始

```bash
# 管理后台
cd admin
cp .env.example .env
composer install
php start.php start

# 业主端
cd service
cp .env.example .env
composer install
php start.php start
```

## 代码规范

### PHP
- `declare(strict_types=1)` 所有文件
- 使用 `use` 导入，不加前置 `\`
- 配置文件含中文注释
- 新建 `.php` 文件头包含版权声明
- 运行 `vendor/bin/php-cs-fixer fix` 自动格式化
- 运行 `vendor/bin/phpstan analyse` 静态分析

### 数据库
- 表前缀 `erik_`
- 主键 BIGINT 非自增，由 Snowflake 生成
- 敏感字段使用 Encryptable trait
- 迁移文件使用 SQL 格式

### Flutter
- PC 管理后台风格（侧边栏 + 顶栏 + 内容区）
- GetX 状态管理
- `ApiService` 单例（Dio + JWT 拦截器）

## 提交规范

- 一个提交做一件事
- 提交信息使用中文，描述清楚改动原因
- 不提交 `.env`、`vendor/`、`runtime/` 等忽略文件

## 测试

```bash
cd admin && php vendor/bin/phpunit
cd service && php vendor/bin/phpunit
```

新增功能需补充对应测试。

## 安全

发现安全漏洞请通过 `security@erik.xyz` 私密报告，勿公开 Issue。
