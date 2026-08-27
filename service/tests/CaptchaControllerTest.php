<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\api\v1\controller\CaptchaController;
use PHPUnit\Framework\TestCase;
use support\Request;

class CaptchaControllerTest extends TestCase
{
    protected function setUp(): void
    {
        // 显式回退 GD 驱动：本机 CLI 加载了 imagick，DriverFactory 'auto' 会选中 ImagickDriver，
        // 而 vendor 的 ImagickDriver::clone() 在资源未初始化时抛
        // "Typed property $resource must not be accessed before initialization"（vendor bug，禁改 vendor）。
        \Erikwang2013\Poster\PosterConfig::merge(['image' => ['driver' => 'gd']]);
        parent::setUp();
    }

    private static function call(string $method, array $inputs = []): array
    {
        $request = new class($inputs) extends Request {
            public function __construct(private array $inputs = [])
            {
            }

            public function input(string $name, mixed $default = null)
            {
                return $this->inputs[$name] ?? $default;
            }
        };
        $response = (new CaptchaController())->{$method}($request);
        return json_decode($response->rawBody(), true);
    }

    public function test_generate_returns_key_and_png_image(): void
    {
        $body = self::call('generate');
        $this->assertSame(0, $body['code']);
        $this->assertNotEmpty($body['data']['key']);
        $this->assertIsArray($body['data']['extra']['texts']);
        $this->assertNotEmpty($body['data']['extra']['texts']);

        // image 双层编码：控制器对 Poster 的 data URL 再做一次 base64
        $image = base64_decode($body['data']['image'], true);
        $this->assertNotFalse($image);
        $this->assertStringStartsWith('data:image/png;base64,', $image);
        $png = base64_decode(substr($image, strlen('data:image/png;base64,')), true);
        $this->assertNotFalse($png);
        $this->assertStringStartsWith("\x89PNG", $png);
    }

    public function test_verify_missing_key(): void
    {
        $body = self::call('verify', ['clicks' => [[10, 20]]]);
        $this->assertSame(422, $body['code']);
        $this->assertSame('缺少验证参数', $body['message']);
    }

    public function test_verify_missing_clicks(): void
    {
        $body = self::call('verify', ['key' => 'some-key']);
        $this->assertSame(422, $body['code']);
        $this->assertSame('缺少验证参数', $body['message']);
    }

    public function test_verify_unknown_key_fails(): void
    {
        $body = self::call('verify', ['key' => 'no-such-key', 'clicks' => [[10, 20]]]);
        $this->assertSame(422, $body['code']);
        $this->assertSame('验证失败，请重试', $body['message']);
        $this->assertFalse($body['data']['valid']);
    }

    public function test_verify_wrong_clicks_for_generated_key_fails(): void
    {
        $generated = self::call('generate');
        $this->assertSame(0, $generated['code']);

        $body = self::call('verify', ['key' => $generated['data']['key'], 'clicks' => [[0, 0], [1, 1]]]);
        $this->assertSame(422, $body['code']);
        $this->assertFalse($body['data']['valid']);
    }
}
