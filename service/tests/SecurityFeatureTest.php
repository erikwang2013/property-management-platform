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
        // 不查 config('jwt.secret')：① phpunit 引导不加载 webman 配置树，该路径恒为空；
        // ② 插件配置的真实出处是 config/plugin/erikwang2013/jwt/jwt.php。直接 require 它 ——
        // 文件本身对 JWT_SECRET_KEY 缺失/占位符 fail-fast（抛 RuntimeException），
        // 配好后返回非空 secret_key，这正是要钉住的语义。
        $config = require __DIR__ . '/../config/plugin/erikwang2013/jwt/jwt.php';
        $this->assertNotEmpty($config['secret_key']);
    }

    public function test_service_encryption_configured(): void
    {
        // 同上：config/encryption.php 对 ENCRYPTION_KEY 同样 fail-fast。
        $config = require __DIR__ . '/../config/encryption.php';
        $this->assertNotEmpty($config['key']);
    }

    public function test_disabled_default_route(): void
    {
        $source = file_get_contents(__DIR__ . '/../config/route.php');
        $this->assertStringContainsString('disableDefaultRoute', $source);
    }
}
