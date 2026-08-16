# 数据库恢复演练手册（Recovery Runbook）

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> 适用: property-management-platform（admin 端 + service 端，MySQL 8.0）
> 与 [OPS_RUNBOOK.md](OPS_RUNBOOK.md) 第 1 节配合阅读：备份生成、crontab、RPO/RTO 见 OPS_RUNBOOK，本文只讲"怎么恢复、怎么验证"。

## 0. 目标

- **演练目标：30 分钟完成一次完整恢复演练**（恢复 + 验证），每季度至少一次。
- 任何时刻拿到最近一份备份，都能按本文档恢复到空库或指定时间点。

前置条件：

- 备份文件可用：`scripts/backup.sh` 已按 cron 运行（见 OPS_RUNBOOK 1.2）。
- 恢复目标环境（演练机或生产机）与生产同构：同一份 docker-compose、同版本 MySQL 8.0。
- 恢复前确认：`gzip -t 备份文件` 通过；磁盘剩余空间 ≥ 备份体积 2 倍。

## 1. 场景 A：恢复到空库（最常用，演练默认场景）

目标：把备份导入一个全新的空库，验证数据可用。

```bash
cd /path/to/property-management-platform

# 1) 选取最近一份备份
ls -lt backups/backup_*.sql.gz | head

# 2) 完整性检查（不通过则换更早的备份）
gzip -t backups/backup_20260816_020000.sql.gz && echo OK

# 3) 确认目标容器在跑
docker compose -f admin/docker-compose.yml ps mysql

# 4) 建空库（演练库名加 _drill 后缀，避免误覆盖生产数据）
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot -e "CREATE DATABASE IF NOT EXISTS property_management_drill DEFAULT CHARACTER SET utf8mb4;"'

# 5) 导入（-T 关闭 TTY，保证非交互；实测约 1-5 分钟）
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot --default-character-set=utf8mb4 property_management_drill' \
  < backups/backup_20260816_020000.sql.gz
```

> 凭据提示：`MYSQL_PWD` 取 `admin/.env` 的 `DB_PASSWORD`；生产上禁止明文出现在 shell 历史，建议改用 `--env-file admin/.env` 或注入环境变量。本手册示例为演练环境约定值。

## 2. 场景 B：恢复到指定时间点（binlog 回放）

前提：MySQL 8 默认开启 binlog（`log_bin=ON`），备份时刻之后的增量都在 binlog 里。数据丢失 ≤ 最近一次备份 + binlog 保留期（默认 `binlog_expire_logs_seconds=2592000`，30 天）。

思路：全量恢复 → 找 binlog 起点 → `mysqlbinlog` 回放到目标时间点。

```bash
# 1) 确认 binlog 开启，列出日志文件
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot -e "SHOW VARIABLES LIKE \"log_bin\"; SHOW BINARY LOGS;"'

# 2) 全量恢复（同场景 A 第 4-5 步，恢复到空库）

# 3) 找备份对应的 binlog 起点：备份文件里记录的位置（--master-data=2 时）
#    本脚本未带 --master-data，起点用"备份开始时刻"，误差在备份时长内。
#    回放 binlog 到目标时间点（示例：恢复到 2026-08-16 10:30:00）
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysqlbinlog --stop-datetime="2026-08-16 10:30:00" /var/lib/mysql/binlog.000012 | mysql -uroot property_management_drill'
```

要点：

- binlog 在容器内路径 `/var/lib/mysql/binlog.0000NN`，从 `SHOW BINARY LOGS` 的输出对号入座。
- 只回放"备份开始时刻之后"的 binlog；回放后立即验证（见第 3 节），确认 `max(updated_at)` 符合预期。
- 精确到秒的误操作恢复：先定位误操作语句 `mysqlbinlog /var/lib/mysql/binlog.0000NN | grep -n "误操作关键字"`，再决定 `--stop-datetime` 或 `--stop-position`。

## 3. 数据一致性验证（恢复后必做）

| 检查项 | 命令 | 通过标准 |
|---|---|---|
| 备份文件完整性 | `gzip -t <备份>` | 无报错 |
| 关键表行数 | `SELECT COUNT(*) FROM erik_admin_user;` | 与备份前记录的行数一致 |
| 业务表抽查 | `SELECT COUNT(*) FROM erik_owner;`、`erik_tenant`、`erik_fee_bill`、`erik_repair_order` | 三张以上数量级合理（非 0 且与备份前一致） |
| 加密字段可解密 | 查一条含 encryptable 字段的记录（如 `erik_owner` 身份证/手机号） | 值正确、应用日志无 decrypt 报错 |
| 业务冒烟 | 登录、拉取列表接口各 1 次 | 200 / 正常返回 |

抽查脚本示例（演练环境）：

```bash
docker compose -f admin/docker-compose.yml exec -T -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot property_management_drill -e "
    SELECT (SELECT COUNT(*) FROM erik_admin_user) AS users,
           (SELECT COUNT(*) FROM erik_owner) AS owners,
           (SELECT COUNT(*) FROM erik_tenant) AS tenants,
           (SELECT COUNT(*) FROM erik_fee_bill) AS fee_bills,
           (SELECT COUNT(*) FROM erik_repair_order) AS repair_orders;"'
```

> 行数一致性：备份前用同一条 SQL 记录基线，恢复后对比；演练时把基线写入演练记录。

## 4. 30 分钟演练时间表

| 时间 | 动作 | 负责 |
|---|---|---|
| 0-5 min | 选备份、`gzip -t`、建空库、记录基线行数 | 运维 |
| 5-15 min | 场景 A 恢复导入 | 运维 |
| 15-25 min | 第 3 节一致性验证 + 业务冒烟 | 运维 + 业务 |
| 25-30 min | 记录结果、清理演练库（`DROP DATABASE property_management_drill`）、更新 OPS_RUNBOOK 1.4 实测 RTO | 运维 |

## 5. 失败处理

| 症状 | 处理 |
|---|---|
| `gzip -t` 失败 | 备份损坏，换更早备份，接受更大 RPO，并检查备份 cron 是否正常 |
| 导入报错（字符集/权限） | 确认 `--default-character-set=utf8mb4` 与空库字符集一致；确认用户有建表权限 |
| 行数与基线不符 | 立即停止演练，检查是否导错库/导错文件；生产恢复场景则继续排查并回滚应用 |
| 回放 binlog 后数据仍缺 | 检查 `--stop-datetime` 是否晚于备份开始时刻；确认回放从备份后的第一个 binlog 开始 |

## 6. 演练记录模板

```text
日期: 2026-08-16
恢复目标: 空库（场景 A）/ 时间点（场景 B）
备份文件: backups/backup_20260816_020000.sql.gz
基线行数: erik_admin_user=1, erik_owner=42, erik_fee_bill=128
恢复耗时: XX 分钟    验证耗时: XX 分钟    总计: XX 分钟（目标 ≤ 30）
结果: 通过 / 失败（附失败原因与处理）
```
