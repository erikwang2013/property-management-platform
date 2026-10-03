<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\api\v1\controller\HomeController;
use PHPUnit\Framework\TestCase;
use support\Db;
use support\Request;

class HomeControllerTest extends TestCase
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

    protected function requireDb(): void
    {
        if (!self::$db) {
            $this->markTestSkipped('DB 不可用');
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

    public function test_index_returns_dashboard_structure(): void
    {
        $this->requireDb();
        $response = (new HomeController())->index(self::makeRequest(999999999));
        $body = json_decode($response->rawBody(), true);

        $this->assertSame(0, $body['code']);
        $this->assertSame(0, $body['data']['room_count']);
        $this->assertSame(0, $body['data']['pending_bill_count']);
        $this->assertSame(0, $body['data']['repairing_count']);
        $this->assertSame('0.00', $body['data']['pending_amount']);
        $this->assertIsArray($body['data']['announcements']);
    }

    public function test_index_announcements_have_expected_keys(): void
    {
        $this->requireDb();
        $response = (new HomeController())->index(self::makeRequest(999999999));
        $body = json_decode($response->rawBody(), true);

        foreach ($body['data']['announcements'] as $item) {
            $this->assertArrayHasKey('id', $item);
            $this->assertArrayHasKey('title', $item);
            $this->assertArrayHasKey('category', $item);
            $this->assertArrayHasKey('published_at', $item);
        }
    }
}
