<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\api\v1\controller\AuthController;
use PHPUnit\Framework\TestCase;
use ReflectionMethod;
use support\Request;

/**
 * API 认证控制器测试
 * 覆盖所有不依赖 DB/Redis 的路径：参数校验、验证码失败、无令牌刷新、点击坐标归一化
 */
class AuthControllerTest extends TestCase
{
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

            public function all()
            {
                return $this->inputs;
            }
        };
    }

    private static function body(\support\Response $response): array
    {
        return json_decode($response->rawBody(), true);
    }

    public function test_login_rejects_missing_username(): void
    {
        $resp = (new AuthController())->login(self::makeRequest([
            'password' => 'Abcdef1@',
        ]));
        $body = self::body($resp);
        $this->assertSame(422, $body['code']);
        $this->assertStringContainsString('username', $body['message']);
    }

    public function test_login_rejects_weak_password(): void
    {
        // 密码复杂度：8-32 位且必须含大小写字母、数字、特殊字符
        $resp = (new AuthController())->login(self::makeRequest([
            'username' => 'zhangsan',
            'password' => 'onlylower1@', // 无大写字母
        ]));
        $this->assertSame(422, self::body($resp)['code']);
    }

    public function test_login_rejects_invalid_captcha(): void
    {
        // 参数全部合法时进入验证码校验：不存在的 key 必然失败（file storage，无 DB/Redis）
        $resp = (new AuthController())->login(self::makeRequest([
            'username'    => 'zhangsan',
            'password'    => 'Abcdef1@x',
            'captcha_key' => 'no-such-key',
            'clicks'      => [[0, 0], [999, 999]],
        ]));
        $body = self::body($resp);
        $this->assertSame(422, $body['code']);
        $this->assertStringContainsString('验证码错误', $body['message']);
    }

    public function test_register_rejects_short_password(): void
    {
        $resp = (new AuthController())->register(self::makeRequest([
            'username' => 'lisi',
            'password' => 'Short1@',
            'real_name' => '李四',
        ]));
        $this->assertSame(422, self::body($resp)['code']);
    }

    public function test_refresh_missing_token_returns_422(): void
    {
        $resp = (new AuthController())->refresh(self::makeRequest([]));
        $body = self::body($resp);
        $this->assertSame(422, $body['code']);
        $this->assertStringContainsString('缺少刷新令牌', $body['message']);
    }

    public function test_normalize_clicks_preserves_numeric_index(): void
    {
        $this->assertSame([[0, 0], [999, 999]], self::invokeNormalizeClicks([[0, 0], [999, 999]]));
    }

    public function test_normalize_clicks_converts_associative(): void
    {
        // 关联数组 {x,y} 归一化为数字索引（包契约），与原值等价
        $this->assertSame([[5, 6]], self::invokeNormalizeClicks([['x' => 5, 'y' => 6]]));
    }

    public function test_normalize_clicks_non_array_returns_empty(): void
    {
        $this->assertSame([], self::invokeNormalizeClicks('bad'));
        $this->assertSame([], self::invokeNormalizeClicks(null));
    }

    private static function invokeNormalizeClicks(mixed $clicks): array
    {
        $ref = new ReflectionMethod(AuthController::class, 'normalizeClicks');
        $ref->setAccessible(true);
        return $ref->invoke(new AuthController(), $clicks);
    }
}
