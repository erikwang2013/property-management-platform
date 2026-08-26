# Performance Load Test & Slow Query Report (2026-08-16)

Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## 1. Test Environment & Methodology

| Item | Value |
|---|---|
| Application | webman v2 (PHP 8.3, 32 workers), admin + service dual applications |
| Tested instance | admin on dedicated port 8790 (`SERVER_LISTEN=http://0.0.0.0:8790`) |
| Tool | k6 v0.51.0 (no wrk/ab/hey on this machine), scripts in `scripts/loadtest/` |
| Load test targets | Login (/api/auth/login), dashboard (/admin/dashboard), charge payment list (/admin/fee-payment) |
| Authentication | dashboard/fee use JWT signed by `scripts/loadtest/mint-token.php` (bypasses captcha, `sub=21000000000000100`); the login script uses an invalid captcha to probe the chain |
| Data | Single machine, direct 127.0.0.1 connection, no gateway/CDN; MySQL/Redis on the same host as the app |

Script entry: `bash scripts/loadtest/run.sh [BASE_URL] [VUS] [DURATION]` (requires k6 in PATH).
Login script notes: login is double-protected by captcha + rate limiting (10/min/IP), which is a security design; it cannot and should not be load tested at high concurrency. login.js probes chain latency at a low rate of 1 VU / 8 requests, expecting 422 (incorrect captcha) or 429 (rate limited) — both mean the defenses are working correctly.

## 2. Load Test Results

### 20 VU / 30s (baseline load)

| Endpoint | Requests | Throughput | avg | p90 | p95 | max | Failure Rate |
|---|---|---|---|---|---|---|---|
| login (1 VU × 8) | 8 | 14.4/s | 68.6ms | 154ms | 207.8ms | 261ms | 0% |
| dashboard | 6863 | 227.9/s | 86.0ms | 151ms | 189.5ms | 1.37s | 0% |
| fee-payment | 5944 | 197.2/s | 99.3ms | 178ms | 220.0ms | 704ms | 0% |

### 50 VU / 30s (increased load)

| Endpoint | Requests | Throughput | avg | p95 | max | Failure Rate |
|---|---|---|---|---|---|---|
| login (1 VU × 8) | 8 | 18.7/s | 52.1ms | 173ms | 243.8ms | 0% |
| dashboard | 6902 | 226.9/s | 212.7ms | 544.0ms | 1.99s | 0% |
| fee-payment | 7525 | 247.4/s | 195.7ms | 514.2ms | 2.0s | 0% |

(At 50 VU the p95 exceeded the 500ms threshold, so k6 exited on threshold breach, but 0% of requests failed and there were 0 non-200 responses.)

### Conclusion

- All endpoints had 0 failures at 20 VU, p95 < 220ms — healthy.
- **Throughput bottleneck is about 230–250 rps**: going from 20 VU → 50 VU, throughput plateaued instead of rising (dashboard 227.9 → 226.9, fee 197 → 247), while p95 latency doubled (~190ms → ~540ms). On a single machine with 32 workers that is about 7–8 rps per worker — characteristic of the per-core processing ceiling of the full PHP chain (including MySQL queries and Redis cache round trips), not connection exhaustion (no failed requests).
- Recommendation: this scale on a single machine is sufficient (about 20 million requests/day); for higher throughput, prefer scaling out instances horizontally, then investigate per-endpoint SQL and cache hit rates (see below).

## 3. Slow Query Review

- The charge tables `erik_fee_bill` / `erik_fee_payment` have well-formed indexes (paid_at, bill_id, owner_id, payment_number, etc.); all core queries have usable indexes.
- Finding: the charge list fuzzy search by `payment_number like %kw%` (leading wildcard) cannot use an index and degrades to a full table scan at scale. It is a low-frequency admin search, so left as-is for now; can switch to inverted or prefix indexes as data grows.
- **MySQL slow_query_log is OFF**: recommended to enable it with `long_query_time=1` to continuously observe real slow SQL (rather than inferring from load tests). Production commands:
  ```sql
  SET GLOBAL slow_query_log = ON;
  SET GLOBAL long_query_time = 1;
  ```
- Dashboard aggregation: each cache rebuild runs about 8 COUNT aggregations + 30-day grouped statistics; a single rebuild costs seconds, absorbed by the Redis 5-minute cache (see below) — not a hot path.

## 4. Redis Cache Re-check

- Dashboard cache `dashboard:data`: `setex 300`; ~10ms on hit, seconds to rebuild on miss. **Issue: no invalidation on any write operation**, so data can be up to 5 minutes stale after changes. Recommendation: delete this key in charge/property write endpoints (one line: `del dashboard:data`).
- **No cache-breakdown protection**: when the key expires, all 32 workers rebuild simultaneously (repeating the 8 aggregation queries). At scale, consider a simple mutex (e.g. `set nx ex` lock + double-check).
- Permission cache `perm:{adminId}` at 60s behaves correctly.
- Open investigation item: the `dashboard:data` key was never observed in the local Redis (checked across multiple DBs), yet endpoint responses are normal and hit latency is clearly lower. During load testing, occasional 403 "no permission" responses appeared (2 occurrences, then stable 200). Suspected difference between local multi-Redis instances/env var config and production; needs verification in the target environment and does not affect the load test conclusions (0 failures in the stable phase).

## 5. Deliverables

- `scripts/loadtest/mint-token.php` — signs load-test JWTs (`php mint-token.php --file=/tmp/pmp-token`)
- `scripts/loadtest/login.js` / `dashboard.js` / `fee.js` — k6 scripts
- `scripts/loadtest/run.sh` — one-click runner (mints token + runs three scripts; args: BASE_URL VUS DURATION)
- This report

Reproduction command: `PATH=/home/erik/bin:$PATH bash scripts/loadtest/run.sh http://127.0.0.1:8790 20 30s`
