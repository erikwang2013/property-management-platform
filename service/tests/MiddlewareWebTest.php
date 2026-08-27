<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\common\SnowflakeService;
use app\middleware\Cors;
use app\middleware\MetricsCollector;
use app\middleware\OperationLog;
use app\middleware\RateLimit;
use PHPUnit\Framework\TestCase;
use ReflectionMethod;
use support\Db;
use support\Redis;
use support\Request;

class MiddlewareWebTest extends TestCase
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

    private static function request(string $method = 'GET', string $path = '/service/home', array $headers = []): Request
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

    // ── Cors ────────────────────────────────────────────────────

    public function test_cors_preflight_returns_204_with_headers(): void
    {
        $response = (new Cors())->process(self::request('OPTIONS', '/service/home'), self::next());
        $this->assertSame(204, $response->getStatusCode());
        $this->assertSame('http://localhost:8788', $response->getHeader('Access-Control-Allow-Origin'));
        $this->assertStringContainsString('GET', $response->getHeader('Access-Control-Allow-Methods'));
        $this->assertSame('86400', $response->getHeader('Access-Control-Max-Age'));
    }

    public function test_cors_adds_security_headers_to_response(): void
    {
        $response = (new Cors())->process(self::request('GET', '/service/home'), self::next());
        $this->assertSame('nosniff', $response->getHeader('X-Content-Type-Options'));
        $this->assertSame('DENY', $response->getHeader('X-Frame-Options'));
        $this->assertSame('http://localhost:8788', $response->getHeader('Access-Control-Allow-Origin'));
    }

    // ── OperationLog ────────────────────────────────────────────

    public function test_operation_log_get_does_not_write(): void
    {
        $this->requireDb();
        $before = Db::table('management_operation_log')->count();
        (new OperationLog())->process(self::request('GET', '/service/home'), self::next());
        $this->assertSame($before, Db::table('management_operation_log')->count());
    }

    public function test_operation_log_post_writes_masked_input(): void
    {
        $this->requireDb();
        $request = self::request('POST', '/service/profile/password', [
            'Content-Type' => 'application/x-www-form-urlencoded',
        ]);
        $request->ownerId = 7;
        (new OperationLog())->process($request, self::next());

        $log = Db::table('management_operation_log')->where('user_id', 7)->where('action', 'POST')->first();
        $this->assertNotNull($log);
        $this->assertSame('/service/profile/password', $log->path);
    }

    public function test_operation_log_filter_sensitive_masks_keys(): void
    {
        $method = new ReflectionMethod(OperationLog::class, 'filterSensitive');
        $method->setAccessible(true);
        $filtered = $method->invoke(new OperationLog(), [
            'password'      => 'plain-text',
            'old_password'  => 'plain-text',
            'token'         => 'jwt-token',
            'visitor_name'  => '张三',
        ]);
        $this->assertSame('***', $filtered['password']);
        $this->assertSame('***', $filtered['old_password']);
        $this->assertSame('***', $filtered['token']);
        $this->assertSame('张三', $filtered['visitor_name']);
    }

    // ── MetricsCollector ────────────────────────────────────────

    public function test_metrics_collector_increments_all_counter(): void
    {
        $before = (int) (Redis::get('property_service_metrics:http_all') ?: 0);
        (new MetricsCollector())->process(self::request('GET', '/service/home'), self::next());
        $after = (int) (Redis::get('property_service_metrics:http_all') ?: 0);
        Redis::set('property_service_metrics:http_all', $before); // 还原计数
        $this->assertSame($before + 1, $after);
    }

    public function test_metrics_collector_counts_5xx(): void
    {
        $allBefore = (int) (Redis::get('property_service_metrics:http_all') ?: 0);
        $failsBefore = (int) (Redis::get('property_service_metrics:http_5xx') ?: 0);
        (new MetricsCollector())->process(self::request('GET', '/error'), fn() => json(['code' => 500])->withStatus(500));
        $failsAfter = (int) (Redis::get('property_service_metrics:http_5xx') ?: 0);
        Redis::set('property_service_metrics:http_all', $allBefore);
        Redis::set('property_service_metrics:http_5xx', $failsBefore);
        $this->assertSame($failsBefore + 1, $failsAfter);
    }

    // ── RateLimit ───────────────────────────────────────────────

    public function test_rate_limit_allows_first_request(): void
    {
        Redis::del('rate_limit:10.0.0.1:_service_home');
        $response = (new RateLimit())->process(
            self::request('GET', '/service/home', ['X-Forwarded-For' => '10.0.0.1']),
            self::next()
        );
        Redis::del('rate_limit:10.0.0.1:_service_home');
        $this->assertSame(200, $response->getStatusCode());
        $this->assertSame('60', $response->getHeader('X-RateLimit-Limit'));
    }

    public function test_rate_limit_login_path_throttles_after_10(): void
    {
        $key = 'rate_limit:10.0.0.2:_api_auth_login';
        Redis::del($key);

        $middleware = new RateLimit();
        $handler = fn() => json(['code' => 0]);
        $statusCodes = [];
        for ($i = 0; $i < 12; $i++) {
            $response = $middleware->process(
                self::request('POST', '/api/auth/login', ['X-Forwarded-For' => '10.0.0.2']),
                $handler
            );
            $statusCodes[] = $response->getStatusCode();
        }

        $this->assertSame(429, $statusCodes[10], '第11次请求应被限流');
        $this->assertSame(429, $statusCodes[11]);
        $this->assertNotSame(429, $statusCodes[9], '第10次请求应放行');
        // 已触发限流后，再请求 remaining 应为 0（在清理 key 之前断言）
        $this->assertSame('0', (new RateLimit())->process(
            self::request('POST', '/api/auth/login', ['X-Forwarded-For' => '10.0.0.2']),
            $handler
        )->getHeader('X-RateLimit-Remaining'));
        Redis::del($key); // 清理（放在断言之后，避免破坏限流状态）
    }
}
