#!/usr/bin/env bash
# 安装向导 + 首页 E2E 编排
#   1. broken 模式：当前 git 状态（模板位于 app/view/install/）→ 记录 500 缺陷
#   2. index-page：/ 与 /health 断言（与模板位置无关）
#   3. fixed 模式：临时把模板移动到 app/admin/view/install/（webman 实际解析路径），
#      重启服务后完整跑通向导 4 页并截图，随后还原模板与代码并重启服务
# 说明：向导"确认安装"(_confirm=1) 会改写 .env / 导入 install.sql / 创建 .installed，
#      按约束禁测；installed 页通过临时创建 public/.installed 验证并立即删除。
# Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
set -u
cd "$(dirname "$0")"
ADMIN=../../admin
BASE_URL=http://127.0.0.1:8787
export E2E_BASE=$BASE_URL

run() { node "$1"; }

restart() {
  (cd "$ADMIN" && php start.php stop >/dev/null 2>&1)
  sleep 2
  nohup php "$ADMIN/start.php" start >/tmp/webman-e2e.log 2>&1 &
  sleep 5
  curl -s -o /dev/null -w "server-check /health: %{http_code}\n" "$BASE_URL/health"
}

echo "========== Phase 1: broken（当前 git 状态，预期暴露 500 缺陷）=========="
E2E_MODE=broken run wizard-e2e.js || true

echo "========== Phase 2: 首页 / 健康检查（与模板位置无关）=========="
run index-page.js || true

echo "========== Phase 3: fixed（临时修复模板路径后完整验证向导）=========="
mv "$ADMIN/app/view/install" "$ADMIN/app/admin/view/install"
restart
E2E_MODE=fixed run wizard-e2e.js || true

# installed 页验证：临时创建锁定文件，验证后立即删除
echo "---------- installed 页（临时 .installed 锁） ----------"
touch "$ADMIN/public/.installed"
restart
node installed-page.js || true
rm -f "$ADMIN/public/.installed"
restart
echo "lock removed, /install status: $(curl -s -o /dev/null -w '%{http_code}' $BASE_URL/install)"

echo "========== Phase 4: 还原模板位置并重启，恢复原状 =========="
mv "$ADMIN/app/admin/view/install" "$ADMIN/app/view/install"
restart
echo "restored /install status: $(curl -s -o /dev/null -w '%{http_code}' $BASE_URL/install)"
echo "全部阶段完成，截图见 scripts/e2e/screenshots/"
