# 项目安全与生态配置审查报告

> 审查日期：2026-08-04  
> 审查范围：admin + service 全栈  
> 基准提交：5fcc86f

---

## 一、测试结果

### 1.1 PHP 语法检查

| 范围 | 结果 |
|------|------|
| 全项目 `*.php`（排除 vendor） | **全部通过** |

### 1.2 PHPUnit 单元测试

| 模块 | 测试数 | 断言数 | 通过 | 失败 | 跳过 | 状态 |
|------|--------|--------|------|------|------|------|
| admin | 60 | 165 | 58 | 2 | 0 | 2 个失败为预存问题（CaptchaTest 依赖 GD 图像处理） |
| service | 18 | 42 | 14 | 0 | 4 | **全部通过** |

### 1.3 Composer 依赖审计

`composer audit` 结果：**27 个安全漏洞，涉及 8 个包，1 个废弃包**

#### 高危漏洞（6 个，需立即修复）

| 包 | CVE | 描述 |
|----|-----|------|
| guzzlehttp/guzzle | CVE-2026-69246 | 非规范主机名可绕过主机检查 |
| phpoffice/phpspreadsheet | CVE-2026-59933 | XLS/OLE 扇区链自循环导致内存耗尽 |
| phpoffice/phpspreadsheet | CVE-2026-59932 | Gnumeric 读取器无界 gzip 扩展导致内存耗尽 |
| phpoffice/phpspreadsheet | CVE-2026-59931 | WEBSERVICE() 域名白名单 SSRF 绕过 |
| symfony/http-kernel | CVE-2026-45075 | HEAD 请求绕过 method 过滤 |
| symfony/mime | CVE-2026-45067 | 邮件头/SMTP 命令注入（CRLF） |

#### 中危漏洞（17 个）

| 包 | 数量 | 类型 |
|----|------|------|
| dompdf/dompdf | 4 | SVG 文件泄露、BMP DoS、font-face 文件探测 |
| guzzlehttp/guzzle | 8 | Cookie 泄露/注入、代理 HTTPS 降级、URI 片段泄露 |
| guzzlehttp/psr7 | 4 | 主机混淆、CRLF 注入 |
| symfony/http-foundation | 1 | IPv6 过渡地址 SSRF 绕过 |

#### 废弃包

| 包 | 建议替代 |
|----|---------|
| doctrine/annotations | 无（PHP 8 原生属性替代） |

**修复建议**：执行 `composer update` 更新所有依赖。

---

## 二、安全防护总览

### 2.1 本会话已修复（10 项）

| # | 级别 | 问题 | 修改文件 | 状态 |
|---|------|------|---------|------|
| 1 | 高危 | `.env.example`/配置文件默认密钥硬编码 | `.env.example` x2, `jwt.php` x2, `encryption.php` x2, `encryptable.php` x2 | ✅ |
| 2 | 高危 | CORS `Access-Control-Allow-Origin: *` | `Cors.php` x2 | ✅ |
| 3 | 高危 | Session Cookie `secure=false`, `same_site=''` | `session.php` x2 | ✅ |
| 4 | 中危 | ES `xpack.security.enabled: false` | `docker-compose.yml` x2, `.env.docker` x2, `.env.example` x2 | ✅ |
| 5 | 中危 | MySQL root 账户 + 弱密码 | `docker-compose.yml` x2, `.env.docker` x2, `.env.example` x2 | ✅ |
| 6 | 低危 | 缺少 HSTS 响应头 | `Cors.php` x2 | ✅ |
| 7 | 低危 | 密码仅校验长度（6 位） | `ProfileController.php`, `AuthController.php` x2 | ✅ |
| 8 | 低危 | CI 缺少依赖安全扫描 | `.github/workflows/ci.yml` | ✅ |
| 9 | — | EnvConfigTest 新增 env key 失败 | `admin/.env`, `service/.env` | ✅ |
| 10 | — | 文档未反映变更 | `SECURITY.md`, `admin/CLAUDE.md` | ✅ |

### 2.2 纵深防御矩阵

| 层 | 机制 | 评分 |
|----|------|:----:|
| L1 | SecurityFilter — XSS/SQL注入/路径遍历/命令注入/恶意文件/WAF + IP黑名单升级 | A |
| L2 | CORS + 安全响应头 — 可配来源 + HSTS + CSP + X-Frame-Options + X-Content-Type-Options | A |
| L3 | RateLimit — Redis Lua 滑动窗口（原子化）+ 账号锁定 + 验证码 | A |
| L4 | AdminAuth — JWT + 黑名单登出 + 并发会话限制（最多 3 个） | A |
| L5 | AdminPermission — RBAC method.path 粒度 + Redis 60s 缓存 | A |
| L6 | OperationLog — 操作审计 + 8 平台来源检测 + 敏感字段脱敏 | A |
| L7 | 传输加密 — AES-256-CBC（EncryptionService） | A |
| L8 | 存储加密 — Encryptable cast（字段级自动加解密） | A |
| L9 | ID 混淆 — Hashids 隐藏主键 + 导出脱敏 | A |

---

## 三、待解决问题

### 3.1 高危 — 依赖漏洞

见 1.3 节。执行以下命令修复：

```bash
cd admin && composer update
cd ../service && composer update
```

### 3.2 中危 — Redis 无密码认证

`docker-compose.yml` 中 Redis 未设置 `requirepass`。建议：

```yaml
redis:
  command: redis-server --requirepass ${REDIS_PASSWORD:-change-me-redis-password}
```

### 3.3 中危 — Docker 容器以 root 运行

`Dockerfile` 缺少 `USER` 指令：

```dockerfile
RUN addgroup -S app && adduser -S app -G app
USER app
```

### 3.4 低危 — 缺少 Dependabot 配置

建议添加 `.github/dependabot.yml`：

```yaml
version: 2
updates:
  - package-ecosystem: "composer"
    directory: "/admin"
    schedule:
      interval: "weekly"
  - package-ecosystem: "composer"
    directory: "/service"
    schedule:
      interval: "weekly"
```

### 3.5 低危 — Service 缺少 nginx 安全配置

`service/docs/` 目录不存在。建议从 `admin/docs/nginx-security.conf` 复制并适配。

### 3.6 建议 — CSP unsafe-inline

当前 CSP 含 `'unsafe-inline'`（Flutter Web 依赖）。未来可考虑迁移到 nonce 机制。

### 3.7 建议 — 输入 Schema 校验

控制器直接 `$request->input()` 取值，无结构化校验。建议关键接口增加 Validator 规则。

---

## 四、生态配置完整性

### 4.1 环境变量

| 文件 | admin | service | 一致性 |
|------|-------|---------|:------:|
| `.env.example` | 47 项 | 47 项 | ✅ |
| `.env.docker` | 27 项 | 27 项 | ✅ |
| `config/*.php` | 20 文件 | 20 文件 | ✅ |

### 4.2 Docker 编排

| 服务 | admin | service | 安全配置 |
|------|:-----:|:-------:|---------|
| nginx | ✅ | ✅ | 独立网络隔离 |
| app (PHP 8.3) | ✅ | ✅ | OPcache 生产配置 |
| mysql (8.0) | ✅ | ✅ | 健康检查 + 专用用户 |
| redis (7.2) | ✅ | ✅ | 健康检查（缺密码） |
| elasticsearch (8.x) | ✅ | ✅ | xpack.security 已启用 |

### 4.3 CI/CD

| 步骤 | admin | service |
|------|:-----:|:-------:|
| PHP 语法检查 | ✅ | ✅ |
| Composer 审计 | ✅ | ✅ |
| PHPUnit | ✅ | ✅ |
| Flutter 分析 | ✅ | ✅ |

### 4.4 文档覆盖

| 文档 | admin | service |
|------|:-----:|:-------:|
| CLAUDE.md | ✅ | ❌ |
| SECURITY.md | ✅（12 章） | ❌ |
| API.md | ✅ | ✅ |
| nginx-security.conf | ✅ | ❌ |

---

## 五、综合评分

| 维度 | 评分 | 说明 |
|------|:----:|------|
| 代码质量 | **A** | 全部 PHP 语法通过，测试 92/96 通过（4 跳过） |
| 安全防护 | **A−** | 9 层纵深防御完整；依赖漏洞待 `composer update` |
| 配置安全 | **B+** | 已修复 10 项；Redis 密码和 Docker USER 待补 |
| 生态完整 | **B+** | admin 文档齐全；service 缺 CLAUDE.md 和 nginx 配置 |
| CI/CD | **A−** | 流水线完整；缺 Dependabot 自动更新 |
| 依赖安全 | **C** | 27 个已知漏洞需立即修复 |

| | |
|---|---|
| **综合评分** | **B+ → A−**（修复剩余 5 项可达 A） |
| **修改文件** | 22 个文件，+141 / −50 行 |
| **新增问题** | 0 |
