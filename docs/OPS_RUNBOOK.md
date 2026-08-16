# 运维手册（OPS Runbook）

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> 适用: property-management-platform（admin 端 + service 端，PHP 8.3 webman）

## 1. 数据库备份与恢复

admin 端与 service 端共用同一 MySQL 实例与库 `property_management`，备份一次即可。统一入口：

| 库名 | 备份脚本 | 说明 |
|---|---|---|
| `property_management` | `scripts/backup.sh` | 从 `admin/.env` 读连接（可用 `--container=` 覆盖容器名），默认容器内 mysqldump |

输出 `backups/backup_YYYYMMDD_HHMMSS.sql.gz`，默认保留最近 7 天（`--keep-days=` 可调）。

### 1.1 全量备份

```bash
cd /path/to/property-management-platform
bash scripts/backup.sh
```

### 1.2 定时任务（crontab）

```cron
# 每天 02:00 全量备份
0 2 * * * cd /path/to/property-management-platform && bash scripts/backup.sh >> /var/log/pmp-backup.log 2>&1
```

生产建议：将备份目录挂载到独立磁盘/异地存储，并定期抽查备份文件完整性（`gzip -t` 校验）。

### 1.3 恢复演练流程（每季度至少一次）

1. 选取最近一份备份：`ls -t backups/backup_*.sql.gz`
2. 在**独立环境**（或临时库）执行恢复：详见 [RECOVERY_RUNBOOK.md](RECOVERY_RUNBOOK.md) 场景 A（空库恢复）与场景 B（时间点恢复）。
3. 验证：
   - 行数对比：`SELECT COUNT(*) FROM erik_user;` 与备份前记录一致
   - 加密字段可正常解密：查一条含 encryptable 字段的记录，值正确、日志无 decrypt 报错
   - 业务冒烟：登录、拉取列表接口正常
4. 记录演练耗时与结果（用于 RTO 评估）。

> 完整演练手册（空库恢复 / 时间点恢复 / 一致性验证 / 30 分钟演练时间表）见 [RECOVERY_RUNBOOK.md](RECOVERY_RUNBOOK.md)。

### 1.4 RPO / RTO 说明

- **RPO（数据可丢失量）**：由备份频率决定。每日全量备份 → RPO ≤ 24 小时，即最多丢失最近一天的数据。需要更小 RPO 可增加备份频率（如每天 2 次）或启用 binlog 增量备份。
- **RTO（恢复所需时间）**：取决于库大小与恢复速度，目标 ≤ 1 小时（恢复 + 校验 + 服务重启）。每次演练后更新实际测量值。
- 恢复失败应急：先回滚应用代码，再用最近的可用备份重试；如备份损坏，用更早的备份并接受更大 RPO。

## 2. 密钥管理

项目依赖 5 个密钥，均在 `.env` 中（admin 与 service 各自独立，勿共用同一套）：

| 变量 | 长度 | 用途 |
|---|---|---|
| `ENCRYPTION_KEY` | 32 字节 | API 传输加密（config/encryption.php） |
| `ENCRYPTABLE_KEY` | 32 字节 | 数据库敏感字段加密（encryptable 插件，**勿与 ENCRYPTION_KEY 共用**） |
| `JWT_SECRET_KEY` | 64 位以上 | JWT 签名 |
| `HASHIDS_SALT` | — | ID 加解密 |
| `HASHIDS_ALT_SALT` | — | ID 加解密备用 |

### 2.1 生成密钥

```bash
# 输出 5 个 KEY=VALUE 到 stdout，可直接追加到 .env
php scripts/gen_env_keys.php

# 直接写入 .env：已存在的密钥不覆盖，只追加缺失的
php scripts/gen_env_keys.php --file=.env
```

> 若 .env 中某密钥仍是 `change-me` 占位符，先删除该行再运行（占位符被视为"已存在"，不会覆盖）。

### 2.2 密钥轮换（encryptable）

```bash
bash scripts/rotate_keys.sh            # 默认操作当前目录 .env
bash scripts/rotate_keys.sh /path/to/service/.env
```

脚本自动完成：备份 .env → 生成新 `ENCRYPTABLE_KEY` → 旧 key 追加到 `ENCRYPTION_PREVIOUS_KEYS`（逗号分隔，最近轮换的排最前）→ 写入新 key。然后按提示手动：重启服务 → 验证解密 → 确认后删备份。

**`ENCRYPTION_PREVIOUS_KEYS` 说明**：encryptable 解密时先用当前 `ENCRYPTABLE_KEY`，失败后按列表顺序逐个尝试历史 key。因此**轮换时旧 key 必须在新 key 生效前加入该列表**，否则重启后旧数据无法解密（数据不会丢，回滚 .env 即可恢复）。列表只增不减，删除历史 key 前必须确认所有旧数据已完成重加密。

**不做自动数据迁移**：轮换后旧数据仍以旧 key 加密、可正常读写。如需用新 key 重写存量数据，另行执行数据迁移任务（逐表读取 → 写入触发重加密）。

### 2.3 Fail-fast 启动校验

以下配置在服务启动时校验，密钥**缺失或仍为 `change-me` 占位符**会直接抛 `RuntimeException` 拒绝启动（防止带着占位密钥上线）：

| 配置 | 校验的密钥 |
|---|---|
| `service/config/encryption.php` | `ENCRYPTION_KEY` |
| `service/config/encryptable.php`、`service/config/plugin/erikwang2013/encryptable/app.php` | `ENCRYPTABLE_KEY` |
| `service/config/jwt.php`、`service/config/plugin/erikwang2013/jwt/jwt.php` | `JWT_SECRET_KEY` |

启动报错示例：`ENCRYPTABLE_KEY 未配置或仍为占位符，请在 .env 中配置 32 字节随机密钥`。

**日常操作清单**：

1. 部署新环境：`cp .env.example .env` → 删除 `change-me` 占位行 → `php scripts/gen_env_keys.php --file=.env` → 启动服务确认无密钥报错。
2. 例行轮换：按 2.2 执行，季度一次即可（无强制周期，泄漏时立即轮换）。
3. 备份的 `.env.bak.*` 含明文密钥，与数据库备份同等对待（权限 600、异地存放）。

## 3. 监控告警（Prometheus + Grafana）

编排在 `admin/docker-compose.yml`（新增 prometheus / grafana / redis-exporter 三个服务），配置均在 `admin/deploy/monitoring/`：

```bash
cd admin
docker compose up -d prometheus grafana redis-exporter
# Prometheus: http://host:9090   Grafana: http://host:3000
# 首次登录 Grafana: admin / ${GRAFANA_ADMIN_PASSWORD}（默认 change-me-grafana-password）
```

- **数据源**：Grafana 启动时自动配置 Prometheus 数据源（provisioning），面板在 UI 中创建。
- **告警规则**：`deploy/monitoring/alerts.yml`，覆盖：
  - `AppDown`（应用不可达，等价全站 5xx）— critical
  - `MysqlDown` / `RedisDown`（应用侧探测失败）— critical
  - `ElasticsearchDown`（ES 原生 `/_prometheus/metrics` 抓取失败）+ `ElasticsearchHealthYellow`（集群非绿色）— critical/warning
  - `QueueBacklog`（scout 搜索队列 `queues:scout_*` 堆积 >100 条持续 10 分钟）— warning
- **ES 密码注入**：prometheus 经 compose `secrets` 读取 `ELASTIC_PASSWORD`（需 Docker Compose ≥ 2.24），配置文件不写死密码；未设置时用 change-me 占位，ES 抓取 401 会触发 ElasticsearchDown。
- **重载规则**：改完 alerts.yml 后 `curl -X POST localhost:9090/-/reload`（prometheus 需加 `--web.enable-lifecycle`，默认未加则重启容器）。
- **本地验证**：`bash scripts/verify_monitoring.sh` — 校验 admin/service 两侧告警规则 YAML 语法、curl 两端 `/metrics`（admin:8787 / service:8788）指标输出、Prometheus（9090/9091）规则加载；应用/Prometheus 未运行时对应项提示 SKIP 并 exit 0。

**状态**：admin 与 service 均已有 `/metrics` 端点（MetricsController，免认证）。MetricsCollector 中间件已按 `code="all"|"5xx"` 真实累计计数（admin 输出 `open_admin_http_requests_total`，service 输出 `property_service_http_requests_total`），两侧 alerts.yml 的 `Http5xxRatio` 规则（5xx 比例 >5% 持续 10 分钟）可直接生效。**告警实测待部署**：规则已就绪但尚未在真实部署环境触发验证（依赖 `verify_monitoring.sh` 与 Prometheus 上线）。

## 4. 日志轮转

- **容器日志**：compose 中所有服务已配 `json-file` + `max-size 10m / max-file 3`，无需额外处理。
- **宿主机应用日志**（`runtime/*.log`、`service/workerman.log`）：使用 `admin/deploy/logrotate/pmp-app`：

```bash
sudo cp admin/deploy/logrotate/pmp-app /etc/logrotate.d/pmp-app
# 按实际部署路径修改文件内的路径后生效；copytruncate 使 webman 免重启轮转
sudo logrotate -d /etc/logrotate.d/pmp-app   # 试运行检查
```

默认每日轮转、保留 30 天、gzip 压缩。

## 5. 部署后压测冒烟

部署完成后用 k6 冒烟验证登录链路与关键业务接口可达（低速率，非性能压测）。脚本：`scripts/loadtest/smoke.js`（默认 2 VU、30s，登录 + dashboard，均支持 `BASE_URL`/`VUS`/`DURATION`/`TOKEN` 环境变量覆盖）。

### 5.1 本地冒烟

```bash
cd /path/to/property-management-platform/scripts/loadtest

# 只探测登录链路（无需 token；422 验证码错误/429 限流均属防御生效，视为可达）
k6 run -e BASE_URL=http://127.0.0.1:8790 smoke.js

# 含鉴权业务接口：在部署服务器上签发压测 JWT（依赖 admin/.env 与 vendor）再传入
TOKEN=$(php mint-token.php)
k6 run -e BASE_URL=https://admin.example.com -e TOKEN="$TOKEN" smoke.js

# 自定义并发/时长
k6 run -e BASE_URL=https://admin.example.com -e TOKEN="$TOKEN" -e VUS=5 -e DURATION=60s smoke.js
```

全量压测（login + dashboard + fee 三脚本）仍用 `bash scripts/loadtest/run.sh [BASE_URL] [VUS] [DURATION]`。

### 5.2 CI 冒烟（GitHub Actions 手动触发）

仓库 Actions 页面 → **Loadtest Smoke** → **Run workflow**：

| 输入 | 必填 | 说明 |
|---|---|---|
| `target_url` | 是 | 被测环境地址，如 `https://admin.example.com` |
| `duration` | 否 | 冒烟时长，默认 `30s` |
| `token` | 否 | 压测 JWT；留空则只探测登录链路 |

token 获取（在部署服务器仓库根下执行，需 `admin/.env` 与 `admin/vendor/`）：

```bash
php scripts/loadtest/mint-token.php
```

> 注意：token 是压测专用 JWT（默认 erik 管理员账号），会明文出现在 workflow 日志中，请用压测专用账号签发；生产环境如不便暴露，改用 5.1 本地冒烟。
