<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\common\SnowflakeService;
use app\model\BaseModel;
use app\model\Owner;
use app\model\Room;
use PHPUnit\Framework\TestCase;
use ReflectionProperty;
use support\Db;

class ModelTest extends TestCase
{
    private static bool $db = false;

    public static function setUpBeforeClass(): void
    {
        try {
            Db::select('select 1');
            self::$db = true;
        } catch (\Throwable) {
            self::$db = false;
        }
    }

    protected function setUp(): void
    {
        if (self::$db) {
            Db::beginTransaction();
        }
    }

    protected function tearDown(): void
    {
        if (self::$db) {
            Db::rollBack();
        }
    }

    protected function requireDb(): void
    {
        if (!self::$db) {
            $this->markTestSkipped('DB 不可用');
        }
    }

    public function test_base_model_disables_auto_increment(): void
    {
        $model = new BaseModel();
        $property = new ReflectionProperty(BaseModel::class, 'incrementing');
        $this->assertFalse($property->getValue($model));
    }

    public function test_room_soft_delete(): void
    {
        $this->requireDb();
        $room = new Room();
        $room->id = SnowflakeService::generate();
        $room->community_id = 1;
        $room->building_id = 1;
        $room->unit_id = 1;
        $room->room_number = 'T' . substr((string) $room->id, -8);
        $room->area_total = '88.5';
        $room->save();
        $id = $room->id;

        $this->assertNotNull(Room::find($id));
        $room->delete();
        $this->assertNull(Room::find($id));
        $this->assertNotNull(Room::withTrashed()->find($id));
        $this->assertSame(0, Room::where('id', $id)->count()); // 本行已软删（表内可能还有其他行）
    }

    public function test_room_decimal_cast(): void
    {
        // 2026-10-04 修复：Room 等模型 decimal 裸 cast 已全部补显式 scale（decimal:2，对齐 install.sql DECIMAL(x,2)）
        $this->requireDb();
        $room = new Room();
        $room->id = SnowflakeService::generate();
        $room->community_id = 1;
        $room->building_id = 1;
        $room->unit_id = 1;
        $room->room_number = 'T' . substr((string) $room->id, -8);
        $room->area_total = '88.50';
        $room->save();

        $fresh = Room::find($room->id);
        $this->assertSame('88.50', $fresh->area_total); // decimal cast 返回字符串
        $this->assertIsInt($fresh->community_id);       // integer cast
    }

    public function test_owner_encryptable_phone_roundtrip(): void
    {
        $this->requireDb();
        $owner = new Owner();
        $owner->id = SnowflakeService::generate();
        $owner->name = '加密测试';
        $owner->phone = '13800138000';
        $owner->password = password_hash('secret123', PASSWORD_BCRYPT);
        $owner->save();

        $fresh = Owner::find($owner->id);
        $this->assertSame('13800138000', $fresh->phone, '加密字段读回应解密为原文');

        $raw = Db::table('management_owner')->where('id', $owner->id)->value('phone');
        $this->assertNotSame('13800138000', $raw, '库中不应存明文手机号');
    }

    public function test_owner_hides_sensitive_attributes(): void
    {
        $this->requireDb();
        $owner = new Owner();
        $owner->id = SnowflakeService::generate();
        $owner->name = '隐藏测试';
        $owner->phone = '13900139000';
        $owner->id_card = '110101199001011234';
        $owner->password = password_hash('secret123', PASSWORD_BCRYPT);
        $owner->save();

        $array = Owner::find($owner->id)->toArray();
        $this->assertArrayNotHasKey('password', $array);
        $this->assertArrayNotHasKey('id_card', $array);
    }
}
