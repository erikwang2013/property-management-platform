# 物业管理系统 — 业务端 (property-management-service)

基于 webman v2 的物业管理业务 API 系统。

## 版权声明

```
Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
```

> 不可修改、不可移除、不可逆。所有新建文件必须包含上述版权声明作为文件头注释。

## 技术栈

- PHP 8.3+, webman v2 (workerman/webman)
- 数据库: MySQL 8.0+，表前缀 `management_`
- 主键: BIGINT 非自增，`erikwang2013/snowflake-php`
- ID 混淆: `erikwang2013/hashids`
- JWT: `erikwang2013/jwt-webman`
- 传输加密: `erikwang2013/encryption`
- 存储加密: `erikwang2013/encryptable`

## 中间件执行链

```
全局: Cors → SecurityFilter → RateLimit → {路由中间件}
/api/v1: Cors → SecurityFilter → RateLimit → Controller
/service/v1: Cors → SecurityFilter → RateLimit → ServiceAuth → OperationLog → Controller
/open/v1: Cors → SecurityFilter → RateLimit → ApiKeyAuth → Controller
```

## 安全增强

- WAF: SecurityFilter（XSS/SQL注入/路径遍历/命令注入/CSRF）+ IP 黑名单升级；递归扫描嵌套 JSON
- 限流: Redis Lua 滑动窗口；业主注册 5 次/分钟
- CORS: 环境变量可配 + HSTS + CSP + 安全头
- 认证: JWT + 黑名单 + 并发会话限制 + 刷新轮换（旧 refresh 立即失效，access 不能当 refresh）
- 密码: 8-32 位 + 大小写字母 + 数字 + 特殊字符
- Session: Cookie secure + SameSite=Strict
- 加密: AES-256-CBC 传输 + 数据库字段级
- ID: Hashids 混淆；手机号检索走 `phone_hash` 盲索引
- 导出: Excel 清洗公式注入前缀；列表接口 page_size 上限 100
- Redis: requirepass 密码认证
- Docker: 非 root 用户运行

## 部署

```bash
cp .env.docker .env
php ../scripts/gen_env_keys.php --file=.env --replace-placeholders  # 占位密钥自动生成；已有密钥保留
docker compose up -d
# 或一键（推荐）: bash scripts/deploy.sh（双端一起，幂等）
```

编排: nginx + app(PHP 8.3) + mysql + redis + prometheus + grafana + redis-exporter（7 个服务，端口相对 admin 预设偏移）

> MySQL 容器的库名/用户/密码派生自 `DB_DATABASE/DB_USERNAME/DB_PASSWORD`；compose 必填插值 `MYSQL_ROOT_PASSWORD`/`GRAFANA_ADMIN_PASSWORD` 由生成脚本补齐。完整说明见根 README「Docker 部署」与 `docs/INSTALL.md`。

## CI/CD

GitHub Actions: PHP 语法 + Composer 审计 + PHPUnit（service 22 例/42 断言，覆盖率门槛 3%；admin 43 例/103 断言，门槛 1.7%）+ PHPStan + Flutter analyze/test（admin 1 例 + owner 10 例）

## 测试

| 项目 | 测试数 | 断言数 | 通过率 |
|------|--------|--------|--------|
| service | 22 | 42 | 100% |

测试覆盖: PasswordRule / Validator / PaginationBootstrap（纯单元测试，无需 DB/Redis）

## Nginx 安全配置

Docker 完整配置为 `deploy/nginx/default.conf`，容器内挂载为 `/etc/nginx/conf.d/default.conf`，反向代理 `app:8788`，`X-Forwarded-For` 以 `$remote_addr` 覆盖；`docs/nginx-security.conf` 仅是宿主机 Nginx 的安全头/片段参考。
