<?php
declare(strict_types=1);
namespace tests;
use PHPUnit\Framework\TestCase;

class SecurityFeatureTest extends TestCase
{
    public function test_service_middleware_classes_exist(): void
    {
        $this->assertTrue(class_exists(\app\middleware\Cors::class));
        $this->assertTrue(class_exists(\app\middleware\SecurityFilter::class));
        $this->assertTrue(class_exists(\app\middleware\RateLimit::class));
        $this->assertTrue(class_exists(\app\middleware\ServiceAuth::class));
        $this->assertTrue(class_exists(\app\middleware\OperationLog::class));
    }

    public function test_service_jwt_configured(): void
    {
        $secret = config('jwt.secret', '');
        $this->assertNotEmpty($secret);
    }

    public function test_service_encryption_configured(): void
    {
        $key = config('encryption.key', '');
        $this->assertNotEmpty($key);
    }

    public function test_disabled_default_route(): void
    {
        $source = file_get_contents(__DIR__ . '/../config/route.php');
        $this->assertStringContainsString('disableDefaultRoute', $source);
    }
}
