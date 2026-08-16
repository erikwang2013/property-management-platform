<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\api\v1\controller\RoomController;
use app\common\HashidsService;
use PHPUnit\Framework\TestCase;
use support\Db;
use support\Request;

class RoomControllerTest extends TestCase
{
    private static bool $dbAvailable = false;

    public static function setUpBeforeClass(): void
    {
        try {
            Db::select('select 1');
            self::$dbAvailable = true;
        } catch (\Throwable) {
            self::$dbAvailable = false;
        }
    }

    private static function makeRequest(int $ownerId = 0): Request
    {
        return new class($ownerId) extends Request {
            public $ownerId;

            public function __construct(int $ownerId = 0)
            {
                $this->ownerId = $ownerId;
            }
        };
    }

    public function test_show_invalid_hashid_returns_404(): void
    {
        $response = (new RoomController())->show(self::makeRequest(1), 'not-a-hashid');
        $body = json_decode($response->rawBody(), true);
        $this->assertSame(404, $body['code']);
        $this->assertSame('无效的房间ID', $body['message']);
    }

    public function test_show_empty_hashid_returns_404(): void
    {
        $response = (new RoomController())->show(self::makeRequest(1), '');
        $body = json_decode($response->rawBody(), true);
        $this->assertSame(404, $body['code']);
        $this->assertSame('无效的房间ID', $body['message']);
    }

    public function test_show_valid_hashid_not_owned_returns_404(): void
    {
        if (!self::$dbAvailable) {
            $this->markTestSkipped('DB 不可用');
        }
        // 编码一个真实存在的 ID 格式；该房间不属于当前业主，应返回 404
        $response = (new RoomController())->show(self::makeRequest(999999999), HashidsService::encode(123456));
        $body = json_decode($response->rawBody(), true);
        $this->assertSame(404, $body['code']);
    }
}
