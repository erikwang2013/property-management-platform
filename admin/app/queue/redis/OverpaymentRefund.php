<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\queue\redis;

use app\common\PaymentService;
use app\model\PaymentOrder;
use Webman\RedisQueue\Consumer;

/**
 * 溢缴退款任务：线上实付超出账单可入账金额时，异步退还差额。
 *
 * 退款失败抛异常由队列框架重试（max_attempts=5）；重复消费安全：
 * refund() 按累计退款金额幂等，剩余可退金额 <= 0 时直接结束。
 */
class OverpaymentRefund implements Consumer
{
    // 要消费的队列名，对应 PaymentService::enqueueOverpaymentRefund 的入队目标
    public $queue = 'payment_overpay_refund';

    // 连接名，对应 config/plugin/webman/redis-queue/redis.php 里的连接
    public $connection = 'default';

    public function consume($data)
    {
        $orderId = (int) ($data['order_id'] ?? 0);
        if ($orderId <= 0) {
            return;
        }
        $order = PaymentOrder::find($orderId);
        if (!$order) {
            return;
        }

        // 未落 credited_amount 的历史订单按全额入账处理，无溢缴
        $credited = (string) $order->credited_amount;
        if ($credited === '') {
            $credited = (string) $order->amount;
        }
        $excess = bcsub((string) $order->amount, $credited, 2);
        if (bccomp($excess, '0.00', 2) < 0) {
            $excess = '0.00';
        }
        $already = (string) ($order->refund_amount ?? '0.00');
        if ($already === '') {
            $already = '0.00';
        }
        $remaining = bcsub($excess, $already, 2);
        if (bccomp($remaining, '0.00', 2) <= 0) {
            return;
        }

        // 失败不捕获：抛异常交给队列框架重试；固定 request_id 让重复/并发任务本地去重
        (new PaymentService())->refund($orderId, (float) $remaining, 'overpay:' . $orderId);
    }
}
