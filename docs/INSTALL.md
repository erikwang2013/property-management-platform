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

浏览器访问 **`http://localhost:8787/install`**，按提示完成三步配置：

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
CREATE DATABASE IF NOT EXISTS property_management
  DEFAULT CHARSET utf8mb4
  COLLATE utf8mb4_unicode_ci;
SQL
```

### 2. 导入合并安装脚本

```bash
mysql -u root -p property_management < docs/install.sql
```

`docs/install.sql` 包含全部 65 张表 + RBAC 权限种子数据，采用 `CREATE TABLE IF NOT EXISTS` 确保可重复执行。

执行后验证：

```bash
mysql -u root -p property_management -e "SHOW TABLES;" | wc -l
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

> **注意：** admin 和 service 共享同一数据库。`HASHIDS_SALT` 必须与 admin 保持一致，否则 admin 生成的加密 ID 在 service 端无法解密。

---

## Docker 部署

### 管理端

```bash
cd admin
cp .env.docker .env
# 编辑 .env 修改生产密钥

docker compose up -d
# 包含: Nginx + PHP + MySQL + Redis + Elasticsearch
```

### 业务端

```bash
cd service
cp .env.docker .env
# 编辑 .env 修改生产密钥

docker compose up -d
```

### 服务端口规划

| 服务 | admin | service | 说明 |
|------|-------|---------|------|
| 应用 | 8787 | 8788 | webman HTTP |
| MySQL | 3306 | 3307 | 容器端口映射 |
| Redis | 6379 | 6380 | 容器端口映射 |
| Elasticsearch | 9200 | 9201 | 容器端口映射 |
| Nginx | 80/443 | 80/443 | 需错开部署 |

> 同一主机部署两个 docker-compose 时，service 的端口已预设偏移避免冲突。

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

启动服务后访问自动生成的接口文档：

| 端 | 地址 |
|----|------|
| 管理端 | http://localhost:8787/apidoc |
| 业务端 | http://localhost:8788/apidoc |

### 3. 登录测试

```bash
curl -X POST http://localhost:8787/api/auth/login \
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
mysql -u root -p -e "DROP DATABASE IF EXISTS property_management;"
mysql -u root -p -e "CREATE DATABASE property_management DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -p property_management < docs/install.sql
```

### Q: 如何配置 HTTPS

生产环境建议使用 Nginx 反向代理终止 TLS。参考配置见 `admin/docs/nginx-security.conf`。

---

## 下一步

- [架构设计文档](ARCHITECTURE_DESIGN.md) — 系统分层架构与中间件执行链
- [API 文档](API.md) — 完整接口参考
- [功能设计文档](FEATURE_DESIGN.md) — 34 模块功能规格
- [版本对比](EDITIONS.md) — Lite / Standard / Full 版本差异
