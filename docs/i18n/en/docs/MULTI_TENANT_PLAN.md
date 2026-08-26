# Multi-Tenant SaaS Plan Review

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> Status: review draft (P3-① predecessor task) | Date: 2026-08-16

## 1. Current-State Inventory

### 1.1 Table Structure Classification (65 tables, verified against docs/install.sql)

| Category | Tables | Description |
|------|-----|------|
| Global/platform tables | erik_admin_user / admin_role / admin_permission / admin_user_role / admin_role_permission, erik_system_config, erik_operation_log | Auth, config, audit — naturally platform-level, not tenant-bound |
| Community-dimension tables | erik_community and 40+ business tables owned via community_id (building/unit/room/owner/fee_*/repair_order/parking_*/announcement, etc.) | Indirectly tenant-bound through community_id |
| Group association tables | erik_group (group), erik_group_community (group↔community) | Currently **optional associations**, no tenant semantics; cross-community aggregation relies on joins |
| Platform extension tables | erik_notification_template, erik_knowledge_base, erik_mall_*, erik_face_info, etc. | Some platform-level, some community-level; need case-by-case confirmation |
| Confusing table | **erik_tenant (lease tenant table)** | ⚠️ Semantic conflict: it is a "property lease tenant" (room_id/owner_id dimension), **not** a SaaS tenant |

### 1.2 Authorization Chain (admin side, verified in code)

```
Global middleware: Cors → SecurityFilter → RateLimit
Route-group middleware: AdminAuth(JWT → $request->adminId) → AdminPermission(RBAC method.path) → OperationLog → Controller
```

- `AdminAuth` already establishes the request-injection pattern (`$request->adminId`); tenant context can replicate it exactly
- `AdminPermission` is platform-level RBAC, **orthogonal** to tenant isolation and can be layered on top
- service owner side: JWT carries owner_id; data is naturally restricted via room_owner → room.community_id, so cross-tenant risk is low

### 1.3 Key Conclusions

- No existing SaaS tenant model; the `erik_tenant` name is taken by lease tenants, so any new concept must avoid that name
- All controllers query Eloquent directly — no repository layer, no global scopes — so isolation changes must be done at the model layer
- config/database.php uses a single connection, but illuminate/database natively supports multiple connections (reserved for future independent-database evolution)

## 2. Option Comparison & Recommendation

| Option | Mechanism | Rework Effort | Ops Cost | Suitable For |
|------|------|--------|----------|------|
| **A. Shared database + tenant_id row isolation (recommended)** | Tenant table + tenant_id column on business tables + Eloquent global scope filtering | Medium (2 tables get columns + middleware + global scope + backfill existing data) | Low (single-db backup/migration unchanged) | Small/medium properties, <5M rows per tenant |
| B. Independent databases (one DB per tenant) | Connection routing + cross-db aggregation | High (connection management/cross-db reports/migrations×N/backups×N) | High | Large groups, compliance isolation requirements |
| C. Hybrid (sensitive DBs independent + shared) | A+B combination | High | High | Strong-isolation scenarios like payments/face recognition |

**Recommendation: A, with B as the evolution direction.** Reasons:

1. All 65 tables live in a single database; A's tenant_id data model does not block future database splitting (filter granularity changes from row to database; tenant IDs are already globally modeled under A)
2. Business data is all attributed through community_id; tenant_id only needs to be added to the **top-level tables**; the ~40 intermediate business tables are guaranteed by access paths, avoiding per-table column additions
3. Both ends (admin/service) share the same data model; A's changes concentrate in the admin runtime layer
4. Under the current single-machine deployment, B's backup/migration complexity is unacceptable

## 3. Isolation Point Design

### 3.1 Data Model (minimal set)

- Create `erik_platform_tenant` (avoiding conflict with the lease-tenant table erik_tenant): id/name/status/created_at, etc.
- Add `tenant_id BIGINT NOT NULL DEFAULT 0` to `erik_community`, with index `(tenant_id, community_id)`
- Add `tenant_id BIGINT NOT NULL DEFAULT 0` to `erik_admin_user` (0 = platform super admin)
- Business intermediate tables (building/room/fee_bill, ~40 tables) **get no column**; they are attributed via community_id

### 3.2 Runtime-Layer Trio

1. **TenantContext middleware**: add a `tenant_id` claim to the JWT payload → `$request->tenantId` (replicating the AdminAuth injection pattern); whitelist login/install/platform-level routes (user/role/permission/config)
2. **TenantScope global scope**: attach Eloquent global scopes to Community and platform-level business models, auto-filtering by `$request->tenantId`; `find()` is also constrained by the scope, natively preventing cross-tenant single-record direct queries
3. **Tenant::for() explicit context**: scheduled tasks/queues/imports have no HTTP request; wrap them in closures specifying the tenant explicitly; when context is missing, **fail closed** (deny queries) — no unfiltered silent pass-through

### 3.3 Authorization-Bypass Protection Test Points (acceptance matrix)

| Test Case | Expected |
|------|------|
| Tenant A admin lists tenant B's community/building/fee_bill | Empty result or only A's data |
| Tenant A admin find/update/delete of tenant B's single record (direct id query) | 403 / empty data / denied |
| Platform admin (tenant_id=0) cross-tenant operations | Allowed (platform-level capability) |
| service owner cross-community operations (payment/repair) | Denied (community ownership check) |
| Scheduled task/queue without a tenant context | Fail closed with an error, not unfiltered |

## 4. Evolution Path (Stepwise Migration)

| Step | Content | Acceptance |
|------|------|------|
| 1. Data layer | Create platform_tenant table + add columns to community/admin_user + idempotent migration + default tenant initialization and backfill of existing data | Every community must have a tenant; orphan-data report reaches zero |
| 2. Runtime layer | TenantContext middleware + TenantScope + Tenant::for() utility + route whitelist | Single-tenant regression: all 133 tests pass |
| 3. Pilot modules | Enable isolation on four modules first: group management → community → owner → charges (bills) | Authorization-bypass test matrix passes |
| 4. Full rollout | Enable per module in batches (Batch 1 core → Batch 2 auxiliary → extension modules) | Bypass matrix passes for all modules |
| 5. Evolution | Assess database splitting (option B) when single-tenant data >5M rows or compliance requires it; A's data model does not block it | Split-plan review |

Data migration strategy: all existing data goes to the "default tenant" (created by the migration script); no business data is deleted or modified; the migration script is idempotent and re-runnable.

## 5. Risk List

| Risk | Impact Surface | Mitigation / Rollback |
|------|--------|-------------|
| Large rework across 58+17 controller query paths | All business endpoints | Global scopes cover ~80% of list/detail; raw queries and batch imports use Tenant::for(); gradual rollout per batch |
| Global scopes accidentally affecting platform-level queries (dashboard cross-community aggregation) | Dashboard/reports | Platform-level endpoints explicitly use Tenant::without() or tenant_id=0 bypass |
| Scheduled tasks/queues have no request context | Background tasks like reminders/SLA/notifications | Tenant::for() explicit wrapping + fail closed |
| Existing-data backfill errors | All existing data | Idempotent script + backfill validation + dry-run mode |
| Index/performance impact | High-frequency tables (fee_bill/room/owner) | (tenant_id, community_id) composite index; re-check slow query log |
| 133-test regression | Full suite | Run full regression after scope injection before enabling pilots |
| Naming confusion (erik_tenant lease tenant vs SaaS tenant) | Developer cognition | New table named platform_tenant; explicitly documented |
| **Rollback plan** | — | Global scopes can be disabled with a config switch (restoring single-tenant semantics); data columns kept, not deleted; no destructive changes |

## 6. Review Conclusion

**Recommended now**:
- Shared database + tenant_id row isolation (option A); create the `erik_platform_tenant` table; add columns to community/admin_user
- TenantContext middleware + TenantScope global scope + Tenant::for() utility
- Pilot order: group → community → owner → charges
- Precondition: complete — multi-tenant tables/columns/backfill are already inlined into docs/install.sql (merged on 2026-08-16, single database-creation entry)

**Recommended to defer**:
- Independent-database isolation (B): start only when a single tenant exceeds 5M rows or compliance requires it; the data model is already prepared
- Hybrid option (C): evaluate only if a customer explicitly requires strong isolation for payments/face recognition

**Not recommended**:
- Schema-level isolation (MySQL has no independent schema semantics; cost equals independent databases)
- Dynamic multi-database routing (no benefit under single-machine deployment)
- Tenant-specific customized schema/fields (YAGNI)
- Reusing/repurposing the erik_tenant lease-tenant table as the SaaS tenant (semantic conflict; breaks lease-tenant business)
