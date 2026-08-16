#!/usr/bin/env bash
# ============================================================
# 物业管理系统 — MySQL 全量备份脚本 (P8-A)
# Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
# ============================================================
# 用法: bash scripts/backup.sh [--container=NAME] [--output=DIR] [--keep-days=N]
#   从 admin/.env 读取数据库凭据（webman 格式，环境变量优先于 .env）。
#   默认从 docker-compose.yml 探测 MySQL 服务（mysql/db）并经 compose 在容器内
#   执行 mysqldump；找不到 compose 文件或未运行 docker 时回退本机 mysqldump。
#   可 --container= 显式指定容器名（docker exec 方式，跳过 compose 探测）。
# 定时: 0 2 * * * cd /path/to/property-management-platform && bash scripts/backup.sh >> /var/log/pmp-backup.log 2>&1
# 幂等: 每次生成独立时间戳文件，可重复执行；无交互，适合 cron。
# 兼容: bash 3.2+（macOS 默认 bash 可跑）。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT/admin/.env"
BACKUP_DIR="$ROOT/backups"
KEEP_DAYS=7
CONTAINER=""
LOCAL_MODE=0
COMPOSE_FILE=""
COMPOSE_SVC=""

usage() {
    cat <<EOF
用法: $(basename "$0") [选项]
  --container=NAME   指定 MySQL 容器名（跳过 compose 探测，用 docker exec）
  --output=DIR       备份输出目录（默认 $ROOT/backups）
  --keep-days=N      保留 N 天，过期文件自动删除（默认 7）
  --local            强制本机 mysqldump（不经 docker）
  -h, --help         显示本帮助

示例:
  bash scripts/backup.sh                       # 探测 compose 并备份
  bash scripts/backup.sh --container=open-admin-mysql
  bash scripts/backup.sh --output=/mnt/backup --keep-days=30
  bash scripts/backup.sh --local               # 本机直接跑 mysqldump
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --container=*) CONTAINER="${1#*=}" ;;
        --output=*)    BACKUP_DIR="${1#*=}" ;;
        --keep-days=*) KEEP_DAYS="${1#*=}" ;;
        --local)       LOCAL_MODE=1 ;;
        -h|--help)     usage; exit 0 ;;
        *) echo "未知参数: $1（--help 查看用法）" >&2; exit 1 ;;
    esac
    shift
done

case "$KEEP_DAYS" in
    ''|*[!0-9]*) echo "错误: --keep-days 必须是正整数（当前: $KEEP_DAYS）" >&2; exit 1 ;;
esac

# 读取 .env 键值（与 scripts/deploy.sh 同款解析）
env_value() {
    local key="$1" default="$2" v
    v="$(grep -E "^${key}=" "$ENV_FILE" 2>/dev/null | tail -n1 | cut -d= -f2- || true)"
    if [ -n "$v" ]; then printf '%s' "$v"; else printf '%s' "$default"; fi
}

# 取值优先级: 环境变量 > .env > 默认值
get_conf() {
    local key="$1" default="$2"
    local v="${!key:-}"
    if [ -n "$v" ]; then printf '%s' "$v"; else env_value "$key" "$default"; fi
}

DB_HOST="$(get_conf DB_HOST 127.0.0.1)"
DB_PORT="$(get_conf DB_PORT 3306)"
DB_DATABASE="$(get_conf DB_DATABASE property_management)"
DB_USERNAME="$(get_conf DB_USERNAME root)"
DB_PASSWORD="$(get_conf DB_PASSWORD "")"

# 探测 compose 文件里的 MySQL 服务名（mysql 或 db）
find_compose_mysql() {
    local f svc
    for f in "$ROOT/docker-compose.yml" "$ROOT/admin/docker-compose.yml" "$ROOT/service/docker-compose.yml"; do
        [ -f "$f" ] || continue
        svc="$(grep -E "^  (mysql|db):" "$f" | head -n1 | tr -d ' :' || true)"
        if [ -n "$svc" ]; then
            COMPOSE_FILE="$f"
            COMPOSE_SVC="$svc"
            return 0
        fi
    done
    return 1
}

DOCKER_MODE=0
DOCKER_CMD=()
if [ -n "$CONTAINER" ]; then
    DOCKER_MODE=1
    DOCKER_CMD=(docker exec -i -e "MYSQL_PWD=$DB_PASSWORD" "$CONTAINER")
elif [ "$LOCAL_MODE" -ne 1 ] && command -v docker >/dev/null 2>&1 && find_compose_mysql; then
    DOCKER_MODE=1
    DOCKER_CMD=(docker compose -f "$COMPOSE_FILE" exec -T -e "MYSQL_PWD=$DB_PASSWORD" "$COMPOSE_SVC")
fi

mkdir -p "$BACKUP_DIR"
BACKUP_FILE="${BACKUP_DIR}/backup_$(date +%Y%m%d_%H%M%S).sql.gz"

now() { date '+%Y-%m-%d %H:%M:%S'; }
echo "[$(now)] 开始备份: ${DB_DATABASE}@${DB_HOST}:${DB_PORT} → $BACKUP_FILE"

MYSQLDUMP_ARGS=(
    -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME"
    --single-transaction --routines --triggers
    --default-character-set=utf8mb4
    "$DB_DATABASE"
)

if ! { if [ "$DOCKER_MODE" -eq 1 ]; then
           "${DOCKER_CMD[@]}" mysqldump "${MYSQLDUMP_ARGS[@]}"
       else
           MYSQL_PWD="$DB_PASSWORD" mysqldump "${MYSQLDUMP_ARGS[@]}"
       fi
    } | gzip > "$BACKUP_FILE"; then
    echo "错误: 备份失败（mysqldump/gzip 报错见上方 stderr），已删除残缺文件" >&2
    rm -f "$BACKUP_FILE"
    exit 1
fi

echo "[$(now)] 备份完成: $(du -h "$BACKUP_FILE" | cut -f1)"

find "$BACKUP_DIR" -name "backup_*.sql.gz" -type f -mtime +"$KEEP_DAYS" -delete 2>/dev/null || true
echo "[$(now)] 已清理 ${KEEP_DAYS} 天前的备份"
