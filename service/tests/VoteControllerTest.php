<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\api\v1\controller\VoteController;
use PHPUnit\Framework\TestCase;
use support\Request;

class VoteControllerTest extends TestCase
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

    public function test_show_invalid_hashid(): void
    {
        $response = (new VoteController())->show(self::makeRequest(), 'not-a-hashid');
        $body = json_decode($response->rawBody(), true);
        $this->assertSame(404, $body['code']);
        $this->assertSame('无效的投票ID', $body['message']);
    }

    public function test_cast_invalid_hashid(): void
    {
        $response = (new VoteController())->cast(self::makeRequest(), 'not-a-hashid');
        $body = json_decode($response->rawBody(), true);
        $this->assertSame(404, $body['code']);
        $this->assertSame('无效的投票ID', $body['message']);
    }

    public function test_index_owner_without_rooms_returns_empty(): void
    {
        $response = (new VoteController())->index(self::makeRequest(999999999));
        $body = json_decode($response->rawBody(), true);
        $this->assertSame(0, $body['code']);
        $this->assertSame([], $body['data']['data']);
        $this->assertSame(0, $body['data']['total']);
    }
}
