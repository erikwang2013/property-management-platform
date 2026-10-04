#!/usr/bin/env bash
# ============================================================
# fresh 库总复验（⑤）：全新库导入 install.sql → 两端全量套件 → 三项 e2e → 安装向导建号 → 真登录
# Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
# ============================================================
# 关键约束（踩过的坑，必须遵守）：
#   **PHPUnit 进程读的库必须与 8787/8788 实例读的库是同一个。**
#   否则 OpenApiTest 的 4 个 HTTP 探测用例会假红（测试把 ApiKey 写进 A 库，
#   8788 实例从 B 库校验 → 401，看起来像代码缺陷）。
#   手法：两个 .env 一起切到 fresh 库 + 重启两个实例，跑完由 trap 还原并重启回原库。
#
# 用法：bash scripts/verify-fresh-db.sh          （VERIFY_DB 可覆盖，默认 management_fresh）
#       STOP_AFTER=1 bash scripts/verify-fresh-db.sh   → 只跑到 ①（建库+不变量），不切库不重启
# 副作用（全部在 trap 里还原）：service/.env、admin/.env、admin/public/.installed、两个实例重启
# .installed 终态：**不保留**（本机库从未走向导安装；删除=向导保持可用，保留=锁死 /install）
# 依赖：docker 容器 pmp-mysql(3307)、redis(6379)、端口 8787/8788
set -uo pipefail

ROOT=/home/wwwroot/property-management-platform
VERIFY_DB=${VERIFY_DB:-management_fresh}
# 验证用一次性口令：当场随机生成，不落库也不入库（V/O 前缀 + 大小写 + 数字 + @ 满足强度规则）
ADMIN_PW="V$(openssl rand -hex 6)Aa1@"
OWNER_PW="O$(openssl rand -hex 6)aA1@"
TS=$(date +%Y%m%d-%H%M%S)
LOG=${LOG:-/tmp/pmp-verify-$TS}
BKDIR=$LOG/backup
mkdir -p "$BKDIR" "$LOG"
SERVICE_ENV="$ROOT/service/.env"
ADMIN_ENV="$ROOT/admin/.env"
LOCK="$ROOT/admin/public/.installed"
FAILED=()
DEFECTS=()   # 已知缺陷：不影响本次复验成败，但要如实列出（不混进 FAILED）

say()  { printf '\n== %s ==\n' "$*"; }
ok()   { printf '  [OK] %s\n' "$*"; }
bad()  { printf '  [!!] %s\n' "$*"; FAILED+=("$*"); }
warn() { printf '  [~~] %s\n' "$*"; DEFECTS+=("$*"); }

# ---------- 凭据：只从 .env 读，绝不打印（不 source：.env 值含特殊字符会炸） ----------
env_get() { sed -n "s/^$1=//p" "$2" | head -1 | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//"; }
DB_USERNAME=$(env_get DB_USERNAME "$SERVICE_ENV")
DB_PASSWORD=$(env_get DB_PASSWORD "$SERVICE_ENV")
mysql_q() { docker exec -i pmp-mysql mysql -h127.0.0.1 -u"$DB_USERNAME" -p"$DB_PASSWORD" -N -B -e "$1" "${2:-$VERIFY_DB}" 2>&1 | grep -v 'Using a password'; }

# 全新库不变量：① 用 install.sql 独立导入后、④ 用向导导入后各校验一次（同一套判据，别写两份）
fresh_invariants() { # $1=标签
    local tag=$1 T M P G slug U
    T=$(mysql_q "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$VERIFY_DB'")
    [ "$T" = "67" ] && ok "$tag：表数 67" || bad "$tag：表数 $T（期望 67）"
    # 唯一索引：无 uk_slug 时 INSERT IGNORE 挡不住「同 slug 不同 id」的重复权限行（2026-10-04 撞过）
    U=$(mysql_q "SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema='$VERIFY_DB' AND table_name='management_admin_permission' AND index_name='uk_slug' AND non_unique=0")
    [ "$U" = "1" ] && ok "$tag：permission.slug 唯一索引 uk_slug 存在" || bad "$tag：permission.slug 缺唯一索引（uk_slug=$U）"
    M=$(mysql_q "SELECT COUNT(*) FROM information_schema.tables t WHERE t.table_schema='$VERIFY_DB'
          AND t.table_name IN (SELECT table_name FROM information_schema.columns WHERE table_schema='$VERIFY_DB' AND column_name='created_at')
          AND t.table_name NOT IN (SELECT table_name FROM information_schema.columns WHERE table_schema='$VERIFY_DB' AND column_name='updated_at')")
    [ "$M" = "0" ] && ok "$tag：有 created_at 缺 updated_at 的表 0" || bad "$tag：仍缺 updated_at 的表 $M"
    # 权限种子：路由+文档存在但缺 slug 时任何角色（含超管）一律 403，故逐条校验种子与超管授权
    for slug in 'get.admin/report' 'post.admin/export/property-excel' \
                'post.admin/payment-order/create' 'post.admin/payment-order/reconcile' 'get.admin/profile'; do
        P=$(mysql_q "SELECT COUNT(*) FROM management_admin_permission WHERE slug='$slug'")
        G=$(mysql_q "SELECT COUNT(*) FROM management_admin_role_permission rp JOIN management_admin_permission p ON p.id=rp.permission_id WHERE rp.role_id=10000000000000001 AND p.slug='$slug'")
        { [ "$P" = "1" ] && [ "$G" = "1" ]; } && ok "$tag：$slug 种子 + 超管授权齐备" || bad "$tag：权限种子缺失（$slug permission=$P grant=$G）"
    done
}
fresh_drop_create() { docker exec -i pmp-mysql mysql -h127.0.0.1 -u"$DB_USERNAME" -p"$DB_PASSWORD" \
    -e "DROP DATABASE IF EXISTS \`$VERIFY_DB\`; CREATE DATABASE \`$VERIFY_DB\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>&1 | grep -v 'Using a password'; }

# ---------- 实例重启 ----------
# 选 master 只认 args 首个词是 "WorkerMan:" 且第二词是 "master" 的行（ps 按空白切列 → $2/$3）。
# 坑：别的进程（如他人的 `bash -c ...` 外壳）命令行文本里也可能含 "master process" 字样，
# 用整行 index($0,'master process') 匹配会杀错对象 —— 真 master 没被杀掉，实例仍读旧库，
# 而健康检查照旧 200，脚本会误报「已起」且后续步骤全部对着旧库跑（曾把 04:29 的实例误判）。
pid_of_master() { # $1=dir
    ps -eo pid=,args= | awk -v d="$1/start.php" '$2=="WorkerMan:" && $3=="master" && index($0,d){print $1; exit}'
}
restart_inst() { # $1=dir $2=port $3=tag
    local dir=$1 port=$2 tag=$3 pid newpid gone=0
    pid=$(pid_of_master "$dir")
    [ -z "$pid" ] && { bad "$tag 未找到 master 进程（$dir）"; return 1; }
    kill -TERM "$pid" 2>/dev/null
    for _ in $(seq 1 40); do kill -0 "$pid" 2>/dev/null || { gone=1; break; }; sleep 0.5; done
    [ "$gone" -eq 1 ] || { bad "$tag 旧 master($pid) 未退出，放弃重启（避免双实例抢端口）"; return 1; }
    # 真脱离（踩过的坑）：① 子 shell 自身的 stdout/stderr 必须一并重定向掉——否则它继承调用方的 fd1，
    #   调用方若是 `script | tee`，这个空转壳会把管道一直撑开，脚本早已跑完、调用方却永远等不到 EOF
    #   （实测卡满 600s 超时；对照实验：旧写法 6007ms 才关管，本写法 6ms）；② setsid -f 让 master 进
    #   新会话，不再挂在脚本进程树里（否则 ps 里是一串空转壳抱着 master）。判定条件不变：新 master + health ok。
    ( cd "$dir" && setsid -f nohup php start.php start > "$LOG/$tag.out" 2>&1 < /dev/null ) >/dev/null 2>&1 &
    for _ in $(seq 1 60); do
        newpid=$(pid_of_master "$dir")
        # 必须是「新的 master + health ok」：只看 health 会被尚未退出的旧实例骗过
        if [ -n "$newpid" ] && [ "$newpid" != "$pid" ] && curl -s --max-time 2 "http://localhost:$port/health" | grep -q 'ok'; then
            ok "$tag :$port 已起（master $pid → $newpid）"; return 0
        fi
        sleep 0.5
    done
    bad "$tag :$port 起不来（看 $LOG/$tag.out）"; return 1
}

SWAPPED=0
SWAP_ADMIN_MD5=""; SWAP_SERVICE_MD5=""
LOCK_EXISTED=0; [ -f "$LOCK" ] && LOCK_EXISTED=1
# 还原 .env 前先比对「本轮自己最后一次写入的 md5」与当前值：不一致说明复验期间有第三方改过
# （本机曾发生：另一 agent 复验中把 admin/.env 切到别的库）——此时跳过还原，避免覆盖别人的改动
restore_env_file() { # $1=目标 .env $2=备份 $3=本轮最后写入的 md5 $4=显示名
    local cur; cur=$(md5sum "$1" | cut -d' ' -f1)
    if [ "$cur" != "$3" ]; then
        warn "$4 本轮被第三方改动（我最后写入 ${3:0:8}，当前 ${cur:0:8}）——不还原以免覆盖别人的改动，请人工确认后再动"
    else
        cp -p "$2" "$1"; ok "$4 已还原"
    fi
}
restore() {
    say "还原环境"
    restore_env_file "$SERVICE_ENV" "$BKDIR/service.env" "$SWAP_SERVICE_MD5" "service/.env"
    restore_env_file "$ADMIN_ENV"   "$BKDIR/admin.env"   "$SWAP_ADMIN_MD5"   "admin/.env"
    [ "$LOCK_EXISTED" -eq 0 ] && rm -f "$LOCK"
    ok ".installed $( [ "$LOCK_EXISTED" -eq 0 ] && echo '确保不存在（原本也不存在）' || echo '保留（原本就有）' )"
    if [ "$SWAPPED" -eq 1 ]; then
        restart_inst "$ROOT/service" 8788 service
        restart_inst "$ROOT/admin"   8787 admin
    fi
}
trap restore EXIT INT TERM

cp -p "$SERVICE_ENV" "$BKDIR/service.env"
cp -p "$ADMIN_ENV"   "$BKDIR/admin.env"
# 记下「本轮拥有的 .env 状态」：未切库时即备份时刻，切库后由 ② 覆盖重记（trap 用它判第三方改动）
SWAP_SERVICE_MD5=$(md5sum "$SERVICE_ENV" | cut -d' ' -f1)
SWAP_ADMIN_MD5=$(md5sum "$ADMIN_ENV" | cut -d' ' -f1)
ok "已备份 .env 到 $BKDIR"

# ============================================================
say "① 全新库 $VERIFY_DB：导入 docs/install.sql"
# ============================================================
fresh_drop_create
docker exec -i pmp-mysql mysql -h127.0.0.1 -u"$DB_USERNAME" -p"$DB_PASSWORD" "$VERIFY_DB" < "$ROOT/docs/install.sql" 2>&1 | grep -v 'Using a password'

fresh_invariants "install.sql 独立导入"

if [ "${STOP_AFTER:-}" = "1" ]; then
    say "STOP_AFTER=1：停在 ① 后（未切库、未重启）"
    [ ${#FAILED[@]} -eq 0 ] || exit 1
    exit 0
fi

# ============================================================
say "② 切库并重启两端实例（同一 .env，保证测试库 = 实例库）"
# ============================================================
sed -i "s/^DB_DATABASE=.*/DB_DATABASE=$VERIFY_DB/; s/dbname=[^;]*/dbname=$VERIFY_DB/" "$SERVICE_ENV"
sed -i "s/^DB_DATABASE=.*/DB_DATABASE=$VERIFY_DB/" "$ADMIN_ENV"
SWAP_SERVICE_MD5=$(md5sum "$SERVICE_ENV" | cut -d' ' -f1)   # 供 trap 判断「是否被第三方改过」
SWAP_ADMIN_MD5=$(md5sum "$ADMIN_ENV" | cut -d' ' -f1)
SWAPPED=1
restart_inst "$ROOT/service" 8788 service
restart_inst "$ROOT/admin"   8787 admin

# ============================================================
say "③ 两端全量套件"
# ============================================================
( cd "$ROOT/service" && php vendor/bin/phpunit --no-coverage > "$LOG/service-suite.log" 2>&1 ); rc_s=$?
( cd "$ROOT/admin"   && php vendor/bin/phpunit --no-coverage > "$LOG/admin-suite.log"   2>&1 ); rc_a=$?
# phpunit 输出带 ANSI 色码（非 tty 也上色），断言前先剥掉，否则 ^Tests: 匹配不上
for t in service:$rc_s admin:$rc_a; do
    name=${t%%:*}; rc=${t##*:}
    line=$(sed -e 's/\x1b\[[0-9;]*m//g' "$LOG/$name-suite.log" | grep -E '^(OK|Tests:|FAILURES)' | tail -1)
    [ "$rc" -eq 0 ] && [ -n "$line" ] && ok "$name 套件：$line" \
        || bad "$name 套件失败（rc=$rc）：$line（$LOG/$name-suite.log）"
done

# ============================================================
say "④ e2e：安装向导建号 → 真登录 → /admin/report 不再 403"
# ============================================================
B=http://127.0.0.1:8787
INSTALL="$B/install"          # 路由在根路径（route.php:316/317），不是 /admin/install
curl -s -o "$LOG/install-step2.html" -X POST "$INSTALL" \
    --data-urlencode "_step=2" --data-urlencode "host=127.0.0.1" --data-urlencode "port=3307" \
    --data-urlencode "database=$VERIFY_DB" --data-urlencode "username=$DB_USERNAME" --data-urlencode "password=$DB_PASSWORD"
grep -q 'name="admin_username"' "$LOG/install-step2.html" \
    && ok "向导 step1→step2 校验通过（DB 连接 OK）" || bad "向导未进入 step2（$LOG/install-step2.html）"

# 4a. 清空库，让**向导自己做第一次导入** —— 这才是产品真实的全新安装路径。
#     若先由 ① 灌过 install.sql、再让向导灌第二遍，重复索引/种子会报几十条错，
#     而 importSql 一旦有失败就在 createAdminUser 之前中止（InstallController.php:174-179）：
#     那时 4a/4b 红的是「重复导入」而非「向导装不出正确的库」，掩盖真问题。
fresh_drop_create
ok "已清空 $VERIFY_DB（交由向导导入）"
# 字段集与修好后的 step3.html 一致（含 admin_password_confirm）；手工拼 body 必须自己 urlencode
UI_PW=$(php -r 'echo urlencode($argv[1]);' "$ADMIN_PW")
DB_U=$(php -r 'echo urlencode($argv[1]);' "$DB_USERNAME")
DB_P=$(php -r 'echo urlencode($argv[1]);' "$DB_PASSWORD")
UI_FORM="_step=3&_confirm=1&host=127.0.0.1&port=3307&database=$VERIFY_DB&db_username=$DB_U&db_password=$DB_P&admin_username=verifyadmin"
curl -s -o "$LOG/install-ui.html" -X POST "$INSTALL" -d "$UI_FORM&admin_password=$UI_PW&admin_password_confirm=$UI_PW"
if grep -q '密码不一致' "$LOG/install-ui.html"; then
    bad "向导回归：step3 确认页与 InstallValidator 的 confirm 校验又不一致了（$LOG/install-ui.html）"
else
    ok "向导确认页字段集校验通过（不再报密码不一致）"
fi
[ -f "$LOCK" ] && ok "向导写入 .installed" || bad "向导未写 .installed（看 $LOG/install-ui.html）"
U=$(mysql_q "SELECT COUNT(*) FROM management_admin_user WHERE username='verifyadmin'")
[ "$U" = "1" ] && ok "向导建号成功（verifyadmin）" || bad "向导建号失败（admin_user=$U）"
fresh_invariants "向导导入"      # 向导装出来的库必须与 install.sql 独立导入等价

# 4b. 重复导入路径（信息项，不是本次复验的阻断判据）：删掉 .installed 再把已灌过的库灌一遍，
#     如实记录真实报错数（backend-dev 正在把 1061/1050/1060 降级为 skip+汇总）
rm -f "$LOCK"
curl -s -o "$LOG/install-dup.html" -X POST "$INSTALL" -d "$UI_FORM&admin_password=$UI_PW&admin_password_confirm=$UI_PW"
dup_msg=$(sed -e 's/\x1b\[[0-9;]*m//g' "$LOG/install-dup.html" | grep -o '[0-9]*/[0-9]* 条语句执行失败[^<]*' | head -1)
if [ -f "$LOCK" ]; then ok "重装向导：重复导入被容忍，安装可完成"
elif [ -n "$dup_msg" ]; then warn "重装向导：$dup_msg（product 行为记录，见 $LOG/install-dup.html）"
else warn "重装向导：未写 .installed 且未匹配到失败计数，人工看 $LOG/install-dup.html"
fi
# .installed 终态（lead 授权我定）：**不保留**。
# 理由：本机基准库 management 从未走向导安装，⑤ 结束应把机器还原成进来时的样子——
# 删除=向导保持可用（后续还能再验 fresh 安装），保留=会把 /install 锁死且改变实例的「已安装」语义。
# trap 亦按同一规则（进来时不存在就删），两边一致。
rm -f "$LOCK"
ok ".installed 终态：不保留（/install 仍可用，与 ⑤ 前状态一致）"
# 向导按设计会重写 admin/.env（InstallController 生成：补齐 PAYMENT_ENVIRONMENT 等键），
# 这里必须重记「本轮拥有的」md5 —— 否则 trap 会把自家向导的写入误判成第三方改动而拒绝还原，
# 把 admin/.env 留在 fresh 库上（2026-10-04 实测：⑤ 跑完 admin 实例指向了 management_fresh）。
SWAP_ADMIN_MD5=$(md5sum "$ADMIN_ENV" | cut -d' ' -f1)

# 点选验证码：答案在 Redis poster:captcha:<key>，按 order 取坐标 —— 不必解图
cat > "$LOG/login.php" <<'PHP'
<?php
// 用法: php login.php <base_url> <admin|owner> <account> <password> → 打印 access_token
// 响应字段是 data.access_token（不是 data.token），admin 传 username、service 传 phone
[$_, $base, $mode, $account, $password] = $argv;
function http(string $url, ?array $json = null): array {
    $ctx = stream_context_create(['http' => [
        'method' => $json === null ? 'GET' : 'POST',
        'header' => "Content-Type: application/json\r\n",
        'content' => $json === null ? '' : json_encode($json),
        'ignore_errors' => true, 'timeout' => 10,
    ]]);
    $body = @file_get_contents($url, false, $ctx);
    preg_match('#HTTP/\S+ (\d+)#', $http_response_header[0] ?? '', $m);
    return [(int) ($m[1] ?? 0), json_decode((string) $body, true)];
}
[$_, $gen] = http("$base/api/v1/captcha/generate", ['difficulty' => 'medium']);
$key = $gen['data']['key'] ?? '';
$r = new Redis();
$r->connect(getenv('REDIS_HOST') ?: '127.0.0.1', (int) (getenv('REDIS_PORT') ?: 6379));
$payload = json_decode((string) $r->get('poster:captcha:' . $key), true);
$targets = $payload['data']['targets'] ?? [];
usort($targets, fn($a, $b) => $a['order'] <=> $b['order']);
$clicks = array_map(fn($t) => [$t['x'], $t['y']], $targets);
$field = $mode === 'owner' ? 'phone' : 'username';
[$code, $res] = http("$base/api/v1/auth/login", [
    $field => $account, 'password' => $password, 'captcha_key' => $key, 'clicks' => $clicks,
]);
$token = $res['data']['access_token'] ?? '';
fwrite(STDERR, "login($mode) HTTP $code token=" . ($token ? 'yes' : 'no') . ' msg=' . ($res['message'] ?? '') . "\n");
echo $token;
PHP
TOKEN=$(php "$LOG/login.php" "$B" admin verifyadmin "$ADMIN_PW" 2> "$LOG/login.err")
if [ -z "$TOKEN" ]; then bad "向导建号后真登录失败（$(cat "$LOG/login.err")）"; else
    ok "真登录成功（$(cat "$LOG/login.err")）"
    # 报表中心：install.sql 缺 get.admin/report 种子时超管也 403（本轮修复点）
    C=$(curl -s -o "$LOG/resp-report.json" -w '%{http_code}' -H "Authorization: Bearer $TOKEN" "$B/admin/report")
    [ "$C" = "200" ] && ok "GET /admin/report → 200（不再 403）" \
        || bad "GET /admin/report → $C（$(head -c 200 "$LOG/resp-report.json")）"
    # 物业数据导出：slug post.admin/export/property-excel 缺失时超管同样 403（本轮补种）
    C=$(curl -s -o "$LOG/resp-property-excel.xlsx" -w '%{http_code}' -X POST "$B/admin/export/property-excel" \
        -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d '{"type":"owners"}')
    [ "$C" = "200" ] && ok "POST /admin/export/property-excel → 200（权限种子生效）" \
        || bad "POST /admin/export/property-excel → $C（$(head -c 200 "$LOG/resp-property-excel.xlsx")）"
fi

# 派单链路（hashid）：建房 → 建单 → assign → 无效 hashid 应 422
cat > "$LOG/fixture.php" <<'PHP'
<?php
// 用法: php fixture.php → 打印 JSON: {room_id, staff_id, bill_id}
// 注意字段名按 install.sql DDL：unit 无 community_id；staff 无 type，是 department(3=工程)
// bill_id 不落库，只用于超管可达探针（合法 hashid、非零，走到业务校验即 422）
require '/home/wwwroot/property-management-platform/admin/tests/bootstrap.php';
use app\common\SnowflakeService as SF;
use app\common\HashidsService;
use app\model\Community, app\model\Building, app\model\Unit, app\model\Room, app\model\Staff;
$cid = SF::generate(); Community::create(['id'=>$cid,'name'=>'复验小区','status'=>1]);
$bid = SF::generate(); Building::create(['id'=>$bid,'community_id'=>$cid,'name'=>'1号楼']);
$uid = SF::generate(); Unit::create(['id'=>$uid,'building_id'=>$bid,'name'=>'1单元']);
$rid = SF::generate(); Room::create(['id'=>$rid,'community_id'=>$cid,'building_id'=>$bid,'unit_id'=>$uid,'room_number'=>'101','area_total'=>'88.50','status'=>3]);
$sid = SF::generate(); Staff::create(['id'=>$sid,'community_id'=>$cid,'name'=>'复验维修工','phone'=>'13800000001','department'=>3,'status'=>1]);
echo json_encode(['room_id'=>HashidsService::encode($rid), 'staff_id'=>HashidsService::encode($sid), 'bill_id'=>HashidsService::encode(SF::generate())]);
PHP
FIX=$(php "$LOG/fixture.php" 2> "$LOG/fixture.err")
echo "$FIX" | grep -q room_id && ok "夹具（小区/楼栋/单元/房产/员工）就绪" || bad "夹具失败（$(cat "$LOG/fixture.err" | tail -2)）"

if [ -n "$TOKEN" ] && [ -n "$FIX" ]; then
    ROOM=$(echo "$FIX" | php -r '$d=json_decode(file_get_contents("php://stdin"),true);echo $d["room_id"];')
    STAFF=$(echo "$FIX" | php -r '$d=json_decode(file_get_contents("php://stdin"),true);echo $d["staff_id"];')
    BILL=$(echo "$FIX" | php -r '$d=json_decode(file_get_contents("php://stdin"),true);echo $d["bill_id"];')
    NEW=$(curl -s -X POST "$B/admin/repair" -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
        -d "{\"room_id\":\"$ROOM\",\"contact_phone\":\"13800000002\",\"category\":1,\"description\":\"复验派单\"}")
    RID=$(echo "$NEW" | php -r '$d=json_decode(file_get_contents("php://stdin"),true);echo $d["data"]["id"] ?? "";')
    [ -n "$RID" ] && ok "建报修单 → $RID" || bad "建报修单失败：$NEW"
    # 分页：page_size 必须被 honor，且新单能被计入（LengthAwarePaginator 序列化为 data.{data,total,per_page}）
    C=$(curl -s -o "$LOG/resp-repair.json" -w '%{http_code}' -H "Authorization: Bearer $TOKEN" "$B/admin/repair?page=1&page_size=5")
    read -r TOT PER ROWS < <(php -r '$d=json_decode(file_get_contents($argv[1]),true)["data"]??[];
        echo ($d["total"]??"-")," ",($d["per_page"]??"-")," ",count($d["data"]??[]);' "$LOG/resp-repair.json")
    { [ "$C" = "200" ] && [ "$TOT" = "1" ] && [ "$PER" = "5" ] && [ "$ROWS" = "1" ]; } \
        && ok "GET /admin/repair?page=1&page_size=5 → 200，total=1 per_page=5 rows=1" \
        || bad "分页异常：HTTP=$C total=$TOT per_page=$PER rows=$ROWS（$LOG/resp-repair.json）"
    A=$(curl -s -o "$LOG/assign.json" -w '%{http_code}' -X PUT "$B/admin/repair/$RID/assign" -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d "{\"staff_id\":\"$STAFF\"}")
    [ "$A" = "200" ] && ok "派单（hashid）→ 200" || bad "派单 → $A（$(cat "$LOG/assign.json")）"
    # 仓约定：错误响应是「HTTP 200 + body.code」，decodeId 的 422（InvalidResourceIdException）亦然；
    # 断言裸 HTTP 状态码会永远红（实测 HTTP 200），必须解 body。
    bad_http=$(curl -s -o "$LOG/bad-hashid.json" -w '%{http_code}' -X PUT "$B/admin/repair/$RID/assign" -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d '{"staff_id":"not-a-hashid"}')
    bad_code=$(php -r '$d=json_decode(file_get_contents($argv[1]),true);echo is_array($d)?($d["code"]??"-"):"-";' "$LOG/bad-hashid.json")
    { [ "$bad_http" = "200" ] && [ "$bad_code" = "422" ]; } \
        && ok "无效 hashid → HTTP 200 + body.code 422（InvalidResourceIdException）" \
        || bad "无效 hashid → HTTP $bad_http code=$bad_code（期望 200 + 422；$LOG/bad-hashid.json）"

    # 带参数段端点超管可达抽查（14 条同类端点挑 5 条代表）
    # 判据：AdminPermission 的 403 是「HTTP 外层 200 + body.code=403」；5xx 记 warn（RBAC 已放行但接口异常）。
    # 前 3 条依赖中间件剥 {…} 段后命中既有种子；后 2 条是本轮新补的精确 slug 种子。
    probe() { # $1=METHOD $2=路径 $3=body(可空；注意 set -u：必须 ${3:-} 取默认)
        local out="$LOG/probe-$(printf '%s' "$1$2" | tr -c 'A-Za-z0-9' '_').json" c code body=${3:-}
        if [ -n "$body" ]; then
            c=$(curl -s -o "$out" -w '%{http_code}' -X "$1" "$B$2" -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d "$body")
        else
            c=$(curl -s -o "$out" -w '%{http_code}' -X "$1" "$B$2" -H "Authorization: Bearer $TOKEN")
        fi
        code=$(php -r '$d=json_decode(file_get_contents($argv[1]),true);echo is_array($d)?($d["code"]??"-"):"-";' "$out" 2>/dev/null)
        if [ "${c:0:1}" = "5" ]; then warn "超管 $1 $2 → HTTP $c code=$code（5xx：RBAC 已放行但接口异常）"
        elif [ "$code" = "403" ]; then bad "超管 $1 $2 → 403（RBAC 未放行）"
        else ok "超管 $1 $2 → HTTP $c code=$code"
        fi
    }
    probe PUT  "/admin/complaint/$ROOM/handle"  '{"handle_result":"复验"}'
    probe PUT  "/admin/visitor/$ROOM/approve"   '{}'
    probe PUT  "/admin/face/$ROOM/verify"       '{}'
    # 新种子的 POST 代表用 create：给合法 bill_id+user_id 但缺 channel，在进 service 前即 422（零副作用）。
    # 注意不能传空参：bill_id 缺失时 HashidsService::decode('') 抛异常 → 500（空参应 422 是既有小缺陷，已单独报 lead）
    probe POST "/admin/payment-order/create"    "{\"bill_id\":\"$BILL\",\"user_id\":1}"
    probe GET  "/admin/profile"
fi

# ============================================================
say "⑤ e2e：业主真登录（service，fresh 库）"
# ============================================================
cat > "$LOG/owner-fixture.php" <<'PHP'
<?php
// 用法: php owner-fixture.php <password> → 打印手机号
// 全新库无任何业主 → 直接造一个
// phone 是 encryptable（随机 IV）：明文 WHERE 匹配不到，所以不做查重，固定只跑一次
require '/home/wwwroot/property-management-platform/service/tests/bootstrap.php';
$o = new app\model\Owner();
$o->id = app\common\SnowflakeService::generate();
$o->name = '复验业主';
$o->phone = '13900000001';
$o->password = password_hash($argv[1], PASSWORD_BCRYPT);
$o->status = 1;
$o->save();
echo $o->phone;
PHP
PHONE=$(php "$LOG/owner-fixture.php" "$OWNER_PW" 2> "$LOG/owner.err")
if [ -z "$PHONE" ]; then bad "业主夹具失败（$(tail -2 "$LOG/owner.err")）"; else
    ok "业主夹具就绪（$PHONE）"
    OT=$(php "$LOG/login.php" http://127.0.0.1:8788 owner "$PHONE" "$OWNER_PW" 2> "$LOG/owner-login.err")
    [ -n "$OT" ] && ok "业主真登录成功（$(cat "$LOG/owner-login.err")）" || bad "业主登录失败（$(cat "$LOG/owner-login.err")）"
fi

# ============================================================
say "汇总"
if [ ${#FAILED[@]} -eq 0 ]; then
    echo "  全部通过。日志：$LOG"
else
    printf '  未通过 %d 项：\n' "${#FAILED[@]}"
    printf '   - %s\n' "${FAILED[@]}"
    echo "  日志：$LOG"
fi
if [ ${#DEFECTS[@]} -gt 0 ]; then
    printf '  已知缺陷 %d 项（不算复验失败）：\n' "${#DEFECTS[@]}"
    printf '   - %s\n' "${DEFECTS[@]}"
fi
# 退出码必须反映结论：否则「有失败也 exit 0」，链式调用/CI 里会被当成绿
[ ${#FAILED[@]} -eq 0 ] || exit 1
