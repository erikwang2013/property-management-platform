# 物业管理系统 — 业务端 (property-management-service)

基于 webman v2 的物业管理业务 API 系统。

## 版权声明

```
Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
```

> 不可修改、不可移除、不可逆。所有新建文件必须包含上述版权声明作为文件头注释。

## 技术栈

- PHP 8.3+, webman v2 (workerman/webman)
- 数据库: MySQL 8.0+，表前缀 `erik_`
- 主键: BIGINT 非自增，`erikwang2013/snowflake-php`
- ID 混淆: `erikwang2013/hashids`
- JWT: `erikwang2013/jwt-webman`
- 传输加密: `erikwang2013/encryption`
- 存储加密: `erikwang2013/encryptable`
- ES: `erikwang2013/webman-scout`

## 中间件执行链

```
全局: Cors → SecurityFilter → RateLimit → {路由中间件}
/api: Cors → SecurityFilter → RateLimit → ApiVersion → Controller
认证: Cors → SecurityFilter → RateLimit → ServiceAuth → OperationLog → Controller
```

## 安全增强

- WAF: SecurityFilter（XSS/SQL注入/路径遍历/命令注入/CSRF）+ IP 黑名单升级
- 限流: Redis Lua 滑动窗口
- CORS: 环境变量可配 + HSTS + CSP + 安全头
- 认证: JWT + 黑名单 + 并发会话限制
- 密码: 8-32 位 + 大小写字母 + 数字 + 特殊字符
- Session: Cookie secure + SameSite=Strict
- 加密: AES-256-CBC 传输 + 数据库字段级
- ID: Hashids 混淆
- ES: xpack.security 密码认证
- Redis: requirepass 密码认证
- Docker: 非 root 用户运行

## 部署

```bash
cp .env.docker .env
# 修改 .env 中所有 change-me-* 占位符
docker-compose up -d
```

编排: nginx + app(PHP 8.3) + mysql + redis + elasticsearch

## CI/CD

GitHub Actions: PHP 语法 + Composer 审计 + PHPUnit + Flutter 分析

## 测试

| 项目 | 测试数 | 断言数 | 通过率 |
|------|--------|--------|--------|
| service | 43 | 248 | 100% (1个跳过) |

测试覆盖: Snowflake/Hashids/Auth/Fee/Security/Validator/DatabaseSchema/i18n

## Nginx 安全配置

`docs/nginx-security.conf` — 反向代理安全加固参考
