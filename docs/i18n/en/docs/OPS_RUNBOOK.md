# OPS Runbook

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> Applies to: property-management-platform (admin + service, PHP 8.3 webman)

## 1. Database Backup & Restore

The admin and service ends share the same MySQL instance and database `management`; one backup suffices. Unified entry:

| Database | Backup Script | Description |
|---|---|---|
| `management` | `scripts/backup.sh` | Reads the connection from `admin/.env` (override the container name with `--container=`), defaults to mysqldump inside the container |

Outputs `backups/backup_YYYYMMDD_HHMMSS.sql.gz`, retaining the last 7 days by default (`--keep-days=` adjustable).

### 1.1 Full Backup

```bash
cd /path/to/property-management-platform
bash scripts/backup.sh
```

### 1.2 Scheduled Task (crontab)

```cron
# Full backup every day at 02:00
0 2 * * * cd /path/to/property-management-platform && bash scripts/backup.sh >> /var/log/pmp-backup.log 2>&1
```

Production recommendation: mount the backup directory on a separate disk/off-site storage, and periodically spot-check backup file integrity (`gzip -t`).

### 1.3 Restore Drill Procedure (at least once per quarter)

1. Pick the most recent backup: `ls -t backups/backup_*.sql.gz`
2. Restore in an **isolated environment** (or a temporary database): see [RECOVERY_RUNBOOK.md](RECOVERY_RUNBOOK.md) Scenario A (empty-database restore) and Scenario B (point-in-time restore).
3. Verify:
   - Row-count comparison: `SELECT COUNT(*) FROM management_user;` matches the pre-backup record
   - Encrypted fields decrypt correctly: query a record with encryptable fields; values correct, no decrypt errors in logs
   - Business smoke test: login and list endpoints work normally
4. Record the drill duration and result (for RTO assessment).

> The full drill manual (empty-database restore / point-in-time restore / consistency verification / 30-minute drill schedule) is in [RECOVERY_RUNBOOK.md](RECOVERY_RUNBOOK.md).

### 1.4 RPO / RTO Explanation

- **RPO (acceptable data loss)**: determined by backup frequency. Daily full backup → RPO ≤ 24 hours, i.e., at most the last day's data is lost. For a smaller RPO, increase backup frequency (e.g., twice daily) or enable binlog incremental backups.
- **RTO (time to recover)**: depends on database size and restore speed; target ≤ 1 hour (restore + verification + service restart). Update the measured value after every drill.
- Recovery-failure emergency: first roll back the application code, then retry with the most recent usable backup; if the backup is corrupted, use an earlier backup and accept a larger RPO.

## 2. Key Management

The project depends on 5 keys, all in `.env` (admin and service are independent — do not share the same set):

| Variable | Length | Purpose |
|---|---|---|
| `ENCRYPTION_KEY` | 32 bytes | API transport encryption (config/encryption.php) |
| `ENCRYPTABLE_KEY` | 32 bytes | Sensitive database field encryption (encryptable plugin, **do not share with ENCRYPTION_KEY**) |
| `JWT_SECRET_KEY` | 64+ chars | JWT signing |
| `HASHIDS_SALT` | — | ID encryption/decryption |
| `HASHIDS_ALT_SALT` | — | ID encryption/decryption backup |

### 2.1 Generating Keys

```bash
# Outputs 5 KEY=VALUE lines to stdout, appendable directly to .env
php scripts/gen_env_keys.php

# Writes directly to .env: existing keys are not overwritten, only missing ones are appended
php scripts/gen_env_keys.php --file=.env
```

> If a key in .env is still the `change-me` placeholder, delete that line first, then run (the placeholder counts as "already exists" and will not be overwritten).

### 2.2 Key Rotation (encryptable)

```bash
bash scripts/rotate_keys.sh            # operates on the .env in the current directory by default
bash scripts/rotate_keys.sh /path/to/service/.env
```

The script does automatically: backup .env → generate a new `ENCRYPTABLE_KEY` → append the old key to `ENCRYPTION_PREVIOUS_KEYS` (comma-separated, most recently rotated first) → write the new key. Then manually, as prompted: restart the service → verify decryption → delete the backup after confirmation.

**About `ENCRYPTION_PREVIOUS_KEYS`**: encryptable first tries the current `ENCRYPTABLE_KEY` when decrypting; on failure it tries the historical keys in list order. Therefore **the old key must be added to this list before the new key takes effect**, otherwise old data cannot be decrypted after restart (no data loss — restore .env to recover). The list only grows; before removing historical keys you must confirm all old data has been re-encrypted.

**No automatic data migration**: after rotation, old data remains encrypted with the old key and reads/writes work normally. To rewrite existing data with the new key, run a data migration task separately (read table by table → write to trigger re-encryption).

### 2.3 Fail-Fast Startup Validation

The following configs are validated at service startup; a **missing key or one still holding the `change-me` placeholder** throws a `RuntimeException` and refuses to start (preventing going live with placeholder keys):

| Config | Key Validated |
|---|---|
| `service/config/encryption.php` | `ENCRYPTION_KEY` |
| `service/config/encryptable.php`, `service/config/plugin/erikwang2013/encryptable/app.php` | `ENCRYPTABLE_KEY` |
| `service/config/jwt.php`, `service/config/plugin/erikwang2013/jwt/jwt.php` | `JWT_SECRET_KEY` |

Example startup error: `ENCRYPTABLE_KEY not configured or still a placeholder; please configure a 32-byte random key in .env`.

**Daily operations checklist**:

1. Deploying a new environment: `cp .env.example .env` → delete `change-me` placeholder lines → `php scripts/gen_env_keys.php --file=.env` → start the service and confirm no key errors.
2. Routine rotation: follow 2.2, once per quarter is enough (no mandatory period; rotate immediately on leakage).
3. Backup `.env.bak.*` files contain plaintext keys; treat them like database backups (permissions 600, off-site storage).

## 3. Monitoring & Alerting (Prometheus + Grafana)

Orchestrated in `admin/docker-compose.yml` (adds prometheus / grafana / redis-exporter services); all config is in `admin/deploy/monitoring/`:

```bash
cd admin
docker compose up -d prometheus grafana redis-exporter
# Prometheus: http://host:9090   Grafana: http://host:3000
# First Grafana login: admin / ${GRAFANA_ADMIN_PASSWORD} (default change-me-grafana-password)
```

- **Data source**: Grafana auto-configures the Prometheus data source on startup (provisioning); panels are created in the UI.
- **Alert rules**: `deploy/monitoring/alerts.yml`, covering:
  - `AppDown` (application unreachable, equivalent to full-site 5xx) — critical
  - `MysqlDown` / `RedisDown` (app-side probe failures) — critical
  - `ElasticsearchDown` (ES native `/_prometheus/metrics` scrape failure) + `ElasticsearchHealthYellow` (cluster not green) — critical/warning
  - `QueueBacklog` (scout search queue `queues:scout_*` backlog >100 for 10 minutes) — warning
- **ES password injection**: prometheus reads `ELASTIC_PASSWORD` via compose `secrets` (requires Docker Compose ≥ 2.24); the config file does not hardcode the password; if unset, the change-me placeholder is used and ES 401 scrapes trigger ElasticsearchDown.
- **Reloading rules**: after editing alerts.yml, run `curl -X POST localhost:9090/-/reload` (prometheus needs `--web.enable-lifecycle`; if not added by default, restart the container).
- **Local verification**: `bash scripts/verify_monitoring.sh` — validates alert rule YAML syntax on both admin/service sides, curls both `/metrics` endpoints (admin:8787 / service:8788) for metric output, and checks Prometheus (9090/9091) rule loading; when the app/Prometheus is not running, the corresponding item prints SKIP and exits 0.

**Status**: both admin and service have `/metrics` endpoints (MetricsController, no authentication). The MetricsCollector middleware counts real accumulations by `code="all"|"5xx"` (admin outputs `open_admin_http_requests_total`, service outputs `property_service_http_requests_total`); the `Http5xxRatio` rule in both sides' alerts.yml (5xx ratio >5% for 10 minutes) is effective immediately. **Alert real-trigger verification awaits deployment**: rules are ready but have not been triggered in a real deployment (depends on `verify_monitoring.sh` and Prometheus going live).

## 4. Log Rotation

- **Container logs**: all compose services are configured with `json-file` + `max-size 10m / max-file 3`; no extra handling needed.
- **Host application logs** (`runtime/*.log`, `service/workerman.log`): use `admin/deploy/logrotate/pmp-app`:

```bash
sudo cp admin/deploy/logrotate/pmp-app /etc/logrotate.d/pmp-app
# Modify the paths in the file to match the actual deployment, then it takes effect; copytruncate allows rotation without restarting webman
sudo logrotate -d /etc/logrotate.d/pmp-app   # dry run check
```

Daily rotation by default, 30-day retention, gzip compression.

## 5. Post-Deployment Load-Test Smoke

After deployment, use k6 to smoke-test the login chain and key business endpoint reachability (low rate, not performance testing). Script: `scripts/loadtest/smoke.js` (default 2 VU, 30s, login + dashboard; all support `BASE_URL`/`VUS`/`DURATION`/`TOKEN` env var overrides).

### 5.1 Local Smoke

```bash
cd /path/to/property-management-platform/scripts/loadtest

# Probe only the login chain (no token needed; 422 incorrect captcha / 429 rate limited both mean defenses are active, treated as reachable)
k6 run -e BASE_URL=http://127.0.0.1:8790 smoke.js

# With authenticated business endpoints: sign a load-test JWT on the deployment server (depends on admin/.env and vendor), then pass it in
TOKEN=$(php mint-token.php)
k6 run -e BASE_URL=https://admin.example.com -e TOKEN="$TOKEN" smoke.js

# Custom concurrency/duration
k6 run -e BASE_URL=https://admin.example.com -e TOKEN="$TOKEN" -e VUS=5 -e DURATION=60s smoke.js
```

For full load testing (login + dashboard + fee, three scripts), still use `bash scripts/loadtest/run.sh [BASE_URL] [VUS] [DURATION]`.

### 5.2 CI Smoke (GitHub Actions manual trigger)

Repository Actions page → **Loadtest Smoke** → **Run workflow**:

| Input | Required | Description |
|---|---|---|
| `target_url` | Yes | Environment under test, e.g. `https://admin.example.com` |
| `duration` | No | Smoke duration, default `30s` |
| `token` | No | Load-test JWT; leave empty to probe only the login chain |

Getting the token (run at the repo root on the deployment server; requires `admin/.env` and `admin/vendor/`):

```bash
php scripts/loadtest/mint-token.php
```

> Note: the token is a load-test-only JWT (default erik admin account) and appears in plain text in workflow logs — sign it with a load-test-only account; if exposing it in production is inconvenient, use the 5.1 local smoke instead.
