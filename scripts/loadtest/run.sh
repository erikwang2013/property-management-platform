#!/usr/bin/env bash
# ============================================================
# 压测一键运行（k6 + mint-token）
# Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
#
# 用法: bash run.sh [BASE_URL] [VUS] [DURATION]
# 示例: bash run.sh http://127.0.0.1:8790 20 30s
# 依赖: k6 在 PATH 中（下载: https://k6.io/get-started/）
# ============================================================

set -euo pipefail

BASE_URL="${1:-http://127.0.0.1:8790}"
VUS="${2:-20}"
DURATION="${3:-30s}"

DIR="$(cd "$(dirname "$0")" && pwd)"

TOKEN=$("$DIR/mint-token.php" --file=/tmp/pmp-token >/dev/null && cat /tmp/pmp-token)

for script in login dashboard fee; do
    echo "===== $script.js (VUS=$VUS, $DURATION) ====="
    k6 run -e BASE_URL="$BASE_URL" -e TOKEN="$TOKEN" -e VUS="$VUS" -e DURATION="$DURATION" "$DIR/$script.js"
done
