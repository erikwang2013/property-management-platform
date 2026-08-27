<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\api\v1\controller\VisitorController;
use app\common\HashidsService;
use app\common\SnowflakeService;
use app\model\Owner;
use app\model\Visitor;
use PHPUnit\Framework\TestCase;
use support\Db;
use support\Request;

class VisitorControllerTest extends TestCase
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

    private static function call(string $method, array $inputs, int $ownerId = 1, ?string $hashid = null): array
    {
        $controller = new VisitorController();
        $request = self::makeRequest($inputs, $ownerId);
        $response = $hashid === null
            ? $controller->{$method}($request)
            : $controller->{$method}($request, $hashid);
        return json_decode($response->rawBody(), true);
    }

    private static function createOwner(int $ownerId, string $password): Owner
    {
        $owner = new Owner();
        $owner->id = $ownerId;
        $owner->name = '测试业主';
        $owner->phone = '13900000000';
        $owner->password = password_hash($password, PASSWORD_BCRYPT);
        $owner->save();
        return $owner;
    }

    public function test_store_missing_name(): void
    {
        $body = self::call('store', ['visitor_phone' => '13800138000']);
        $this->assertSame(422, $body['code']);
        $this->assertSame('请填写访客姓名', $body['message']);
    }

    public function test_store_missing_phone(): void
    {
        $body = self::call('store', ['visitor_name' => '张三']);
        $this->assertSame(422, $body['code']);
        $this->assertSame('请填写访客电话', $body['message']);
    }

    public function test_store_invalid_room_hashid(): void
    {
        $body = self::call('store', ['visitor_name' => '张三', 'visitor_phone' => '13800138000', 'room_id' => 'not-a-hashid']);
        $this->assertSame(404, $body['code']);
        $this->assertSame('无效的房间ID', $body['message']);
    }

    public function test_store_success_creates_visitor(): void
    {
        $this->requireDb();
        $body = self::call('store', [
            'visitor_name'  => '张三',
            'visitor_phone' => '13800138000',
            'visitor_count' => 2,
            'plate_number'  => '京A12345',
            'purpose'       => '拜访',
        ], 1);
        $this->assertSame(0, $body['code']);
        $this->assertSame('访客预约已创建', $body['message']);
        $this->assertMatchesRegularExpression('/^\d{6}$/', $body['data']['pass_code']);

        $visitor = Visitor::find(HashidsService::decode($body['data']['id']));
        $this->assertNotNull($visitor);
        $this->assertSame('张三', $visitor->visitor_name);
        $this->assertSame(0, $visitor->status);
    }

    public function test_update_invalid_hashid(): void
    {
        $body = self::call('update', [], 1, 'not-a-hashid');
        $this->assertSame(404, $body['code']);
        $this->assertSame('无效的访客ID', $body['message']);
    }

    public function test_update_other_owners_visitor_returns_404(): void
    {
        $this->requireDb();
        $visitor = new Visitor();
        $visitor->id = SnowflakeService::generate();
        $visitor->room_id = 0;
        $visitor->owner_id = 9999;
        $visitor->visitor_name = '李四';
        $visitor->visitor_phone = '13700137000';
        $visitor->pass_code = '000000';
        $visitor->status = 0;
        $visitor->save();

        $body = self::call('update', ['visitor_name' => '王五'], 1, HashidsService::encode($visitor->id));
        $this->assertSame(404, $body['code']);
        $this->assertSame('访客预约不存在或无权操作', $body['message']);
    }

    public function test_destroy_empty_password_rejected_before_db(): void
    {
        $body = self::call('destroy', ['password' => ''], 1, 'any-hashid');
        $this->assertSame(422, $body['code']);
        $this->assertSame('敏感操作需要输入密码确认', $body['message']);
    }

    public function test_destroy_wrong_password_rejected(): void
    {
        $this->requireDb();
        self::createOwner(1, 'correct-pass');
        $body = self::call('destroy', ['password' => 'wrong-pass'], 1, 'any-hashid');
        $this->assertSame(422, $body['code']);
        $this->assertSame('密码验证失败', $body['message']);
    }

    public function test_destroy_invalid_hashid_returns_404(): void
    {
        $this->requireDb();
        self::createOwner(1, 'correct-pass');
        $body = self::call('destroy', ['password' => 'correct-pass'], 1, 'not-a-hashid');
        $this->assertSame(404, $body['code']);
        $this->assertSame('无效的访客ID', $body['message']);
    }

    public function test_destroy_success_cancels_visitor(): void
    {
        $this->requireDb();
        self::createOwner(1, 'correct-pass');

        $visitor = new Visitor();
        $visitor->id = SnowflakeService::generate();
        $visitor->room_id = 0;
        $visitor->owner_id = 1;
        $visitor->visitor_name = '张三';
        $visitor->visitor_phone = '13800138000';
        $visitor->pass_code = '123456';
        $visitor->status = 0;
        $visitor->save();

        $body = self::call('destroy', ['password' => 'correct-pass'], 1, HashidsService::encode($visitor->id));
        $this->assertSame(0, $body['code']);
        $this->assertSame('访客预约已取消', $body['message']);
        $this->assertSame(3, $visitor->fresh()->status);
    }

    public function test_destroy_checked_in_visitor_cannot_cancel(): void
    {
        $this->requireDb();
        self::createOwner(1, 'correct-pass');

        $visitor = new Visitor();
        $visitor->id = SnowflakeService::generate();
        $visitor->room_id = 0;
        $visitor->owner_id = 1;
        $visitor->visitor_name = '张三';
        $visitor->visitor_phone = '13800138000';
        $visitor->pass_code = '123456';
        $visitor->status = 1;
        $visitor->save();

        $body = self::call('destroy', ['password' => 'correct-pass'], 1, HashidsService::encode($visitor->id));
        $this->assertSame(422, $body['code']);
        $this->assertSame('当前状态不允许取消', $body['message']);
    }
}
