<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\model\FeeBill;
use PHPUnit\Framework\TestCase;

/**
 * 账单金额/状态纯逻辑测试（不连库）
 *
 * 金额一律走 bcmath 两位小数，避免浮点累加把「缴清」算成「差一分」。
 */
class FeeBillStatusTest extends TestCase
{
    private function bill(string $amount, string $paidAmount, string $lateFee): FeeBill
    {
        $bill = new FeeBill();
        $bill->amount = $amount;
        $bill->paid_amount = $paidAmount;
        $bill->late_fee = $lateFee;
        return $bill;
    }

    public function test_status_constants(): void
    {
        $this->assertSame(0, FeeBill::STATUS_UNPAID);
        $this->assertSame(1, FeeBill::STATUS_PARTIAL);
        $this->assertSame(2, FeeBill::STATUS_PAID);
        $this->assertSame(3, FeeBill::STATUS_OVERDUE);
        $this->assertSame(4, FeeBill::STATUS_WAIVED);
    }

    public function test_unpaid_amount_includes_late_fee_and_subtracts_paid(): void
    {
        $this->assertSame('40.00', $this->bill('100.00', '70.00', '10.00')->unpaidAmount());
    }

    public function test_unpaid_amount_floors_at_zero(): void
    {
        $this->assertSame('0.00', $this->bill('100.00', '200.00', '10.00')->unpaidAmount());
        $this->assertSame('0.00', $this->bill('100.00', '110.00', '10.00')->unpaidAmount());
    }

    public function test_waived_bill_has_no_unpaid_amount(): void
    {
        $bill = $this->bill('100.00', '0.00', '0.00');
        $bill->status = FeeBill::STATUS_WAIVED;
        $this->assertSame('0.00', $bill->unpaidAmount());
    }

    public function test_status_after_payment_uses_late_fee(): void
    {
        $this->assertSame(FeeBill::STATUS_PAID, FeeBill::statusAfterPayment('110.00', '100.00', '10.00'));
        $this->assertSame(FeeBill::STATUS_PARTIAL, FeeBill::statusAfterPayment('109.99', '100.00', '10.00'));
        $this->assertSame(FeeBill::STATUS_PAID, FeeBill::statusAfterPayment('100.00', '100.00', '0.00'));
        $this->assertSame(FeeBill::STATUS_PARTIAL, FeeBill::statusAfterPayment('99.99', '100.00', '0.00'));
    }

    public function test_status_after_payment_float_boundary(): void
    {
        // 0.70 + 0.10 用浮点算会得到 0.7999999999999999；bcmath 下恰为 0.80 → 已缴清
        $this->assertSame(FeeBill::STATUS_PAID, FeeBill::statusAfterPayment('0.80', '0.70', '0.10'));
        $this->assertSame(FeeBill::STATUS_PARTIAL, FeeBill::statusAfterPayment('0.79', '0.70', '0.10'));
    }
}
