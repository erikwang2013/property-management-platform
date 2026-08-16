<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\common\PaymentService;
use app\common\payment\AlipayChannel;
use app\common\payment\WechatPayChannel;
use PHPUnit\Framework\TestCase;

class PaymentServiceTest extends TestCase
{
    private static string $privateKey = '';
    private static string $publicKey = '';

    public static function setUpBeforeClass(): void
    {
        $res = openssl_pkey_new([
            'private_key_bits' => 2048,
            'private_key_type' => OPENSSL_KEYTYPE_RSA,
        ]);
        openssl_pkey_export($res, self::$privateKey);
        self::$publicKey = (string) openssl_pkey_get_details($res)['key'];
    }

    public function test_wechat_build_sign_message_format(): void
    {
        $message = WechatPayChannel::buildSignMessage('1720000000', 'nonce123', '{"a":1}');
        $this->assertSame("1720000000\nnonce123\n{\"a\":1}\n", $message);
    }

    public function test_wechat_sign_verify_roundtrip(): void
    {
        $message = WechatPayChannel::buildSignMessage('1720000000', 'nonce123', '{"out_trade_no":"123"}');
        $signature = WechatPayChannel::sign($message, self::$privateKey);
        $this->assertTrue(WechatPayChannel::verify($message, $signature, self::$publicKey));
        $this->assertFalse(WechatPayChannel::verify($message . 'x', $signature, self::$publicKey));
    }

    public function test_wechat_to_cents(): void
    {
        $this->assertSame(1050, WechatPayChannel::toCents(10.5));
        $this->assertSame(1, WechatPayChannel::toCents(0.01));
        $this->assertSame(123456, WechatPayChannel::toCents(1234.56));
    }

    public function test_alipay_build_param_string_sorted_and_excludes_sign(): void
    {
        $params = ['sign' => 'abc', 'sign_type' => 'RSA2', 'b' => '2', 'a' => '1', 'charset' => 'utf-8'];
        $this->assertSame('a=1&b=2&charset=utf-8', AlipayChannel::buildParamString($params));
    }

    public function test_alipay_sign_verify_roundtrip(): void
    {
        $message = AlipayChannel::buildParamString(['out_trade_no' => '123', 'total_amount' => '10.00']);
        $signature = AlipayChannel::sign($message, self::$privateKey);
        $this->assertTrue(AlipayChannel::verify($message, $signature, self::$publicKey));
        $this->assertFalse(AlipayChannel::verify($message . 'x', $signature, self::$publicKey));
    }

    public function test_reconcile_classify_cases(): void
    {
        // 本地已支付、渠道缺失
        $this->assertSame('local_paid_gateway_missing', PaymentService::classify(false, 1, 0.0, 100.0));
        // 一致
        $this->assertSame('ok', PaymentService::classify(true, 1, 100.0, 100.0));
        // 金额不一致
        $this->assertSame('amount_mismatch', PaymentService::classify(true, 1, 99.0, 100.0));
        // 渠道已付、本地待支付、金额一致 → 可自动补齐
        $this->assertSame('gateway_paid_local_pending', PaymentService::classify(true, 0, 100.0, 100.0));
        // 渠道已付、本地待支付、金额不一致
        $this->assertSame('amount_mismatch', PaymentService::classify(true, 0, 50.0, 100.0));
        // 双方未支付
        $this->assertSame('ok', PaymentService::classify(false, 0, 0.0, 100.0));
    }

    public function test_payment_config_has_channel_keys(): void
    {
        $this->assertArrayHasKey('wechat', config('payment.channels', []));
        $this->assertArrayHasKey('alipay', config('payment.channels', []));
        $this->assertContains(config('payment.environment', ''), ['sandbox', 'production']);
    }

    public function test_notify_idempotency_state_machine(): void
    {
        // 仅待支付(0)订单接受入账
        $this->assertTrue(PaymentService::canApplyNotify(0));
        // 重复回调：已支付/已退款/已关闭/处理中 一律拒绝入账
        $this->assertFalse(PaymentService::canApplyNotify(1));
        $this->assertFalse(PaymentService::canApplyNotify(2));
        $this->assertFalse(PaymentService::canApplyNotify(3));
        $this->assertFalse(PaymentService::canApplyNotify(4));
    }

    public function test_apply_bill_payment_math(): void
    {
        // 部分支付 → 仍待支付
        $this->assertSame([150.0, 0], PaymentService::applyBillPayment(100.0, 200.0, 50.0));
        // 恰好缴清 → 已缴清
        $this->assertSame([100.0, 1], PaymentService::applyBillPayment(0.0, 100.0, 100.0));
        // 浮点边界：99.5 + 0.5 = 100 → 已缴清
        $this->assertSame([100.0, 1], PaymentService::applyBillPayment(99.5, 100.0, 0.5));
        // 超缴（重复回调的账单兜底）→ 已缴金额累加但状态保持已缴清
        $this->assertSame([200.0, 1], PaymentService::applyBillPayment(100.0, 100.0, 100.0));
    }

    public function test_payment_order_unique_constraint_in_schema(): void
    {
        $sql = (string) file_get_contents(dirname(__DIR__, 2) . '/docs/install.sql');
        // 支付单号唯一约束：重复回调不会产生第二笔入账记录
        $this->assertMatchesRegularExpression(
            '/CREATE TABLE IF NOT EXISTS `erik_payment_order`.*?UNIQUE KEY `uk_order_number` \(`order_number`\)/s',
            $sql
        );
    }
}
