<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\api\v1\controller\ComplaintController;
use app\common\HashidsService;
use app\common\SnowflakeService;
use PHPUnit\Framework\TestCase;
use support\Db;
use support\Request;

class ComplaintControllerTest extends TestCase
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
        $controller = new ComplaintController();
        $request = self::makeRequest($inputs, $ownerId);
        $response = $hashid === null
            ? $controller->{$method}($request)
            : $controller->{$method}($request, $hashid);
        return json_decode($response->rawBody(), true);
    }

    private static function createComplaint(int $ownerId = 1, int $status = 0, array $overrides = []): int
    {
        $id = SnowflakeService::generate();
        Db::table('erik_complaint')->insert([
            'id'           => $id,
            'owner_id'     => $ownerId,
            'type'         => $overrides['type'] ?? 1,
            'category'     => $overrides['category'] ?? 5,
            'title'        => $overrides['title'] ?? '夜间噪音扰民',
            'content'      => $overrides['content'] ?? '楼下半夜装修',
            'images'       => json_encode([]),
            'is_anonymous' => 0,
            'status'       => $status,
            'created_at'   => date('Y-m-d H:i:s'),
            'updated_at'   => date('Y-m-d H:i:s'),
        ]);
        return $id;
    }

    public function test_store_missing_title(): void
    {
        $body = self::call('store', ['content' => '内容']);
        $this->assertSame(422, $body['code']);
        $this->assertSame('请填写投诉标题', $body['message']);
    }

    public function test_store_missing_content(): void
    {
        $body = self::call('store', ['title' => '标题']);
        $this->assertSame(422, $body['code']);
        $this->assertSame('请填写投诉内容', $body['message']);
    }

    public function test_store_success(): void
    {
        $this->requireDb();
        $body = self::call('store', ['title' => '噪音', 'content' => '半夜装修', 'is_anonymous' => 1, 'type' => 1, 'category' => 5]);
        $this->assertSame(0, $body['code']);
        $this->assertSame('投诉已提交', $body['message']);
        $row = Db::table('erik_complaint')->where('id', HashidsService::decode($body['data']['id']))->first();
        $this->assertNotNull($row);
        $this->assertSame(1, (int) $row->owner_id);
        $this->assertSame(0, (int) $row->status);
    }

    public function test_show_invalid_hashid(): void
    {
        $body = self::call('show', [], 1, 'not-a-hashid');
        $this->assertSame(404, $body['code']);
        $this->assertSame('无效的投诉ID', $body['message']);
    }

    public function test_show_other_owners_complaint_returns_404(): void
    {
        $this->requireDb();
        $id = self::createComplaint(9999);
        $body = self::call('show', [], 1, HashidsService::encode($id));
        $this->assertSame(404, $body['code']);
        $this->assertSame('投诉不存在或无权访问', $body['message']);
    }

    public function test_show_own_complaint_detail(): void
    {
        $this->requireDb();
        $id = self::createComplaint(1, 0, ['title' => '电梯故障']);
        $body = self::call('show', [], 1, HashidsService::encode($id));
        $this->assertSame(0, $body['code']);
        $this->assertSame('电梯故障', $body['data']['title']);
        $this->assertSame(0, $body['data']['status']);
    }

    public function test_satisfaction_requires_processed_status(): void
    {
        $this->requireDb();
        $id = self::createComplaint(1, 0); // 未处理
        $body = self::call('satisfaction', ['score' => 5], 1, HashidsService::encode($id));
        $this->assertSame(422, $body['code']);
        $this->assertSame('仅已处理状态的投诉可以评价', $body['message']);
    }

    public function test_satisfaction_score_out_of_range(): void
    {
        $this->requireDb();
        $id = self::createComplaint(1, 2); // 已处理
        foreach ([0, 6] as $score) {
            $body = self::call('satisfaction', ['score' => $score], 1, HashidsService::encode($id));
            $this->assertSame(422, $body['code'], "score=$score 应被拒绝");
            $this->assertSame('评分必须在1-5之间', $body['message']);
        }
    }

    public function test_satisfaction_success(): void
    {
        $this->requireDb();
        $id = self::createComplaint(1, 2);
        $body = self::call('satisfaction', ['score' => 4], 1, HashidsService::encode($id));
        $this->assertSame(0, $body['code']);
        $this->assertSame('评价成功', $body['message']);
        $row = Db::table('erik_complaint')->where('id', $id)->first();
        $this->assertSame(4, (int) $row->satisfaction);
    }
}
