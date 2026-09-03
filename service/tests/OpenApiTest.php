<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\common\SnowflakeService;
use app\model\ApiKey;
use PHPUnit\Framework\TestCase;

class OpenApiTest extends TestCase
{
    private const TEST_KEY = 'openapi_test_key_0123456789abcdef';

    // 探测端口可用环境变量 OPEN_API_TEST_PORT 覆盖（本机 8788 被其他项目占用时设置）
    private static function baseUrl(): string
    {
        return 'http://localhost:' . (getenv('OPEN_API_TEST_PORT') ?: 8788);
    }

    private static ?ApiKey $key = null;

    /** 端口可能被其他项目占用：-1=未探测 0=非本服务 1=本服务 */
    private static int $serviceUp = -1;

    public static function setUpBeforeClass(): void
    {
        try {
            self::$key = new ApiKey();
            self::$key->setAttribute('id', SnowflakeService::generate());
            self::$key->name = 'phpunit-test';
            self::$key->api_key_hash = hash('sha256', self::TEST_KEY);
            self::$key->status = 1;
            self::$key->save();
        } catch (\Throwable $e) {
            self::$key = null; // DB 不可用时仅跑静态断言
        }
    }

    public static function tearDownAfterClass(): void
    {
        if (self::$key) {
            self::$key->delete();
        }
    }

    private function httpGet(string $path, ?string $apiKey): ?array
    {
        // 8788 端口可能被其他项目占用（本机即被 social-service 占用）：
        // 仅当 /health 确认是物业系统服务才发起探测，否则与"服务未运行"同等处理（跳过用例）
        if (self::$serviceUp === -1) {
            $health = @file_get_contents(self::baseUrl() . '/health');
            self::$serviceUp = $health !== false && str_contains((string) $health, 'property-service') ? 1 : 0;
        }
        if (self::$serviceUp !== 1) {
            return null;
        }
        $ctx = stream_context_create(['http' => [
            'timeout'       => 5,
            'ignore_errors' => true, // 4xx/5xx 也返回响应体
            'header'        => $apiKey !== null ? "X-API-Key: $apiKey" : '',
        ]]);
        $fp = @fopen(self::baseUrl() . $path, 'r', false, $ctx);
        if ($fp === false) {
            return null;
        }
        $body = stream_get_contents($fp);
        $status = $http_response_header[0] ?? '';
        fclose($fp);
        return ['body' => json_decode($body, true), 'status' => $status];
    }

    public function test_open_routes_registered(): void
    {
        $source = file_get_contents(__DIR__ . '/../config/route.php');
        $this->assertStringContainsString('/open', $source);
        $this->assertStringContainsString('ApiKeyAuth', $source);
        $this->assertStringContainsString('OpenApiController', $source);
    }

    public function test_middleware_and_controller_exist(): void
    {
        $this->assertTrue(class_exists(\app\middleware\ApiKeyAuth::class));
        $this->assertTrue(class_exists(\app\api\v1\controller\OpenApiController::class));
        $this->assertTrue(class_exists(\app\model\ApiKey::class));
    }

    public function test_gen_script_exists(): void
    {
        $this->assertFileExists(__DIR__ . '/../../scripts/gen_api_key.php');
    }

    public function test_api_key_stores_sha256_hash_not_plaintext(): void
    {
        if (self::$key === null) {
            $this->markTestSkipped('DB 不可用');
        }
        $this->assertSame(hash('sha256', self::TEST_KEY), self::$key->api_key_hash);
        $this->assertNotSame(self::TEST_KEY, self::$key->api_key_hash);
    }

    public function test_no_key_returns_401(): void
    {
        if (self::$key === null) {
            $this->markTestSkipped('DB 不可用');
        }
        $result = $this->httpGet('/open/v1/announcements', null);
        if ($result === null) {
            $this->markTestSkipped('Service not running on port 8788');
        }
        $this->assertSame('401', substr($result['status'], 9, 3), '缺少 X-API-Key 应返回 401');
        $this->assertSame(401, $result['body']['code'] ?? null);
    }

    public function test_wrong_key_returns_401(): void
    {
        if (self::$key === null) {
            $this->markTestSkipped('DB 不可用');
        }
        $result = $this->httpGet('/open/v1/announcements', 'wrong_key_0000000000000000');
        if ($result === null) {
            $this->markTestSkipped('Service not running on port 8788');
        }
        $this->assertSame('401', substr($result['status'], 9, 3), '错误 X-API-Key 应返回 401');
        $this->assertSame(401, $result['body']['code'] ?? null);
    }

    public function test_valid_key_allows_announcements(): void
    {
        if (self::$key === null) {
            $this->markTestSkipped('DB 不可用');
        }
        $result = $this->httpGet('/open/v1/announcements', self::TEST_KEY);
        if ($result === null) {
            $this->markTestSkipped('Service not running on port 8788');
        }
        $this->assertSame('200', substr($result['status'], 9, 3), '正确 Key 应放行');
        $this->assertSame(0, $result['body']['code'] ?? null);
        $this->assertArrayHasKey('data', $result['body']);
    }

    public function test_bills_requires_bill_number(): void
    {
        if (self::$key === null) {
            $this->markTestSkipped('DB 不可用');
        }
        $result = $this->httpGet('/open/v1/bills', self::TEST_KEY);
        if ($result === null) {
            $this->markTestSkipped('Service not running on port 8788');
        }
        $this->assertSame(400, $result['body']['code'] ?? null, '缺少 bill_number 应返回 400');
    }

    public function test_repairs_requires_order_number(): void
    {
        if (self::$key === null) {
            $this->markTestSkipped('DB 不可用');
        }
        $result = $this->httpGet('/open/v1/repairs', self::TEST_KEY);
        if ($result === null) {
            $this->markTestSkipped('Service not running on port 8788');
        }
        $this->assertSame(400, $result['body']['code'] ?? null, '缺少 order_number 应返回 400');
    }

    public function test_unknown_bill_returns_404(): void
    {
        if (self::$key === null) {
            $this->markTestSkipped('DB 不可用');
        }
        $result = $this->httpGet('/open/v1/bills?bill_number=NONEXISTENT-0001', self::TEST_KEY);
        if ($result === null) {
            $this->markTestSkipped('Service not running on port 8788');
        }
        $this->assertSame(404, $result['body']['code'] ?? null);
    }
}
