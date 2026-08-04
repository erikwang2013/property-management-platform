<?php
declare(strict_types=1);
namespace tests;
use PHPUnit\Framework\TestCase;

class AuthFeatureTest extends TestCase
{
    public function test_auth_controller_exists(): void
    {
        $this->assertTrue(class_exists(\app\api\v1\controller\AuthController::class));
    }

    public function test_auth_routes_registered(): void
    {
        $source = file_get_contents(__DIR__ . '/../config/route.php');
        $this->assertStringContainsString('auth/login', $source);
        $this->assertStringContainsString('auth/register', $source);
        $this->assertStringContainsString('auth/refresh', $source);
    }

    public function test_middleware_classes_exist(): void
    {
        $this->assertTrue(class_exists(\app\middleware\ServiceAuth::class));
        $this->assertTrue(class_exists(\app\middleware\Cors::class));
        $this->assertTrue(class_exists(\app\middleware\RateLimit::class));
        $this->assertTrue(class_exists(\app\middleware\SecurityFilter::class));
        $this->assertTrue(class_exists(\app\middleware\OperationLog::class));
        $this->assertTrue(class_exists(\app\middleware\ApiVersion::class));
    }
}
