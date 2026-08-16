<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

/**
 * Demo 演示数据脚本（幂等，可重复执行）
 *
 * 用法: cd admin && php ../scripts/demo_data.php
 * 前置: admin/.env 已配置数据库连接且已执行 install.sql
 *
 * 数据范围: 小区/楼栋/单元/户型/房产/业主/租户/费用/账单/公告/演示账号，
 * 覆盖 Lite 核心模块，Standard/Full 模块数据量少、由真实业务录入即可。
 */

declare(strict_types=1);

use app\common\SnowflakeService;
use app\model\AdminUser;
use app\model\Announcement;
use app\model\Building;
use app\model\Community;
use app\model\FeeBill;
use app\model\FeeType;
use app\model\Owner;
use app\model\Room;
use app\model\RoomType;
use app\model\Tenant;
use app\model\Unit;

$baseDir = __DIR__ . '/../admin';

require_once $baseDir . '/vendor/autoload.php';

if (class_exists('Dotenv\Dotenv') && file_exists($baseDir . '/.env')) {
    \Dotenv\Dotenv::createUnsafeMutable($baseDir)->load();
}

\Webman\Config::clear();
support\App::loadAllConfig(['route']);
support\bootstrap\Db::start(null);

// 非自增主键由 snowflake 生成（与控制器写法一致）
// CLI 下 webman 未装配 Eloquent 事件分发器，需手动挂载；
// 模型事件按类名注册，基类上的 creating 监听不生效，故用通配符
use Illuminate\Database\Eloquent\Model;
use Illuminate\Events\Dispatcher;
Model::setEventDispatcher($eloquentEvents = new Dispatcher());
$eloquentEvents->listen('eloquent.creating: *', function (...$args): void {
    $model = ($args[1] ?? null) instanceof Model ? $args[1] : ($args[1][0] ?? null);
    if (!$model instanceof Model || $model->getKey() || $model->incrementing) {
        return;
    }
    $model->setAttribute($model->getKeyName(), SnowflakeService::generate());
});

$stats = [];
$mark = function (string $entity, $model) use (&$stats): void {
    $stats[$entity] = $model->wasRecentlyCreated ? 'created' : 'exists';
};

// ---- 小区 / 楼栋 / 单元 / 户型 ----
$community = Community::firstOrCreate(
    ['name' => '阳光花园'],
    ['address' => '示例市示例区阳光路 1 号', 'province' => '示例省', 'city' => '示例市', 'district' => '示例区',
     'area_total' => 120000, 'building_count' => 2, 'room_count' => 4,
     'developer' => '示例房地产开发有限公司', 'property_company' => '示例物业管理有限公司', 'contact_phone' => '0571-88888888']
);
$mark('community', $community);

$buildings = [];
foreach ([['1号楼', 18, 2], ['2号楼', 24, 3]] as [$name, $floors, $elevators]) {
    $buildings[] = Building::firstOrCreate(
        ['community_id' => $community->id, 'name' => $name],
        ['building_type' => 1, 'floor_count' => $floors, 'unit_count' => 3, 'elevator_count' => $elevators,
         'build_year' => 2020, 'structure_type' => '框架', 'sort' => count($buildings) + 1]
    );
}
$mark('building', $buildings[0]);

$units = [];
foreach ($buildings as $i => $building) {
    foreach (['一单元', '二单元'] as $j => $unitName) {
        $units[] = Unit::firstOrCreate(
            ['building_id' => $building->id, 'name' => $unitName],
            ['room_count_per_floor' => 2, 'sort' => $j + 1]
        );
    }
}
$mark('unit', $units[0]);

$roomType = RoomType::firstOrCreate(
    ['name' => '两室一厅'],
    ['bedrooms' => 2, 'halls' => 1, 'bathrooms' => 1, 'image' => '']
);
$mark('room_type', $roomType);

// ---- 房产 / 业主 / 租户 ----
$rooms = [];
foreach ([['101', 1], ['102', 1], ['201', 2], ['202', 2]] as [$no, $floor]) {
    $rooms[] = Room::firstOrCreate(
        ['community_id' => $community->id, 'room_number' => $no],
        ['building_id' => $buildings[0]->id, 'unit_id' => $units[0]->id, 'floor' => $floor,
         'room_type_id' => $roomType->id, 'area_indoor' => 89.5, 'area_shared' => 12.6,
         'area_total' => 102.1, 'orientation' => '南', 'decoration' => 3, 'usage_type' => 1, 'status' => 1]
    );
}
$mark('room', $rooms[0]);

$owners = [];
foreach ([['张三', '13800000001'], ['李四', '13800000002']] as [$name, $phone]) {
    // phone 字段为加密存储（随机 IV），无法按明文查询，改用 name 作幂等键
    $owners[] = Owner::firstOrCreate(
        ['name' => $name],
        ['name' => $name, 'password' => password_hash('demo123456', PASSWORD_BCRYPT), 'phone' => $phone, 'email' => '',
         'id_card' => '', 'gender' => 1, 'check_in_date' => date('Y-m-d', strtotime('-2 years')),
         'remark' => 'demo', 'status' => 1]
    );
}
$mark('owner', $owners[0]);

// 业主-房产关联（erik_room_owner 中间表，含 snowflake 主键）
$pivot = fn (int $roomId): array => ['id' => SnowflakeService::generate()];
$owners[0]->rooms()->syncWithoutDetaching([$rooms[0]->id => $pivot($rooms[0]->id), $rooms[2]->id => $pivot($rooms[2]->id)]);
$owners[1]->rooms()->syncWithoutDetaching([$rooms[1]->id => $pivot($rooms[1]->id), $rooms[3]->id => $pivot($rooms[3]->id)]);

$tenant = Tenant::firstOrCreate(
    ['room_id' => $rooms[1]->id, 'name' => '王五'],
    ['owner_id' => $owners[1]->id, 'phone' => '13800000003', 'id_card' => '',
     'lease_start' => date('Y-m-d', strtotime('-1 year')), 'lease_end' => date('Y-m-d', strtotime('+1 year')),
     'rent_amount' => 3200, 'status' => 1]
);
$mark('tenant', $tenant);

// ---- 费用 / 账单 / 公告 ----
$feeTypes = [];
foreach ([['物业费', 2.5, 1, 1], ['水费', 4.2, 2, 2]] as [$name, $price, $category, $unitType]) {
    $feeTypes[] = FeeType::firstOrCreate(
        ['name' => $name],
        ['category' => $category, 'unit_price' => $price, 'unit_type' => $unitType, 'cycle_type' => 1, 'is_required' => 1, 'sort' => count($feeTypes) + 1]
    );
}
$mark('fee_type', $feeTypes[0]);

foreach ($rooms as $i => $room) {
    FeeBill::firstOrCreate(
        ['bill_number' => 'DEMO-' . date('Y') . sprintf('%03d', $i + 1)],
        ['room_id' => $room->id, 'owner_id' => $owners[$i % 2]->id, 'fee_type_id' => $feeTypes[0]->id,
         'amount' => 255.25, 'paid_amount' => 0, 'late_fee' => 0,
         'start_date' => date('Y-m-01'), 'end_date' => date('Y-m-t'), 'due_date' => date('Y-m-15')]
    );
}
$mark('fee_bill', FeeBill::first());

// 演示后台账号（仅在无管理员时创建，密码 demo123456）
// 注意: AdminUser 挂载了 scout 观察者，CLI 无 ES 客户端会崩，故用原生 insert
if (AdminUser::query()->count() === 0) {
    \support\Db::table('erik_admin_user')->insert([
        'id' => SnowflakeService::generate(), 'username' => 'admin',
        'password' => password_hash('demo123456', PASSWORD_BCRYPT), 'real_name' => '系统管理员',
        'status' => 1, 'created_at' => date('Y-m-d H:i:s'), 'updated_at' => date('Y-m-d H:i:s'),
    ]);
    $stats['admin_user'] = 'created (demo123456)';
}
$publisherId = AdminUser::query()->value('id');
Announcement::firstOrCreate(
    ['community_id' => $community->id, 'title' => '欢迎入住阳光花园'],
    ['content' => "尊敬的业主：\n欢迎入住阳光花园！请前往「我的房产」核对房产信息，并按时缴纳物业费。", 'category' => 1,
     'is_top' => 1, 'is_published' => 1, 'published_at' => date('Y-m-d H:i:s'), 'publisher_id' => $publisherId]
);
$mark('announcement', Announcement::first());

echo "Demo 数据就绪：\n";
foreach ($stats as $entity => $state) {
    printf("  %-12s %s\n", $entity, $state);
}
echo "演示账号: admin / demo123456（仅当系统无管理员时创建）\n";
