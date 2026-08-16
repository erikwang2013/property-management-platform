#!/usr/bin/env bash
# ============================================================
# 监控验证脚本（本地可跑部分）
# Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
# ============================================================
# 用法: bash scripts/verify_monitoring.sh
# 检查项:
#   1. admin/ 与 service/ 的 deploy/monitoring/ 告警规则 YAML 语法（yamllint 或 python3+yaml）
#   2. curl 两端 /metrics 端点（admin:8787, service:8788，端口可覆盖）验证指标输出
#   3. Prometheus 在跑则校验 /-/healthy 与 /api/v1/rules 规则已加载；不在跑则提示跳过
# 退出码: 0 = 无失败（SKIP 不计失败），1 = 存在失败
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ADMIN_PORT="${ADMIN_METRICS_PORT:-8787}"
SERVICE_PORT="${SERVICE_METRICS_PORT:-8788}"
PROM_ADMIN="${PROMETHEUS_ADMIN_PORT:-9090}"
PROM_SERVICE="${PROMETHEUS_SERVICE_PORT:-9091}"
FAIL=0

say()  { printf '%-6s %s\n' "$1" "$2"; }
fail() { say FAIL "$1"; FAIL=1; }

# ── 1. 告警规则 YAML 语法 ──
yaml_check() {
    local file="$1"
    if command -v yamllint >/dev/null 2>&1; then
        if yamllint -q "$file"; then say PASS "YAML $file"; else fail "YAML $file"; fi
    elif command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' >/dev/null 2>&1; then
        if python3 - "$file" <<'PY'
import sys, yaml
try:
    yaml.safe_load(open(sys.argv[1]))
except Exception as e:
    print(f"FAIL: {e}")
    sys.exit(1)
PY
        then say PASS "YAML $file"; else fail "YAML $file"; fi
    else
        say SKIP "YAML $file（无 yamllint/python3-yaml，跳过解析）"
    fi
}

for f in "$ROOT/admin/deploy/monitoring/alerts.yml" "$ROOT/admin/deploy/monitoring/prometheus.yml" \
         "$ROOT/service/deploy/monitoring/alerts.yml" "$ROOT/service/deploy/monitoring/prometheus.yml"; do
    [ -f "$f" ] && yaml_check "$f" || fail "文件缺失 $f"
done

# ── 2. 两端 /metrics 端点 ──
metrics_check() {
    local name="$1" port="$2" prefix="$3"
    local url="http://localhost:${port}/metrics"
    local out
    if out="$(curl -fsS -m 5 "$url" 2>/dev/null)"; then
        if grep -q "$prefix" <<<"$out"; then
            say PASS "$name /metrics（含 ${prefix}* 指标）"
        elif ! grep -qE '^# (HELP|TYPE) ' <<<"$out"; then
            say SKIP "$name /metrics 端口被其他应用占用或响应非 Prometheus 指标格式（$url）"
        else
            fail "$name /metrics 端点响应但无 ${prefix}* 指标"
        fi
    else
        say SKIP "$name /metrics 不可达（应用未运行？）$url"
    fi
}

metrics_check "admin   " "$ADMIN_PORT" "open_admin_"
metrics_check "service " "$SERVICE_PORT" "property_service_"

# ── 3. Prometheus 规则加载校验 ──
prom_check() {
    local port="$1" label="$2" rules_file="$3"
    if ! curl -fsS -m 3 "http://localhost:${port}/-/healthy" >/dev/null 2>&1; then
        say SKIP "prometheus($label) :${port} 未运行"
        return
    fi
    say PASS "prometheus($label) :${port} /-/healthy"
    local rules
    rules="$(curl -fsS -m 5 "http://localhost:${port}/api/v1/rules" 2>/dev/null)" || { fail "prometheus($label) /api/v1/rules 不可达"; return; }
    local missing=0 alert
    while read -r alert; do
        [ -z "$alert" ] && continue
        if ! grep -q "\"name\":\"${alert}\"" <<<"$rules"; then
            say FAIL "prometheus($label) 规则未加载: $alert"
            missing=1
        fi
    done < <(grep -E '^[[:space:]]*-[[:space:]]*alert:' "$rules_file" | sed 's/.*alert:[[:space:]]*//')
    [ "$missing" -eq 0 ] && say PASS "prometheus($label) 告警规则已加载（$(grep -cE '^[[:space:]]*-[[:space:]]*alert:' "$rules_file") 条）" || FAIL=1
}

prom_check "$PROM_ADMIN" "admin" "$ROOT/admin/deploy/monitoring/alerts.yml"
prom_check "$PROM_SERVICE" "service" "$ROOT/service/deploy/monitoring/alerts.yml"

# ── 汇总 ──
if [ "$FAIL" -eq 0 ]; then
    echo ""
    echo "监控验证通过（SKIP 项为本地环境未运行，不影响结果）"
else
    echo ""
    echo "监控验证存在失败，请检查上方 FAIL 项"
fi
exit "$FAIL"
