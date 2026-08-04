<?php
declare(strict_types=1);
namespace tests;
use PHPUnit\Framework\TestCase;

class CommunityFeatureTest extends TestCase
{
    public function test_community_controller_class_exists(): void
    {
        $this->assertTrue(class_exists(\app\admin\controller\CommunityController::class));
    }

    public function test_community_route_registered(): void
    {
        $source = file_get_contents(__DIR__ . '/../config/route.php');
        $this->assertStringContainsString('/community', $source);
        $this->assertStringContainsString('CommunityController', $source);
    }

    public function test_community_controller_extends_base(): void
    {
        $c = new \app\admin\controller\CommunityController();
        $this->assertInstanceOf(\app\admin\controller\BaseController::class, $c);
    }

    public function test_snowflake_service_works(): void
    {
        $id = \app\common\SnowflakeService::generate();
        $this->assertIsInt($id);
        $this->assertGreaterThan(0, $id);
    }

    public function test_hashids_service_works(): void
    {
        $encoded = \app\common\HashidsService::encode(12345);
        $this->assertIsString($encoded);
        $this->assertNotEmpty($encoded);
        $this->assertEquals(12345, \app\common\HashidsService::decode($encoded));
    }
}
