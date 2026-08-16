#!/usr/bin/env bash
# ============================================================
# encryptable 数据库加密密钥轮换脚本
# Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
#
# 用法: bash scripts/rotate_keys.sh [.env 路径, 默认 ./.env]
#
# 流程: 备份 .env → 生成新 ENCRYPTABLE_KEY → 旧 key 自动追加到
#       ENCRYPTION_PREVIOUS_KEYS（逗号分隔）→ 写入新 key
# 注意: 不做数据迁移。轮换后旧数据仍以旧 key 加密，由 previous_keys
#       列表负责解密；确认解密正常后如需重加密，另行跑数据迁移任务。
# ============================================================

set -euo pipefail

ENV_FILE="${1:-.env}"

[ -f "$ENV_FILE" ] || { echo "错误: 文件不存在 — $ENV_FILE"; exit 1; }

OLD_KEY=$(grep -E '^ENCRYPTABLE_KEY=' "$ENV_FILE" | head -1 | cut -d= -f2-)
if [ -z "$OLD_KEY" ]; then
    echo "错误: $ENV_FILE 中未找到 ENCRYPTABLE_KEY"
    exit 1
fi
if [[ $OLD_KEY == change-me* ]]; then
    echo "错误: ENCRYPTABLE_KEY 仍是占位符，请先运行 scripts/gen_env_keys.php 生成真实密钥"
    exit 1
fi

PREV=$(grep -E '^ENCRYPTION_PREVIOUS_KEYS=' "$ENV_FILE" | head -1 | cut -d= -f2- || true)
if [[ ",$PREV," == *",$OLD_KEY,"* ]]; then
    echo "错误: ENCRYPTION_PREVIOUS_KEYS 已包含当前密钥，疑似重复轮换"
    exit 1
fi

echo "=========================================="
echo "  encryptable 密钥轮换"
echo "  当前 ENCRYPTABLE_KEY: ${OLD_KEY:0:8}…"
echo "  历史密钥列表: ${PREV:-（空）}"
echo "=========================================="
read -rp "确认轮换？将修改 $ENV_FILE（自动备份）[y/N] " confirm
if [ "${confirm,,}" != "y" ]; then
    echo "已取消"
    exit 0
fi

TS=$(date +%Y%m%d_%H%M%S)
cp "$ENV_FILE" "${ENV_FILE}.bak.${TS}"
echo "[$(date)] 已备份: ${ENV_FILE}.bak.${TS}"

NEW_KEY=$(php -r 'echo bin2hex(random_bytes(16));')
if [ ${#NEW_KEY} -ne 32 ]; then
    echo "错误: 新密钥生成失败"
    exit 1
fi

# 旧 key 追加到历史密钥列表（逗号分隔，最近轮换的排最前）
if grep -qE '^ENCRYPTION_PREVIOUS_KEYS=' "$ENV_FILE"; then
    sed -i "s|^ENCRYPTION_PREVIOUS_KEYS=.*|ENCRYPTION_PREVIOUS_KEYS=${OLD_KEY}${PREV:+,$PREV}|" "$ENV_FILE"
else
    echo "ENCRYPTION_PREVIOUS_KEYS=$OLD_KEY" >> "$ENV_FILE"
fi

sed -i "s|^ENCRYPTABLE_KEY=.*|ENCRYPTABLE_KEY=$NEW_KEY|" "$ENV_FILE"

echo "[$(date)] 轮换完成: ENCRYPTABLE_KEY 已更新为 ${NEW_KEY:0:8}…"
echo ""
echo "接下来手动执行:"
echo "  1. 重启服务（service 端: cd service && php start.php restart；admin 端同理）"
echo "  2. 验证解密: 查询一条含加密字段的记录，确认值正常、日志无 decrypt 报错"
echo "  3. 确认无误后可删除备份: ${ENV_FILE}.bak.${TS}"
echo "  4. 旧数据仍以旧 key 加密；需重加密时再执行数据迁移任务"
