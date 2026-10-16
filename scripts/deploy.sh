#!/usr/bin/env bash
# ============================================================
# 物业管理系统 — 一键部署脚本 (P6-A)
# Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
# ============================================================
# 用法: bash scripts/deploy.sh
# 流程: git pull → 检查/生成双端 .env（缺失键自动补齐，已有密钥一律保留）
#       → 双端 docker compose up -d（MySQL 首启由 compose initdb 挂载自动导入 install.sql）
#       → 数据库初始化校验 → 创建默认管理员（admin，幂等）→ 监控冒烟验证
# 幂等: 可重复执行；已存在的 .env 不覆盖，已初始化的库不重复导入。
# 出错即停: 任一步骤失败立即退出并打印失败步骤。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ADMIN_DIR="$ROOT/admin"
SERVICE_DIR="$ROOT/service"
SQL_FILE="$ROOT/docs/install.sql"
# 加密密钥：占位符视为未完成部署，硬校验（gen_env_keys.php 仅在新 .env 时替换）
CRYPTO_KEYS=(ENCRYPTION_KEY ENCRYPTABLE_KEY JWT_SECRET_KEY HASHIDS_SALT HASHIDS_ALT_SALT)
# compose 插值必需键：缺失或为空值时 docker compose config 直接报错
COMPOSE_KEYS=(MYSQL_ROOT_PASSWORD REDIS_PASSWORD ELASTIC_PASSWORD GRAFANA_ADMIN_PASSWORD)

CURRENT_STEP="初始化"
trap 'echo "部署失败于步骤: ${CURRENT_STEP}" >&2; exit 1' ERR

step() { CURRENT_STEP="$1"; echo; echo "==> $1"; }
say()  { printf '%-10s %s\n' "$1" "$2"; }

# 读取 .env 中的键值（缺失时返回默认值）
env_value() {
    local dir="$1" key="$2" default="${3:-}"
    local v
    v="$(grep -E "^${key}=" "$dir/.env" | tail -n1 | cut -d= -f2- || true)"
    if [ -n "$v" ]; then printf '%s' "$v"; else printf '%s' "$default"; fi
}

# 检查/生成单端 .env：模板复制 + 密钥补齐 + 必需键/占位符/空值校验
# 旧密钥保留：已存在的真实密钥绝不改写；仅「新生成的 .env」会把 change-me 占位符替换为随机值
prepare_env() {
    local dir="$1" name="$2" fresh=0
    step "$name: 检查 .env"
    if [ ! -f "$dir/.env" ]; then
        cp "$dir/.env.docker" "$dir/.env"
        fresh=1
        say OK "$name: 已从 .env.docker 生成 .env（占位符将自动替换为随机密钥）"
    else
        say OK "$name: .env 已存在，仅补齐缺失键（旧密钥一律保留）"
    fi

    if [ "$fresh" = 1 ]; then
        php "$ROOT/scripts/gen_env_keys.php" --file="$dir/.env" --replace-placeholders
    else
        php "$ROOT/scripts/gen_env_keys.php" --file="$dir/.env"
    fi

    local missing=() k
    for k in "${CRYPTO_KEYS[@]}" "${COMPOSE_KEYS[@]}" DB_HOST DB_PORT DB_DATABASE DB_USERNAME DB_PASSWORD REDIS_HOST REDIS_PORT; do
        grep -qE "^${k}=" "$dir/.env" || missing+=("$k")
    done
    if [ "${#missing[@]}" -gt 0 ]; then
        echo "错误: $name/.env 缺少必需键: ${missing[*]}" >&2
        echo "提示: 删除 .env 后重跑 deploy.sh（将从 .env.docker 重新生成），或手工补齐" >&2
        exit 1
    fi

    # 空值检查：compose 的 ${VAR:?} 对「未设置」与「空值」同样报错
    local empty=()
    for k in "${CRYPTO_KEYS[@]}" "${COMPOSE_KEYS[@]}" DB_PASSWORD; do
        [ -z "$(grep -E "^${k}=" "$dir/.env" | head -1 | cut -d= -f2-)" ] && empty+=("$k")
    done
    if [ "${#empty[@]}" -gt 0 ]; then
        echo "错误: $name/.env 以下必需键为空值: ${empty[*]}" >&2
        echo "提示: 填入随机值后重跑（生成脚本不会改动已存在的非空键，也不会填它认为有意留空的空值）" >&2
        exit 1
    fi

    local bad=()
    for k in "${CRYPTO_KEYS[@]}"; do
        grep -qE "^${k}=change-me" "$dir/.env" && bad+=("$k")
    done
    if [ "${#bad[@]}" -gt 0 ]; then
        echo "错误: $name/.env 加密密钥仍为 change-me 占位符: ${bad[*]}" >&2
        echo "提示: 删除上述键所在行后重跑 deploy.sh（gen_env_keys.php 将生成随机值），或手工替换" >&2
        exit 1
    fi

    grep -qE '^[A-Z0-9_]+=change-me' "$dir/.env" && say WARN "$name: 存在 change-me 占位值（如 ELASTIC_PASSWORD），该键已随部署长期使用，未自动替换；如需更换请同步 ES 容器"
    [ "$(env_value "$dir" DB_HOST)" != "mysql" ] && say WARN "$name: DB_HOST=$(env_value "$dir" DB_HOST)，docker 部署应为 mysql，连接失败请检查"
}

# 数据库初始化：等待 mysql 就绪 → 建库（缺则建）→ 空库时导入 docs/install.sql
init_db() {
    local dir="$1" name="$2"
    step "$name: 数据库初始化检查"
    local db root_pw
    db="$(env_value "$dir" DB_DATABASE management)"
    root_pw="$(env_value "$dir" MYSQL_ROOT_PASSWORD change-me-root-password)"

    local i=0
    until ( cd "$dir" && docker compose exec -T -e "MYSQL_PWD=$root_pw" mysql mysqladmin -uroot ping >/dev/null 2>&1 ); do
        i=$((i + 1))
        [ "$i" -ge 30 ] && { echo "错误: $name mysql 容器 60 秒内未就绪" >&2; exit 1; }
        sleep 2
    done
    say OK "$name: mysql 容器已就绪"

    ( cd "$dir" && docker compose exec -T -e "MYSQL_PWD=$root_pw" mysql mysql -uroot \
        -e "CREATE DATABASE IF NOT EXISTS \`$db\` DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci" )

    local count
    count="$( cd "$dir" && docker compose exec -T -e "MYSQL_PWD=$root_pw" mysql mysql -uroot -N \
        -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$db'" )"
    if [ "${count:-0}" = "0" ]; then
        say INFO "$name: 数据库 $db 为空，导入 docs/install.sql"
        ( cd "$dir" && docker compose exec -T -e "MYSQL_PWD=$root_pw" mysql mysql -uroot "$db" < "$SQL_FILE" )
        say OK "$name: 数据库初始化完成 ($db)"
    else
        say OK "$name: 数据库已初始化，跳过导入 ($db, $count 张表)"
    fi
}

# 默认管理员：install.sql 不含管理员种子（由安装向导建号），一键部署在此补齐
# 文档承诺的默认账号——密码可用 .env 的 ADMIN_INITIAL_PASSWORD 覆盖；已存在则跳过（幂等）
init_default_admin() {
    local dir="$1" pw
    step "admin: 初始化默认管理员"
    pw="$(env_value "$dir" ADMIN_INITIAL_PASSWORD "Admin@123456")"
    if ( cd "$dir" && docker compose exec -T app php /app/scripts/create_admin.php --username=admin --password="$pw" ); then
        say OK "admin: 默认管理员就绪（admin / $pw，见「默认账户」文档；首登后请立即改密）"
    else
        echo "错误: 默认管理员创建失败（密码需满足 8-32 位 + 大小写 + 数字 + 特殊字符 @\$!%*?&）" >&2
        exit 1
    fi
}

docker compose version >/dev/null 2>&1 || { echo "错误: docker compose 插件不可用（需 Compose v2）" >&2; exit 1; }

step "git pull"
git -C "$ROOT" pull --ff-only

prepare_env "$ADMIN_DIR" "admin"
prepare_env "$SERVICE_DIR" "service"

step "admin: docker compose 校验并启动"
( cd "$ADMIN_DIR" && docker compose config -q && docker compose up -d )

step "service: docker compose 校验并启动"
( cd "$SERVICE_DIR" && docker compose config -q && docker compose up -d )

init_db "$ADMIN_DIR" "admin"
init_default_admin "$ADMIN_DIR"
init_db "$SERVICE_DIR" "service"

step "监控冒烟验证 (scripts/verify_monitoring.sh)"
if bash "$ROOT/scripts/verify_monitoring.sh"; then
    say OK "监控冒烟验证通过"
else
    echo "错误: 监控验证存在失败项，请查看上方输出" >&2
    exit 1
fi

echo
echo "部署完成。"
echo "  默认管理员: admin / Admin@123456（除非 .env 设置了 ADMIN_INITIAL_PASSWORD；生产环境请立即修改）"
echo "  监控入口: admin Prometheus :9090 / Grafana :3000；service :9091 / :3001（可用 .env 中 PROMETHEUS_PORT/GRAFANA_PORT 覆盖）"
echo "  注意: 双端 nginx 默认均映射 80/443，同主机部署需通过 .env 的 NGINX_PORT/NGINX_SSL_PORT 错开"
echo "  提醒: 上线后配置数据库备份 cron（bash scripts/backup.sh，详见 docs/OPS_RUNBOOK.md 1.2 与 docs/RECOVERY_RUNBOOK.md）"
