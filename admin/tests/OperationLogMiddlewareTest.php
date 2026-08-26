<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\middleware\OperationLog;
use PHPUnit\Framework\TestCase;
use ReflectionMethod;
use support\Request;

class OperationLogMiddlewareTest extends TestCase
{
    private static function filterSensitive(array $data): array
    {
        $method = new ReflectionMethod(OperationLog::class, 'filterSensitive');
        $method->setAccessible(true);
        return $method->invoke(new OperationLog(), $data);
    }

    private static function detectSource(string $ua, string $platform = ''): string
    {
        $buffer = "GET /admin/community HTTP/1.1\r\n"
            . ($platform !== '' ? "X-Client-Platform: {$platform}\r\n" : '')
            . "User-Agent: {$ua}\r\nHost: localhost\r\n\r\n";
        $method = new ReflectionMethod(OperationLog::class, 'detectSource');
        $method->setAccessible(true);
        return $method->invoke(new OperationLog(), new Request($buffer));
    }

    // ============ filterSensitive ============

    public function test_top_level_sensitive_keys_masked(): void
    {
        $out = self::filterSensitive(['username' => 'erik', 'password' => 'secret123', 'token' => 'abc']);
        $this->assertSame('erik', $out['username']);
        $this->assertSame('***', $out['password']);
        $this->assertSame('***', $out['token']);
    }

    public function test_nested_sensitive_keys_masked_recursively(): void
    {
        $out = self::filterSensitive(['user' => ['password' => 'x', 'meta' => ['refresh_token' => 'y', 'note' => 'keep']]]);
        $this->assertSame('***', $out['user']['password']);
        $this->assertSame('***', $out['user']['meta']['refresh_token']);
        $this->assertSame('keep', $out['user']['meta']['note']);
    }

    public function test_all_known_sensitive_keys_masked(): void
    {
        $keys = ['password', 'old_password', 'new_password', 'new_password_confirmation', 'token', 'secret', 'access_token', 'refresh_token'];
        $out = self::filterSensitive(array_fill_keys($keys, 'raw'));
        foreach ($keys as $key) {
            $this->assertSame('***', $out[$key], "{$key} 应被脱敏");
        }
    }

    // ============ detectSource ============

    public function test_platform_header_takes_priority(): void
    {
        $this->assertSame('ios', self::detectSource('Android 14; Mobile', 'iOS'));
        $this->assertSame('harmonyos', self::detectSource('some UA', 'HarmonyOS'));
    }

    public function test_platform_header_invalid_value_ignored(): void
    {
        // 无效平台值 → 回退到 UA 推断
        $this->assertSame('web', self::detectSource('normal browser', 'hack-os'));
    }

    public function test_ua_inference_all_platforms(): void
    {
        $this->assertSame('harmonyos', self::detectSource('Mozilla/5.0 HarmonyOS 5.0'));
        $this->assertSame('ipados', self::detectSource('Mozilla/5.0 (iPad; CPU OS 17_0)'));
        $this->assertSame('ios', self::detectSource('Mozilla/5.0 (iPhone; CPU iPhone OS 17_0)'));
        $this->assertSame('ios', self::detectSource('CFNetwork/1406 Darwin'));
        $this->assertSame('android', self::detectSource('Mozilla/5.0 (Linux; Android 14)'));
        $this->assertSame('macos', self::detectSource('Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0)'));
        $this->assertSame('windows', self::detectSource('Mozilla/5.0 (Windows NT 10.0; Win64; x64)'));
        $this->assertSame('linux', self::detectSource('Mozilla/5.0 (X11; Linux x86_64)'));
        $this->assertSame('web', self::detectSource('unknown-random-ua'));
    }

    // ============ process 分流 ============

    public function test_read_methods_pass_through_without_logging(): void
    {
        foreach (['GET', 'OPTIONS', 'HEAD'] as $method) {
            $buffer = "{$method} /admin/community HTTP/1.1\r\nHost: localhost\r\n\r\n";
            $request = new Request($buffer);
            $hit = false;
            $response = (new OperationLog())->process($request, function () use (&$hit) {
                $hit = true;
                return response('ok');
            });
            $this->assertTrue($hit, "{$method} 应直接放行");
            $this->assertSame(200, $response->getStatusCode());
        }
    }
}
