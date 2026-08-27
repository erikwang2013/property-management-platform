<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\api\v1\controller\ParkingController;
use app\common\HashidsService;
use app\common\SnowflakeService;
use app\model\ParkingRecord;
use app\model\ParkingSpace;
use app\model\ParkingVehicle;
use PHPUnit\Framework\TestCase;
use support\Db;
use support\Request;

class ParkingControllerTest extends TestCase
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

    private static function makeRequest(array $inputs = [], int $ownerId = 0): Request
    {
        return new class($inputs, $ownerId) extends Request {
            public $ownerId;

            public function __construct(private array $inputs = [], int $ownerId = 0)
            {
                $this->ownerId = $ownerId;
            }

            public function input(string $name, mixed $default = null)
            {
                return $this->inputs[$name] ?? $default;
            }
        };
    }

    private static function call(string $method, array $inputs, int $ownerId = 1): array
    {
        $response = (new ParkingController())->{$method}(self::makeRequest($inputs, $ownerId));
        return json_decode($response->rawBody(), true);
    }

    public function test_vehicles_empty_for_unknown_owner(): void
    {
        $body = self::call('vehicles', [], 999999999);
        $this->assertSame(0, $body['code']);
        $this->assertArrayHasKey('data', $body['data']);
        $this->assertSame(0, $body['data']['total']);
    }

    public function test_records_without_vehicles_returns_empty(): void
    {
        $body = self::call('records', [], 999999999);
        $this->assertSame(0, $body['code']);
        $this->assertSame([], $body['data']['data']);
        $this->assertSame(0, $body['data']['total']);
    }

    public function test_spaces_empty_for_unknown_owner(): void
    {
        $body = self::call('spaces', [], 999999999);
        $this->assertSame(0, $body['code']);
        $this->assertSame(0, $body['data']['total']);
    }

    public function test_vehicles_returns_plate_with_space(): void
    {
        $this->requireDb();
        $space = new ParkingSpace();
        $space->id = SnowflakeService::generate();
        $space->community_id = 1;
        $space->space_number = 'A-101';
        $space->space_type = 1;
        $space->fee_monthly = 200;
        $space->save();

        $vehicle = new ParkingVehicle();
        $vehicle->id = SnowflakeService::generate();
        $vehicle->owner_id = 1;
        $vehicle->space_id = $space->id;
        $vehicle->plate_number = '京A88888';
        $vehicle->status = 1;
        $vehicle->save();

        $body = self::call('vehicles', [], 1);
        $this->assertSame(0, $body['code']);
        $this->assertSame(1, $body['data']['total']);
        $row = $body['data']['data'][0];
        $this->assertSame('京A88888', $row['plate_number']);
        $this->assertSame(HashidsService::encode($space->id), $row['space_id']);
        $this->assertSame('A-101', $row['space']['space_number']);
    }

    public function test_records_returns_entry_time(): void
    {
        $this->requireDb();
        $vehicle = new ParkingVehicle();
        $vehicle->id = SnowflakeService::generate();
        $vehicle->owner_id = 1;
        $vehicle->space_id = 0;
        $vehicle->plate_number = '京B66666';
        $vehicle->status = 1;
        $vehicle->save();

        $record = new ParkingRecord();
        $record->id = SnowflakeService::generate();
        $record->vehicle_id = $vehicle->id;
        $record->space_id = 0;
        $record->entry_time = '2026-08-01 08:00:00';
        $record->exit_time = null;
        $record->duration = 0;
        $record->fee = 0;
        $record->save();

        $body = self::call('records', [], 1);
        $this->assertSame(0, $body['code']);
        $this->assertSame(1, $body['data']['total']);
        $row = $body['data']['data'][0];
        $this->assertSame('2026-08-01 08:00', $row['entry_time']);
        $this->assertSame('京B66666', $row['plate_number']);
    }
}
