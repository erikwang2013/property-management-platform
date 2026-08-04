# 安全架构设计文档 — 业务端

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## 1. 纵深防御全景

service 业务端采用与 admin 管理端一致的 7 层纵深防御模型。

中间件执行链（`config/middleware.php`）：

```
请求 → Cors → SecurityFilter → RateLimit → [路由组中间件: ServiceAuth → OperationLog] → Controller
```

| 层 | 中间件/机制 | 防护目标 |
|----|--------|---------|
| 1 | SecurityFilter | XSS / SQL 注入 / 路径遍历 / 命令注入 / CSRF 攻击拦截 + IP 黑名单升级 |
| 2 | Cors | 跨域安全 + 响应安全头注入（HSTS/CSP/X-Frame-Options） |
| 3 | RateLimit | Redis Lua 滑动窗口限流，防暴力破解 |
| 4 | ServiceAuth | JWT 认证（业主端）+ 黑名单登出 + 并发会话限制 |
| 5 | OperationLog | 操作审计 + 来源端追踪 + 敏感字段脱敏 |
| 6 | 数据加密 | Hashids ID 混淆 + Encryptable DB 加密 + EncryptionService 传输加密 |
| 7 | Validator | 输入 Schema 校验（11 条规则） |

---

## 2. 攻击检测引擎

与 admin 端共享相同的 SecurityFilter 实现，覆盖以下攻击向量：

- **HTTP 方法限制**：仅允许 GET/POST/PUT/DELETE/OPTIONS/HEAD，其他返回 405
- **XSS**：脚本标签、事件属性、JS 伪协议、Data URI、模板注入（5 种模式）
- **SQL 注入**：UNION 查询、OR 恒真、表结构破坏、存储过程、元数据探测、注释绕过（6 种模式）
- **路径遍历**：目录回溯、敏感文件探测、空字节截断（3 种模式）
- **命令注入**：管道/分号、反引号、$() 替换、远程下载管道（4 种模式）
- **CSRF**：Origin/Referer 校验（POST/PUT/DELETE）
- **恶意文件**：双扩展名伪装、PHP 扩展名检测

详细正则和检测逻辑参见 `admin/docs/SECURITY.md` 第 2 章。

---

## 3. IP 黑名单升级机制

```
第 1-4 次攻击 → Redis INCR security_escalate:{ip} (TTL 60s)
第 5 次攻击   → SETEX security_ban:{ip} 900 1 → 封禁 15 分钟
```

封禁期间所有请求直接返回 403。

---

## 4. 响应安全头

所有安全头在 Cors 中间件注入：

| 头 | 值 | 作用 |
|----|-----|------|
| Strict-Transport-Security | `max-age=31536000; includeSubDomains` | 强制 HTTPS |
| X-Content-Type-Options | `nosniff` | 禁止 MIME 嗅探 |
| X-Frame-Options | `DENY` | 禁止 iframe 嵌入 |
| X-XSS-Protection | `1; mode=block` | 浏览器 XSS 过滤器 |
| Referrer-Policy | `strict-origin-when-cross-origin` | 跨域仅发域名 |
| Content-Security-Policy | `default-src 'self'; ...` | 资源来源限制 |
| Permissions-Policy | `camera=(), microphone=(), geolocation=()` | 禁用敏感 API |

---

## 5. 限流策略

Redis Sorted Set 滑动窗口 + Lua 原子化脚本，与 admin 端共享相同实现。

| 路由 | 限制 | 窗口 |
|------|------|------|
| 默认 | 60 次/分钟 | 60s |
| `/api/auth/login` | 10 次/分钟 | 60s |
| `/api/auth/register` | 5 次/分钟 | 60s |

Redis 不可用时 fail-open，放行所有请求。

### 账号锁定

连续 5 次登录失败 → 账号锁定 15 分钟。基于 `userId` 而非 IP，防止定向暴力破解。

---

## 6. 认证与鉴权

### 6.1 JWT 认证（ServiceAuth）

面向业主端，与 admin 端 AdminAuth 共享相同的 JWT 基础设施。

| 参数 | 值 |
|------|-----|
| 算法 | HS256 |
| access_token TTL | 7200s (2h) |
| refresh_token TTL | 1209600s (14d) |

**并发会话限制**：同一业主最多 3 个有效 Token，超出时最旧 Token 加入黑名单。

### 6.2 密码复杂度

8-32 位，必须包含大小写字母、数字和特殊字符。使用 bcrypt 哈希存储。

---

## 7. 数据保护

三层数据保护：

| 层 | 机制 | 密钥 |
|----|------|------|
| 传输 | EncryptionService (AES-256-CBC-HMAC) | `ENCRYPTION_KEY` |
| 存储 | Encryptable cast（字段级加解密） | `ENCRYPTABLE_KEY` |
| 展示 | Hashids ID 混淆 + 导出脱敏 | `HASHIDS_SALT` |

密钥全部通过 `.env` 注入，各层独立密钥，一层泄露不影响其他层。

---

## 8. 基础设施安全

| 措施 | 状态 |
|------|:----:|
| Docker 非 root 用户 | ✅ |
| Redis requirepass | ✅ |
| ES xpack.security | ✅ |
| MySQL 专用用户 | ✅ |
| Dependabot 自动更新 | ✅ |
| Nginx 安全配置 | ✅ `docs/nginx-security.conf` |

---

## 9. 已知局限

| 局限 | 缓解措施 |
|------|---------|
| CSRF 保护仅对浏览器有效 | 非浏览器客户端不受 CSRF 攻击；依赖 JWT 替代 Cookie |
| Redis 不可用时 fail-open | 监控告警；JWT 短期 TTL 兜底 |
| JWT 无法主动失效（除黑名单外） | 黑名单 + 2h TTL |
| CSP 含 `unsafe-inline`（Flutter 依赖） | 未来迁移 nonce 机制 |
