<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\common\SnowflakeService;
use app\middleware\ApiKeyAuth;
use app\middleware\ServiceAuth;
use app\model\ApiKey;
use PHPUnit\Framework\TestCase;
use support\Db;
use support\Request;

class MiddlewareAuthTest extends TestCase
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

    private static function request(string $method = 'GET', string $path = '/open/v1/announcements', array $headers = []): Request
    {
        $buffer = "$method $path HTTP/1.1\r\nHost: localhost:8788\r\n";
        foreach ($headers as $name => $value) {
            $buffer .= "$name: $value\r\n";
        }
        return new Request($buffer . "\r\n");
    }

    private static function next(): callable
    {
        return fn() => json(['code' => 0, 'message' => 'passed', 'data' => []]);
    }

    // ── ApiKeyAuth ──────────────────────────────────────────────

    public function test_api_key_auth_missing_key_returns_401(): void
    {
        $response = (new ApiKeyAuth())->process(self::request(), self::next());
        $body = json_decode($response->rawBody(), true);
        $this->assertSame(401, $body['code']);
        $this->assertSame(401, $response->getStatusCode());
        $this->assertSame('无效的API Key', $body['message']);
    }

    public function test_api_key_auth_wrong_key_returns_401(): void
    {
        $response = (new ApiKeyAuth())->process(
            self::request('GET', '/open/v1/announcements', ['X-API-Key' => 'wrong-key-1234567890']),
            self::next()
        );
        $this->assertSame(401, json_decode($response->rawBody(), true)['code']);
    }

    public function test_api_key_auth_overlong_key_returns_401(): void
    {
        $response = (new ApiKeyAuth())->process(
            self::request('GET', '/open/v1/announcements', ['X-API-Key' => str_repeat('k', 129)]),
            self::next()
        );
        $this->assertSame(401, json_decode($response->rawBody(), true)['code']);
    }

    public function test_api_key_auth_valid_key_passes(): void
    {
        $this->requireDb();
        $key = new ApiKey();
        $key->id = SnowflakeService::generate();
        $key->name = 'phpunit-mw';
        $key->api_key_hash = hash('sha256', 'phpunit-valid-key-0001');
        $key->status = 1;
        $key->save();

        $response = (new ApiKeyAuth())->process(
            self::request('GET', '/open/v1/announcements', ['X-API-Key' => 'phpunit-valid-key-0001']),
            self::next()
        );
        $this->assertSame(0, json_decode($response->rawBody(), true)['code']);
    }

    public function test_api_key_auth_disabled_key_rejected(): void
    {
        $this->requireDb();
        $key = new ApiKey();
        $key->id = SnowflakeService::generate();
        $key->name = 'phpunit-mw';
        $key->api_key_hash = hash('sha256', 'phpunit-disabled-key-0001');
        $key->status = 0;
        $key->save();

        $response = (new ApiKeyAuth())->process(
            self::request('GET', '/open/v1/announcements', ['X-API-Key' => 'phpunit-disabled-key-0001']),
            self::next()
        );
        $this->assertSame(401, json_decode($response->rawBody(), true)['code']);
    }

    // ── ServiceAuth ─────────────────────────────────────────────

    public function test_service_auth_missing_token_returns_401(): void
    {
        $response = (new ServiceAuth())->process(self::request('GET', '/service/v1/home'), self::next());
        $body = json_decode($response->rawBody(), true);
        $this->assertSame(401, $body['code']);
        $this->assertSame('未登录', $body['message']);
    }

    public function test_service_auth_invalid_token_returns_401(): void
    {
        $response = (new ServiceAuth())->process(
            self::request('GET', '/service/v1/home', ['Authorization' => 'Bearer not-a-real-token']),
            self::next()
        );
        $body = json_decode($response->rawBody(), true);
        $this->assertSame(401, $body['code']);
        $this->assertSame('Token已过期或无效', $body['message']);
    }
}
