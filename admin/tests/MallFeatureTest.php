<?php
declare(strict_types=1);
namespace tests;
use PHPUnit\Framework\TestCase;

class MallFeatureTest extends TestCase
{
    public function test_mall_controller_exists(): void
    {
        $this->assertTrue(class_exists(\app\admin\controller\MallController::class));
    }

    public function test_mall_routes_registered(): void
    {
        $source = file_get_contents(__DIR__ . '/../config/route.php');
        $this->assertStringContainsString('mall-category', $source);
        $this->assertStringContainsString('mall-product', $source);
        $this->assertStringContainsString('mall-order', $source);
    }
}
