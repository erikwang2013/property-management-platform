# 安装指南

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

本文档引导你从零开始部署物业管理系统。

---

## 目录

1. [Web 安装向导（推荐）](#web-安装向导推荐)
2. [手动安装](#手动安装)
3. [Docker 部署](#docker-部署)
4. [默认账户](#默认账户)
5. [验证安装](#验证安装)
6. [常见问题](#常见问题)

---

## Web 安装向导（推荐）

项目内置了 Web 安装向导，启动管理端后通过浏览器即可完成全部配置。

### 使用步骤

```bash
# 1. 进入管理端目录
cd admin

# 2. 创建环境变量文件（从模板复制）
cp .env.example .env

# 3. 安装依赖
composer install --no-dev --optimize-autoloader

# 4. 启动服务
php start.php start -d
```

### 5. 打开安装向导

<img src="images/pet_xiaozhu.svg" alt="小筑 · 项目宠物" width="90" align="right">

浏览器访问 **`http://localhost:8787/install`**，按提示完成三步配置（安装向导由项目宠物「小筑」逐步引导）：

| 步骤 | 内容 | 说明 |
|------|------|------|
| 第1步 | 数据库配置 | 填写主机、端口、库名、用户名、密码 |
| 第2步 | 管理员账户 | 设置后台登录用户名和密码（至少6位） |
| 第3步 | 确认安装 | 核对配置信息，点击确认后自动执行安装 |

安装过程会自动完成：
1. 测试数据库连接
2. 写入 `.env` 配置文件
3. 导入全部 65 张数据表 + 权限种子
4. 创建管理员账户并授予超级管理员角色
5. 创建安装锁定文件 `public/.installed`

### 安装完成后

- 管理后台地址：`http://localhost:8787/admin`
- 安装向导将显示登录地址和账户信息
- 建议重启服务使配置生效：`php start.php restart -d`
- 如需重新安装，删除 `public/.installed` 文件即可

---

## 手动安装

### 环境要求

| 组件 | 版本要求 | 说明 |
|------|---------|------|
| PHP | 8.1+（推荐 8.3） | 需 pcntl、pdo_mysql、redis、gd、mbstring 扩展 |
| MySQL | 8.0+ | utf8mb4 字符集 |
| Redis | 6.0+ | 缓存、限流、Session |
| Composer | 2.x | PHP 依赖管理 |
| Elasticsearch | 8.x | 全文检索（可选，禁用则使用数据库查询） |
| Flutter SDK | 3.x | 仅前端开发需要 |

### PHP 扩展检查

```bash
php -m | grep -E "pcntl|pdo_mysql|redis|gd|mbstring|curl|json|xml|dom"
```

---

## 数据库初始化

### 1. 创建数据库

```bash
mysql -u root -p <<SQL
CREATE DATABASE IF NOT EXISTS management
  DEFAULT CHARSET utf8mb4
  COLLATE utf8mb4_unicode_ci;
SQL
```

### 2. 导入合并安装脚本

```bash
mysql -u root -p management < docs/install.sql
```

`docs/install.sql` 包含全部 65 张表 + RBAC 权限种子数据，采用 `CREATE TABLE IF NOT EXISTS` 确保可重复执行。

执行后验证：

```bash
mysql -u root -p management -e "SHOW TABLES;" | wc -l
# 应输出: 66（65张表 + 1行表头）
```

---

## 管理端部署

管理端运行在 `http://localhost:8787`，提供管理员后台 API。

```bash
cd admin

# 1. 配置环境变量
cp .env.example .env
# 编辑 .env，修改数据库密码、JWT 密钥等

# 2. 安装依赖
composer install --no-dev --optimize-autoloader

# 3. 启动服务
php start.php start -d
# -d 表示后台运行，不加 -d 可前台运行查看日志

# 4. 验证
curl http://localhost:8787/health
```

### 关键配置项（admin/.env）

| 配置项 | 说明 | 生产环境要求 |
|--------|------|-------------|
| `JWT_SECRET_KEY` | JWT 签名密钥 | 64 位以上随机字符串 |
| `HASHIDS_SALT` | ID 加密盐值 | 随机字符串，与 service 保持一致 |
| `SNOWFLAKE_DATACENTER_ID` | 数据中心 ID (0-31) | 多机房部署时需区分 |
| `SNOWFLAKE_WORKER_ID` | 工作节点 ID (0-31) | 同机房每台机器不同 |
| `ENCRYPTION_KEY` | API 传输加密密钥 | 32 字节随机字符串 |
| `ENCRYPTABLE_KEY` | 数据库字段加密密钥 | 32 字节随机字符串 |
| `DB_PASSWORD` | 数据库密码 | 强密码 |

---

## 业务端部署

业务端运行在 `http://localhost:8788`，提供业主端 API。

```bash
cd service

# 1. 配置环境变量
cp .env.example .env
# 编辑 .env，修改数据库密码、JWT 密钥等

# 2. 安装依赖
composer install --no-dev --optimize-autoloader

# 3. 启动服务
php start.php start -d

# 4. 验证
curl http://localhost:8788/health
```

> **注意：** admin 和 service 共享同一数据库（表前缀 `management_`）。两端 `HASHIDS_SALT` 相互独立（有意隔离：一端泄漏不至于对端 hashid 被反解，见 `.env.example` 注释），各自的 ID 由各自加解密。

---

## Docker 部署

### 一键部署（推荐）

```bash
bash scripts/deploy.sh
# 幂等：git pull → 补齐双端 .env 缺失密钥 → 双端 compose up → 建库校验 → 监控冒烟
# 已有密钥一律保留，只追加缺失键
```

### 手工部署单端（以管理端为例）

```bash
cd admin
cp .env.docker .env
php ../scripts/gen_env_keys.php --file=.env --replace-placeholders
# 模板中的 change-me* 占位符会被替换为随机密钥；已存在的真实密钥不会被覆盖
# 生产环境仍需复核 APP_URL / CORS_ALLOWED_ORIGIN 等非密钥配置

docker compose up -d
# 包含: Nginx + PHP + MySQL + Redis + Elasticsearch + Prometheus + Grafana + redis-exporter
# 业务端: cd service 重复上述三步（端口已预设偏移，可与 admin 同主机共存）
```

### 密钥规则

| 规则 | 说明 |
|------|------|
| 自动生成 | 缺失键追加、占位符（`change-me*`）替换为随机值，由 `gen_env_keys.php` 完成 |
| 旧密钥保留 | `.env` 中已有的真实密钥绝不改写；重复执行幂等 |
| ES 密码联动 | 替换 `ELASTIC_PASSWORD` 时会同步改写 `SCOUT_HOSTS` / `OPENSEARCH_PASSWORD` 中的内嵌凭证 |
| 加密密钥轮换 | `bash scripts/rotate_keys.sh`（旧 key 自动写入 `ENCRYPTION_PREVIOUS_KEYS`） |
| MySQL 密码 | 容器库名/用户/密码默认派生自 `DB_DATABASE/DB_USERNAME/DB_PASSWORD`，无需配置 `MYSQL_*` |

> 首次启动时 MySQL 数据卷为空，`docs/install.sql`（67 张表 + RBAC 种子）经 compose initdb 挂载自动导入；卷已有数据时不重复导入。
>
> ⚠️ Docker 部署后请勿再走 Web 安装向导（`/install`）改数据库配置——向导会重写 `.env` 的 `DB_*`，破坏容器内的 `DB_HOST=mysql` 连接。

### 服务端口规划

| 服务 | admin | service | 说明 |
|------|-------|---------|------|
| 应用 | 8787 | 8788 | webman HTTP |
| MySQL | 3306 | 3307 | 容器端口映射 |
| Redis | 6379 | 6380 | 容器端口映射 |
| Elasticsearch | 9200 | 9201 | 容器端口映射 |
| Prometheus / Grafana | 9090 / 3000 | 9091 / 3001 | 容器端口映射 |
| Nginx | 80/443 | 80/443 | 需错开部署（service 建议 8080/8443） |

> 同一主机部署两个 docker-compose 时，service 的除 Nginx 外端口已预设偏移避免冲突；Nginx 端口需在 `.env` 用 `NGINX_PORT`/`NGINX_SSL_PORT` 手动错开。

---

## 默认账户

| 用户名 | 密码 | 角色 | 说明 |
|--------|------|------|------|
| admin | admin123 | 超级管理员 | 拥有全部权限 |

> **生产环境请立即修改默认密码。**

---

## 验证安装

### 1. 健康检查

```bash
# 管理端
curl http://localhost:8787/health

# 业务端
curl http://localhost:8788/health
```

### 2. API 文档

全部 API 端点与参数说明见独立文档 [API.md](API.md)。启动服务后也可访问自动生成的交互式接口文档：

| 端 | 地址 |
|----|------|
| 管理端 | http://localhost:8787/apidoc |
| 业务端 | http://localhost:8788/apidoc |

### 3. 登录测试

```bash
curl -X POST http://localhost:8787/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

### 4. 运行测试

```bash
# 管理端
cd admin && php vendor/bin/phpunit

# 业务端
cd service && php vendor/bin/phpunit
```

| 项目 | 测试数 | 断言数 | 通过率 |
|------|--------|--------|--------|
| admin | 258 | 619 | 100% (2个DB门控跳过) |
| service | 201 | 661 | 100% (1个应用缺陷门控跳过) |
| **合计** | **459** | **1280** | — |

单元测试 / API 自动化 / 端到端测试报告见 [docs/tests/](../tests/)（admin-unit-report / service-unit-report / api-report / e2e-report / go-unit-report / rust-unit-report）。

---

## 常见问题

### Q: 启动报错 `Call to undefined function pcntl_fork()`

PHP 缺少 pcntl 扩展。

```bash
# Ubuntu/Debian
apt install php-pcntl

# Docker
docker-php-ext-install pcntl
```

### Q: 登录后提示 Token 无效

检查 admin 和 service 的 `.env` 中以下配置是否一致：
- `JWT_SECRET_KEY`
- `JWT_ALGORITHM`

### Q: 加密 ID 在两端不一致

确保 admin 和 service 的 `HASHIDS_SALT` 值完全相同。

### Q: Docker 容器间网络不通

使用容器名而非 IP 进行连接（如 `DB_HOST=mysql`）。

### Q: 如何重置数据库

```bash
mysql -u root -p -e "DROP DATABASE IF EXISTS management;"
mysql -u root -p -e "CREATE DATABASE management DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -p management < docs/install.sql
```

### Q: 如何配置 HTTPS

生产环境建议使用 Nginx 反向代理终止 TLS。参考配置见 `admin/docs/nginx-security.conf`。

参考配置已包含品牌错误页接线（错误页由项目宠物「小筑」出镜，全部资源内联，后端宕机时同样可显示）：

```nginx
error_page 404 /404.html;
error_page 500 502 503 504 /504.html;
```

对应静态文件位于 `admin/public/{404,504}.html` 与 `service/public/{404,504}.html`，由 webman 静态进程直接从 `public/` 提供。后端整体宕机时上面两条会因代理失败回落到 Nginx 默认页；如需此时也显示品牌错误页，把 `public/` 挂到本机磁盘后改用 `location = /404.html { alias …; internal; }`（参考配置中已注释给出）。

---

## 下一步

- [架构设计文档](ARCHITECTURE_DESIGN.md) — 系统分层架构与中间件执行链
- [API 文档](API.md) — 完整接口参考
- [功能设计文档](FEATURE_DESIGN.md) — 34 模块功能规格
