<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\api\v1\controller\RepairController;
use app\common\HashidsService;
use PHPUnit\Framework\TestCase;
use support\Db;
use support\Request;

class RepairControllerTest extends TestCase
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

    /** confirmPassword 置空，跳过 DB 密码校验，直达参数校验路径 */
    private static function makeController(): RepairController
    {
        return new class extends RepairController {
            public function confirmPassword(int $ownerId, string $password): ?string
            {
                return null;
            }
        };
    }

    private static function call(string $method, array $inputs, ?string $hashid = null): array
    {
        $controller = self::makeController();
        $request = self::makeRequest($inputs, 1);
        $response = $hashid === null ? $controller->{$method}($request) : $controller->{$method}($request, $hashid);
        return json_decode($response->rawBody(), true);
    }

    public function test_store_missing_room_id(): void
    {
        $body = self::call('store', ['description' => '水管漏水']);
        $this->assertSame(422, $body['code']);
        $this->assertSame('请选择报修房间', $body['message']);
    }

    public function test_store_missing_description(): void
    {
        $body = self::call('store', ['room_id' => 'abc']);
        $this->assertSame(422, $body['code']);
        $this->assertSame('请填写报修描述', $body['message']);
    }

    public function test_store_invalid_room_hashid_returns_404(): void
    {
        $body = self::call('store', ['room_id' => 'not-a-hashid', 'description' => '水管漏水']);
        $this->assertSame(404, $body['code']);
        $this->assertSame('无效的房间ID', $body['message']);
    }

    public function test_destroy_invalid_hashid_returns_404(): void
    {
        $body = self::call('destroy', [], 'not-a-hashid');
        $this->assertSame(404, $body['code']);
        $this->assertSame('无效的报修单ID', $body['message']);
    }

    public function test_rate_invalid_hashid_returns_404(): void
    {
        $body = self::call('rate', [], 'not-a-hashid');
        $this->assertSame(404, $body['code']);
        $this->assertSame('无效的报修单ID', $body['message']);
    }

    public function test_destroy_nonexistent_returns_404(): void
    {
        if (!self::$dbAvailable) {
            $this->markTestSkipped('DB 不可用');
        }
        // 编码一个真实存在的 ID 格式；该报修单不存在，应返回 404
        $body = self::call('destroy', [], HashidsService::encode(999999999));
        $this->assertSame(404, $body['code']);
        $this->assertSame('报修单不存在或无权操作', $body['message']);
    }
}
