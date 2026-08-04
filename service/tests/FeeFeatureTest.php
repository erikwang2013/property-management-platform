<?php
declare(strict_types=1);
namespace tests;
use PHPUnit\Framework\TestCase;

class FeeFeatureTest extends TestCase
{
    public function test_fee_controller_exists(): void
    {
        $this->assertTrue(class_exists(\app\api\v1\controller\FeeController::class));
    }

    public function test_fee_routes_registered(): void
    {
        $source = file_get_contents(__DIR__ . '/../config/route.php');
        $this->assertStringContainsString('fees/bills', $source);
        $this->assertStringContainsString('fees/pay', $source);
        $this->assertStringContainsString('fees/statistics', $source);
    }

    public function test_fee_model_files_exist(): void
    {
        $this->assertFileExists(__DIR__ . '/../app/model/FeeBill.php');
        $this->assertFileExists(__DIR__ . '/../app/model/FeePayment.php');
        $this->assertFileExists(__DIR__ . '/../app/model/FeeType.php');
    }
}
