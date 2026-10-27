# Scaling Plan

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

The current deployment is a single-machine docker-compose (MySQL/Redis/Elasticsearch on the same host as the application, see `admin/docker-compose.yml`) with no HA. This document explains the risks and existing mitigations, and provides the horizontal scaling path, data-growth trigger points, and drill recommendations. The operations baseline (backup/restore, monitoring & alerting, log rotation) is in [OPS_RUNBOOK.md](OPS_RUNBOOK.md).

---

## 1. Current Deployment & Risks

### 1.1 Current State

| Component | Version | Description |
|------|------|------|
| MySQL | 8.0.36 | Single instance, data persisted in host volumes |
| Redis | 7.2-alpine | Single instance, cache/queue/lock |
| Elasticsearch | 8.12.0 | Single node, scout full-text search |
| nginx + webman | — | admin (8787) and service (8788) multi-process on one host |
| Prometheus + Grafana | — | Monitoring & alerting, same host |

### 1.2 Risk List

| Risk | Impact | Probability | Consequence |
|------|------|------|------|
| Single point of failure (any middleware down) | Entire site unavailable | Low | High |
| Host disk/memory/CPU contention | Slow queries, ES lag, OOM | Medium (rises as data grows) | Medium |
| MySQL single-instance unrecoverable corruption | Data loss | Very low | Very high |
| No disaster recovery site | Total loss on facility-level failure | Very low | Very high |
| Backup/restore never drilled | Restore timeout or failure | Medium | High |

## 2. Existing Mitigations (Implemented)

- **Backup**: single-entry backup script `scripts/backup.sh` (reads connection from `admin/.env`, defaults to mysqldump inside the container), daily full backup via crontab, 7-day retention by default (`--keep-days=30` configurable); restore drill procedure and RPO/RTO details in OPS_RUNBOOK §1 and RECOVERY_RUNBOOK.
- **Monitoring & alerting**: Prometheus + Grafana + `deploy/monitoring/alerts.yml`, covering AppDown / MysqlDown / RedisDown / ElasticsearchDown / QueueBacklog, see OPS_RUNBOOK §3.
- **Log rotation**: container logs `max-size 10m`, host logs rotated daily by logrotate with 30-day retention, see OPS_RUNBOOK §4.
- **Application layer**: webman multi-process residency, queue tasks decouple slow operations, `/health` health check.

Conclusion: the above mitigations cover "recoverable from failure", **not "uninterrupted operation"**. If business cannot tolerate interruption, proceed to the horizontal scaling in §3.

## 3. Horizontal Scaling Path (by Priority)

General scaling principle: vertical first (add CPU/memory/disk), then horizontal (split components); middleware before application; every step can be rolled back independently.

### 3.1 MySQL Master-Replica + Semi-Sync (First Priority)

- Architecture: primary (current instance) → replica (new machine), enable semi-sync replication (`rpl_semi_sync_master_enabled=1`).
- Read scaling: enable master/replica separation in the app config (`config/database.php` supports read/write splitting; otherwise do master-replica HA first).
- Backup migration: point the backup script at the replica to avoid loading the primary.
- Version: the replica must match the primary's major version (currently 8.0.36).
- Upgrade trigger: primary CPU sustained >70%, connections approaching max_connections, or a surge in scanned rows in the slow query log.

### 3.2 Redis Sentinel or Cluster (Second Priority)

- Sentinel (3 nodes): choose sentinel when capacity needs are modest; failover is second-level, and the client must support `sentinel` mode.
- Cluster (≥3 primary + 3 replica): choose Cluster when cache volume exceeds single-machine memory or write concurrency rises.
- Note: queues and distributed locks depend on Redis; when changing topology, update `config/redis.php` accordingly and verify lock/queue behavior under failover.

### 3.3 Elasticsearch Dedicated Node

- A single-node ES has no replicas; index corruption makes search unavailable. At minimum, migrate to a dedicated machine + 1 replica.
- As data grows, split indexes by business domain and disable replicas on unused indexes to control resources.
- Upgrade trigger: heap usage sustained >70%, write rejections (rising `es_rejected_executions`), or query p95 over 1s.

### 3.4 Application Multi-Replica + Load Balancer (Last)

- Run 2+ replicas of each of admin/service behind nginx load balancing (round-robin or least_conn).
- Precondition: statelessness (sessions in Redis, no local file write dependencies; this system uses JWT + Redis sessions, largely satisfied).
- Then double processing capacity by replica count, and return to the middleware bottlenecks in §3.1-3.3.

## 4. Data Growth Trigger Points & Recommendations

| Trigger | Suggested Threshold | Required Action |
|--------|----------|----------|
| Total database size | > 50GB or single table > 50M rows | Master-replica split + archive historical bill/log tables |
| Slow queries | Daily slow queries > 10 or single query > 2s | Add indexes, shard tables, check N+1 |
| MySQL connections | Sustained > 80% of max_connections | Connection pool + master-replica |
| Redis memory | > 70% and growing | Clean expired keys → Sentinel → Cluster |
| ES heap | > 70% or write rejections | Dedicated node + replicas + index splitting |
| CPU | Single core sustained > 80% with queue backlog | App multi-replica → middleware split |
| Disk | > 80% | Clean backups/logs, archive cold data |

Recommendation: review the table above monthly (data can come from Grafana panels); start the corresponding scaling when any item exceeds its threshold for two consecutive weeks.

## 5. Scaling Drill Recommendations

- **Quarterly**: restore drill (see OPS_RUNBOOK §1.3), verify RPO/RTO targets are met.
- **Annually**: master-replica switch drill (drill on a new machine, never touch the production primary): build replica → catch up → switch → verify reads/writes on both ends → switch back.
- **After the first scale-out**: use `scripts/loadtest` to load test the three paths (login/list/search) to confirm p95 meets targets (see `docs/PERFORMANCE_REPORT_2026-08-16.md`).
- **Drill records**: record every drill in the change log (CHANGELOG.md), including: time, drill item, result, open issues.

## 6. Upgrade Path Quick Reference

```
Single machine (current)
  ├─ MySQL master-replica semi-sync   ← First priority
  ├─ Redis Sentinel/Cluster           ← Second priority
  ├─ ES dedicated node + replicas     ← Third priority
  └─ App multi-replica + LB           ← Last
        ↓
Multi-machine deployment (no single point; tolerable failure interruption → tolerable minute-level interruption → second-level failover)
```

> No scaling is needed at the current business volume; this document exists so that "when data volume/failure requirements change" you can follow it directly instead of deciding on the spot.
