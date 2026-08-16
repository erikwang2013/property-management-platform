<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\admin\controller\CollectionController;
use app\admin\controller\FeeBillController;
use app\model\FeeType;
use app\model\Room;
use PHPUnit\Framework\TestCase;

class FeeLogicTest extends TestCase
{
    public function test_bill_amount_area_based(): void
    {
        // 按面积计费：单价 × 总面积
        $feeType = new FeeType(['unit_type' => 1, 'unit_price' => '3.5']);
        $room    = new Room(['area_total' => '100.5']);
        $this->assertSame(351.75, FeeBillController::calcBillAmount($feeType, $room));
    }

    public function test_bill_amount_flat_price(): void
    {
        // 固定单价：与面积无关
        $feeType = new FeeType(['unit_type' => 0, 'unit_price' => '120']);
        $room    = new Room(['area_total' => '200']);
        $this->assertSame(120.0, FeeBillController::calcBillAmount($feeType, $room));
    }

    public function test_bill_amount_rounds_to_two_decimals(): void
    {
        // 浮点边界：0.1 × 0.1 需精确舍入到分
        $feeType = new FeeType(['unit_type' => 1, 'unit_price' => '0.1']);
        $room    = new Room(['area_total' => '0.1']);
        $this->assertSame(0.01, FeeBillController::calcBillAmount($feeType, $room));
    }

    public function test_overdue_days(): void
    {
        $this->assertSame(9, CollectionController::calcOverdueDays('2026-08-01', '2026-08-10'));
        $this->assertSame(1, CollectionController::calcOverdueDays('2026-08-10', '2026-08-11'));
        // 当天到期不视为逾期
        $this->assertSame(0, CollectionController::calcOverdueDays('2026-08-10', '2026-08-10'));
    }

    public function test_late_fee(): void
    {
        // 未缴金额 × 日费率 × 逾期天数
        $this->assertSame(150.0, CollectionController::calcLateFee(1000.0, 0.005, 30));
        // 无滞纳金策略
        $this->assertSame(0.0, CollectionController::calcLateFee(1000.0, 0.0, 30));
        // 浮点舍入：333.33 × 1% × 7 天 → 23.33
        $this->assertSame(23.33, CollectionController::calcLateFee(333.33, 0.01, 7));
    }
}
