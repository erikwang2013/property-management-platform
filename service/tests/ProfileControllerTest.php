<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\api\v1\controller\ProfileController;
use app\common\SnowflakeService;
use app\model\Owner;
use PHPUnit\Framework\TestCase;
use support\Db;
use support\Request;

class ProfileControllerTest extends TestCase
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
        $response = (new ProfileController())->{$method}(self::makeRequest($inputs, $ownerId));
        return json_decode($response->rawBody(), true);
    }

    private static function createOwner(int $ownerId, string $password = 'secret123'): Owner
    {
        $owner = new Owner();
        $owner->id = $ownerId;
        $owner->name = '测试业主';
        $owner->phone = '13900000000';
        $owner->email = 'owner@example.com';
        $owner->gender = 1;
        $owner->password = password_hash($password, PASSWORD_BCRYPT);
        $owner->save();
        return $owner;
    }

    public function test_index_unknown_owner_returns_404(): void
    {
        $body = self::call('index', [], 999999999);
        $this->assertSame(404, $body['code']);
        $this->assertSame('用户不存在', $body['message']);
    }

    public function test_index_returns_profile(): void
    {
        $this->requireDb();
        self::createOwner(1);
        $body = self::call('index', [], 1);
        $this->assertSame(0, $body['code']);
        $this->assertSame('测试业主', $body['data']['name']);
        $this->assertSame('13900000000', $body['data']['phone']);
        $this->assertArrayNotHasKey('password', $body['data']);
        $this->assertArrayNotHasKey('id_card', $body['data']);
    }

    public function test_update_name_and_email(): void
    {
        $this->requireDb();
        self::createOwner(1);
        $body = self::call('update', ['name' => '新名字', 'email' => 'new@example.com', 'gender' => 2], 1);
        $this->assertSame(0, $body['code']);
        $this->assertSame('更新成功', $body['message']);
        $this->assertSame('新名字', $body['data']['name']);
        $this->assertSame(2, $body['data']['gender']);
    }

    public function test_update_password_empty_fields(): void
    {
        $this->requireDb();
        self::createOwner(1); // 先存在用户，才能走到字段校验（否则先 404）
        $body = self::call('updatePassword', ['old_password' => '', 'new_password' => ''], 1);
        $this->assertSame(422, $body['code']);
        $this->assertSame('请填写旧密码和新密码', $body['message']);
    }

    public function test_update_password_wrong_old_password(): void
    {
        $this->requireDb();
        self::createOwner(1, 'correct-pass');
        $body = self::call('updatePassword', ['old_password' => 'wrong-pass', 'new_password' => 'newpass6'], 1);
        $this->assertSame(422, $body['code']);
        $this->assertSame('旧密码错误', $body['message']);
    }

    public function test_update_password_too_short(): void
    {
        $this->requireDb();
        self::createOwner(1, 'correct-pass');
        $body = self::call('updatePassword', ['old_password' => 'correct-pass', 'new_password' => '123'], 1);
        $this->assertSame(422, $body['code']);
        $this->assertSame('新密码至少6位', $body['message']);
    }

    public function test_update_password_success(): void
    {
        $this->requireDb();
        $owner = self::createOwner(1, 'correct-pass');
        $body = self::call('updatePassword', ['old_password' => 'correct-pass', 'new_password' => 'newpass6'], 1);
        $this->assertSame(0, $body['code']);
        $this->assertTrue(password_verify('newpass6', $owner->fresh()->password));
    }

    public function test_logout_without_token_returns_401(): void
    {
        $request = new \support\Request("POST /service/v1/profile/logout HTTP/1.1\r\nHost: localhost\r\n\r\n");
        $response = (new ProfileController())->logout($request);
        $body = json_decode($response->rawBody(), true);
        $this->assertSame(401, $body['code']);
        $this->assertSame('未登录', $body['message']);
    }
}
