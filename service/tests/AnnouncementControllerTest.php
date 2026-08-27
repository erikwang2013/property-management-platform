<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\api\v1\controller\AnnouncementController;
use app\common\HashidsService;
use app\common\SnowflakeService;
use app\model\Announcement;
use PHPUnit\Framework\TestCase;
use support\Db;
use support\Request;

class AnnouncementControllerTest extends TestCase
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

    private static function makeRequest(array $inputs = []): Request
    {
        return new class($inputs) extends Request {
            public function __construct(private array $inputs = [])
            {
            }

            public function input(string $name, mixed $default = null)
            {
                return $this->inputs[$name] ?? $default;
            }
        };
    }

    private static function call(string $method, array $inputs = [], ?string $hashid = null): array
    {
        $controller = new AnnouncementController();
        $request = self::makeRequest($inputs);
        $response = $hashid === null
            ? $controller->{$method}($request)
            : $controller->{$method}($request, $hashid);
        return json_decode($response->rawBody(), true);
    }

    private static function createAnnouncement(array $overrides = []): Announcement
    {
        $item = new Announcement();
        $item->id = SnowflakeService::generate();
        $item->community_id = 1;
        $item->title = $overrides['title'] ?? '停水通知';
        $item->content = '明早8点停水';
        $item->category = $overrides['category'] ?? 1;
        $item->is_top = $overrides['is_top'] ?? 0;
        $item->is_published = $overrides['is_published'] ?? 1;
        $item->published_at = $overrides['published_at'] ?? date('Y-m-d H:i:s');
        $item->publisher_id = 1;
        $item->save();
        return $item;
    }

    public function test_show_invalid_hashid(): void
    {
        $body = self::call('show', [], 'not-a-hashid');
        $this->assertSame(404, $body['code']);
        $this->assertSame('无效的公告ID', $body['message']);
    }

    public function test_show_unpublished_returns_404(): void
    {
        $this->requireDb();
        $item = self::createAnnouncement(['is_published' => 0]);
        $body = self::call('show', [], HashidsService::encode($item->id));
        $this->assertSame(404, $body['code']);
        $this->assertSame('公告不存在', $body['message']);
    }

    public function test_show_published_detail(): void
    {
        $this->requireDb();
        $item = self::createAnnouncement();
        $body = self::call('show', [], HashidsService::encode($item->id));
        $this->assertSame(0, $body['code']);
        $this->assertSame('停水通知', $body['data']['title']);
        $this->assertSame('明早8点停水', $body['data']['content']);
    }

    public function test_index_returns_paginated_structure(): void
    {
        $this->requireDb();
        self::createAnnouncement(['title' => '公告A']);
        $body = self::call('index');
        $this->assertSame(0, $body['code']);
        $this->assertArrayHasKey('data', $body['data']);
        $this->assertArrayHasKey('total', $body['data']);
        foreach ($body['data']['data'] as $row) {
            $this->assertArrayHasKey('id', $row);
            $this->assertArrayHasKey('title', $row);
            $this->assertArrayHasKey('category', $row);
        }
    }

    public function test_index_filters_by_category(): void
    {
        $this->requireDb();
        self::createAnnouncement(['title' => '停水', 'category' => 1]);
        self::createAnnouncement(['title' => '活动', 'category' => 4]);
        $body = self::call('index', ['category' => 4]);
        $this->assertSame(0, $body['code']);
        $titles = array_column($body['data']['data'], 'title');
        $this->assertContains('活动', $titles);
        $this->assertNotContains('停水', $titles);
    }
}
