# Database Recovery Runbook

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> Applies to: property-management-platform (admin + service, MySQL 8.0)
> Read together with [OPS_RUNBOOK.md](OPS_RUNBOOK.md) §1: backup generation, crontab, RPO/RTO are in OPS_RUNBOOK; this document covers only "how to restore, how to verify".

## 0. Objectives

- **Drill target: complete a full restore drill in 30 minutes** (restore + verify), at least once per quarter.
- Given the most recent backup at any time, you can restore to an empty database or a point in time following this document.

Prerequisites:

- Backup file available: `scripts/backup.sh` running on cron (see OPS_RUNBOOK 1.2).
- The restore target environment (drill machine or production machine) is isomorphic with production: the same docker-compose, the same MySQL 8.0 version.
- Before restoring, confirm: `gzip -t <backup file>` passes; free disk space ≥ 2× the backup size.

## 1. Scenario A: Restore to an Empty Database (most common, default drill scenario)

Objective: import the backup into a brand-new empty database and verify data usability.

```bash
cd /path/to/property-management-platform

# 1) Pick the most recent backup
ls -lt backups/backup_*.sql.gz | head

# 2) Integrity check (if it fails, switch to an earlier backup)
gzip -t backups/backup_20260816_020000.sql.gz && echo OK

# 3) Confirm the target container is running
docker compose -f admin/docker-compose.yml ps mysql

# 4) Create an empty database (suffix the drill DB name with _drill to avoid accidentally overwriting production data)
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot -e "CREATE DATABASE IF NOT EXISTS property_management_drill DEFAULT CHARACTER SET utf8mb4;"'

# 5) Import (-T disables TTY for non-interactive use; measured ~1-5 minutes)
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot --default-character-set=utf8mb4 property_management_drill' \
  < backups/backup_20260816_020000.sql.gz
```

> Credential note: `MYSQL_PWD` comes from `DB_PASSWORD` in `admin/.env`; never let it appear in plain text in shell history in production — prefer `--env-file admin/.env` or environment variable injection. The examples in this manual use drill-environment agreed values.

## 2. Scenario B: Point-in-Time Recovery (binlog replay)

Prerequisite: MySQL 8 enables binlog by default (`log_bin=ON`); all increments after the backup moment are in the binlog. Data loss ≤ most recent backup + binlog retention period (default `binlog_expire_logs_seconds=2592000`, 30 days).

Approach: full restore → find the binlog starting point → replay with `mysqlbinlog` to the target point in time.

```bash
# 1) Confirm binlog is enabled and list log files
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot -e "SHOW VARIABLES LIKE \"log_bin\"; SHOW BINARY LOGS;"'

# 2) Full restore (same as Scenario A steps 4-5, restore to an empty database)

# 3) Find the binlog starting point corresponding to the backup: the position recorded in the backup file (with --master-data=2)
#    This script does not use --master-data, so the starting point is "the moment the backup began"; the error is within the backup duration.
#    Replay the binlog to the target point in time (example: restore to 2026-08-16 10:30:00)
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysqlbinlog --stop-datetime="2026-08-16 10:30:00" /var/lib/mysql/binlog.000012 | mysql -uroot property_management_drill'
```

Key points:

- The binlog is at `/var/lib/mysql/binlog.0000NN` inside the container; match it against the `SHOW BINARY LOGS` output.
- Only replay binlogs after "the moment the backup began"; verify immediately after replay (see §3), confirming `max(updated_at)` matches expectations.
- Second-precision recovery of erroneous operations: first locate the erroneous statement with `mysqlbinlog /var/lib/mysql/binlog.0000NN | grep -n "<erroneous-operation keyword>"`, then decide on `--stop-datetime` or `--stop-position`.

## 3. Data Consistency Verification (mandatory after restore)

| Check | Command | Pass Criteria |
|---|---|---|
| Backup file integrity | `gzip -t <backup>` | No errors |
| Key table row counts | `SELECT COUNT(*) FROM erik_admin_user;` | Matches row counts recorded before the backup |
| Business table spot checks | `SELECT COUNT(*) FROM erik_owner;`, `erik_tenant`, `erik_fee_bill`, `erik_repair_order` | Three or more with reasonable magnitudes (non-zero and matching pre-backup values) |
| Encrypted fields decryptable | Query a record with encryptable fields (e.g. `erik_owner` ID card/phone) | Values correct, no decrypt errors in app logs |
| Business smoke test | Login and list endpoint once each | 200 / normal responses |

Spot-check script example (drill environment):

```bash
docker compose -f admin/docker-compose.yml exec -T -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot property_management_drill -e "
    SELECT (SELECT COUNT(*) FROM erik_admin_user) AS users,
           (SELECT COUNT(*) FROM erik_owner) AS owners,
           (SELECT COUNT(*) FROM erik_tenant) AS tenants,
           (SELECT COUNT(*) FROM erik_fee_bill) AS fee_bills,
           (SELECT COUNT(*) FROM erik_repair_order) AS repair_orders;"'
```

> Row-count consistency: record a baseline with the same SQL before the backup and compare after the restore; write the baseline into the drill record during drills.

## 4. 30-Minute Drill Schedule

| Time | Action | Responsible |
|---|---|---|
| 0-5 min | Pick backup, `gzip -t`, create empty DB, record baseline row counts | Ops |
| 5-15 min | Scenario A restore import | Ops |
| 15-25 min | §3 consistency verification + business smoke test | Ops + Business |
| 25-30 min | Record results, clean up drill DB (`DROP DATABASE property_management_drill`), update measured RTO in OPS_RUNBOOK 1.4 | Ops |

## 5. Failure Handling

| Symptom | Handling |
|---|---|
| `gzip -t` fails | Backup corrupted; switch to an earlier backup, accept a larger RPO, and check whether the backup cron runs correctly |
| Import errors (charset/permissions) | Confirm `--default-character-set=utf8mb4` matches the empty DB charset; confirm the user has table-creation permission |
| Row counts differ from baseline | Stop the drill immediately; check whether the wrong DB/file was imported; in a production restore scenario, keep investigating and roll back the app |
| Data still missing after binlog replay | Check whether `--stop-datetime` is later than the backup start time; confirm replay starts from the first binlog after the backup |

## 6. Drill Record Template

```text
Date: 2026-08-16
Restore target: empty database (Scenario A) / point in time (Scenario B)
Backup file: backups/backup_20260816_020000.sql.gz
Baseline row counts: erik_admin_user=1, erik_owner=42, erik_fee_bill=128
Restore duration: XX minutes    Verification duration: XX minutes    Total: XX minutes (target ≤ 30)
Result: pass / fail (attach failure reason and handling)
```
