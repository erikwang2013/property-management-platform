<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\api\v1\controller\NotificationController;
use PHPUnit\Framework\TestCase;
use support\Request;

class NotificationControllerTest extends TestCase
{
    private static function makeRequest(int $ownerId = 1): Request
    {
        return new class($ownerId) extends Request {
            public $ownerId;

            public function __construct(int $ownerId = 1)
            {
                $this->ownerId = $ownerId;
            }
        };
    }

    public function test_mark_read_invalid_hashid(): void
    {
        $response = (new NotificationController())->markRead(self::makeRequest(), 'not-a-hashid');
        $body = json_decode($response->rawBody(), true);
        $this->assertSame(404, $body['code']);
        $this->assertSame('无效的通知ID', $body['message']);
    }

    public function test_mark_read_empty_hashid(): void
    {
        $response = (new NotificationController())->markRead(self::makeRequest(), '');
        $body = json_decode($response->rawBody(), true);
        $this->assertSame(404, $body['code']);
        $this->assertSame('无效的通知ID', $body['message']);
    }
}
