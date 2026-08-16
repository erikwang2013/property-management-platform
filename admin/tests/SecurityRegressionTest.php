<?php
declare(strict_types=1);
namespace tests;
use PHPUnit\Framework\TestCase;

class SecurityRegressionTest extends TestCase
{
    public function test_all_middleware_classes_exist(): void
    {
        $this->assertTrue(class_exists(\app\middleware\RateLimit::class));
        $this->assertTrue(class_exists(\app\middleware\SecurityFilter::class));
        $this->assertTrue(class_exists(\app\middleware\Cors::class));
        $this->assertTrue(class_exists(\app\middleware\AdminAuth::class));
        $this->assertTrue(class_exists(\app\middleware\AdminPermission::class));
        $this->assertTrue(class_exists(\app\middleware\OperationLog::class));
        $this->assertTrue(class_exists(\app\middleware\ApiVersion::class));
        $this->assertTrue(class_exists(\app\middleware\StaticFile::class));
    }

    public function test_jwt_config_no_default_secret(): void
    {
        $secret = strtolower(config('jwt.secret', ''));
        $this->assertNotEmpty($secret);
        $this->assertStringNotContainsString('change-me', $secret);
        $this->assertStringNotContainsString('your-secret', $secret);
    }

    public function test_encryption_config_no_default_key(): void
    {
        $key = strtolower(config('encryption.key', ''));
        $this->assertNotEmpty($key);
        $this->assertStringNotContainsString('change-me', $key);
        $this->assertStringNotContainsString('default', $key);
    }

    public function test_cors_not_wildcard(): void
    {
        $origin = config('cors.allowed_origin', getenv('CORS_ALLOWED_ORIGIN') ?: '');
        $this->assertNotEmpty($origin);
        $this->assertNotEquals('*', $origin);
    }

    public function test_session_same_site_strict(): void
    {
        $sameSite = config('session.same_site', '');
        $this->assertEquals('Strict', $sameSite);
    }

    public function test_health_no_sensitive_data_leak(): void
    {
        $c = new \app\admin\controller\HealthController();
        $r = $c->index(new \support\Request('/health', 'GET'));
        $body = json_decode($r->rawBody(), true);
        $data = $body['data'] ?? [];
        $this->assertArrayNotHasKey('password', $data);
        $this->assertArrayNotHasKey('secret', $data);
        $this->assertArrayNotHasKey('token', $data);
    }

    public function test_all_service_classes_exist(): void
    {
        $this->assertTrue(class_exists(\app\common\SnowflakeService::class));
        $this->assertTrue(class_exists(\app\common\HashidsService::class));
        $this->assertTrue(class_exists(\app\common\EncryptionService::class));
        $this->assertTrue(class_exists(\app\common\Validator::class));
    }

    public function test_route_file_exists(): void
    {
        $this->assertFileExists(__DIR__ . '/../config/route.php');
        $source = file_get_contents(__DIR__ . '/../config/route.php');
        $this->assertStringContainsString('disableDefaultRoute', $source);
    }

    public function test_security_php_installed_and_wired(): void
    {
        $this->assertTrue(class_exists(\Erikwang2013\Security\SecurityGuard::class));
        $this->assertFileExists(__DIR__ . '/../config/plugin/erikwang2013/security-php/app.php');
        $middleware = file_get_contents(__DIR__ . '/../app/middleware/SecurityFilter.php');
        $this->assertStringContainsString('SecurityGuard', $middleware);
        $this->assertStringContainsString('guardScan', $middleware);
    }

    public function test_security_php_guard_blocks_known_attack(): void
    {
        \Erikwang2013\Security\SecurityGuard::reset();
        \Erikwang2013\Security\SecurityGuard::init(require __DIR__ . '/../config/plugin/erikwang2013/security-php/app.php');
        $threats = \Erikwang2013\Security\SecurityGuard::guard(
            ['keyword' => '<script>alert(1)</script>', 'q' => '1\' OR 1=1 -- '],
            ['ip' => '127.0.0.1', 'method' => 'GET', 'uri' => '/admin/test']
        );
        $this->assertNotEmpty($threats);
        $this->assertTrue(\Erikwang2013\Security\SecurityGuard::shouldBlock($threats));
    }

    public function test_security_php_guard_passes_benign_input(): void
    {
        $threats = \Erikwang2013\Security\SecurityGuard::guard(
            ['keyword' => '张伟', 'page' => '1', 'note' => '普通文本内容'],
            ['ip' => '127.0.0.1', 'method' => 'GET', 'uri' => '/admin/test']
        );
        $this->assertEmpty($threats);

    }
}
