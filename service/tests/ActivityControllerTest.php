<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\api\v1\controller\ActivityController;
use app\common\HashidsService;
use app\common\SnowflakeService;
use app\model\ActivitySignup;
use app\model\CommunityActivity;
use PHPUnit\Framework\TestCase;
use support\Db;
use support\Request;

class ActivityControllerTest extends TestCase
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
        $controller = new ActivityController();
        $request = self::makeRequest($inputs, $ownerId);
        $response = $hashid === null
            ? $controller->{$method}($request)
            : $controller->{$method}($request, $hashid);
        return json_decode($response->rawBody(), true);
    }

    private static function createActivity(array $overrides = []): CommunityActivity
    {
        $activity = new CommunityActivity();
        $activity->id = SnowflakeService::generate();
        $activity->community_id = 1;
        $activity->title = $overrides['title'] ?? '社区植树活动';
        $activity->content = '一起来种树';
        $activity->max_participants = $overrides['max_participants'] ?? 10;
        $activity->status = $overrides['status'] ?? 1;
        $activity->start_time = $overrides['start_time'] ?? '2030-01-01 09:00:00';
        $activity->end_time = $overrides['end_time'] ?? '2030-01-02 18:00:00';
        $activity->signup_start = '2026-01-01 00:00:00';
        $activity->signup_end = '2030-01-01 08:00:00';
        $activity->is_free = 1;
        $activity->cost = 0;
        $activity->organizer = '业委会';
        $activity->contact_phone = '13800138000';
        $activity->save();
        return $activity;
    }

    public function test_signup_requires_login(): void
    {
        $body = self::call('signup', [], 0, 'any-hashid');
        $this->assertSame(401, $body['code']);
        $this->assertSame('请先登录', $body['message']);
    }

    public function test_signup_invalid_hashid(): void
    {
        $body = self::call('signup', [], 1, 'not-a-hashid');
        $this->assertSame(404, $body['code']);
        $this->assertSame('无效的活动ID', $body['message']);
    }

    public function test_signup_activity_not_open(): void
    {
        $this->requireDb();
        $activity = self::createActivity(['status' => 2]);
        $body = self::call('signup', [], 1, HashidsService::encode($activity->id));
        $this->assertSame(422, $body['code']);
        $this->assertSame('当前活动暂未开放报名', $body['message']);
    }

    public function test_signup_success_and_duplicate_rejected(): void
    {
        $this->requireDb();
        $activity = self::createActivity();
        $hashid = HashidsService::encode($activity->id);

        $body = self::call('signup', ['participant_count' => 2, 'contact_phone' => '13800138000'], 1, $hashid);
        $this->assertSame(0, $body['code']);
        $this->assertSame('报名成功', $body['message']);
        $this->assertSame(1, $body['data']['signup_count']);

        $signup = ActivitySignup::where('activity_id', $activity->id)->where('owner_id', 1)->first();
        $this->assertNotNull($signup);
        $this->assertSame(2, $signup->participant_count);

        $body = self::call('signup', [], 1, $hashid);
        $this->assertSame(422, $body['code']);
        $this->assertSame('您已报名该活动', $body['message']);
    }

    public function test_signup_full_activity_rejected(): void
    {
        $this->requireDb();
        $activity = self::createActivity(['max_participants' => 2]);

        // 另一业主占满名额（2 人）
        $signup = new ActivitySignup();
        $signup->id = SnowflakeService::generate();
        $signup->activity_id = $activity->id;
        $signup->owner_id = 9998;
        $signup->participant_count = 2;
        $signup->signup_status = 0;
        $signup->signup_at = date('Y-m-d H:i:s');
        $signup->save();

        $body = self::call('signup', ['participant_count' => 1], 1, HashidsService::encode($activity->id));
        $this->assertSame(422, $body['code']);
        $this->assertSame('报名已满', $body['message']);
    }

    public function test_cancel_no_signup_returns_404(): void
    {
        $this->requireDb();
        $activity = self::createActivity();
        $body = self::call('cancel', [], 1, HashidsService::encode($activity->id));
        $this->assertSame(404, $body['code']);
        $this->assertSame('未找到您的报名记录', $body['message']);
    }

    public function test_cancel_success(): void
    {
        $this->requireDb();
        $activity = self::createActivity();
        $hashid = HashidsService::encode($activity->id);

        self::call('signup', [], 1, $hashid);
        $body = self::call('cancel', [], 1, $hashid);
        $this->assertSame(0, $body['code']);
        $this->assertSame('取消报名成功', $body['message']);
        $this->assertNull(ActivitySignup::where('activity_id', $activity->id)->where('owner_id', 1)->first());
    }

    public function test_cancel_checked_in_rejected(): void
    {
        $this->requireDb();
        $activity = self::createActivity();

        $signup = new ActivitySignup();
        $signup->id = SnowflakeService::generate();
        $signup->activity_id = $activity->id;
        $signup->owner_id = 1;
        $signup->participant_count = 1;
        $signup->signup_status = 1; // 已签到
        $signup->signup_at = date('Y-m-d H:i:s');
        $signup->save();

        $body = self::call('cancel', [], 1, HashidsService::encode($activity->id));
        $this->assertSame(422, $body['code']);
        $this->assertSame('已签到，无法取消报名', $body['message']);
    }

    public function test_show_invalid_hashid(): void
    {
        $body = self::call('show', [], 1, 'not-a-hashid');
        $this->assertSame(404, $body['code']);
        $this->assertSame('无效的活动ID', $body['message']);
    }

    public function test_show_activity_detail(): void
    {
        $this->requireDb();
        $activity = self::createActivity();
        $body = self::call('show', [], 1, HashidsService::encode($activity->id));
        $this->assertSame(0, $body['code']);
        $this->assertSame('社区植树活动', $body['data']['title']);
        $this->assertSame(10, $body['data']['max_participants']);
        $this->assertSame(1, $body['data']['status']);
    }
}
