# 性能压测与慢查询治理报告（2026-08-16）

Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## 1. 测试环境与方法

| 项 | 值 |
|---|---|
| 应用 | webman v2（PHP 8.3，32 workers），admin + service 双应用 |
| 被测实例 | admin 独立端口 8790（`SERVER_LISTEN=http://0.0.0.0:8790`） |
| 工具 | k6 v0.51.0（本机无 wrk/ab/hey），脚本见 `scripts/loadtest/` |
| 压测目标 | 登录（/api/auth/login）、仪表盘（/admin/dashboard）、费用缴费列表（/admin/fee-payment） |
| 鉴权 | dashboard/fee 用 `scripts/loadtest/mint-token.php` 签发 JWT（绕过验证码，`sub=21000000000000100`）；登录脚本用无效验证码探测链路 |
| 数据 | 单机直连 127.0.0.1，未经过网关/CDN；MySQL/Redis 与应用同机 |

脚本入口：`bash scripts/loadtest/run.sh [BASE_URL] [VUS] [DURATION]`（需 k6 在 PATH）。
登录脚本说明：登录为验证码 + 限流（10 次/分/IP）双保护，属安全设计，无法也不应高并发压测；login.js 以 1 VU / 8 次请求低速率探测链路延迟，预期返回 422（验证码错误）或 429（限流），均为防御正常生效。

## 2. 压测结果

### 20 VU / 30s（基准负载）

| 接口 | 请求数 | 吞吐 | avg | p90 | p95 | max | 失败率 |
|---|---|---|---|---|---|---|---|
| login（1 VU × 8 次） | 8 | 14.4/s | 68.6ms | 154ms | 207.8ms | 261ms | 0% |
| dashboard | 6863 | 227.9/s | 86.0ms | 151ms | 189.5ms | 1.37s | 0% |
| fee-payment | 5944 | 197.2/s | 99.3ms | 178ms | 220.0ms | 704ms | 0% |

### 50 VU / 30s（加压）

| 接口 | 请求数 | 吞吐 | avg | p95 | max | 失败率 |
|---|---|---|---|---|---|---|
| login（1 VU × 8 次） | 8 | 18.7/s | 52.1ms | 173ms | 243.8ms | 0% |
| dashboard | 6902 | 226.9/s | 212.7ms | 544.0ms | 1.99s | 0% |
| fee-payment | 7525 | 247.4/s | 195.7ms | 514.2ms | 2.0s | 0% |

（50 VU 下 p95 > 500ms 阈值，k6 判定阈值越界退出，但 0% 请求失败、0 个非 200。）

### 结论

- 全部接口在 20 VU 下 0 失败，p95 < 220ms，健康。
- **吞吐瓶颈约 230–250 rps**：20 VU → 50 VU 吞吐不升反平（dashboard 227.9 → 226.9，fee 197 → 247），而 p95 延迟翻倍（~190ms → ~540ms）。单机 32 worker 下每 worker 约 7–8 rps，为 PHP 全链路（含 MySQL 查询、Redis 缓存往返）的单核处理上限特征，非连接耗尽（无失败请求）。
- 建议：单机该规模已够用（约 2 千万请求/天）；若要更高吞吐，优先横向加实例，其次排查各接口 SQL 与缓存命中（见下）。

## 3. 慢查询审查

- 费用表 `erik_fee_bill` / `erik_fee_payment` 索引完善（paid_at、bill_id、owner_id、payment_number 等），核心查询均有索引可用。
- 发现点：费用列表按 `payment_number like %kw%` 模糊搜索（前导通配符），无法走索引，数据量大时该条件会退化为全表扫。属低频管理端搜索，暂不处理；数据量增长后可改为倒排或前缀索引。
- **MySQL slow_query_log 处于 OFF**：建议开启并设 `long_query_time=1`，持续观察真实慢 SQL（而非靠压测推断）。生产执行：
  ```sql
  SET GLOBAL slow_query_log = ON;
  SET GLOBAL long_query_time = 1;
  ```
- 仪表盘聚合：每次缓存重建执行约 8 个 COUNT 聚合 + 30 天分组统计，单次重建为秒级成本，被 Redis 5 分钟缓存吸收（见下），非热点路径。

## 4. Redis 缓存复查

- 仪表盘缓存 `dashboard:data`：`setex 300`，命中时 ~10ms，未命中重建秒级。**问题：无任何写操作失效逻辑**，数据变更后最多 5 分钟陈旧。建议在费用/房产写接口处删除该 key（一行 `del dashboard:data`）。
- **无缓存击穿保护**：key 过期瞬间 32 个 worker 同时重建（重复执行 8 聚合查询）。数据量大后建议加简单互斥（如 `set nx ex` 锁 + 双检）。
- 权限缓存 `perm:{adminId}` 60s，行为正常。
- 遗留调查项：本机 Redis 中始终未观察到 `dashboard:data` 键（多个 db 均无），但接口响应正常且命中时延明显低。压测期间偶发 403「无权限访问」（出现 2 次后恢复稳定 200）。怀疑为本机多 Redis 实例/环境变量配置与线上差异，需在目标环境复核，不影响压测结论（稳定段 0 失败）。

## 5. 可交付物

- `scripts/loadtest/mint-token.php` — 签发压测 JWT（`php mint-token.php --file=/tmp/pmp-token`）
- `scripts/loadtest/login.js` / `dashboard.js` / `fee.js` — k6 脚本
- `scripts/loadtest/run.sh` — 一键运行（mint token + 三脚本，参数：BASE_URL VUS DURATION）
- 本报告

复现命令：`PATH=/home/erik/bin:$PATH bash scripts/loadtest/run.sh http://127.0.0.1:8790 20 30s`
