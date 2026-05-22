# 架构设计文档 (Architecture Design)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## 1. 系统架构概述

物业管理系统采用「双后端 + 多前端」分层架构。管理员端（admin）和业主业务端（service）为两个独立的 webman v2 项目，通过共享 MySQL 数据库协同工作。前端覆盖 Flutter Web（PC 管理后台风格）和 HarmonyOS 移动端。

### 设计目标

- **独立部署**: admin 和 service 各自独立启停、独立扩缩容、独立密钥管理
- **共享数据**: 共用同一 MySQL 数据库，避免数据同步问题
- **统一规范**: 两个项目遵循相同的代码规范、配置风格、安全策略
- **PC 优先的 Web 端**: Flutter Web 按桌面端管理后台风格设计（侧边栏 + 顶栏 + 内容区）

## 2. 分层架构

```
┌─────────────────────────────────────────────────────────────┐
│                        路由层 (Route Layer)                   │
│   config/route.php — URL → Controller 映射 + 中间件绑定       │
├─────────────────────────────────────────────────────────────┤
│                       中间件层 (Middleware Layer)              │
│   SecurityFilter → RateLimit → ApiVersion → Auth → Permission │
├─────────────────────────────────────────────────────────────┤
│                      控制器层 (Controller Layer)               │
│   BaseController → 请求验证 → ID编解码 → 业务逻辑 → 响应格式化  │
├─────────────────────────────────────────────────────────────┤
│                        服务层 (Service Layer)                  │
│   HashidsService | SnowflakeService | EncryptionService       │
├─────────────────────────────────────────────────────────────┤
│                        模型层 (Model Layer)                    │
│   Eloquent ORM + encryptable 自动加解密 + scout ES 同步        │
├─────────────────────────────────────────────────────────────┤
│                        驱动层 (Driver Layer)                   │
│   MySQL PDO | Elasticsearch HTTP | Redis                      │
└─────────────────────────────────────────────────────────────┘
```

## 3. 中间件执行链

### 管理端 (admin)
```
Cors → SecurityFilter(方法检查→405) → RateLimit(限流) 
  → AdminAuth(JWT验证) → AdminPermission(RBAC鉴权)
    → OperationLog(操作记录) → Controller
```

### 业务端 (service)
```
Cors → SecurityFilter(方法检查→405) → RateLimit(限流)
  → ApiVersion(版本校验) → Controller           # /api/* 公开接口
  → ServiceAuth(JWT业主认证) → Controller       # /service/* 认证接口
```

### 全局中间件说明

| 中间件 | 位置 | 职责 |
|--------|------|------|
| Cors | 全局首位 | 跨域资源共享头处理 |
| SecurityFilter | 全局 | HTTP方法白名单、XSS/SQL注入/路径遍历/命令注入/CSRF攻击拦截、IP黑名单 |
| RateLimit | 全局 | Redis 滑动窗口限流（Lua 原子化），默认60次/分钟 |
| ApiVersion | /api路由 | 请求头 API-Version 校验，注入版本号 |
| AdminAuth | /admin路由 | JWT Token 验证，注入 adminId |
| AdminPermission | /admin路由 | RBAC method.path 权限校验（Redis 60s 缓存）|
| OperationLog | /admin路由 | POST/PUT/DELETE 操作自动记录（含来源端检测） |
| ServiceAuth | /service路由 | JWT Token 验证，注入 ownerId |

## 4. ID 全生命周期

```
生成: SnowflakeService::generate()
      datacenter_id(5bit) + worker_id(5bit) + timestamp(41bit) + sequence(12bit)
      → BIGINT(18) 例: 1750123456789

存储: MySQL erik_* 表
      id BIGINT UNSIGNED NOT NULL（非自增）
      敏感字段 encryptable cast → AES-256-CBC 加密存储

传输: HashidsService::encode(bigint) → hashid 字符串 例: aB3xK9mW2pQ7rT5v
      API 请求/响应中的所有 ID 字段统一使用 hashid

解码: HashidsService::decode(hashid) → BIGINT
      无效 hashid 抛出 InvalidArgumentException
```

## 5. 数据加密分层

### 传输层（encryption）
- AES-256-CBC 加密
- 客户端发送敏感数据前加密，服务端接收后解密
- 独立密钥 `ENCRYPTION_KEY`

### 存储层（encryptable）
- Model `$casts` 机制自动加解密
- 敏感字段：phone, email, id_card, emergency_contact, emergency_phone
- 独立密钥 `ENCRYPTABLE_KEY`
- 写入自动加密为密文，读取自动解密为明文

### 展示层（脱敏）
- 手机号: `138****1234`
- 邮箱: `a***@example.com`
- 身份证: `********`
- Excel/PDF 导出自动脱敏

## 6. 认证与权限

### JWT 认证
- 算法: HS256
- access_token: 2小时有效期
- refresh_token: 14天有效期
- 并发限制: 同一用户最多3个有效 Token，超出时最旧 Token 加入黑名单
- 账号锁定: 连续5次登录失败锁定15分钟

### RBAC 权限模型
- 用户 → 角色 → 权限（多对多）
- 权限类型: type=1(菜单) / type=2(按钮) / type=3(API)
- 权限标识格式: `{method}.{path}` 例: `get.admin/user`
- 超级管理员标识: `*`（跳过所有权限检查）
- 权限树: 自引用 parent_id 支持无限层级

## 7. 安全纵深防御（18层）

```
第1层  点击验证码      → 登录/注册强制人机验证
第2层  密码二次确认    → 敏感操作（删除/缴费/合同终止）必须输入密码
第3层  poster随机验证  → 高频敏感操作随机弹出验证码
第4层  security-php    → 请求周期内自动安全扫描
第5层  SecurityFilter  → XSS/SQL注入/路径遍历/命令注入/CSRF 攻击拦截
第6层  传输安全        → HTTPS + AES-256-CBC
第7层  JWT 认证        → HS256，2h过期 + refresh token
第8层  并发控制        → 同一用户最多3个Token，超出黑名单
第9层  账号锁定        → 连续5次失败锁定15分钟
第10层 RBAC 鉴权       → method.path 粒度权限控制
第11层 限流保护        → Redis 滑动窗口 Lua原子化
第12层 ID 保护         → Hashids 编码，不可逆推真实ID
第13层 请求体加密      → AES-256-CBC 敏感字段
第14层 存储加密        → encryptable DB字段加密
第15层 展示脱敏        → 手机号/邮箱/身份证脱敏
第16层 审计追溯        → OperationLog 全量记录（含来源端 source 自动检测）
第17层 HTTP 头防护     → CSP + X-Permitted-Cross-Domain-Policies
第18层 出口保护        → PDF 版权水印（不可移除）+ Excel 敏感数据脱敏
```

## 8. 限流策略

基于 Redis Sorted Set 滑动窗口算法，Lua 脚本原子化执行：

| 接口 | 限制 |
|------|------|
| 默认 | 60次/分钟/IP/路由 |
| POST /api/auth/login | 10次/分钟 |
| POST /api/auth/register | 5次/分钟 |

超限返回 429 + `X-RateLimit-Limit/Remaining/Reset/Retry-After` 响应头。

## 9. API 版本策略

- 版本通过请求头 `API-Version` 控制（默认 `v1`），不在 URL 中体现
- 不支持版本返回 400
- 控制器按版本组织: `app/api/{version}/controller/`
- 新增版本只需创建目录并注册到 `ApiVersion` 中间件

## 10. 部署架构

```
┌─────────────────────────────────────┐
│            CloudFlare DNS + CDN      │
└────────────────┬────────────────────┘
                 │
┌────────────────▼────────────────────┐
│          Nginx (:443)                │
│   反向代理 + Gzip + SSL 终结         │
│   静态文件: Flutter Web build/       │
└──────┬──────────────────┬───────────┘
       │                  │
┌──────▼──────┐    ┌──────▼──────┐
│ admin webman│    │service webman│
│ :8787       │    │ :8788       │
│ 管理后台API │    │ 业主端API    │
└──────┬──────┘    └──────┬──────┘
       │                  │
       └────────┬─────────┘
                │
┌───────────────┼───────────────────┐
│               │                   │
┌▼──────┐  ┌────▼───┐  ┌──────────▼┐
│MySQL  │  │ Redis  │  │Elasticsearch│
│:3306  │  │ :6379  │  │ :9200      │
└───────┘  └────────┘  └────────────┘
```

### Docker Compose 服务

| 服务 | 镜像 | 说明 |
|------|------|------|
| nginx | nginx:alpine | 反向代理 + 静态文件 |
| admin | Dockerfile构建 | PHP 8.3 + OPcache |
| service | Dockerfile构建 | PHP 8.3 + OPcache |
| mysql | mysql:8.0 | 数据卷持久化 |
| redis | redis:7-alpine | 缓存/限流/Session |
| elasticsearch | elasticsearch:8.x | 全文检索 |

## 11. 国际化设计 (i18n)

### 语言文件结构

系统支持简体中文（zh_CN）和英语（en），默认中文。

**PHP 后端:**
```
resource/translations/
├── zh_CN/
│   └── messages.php    # 中文语言包（42+翻译键）
└── en/
    └── messages.php    # 英文语言包
```

使用 symfony/translation 驱动，配置在 `config/translation.php`：
- `locale`: `zh_CN`
- `fallback_locale`: `['zh_CN', 'en']`
- `path`: `resource/translations`

控制器中通过 `$this->__('key')` 获取翻译：
```php
return $this->success([], $this->__('create_success'));
return $this->fail($this->__('community.name_required'), 422);
```

`__()` 方法内部调用 webman 的 `trans()` 全局函数，翻译不存在时降级返回 key 本身。

**Flutter Web:**
```
apps/flutter/lib/i18n/
└── messages.dart       # AppTranslations extends GetX Translations
```

使用 GetX `Translations`，101个翻译键。通过 `.tr` 扩展使用：
```dart
Text('login_btn'.tr)   // 中文: "登 录", 英文: "Login"
Text('phone_hint'.tr)  // "请输入手机号" / "Enter phone number"
```

语言切换：
```dart
Get.updateLocale(Locale('zh', 'CN'));  // 切换中文
Get.updateLocale(Locale('en', 'US'));  // 切换英文
```

### 翻译键分类

| 分类 | PHP 键示例 | Flutter 键示例 |
|------|-----------|---------------|
| 通用 | `success`, `fail`, `not_found` | `confirm`, `cancel`, `save` |
| 认证 | `auth.login_success`, `auth.*` | `login_btn`, `phone_hint` |
| 小区 | `community.name_required` | - |
| 费用 | `fee.bill_not_found`, `fee.*` | `fee_management`, `bill_status` |
| 报修 | `repair.not_found`, `repair.*` | `repair_submit`, `urgency_normal` |
| 投诉 | `complaint.submit_success` | `complaint_type`, `type_complaint` |
| 个人 | - | `profile`, `change_password` |

**HarmonyOS:** 使用 `resources/base/element/string.json` + `resources/en_US/element/string.json` 资源限定符（创建 HarmonyOS 项目时同步实现）。

## 12. 统一响应格式

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

| code | 含义 |
|------|------|
| 0 | 成功 |
| 400 | 参数错误 |
| 401 | 未认证 |
| 403 | 无权限 |
| 404 | 不存在 |
| 422 | 验证失败 |
| 429 | 请求过于频繁 |
| 500 | 服务端错误 |
