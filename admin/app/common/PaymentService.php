<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\common;

use app\common\payment\AlipayChannel;
use app\common\payment\WechatPayChannel;
use app\model\FeeBill;
use app\model\PaymentOrder;
use RuntimeException;
use support\Db;
use support\Log;
use support\Request;

/**
 * 支付编排：下单 → 回调幂等 → 退款 → 对账
 *
 * 渠道未启用/未配置时抛 RuntimeException，由控制器转为业务失败响应。
 */
class PaymentService
{
    private const CHANNELS = ['wechat', 'alipay'];

    public function createOrder(string $channel, int $billId, int $userId, int $userType, string $subject): array
    {
        $this->assertChannelReady($channel);

        $bill = FeeBill::find($billId);
        if (!$bill) {
            throw new RuntimeException('账单不存在');
        }
        if ((int) $bill->status !== 0) {
            throw new RuntimeException('账单非待支付状态');
        }

        $orderNumber = (string) \app\common\SnowflakeService::generate();
        $expireAt = date('Y-m-d H:i:s', time() + (int) config('payment.reconcile.expire_minutes', 15) * 60);
        $notifyUrl = rtrim((string) config('payment.notify_host', ''), '/') . "/payment/{$channel}/callback";

        $order = new PaymentOrder();
        $order->order_number = $orderNumber;
        $order->bill_id      = $billId;
        $order->user_id      = $userId;
        $order->user_type    = $userType;
        $order->amount       = $bill->amount;
        $order->channel      = $channel;
        $order->status       = 0;
        $order->expire_at    = $expireAt;
        $order->save();

        try {
            $payParams = $this->channel($channel)->prepay($orderNumber, $subject, (float) $bill->amount, $notifyUrl);
        } catch (\Throwable $e) {
            // 预下单失败：关闭本地订单，避免遗留无效单
            $order->status = 4;
            $order->save();
            Log::info('payment_prepay_failed', ['order' => $orderNumber, 'error' => $e->getMessage()]);
            throw new RuntimeException('支付下单失败: ' . $e->getMessage());
        }

        return ['order_number' => $orderNumber, 'pay_params' => $payParams, 'expire_at' => $expireAt];
    }

    /**
     * 处理支付回调（幂等）：仅 status=0 的订单可流转，重复回调直接应答成功
     */
    public function handleNotify(string $channel, Request $request): string
    {
        $this->assertChannelReady($channel);

        if ($channel === 'wechat') {
            $body = $request->rawBody();
            $notify = $this->channel('wechat')->verifyNotify($body, $request->header());
        } else {
            $params = $request->all();
            $notify = $this->channel('alipay')->verifyNotify($params);
            $body = json_encode($params, JSON_UNESCAPED_UNICODE);
        }

        if (empty($notify['order_number'])) {
            return $channel === 'wechat' ? '{"code":"SUCCESS","message":"OK"}' : 'success';
        }

        $paidBill = null;
        Db::transaction(function () use ($notify, $body, &$paidBill) {
            $order = PaymentOrder::where('order_number', $notify['order_number'])->first();
            // 幂等：订单不存在或非待支付状态（重复回调）→ 不重复入账，直接应答成功
            if (!$order || !self::canApplyNotify((int) $order->status)) {
                return;
            }
            $updated = PaymentOrder::where('order_number', $notify['order_number'])
                ->where('status', 0)
                ->update([
                    'status'      => 1,
                    'trade_no'    => $notify['trade_no'],
                    'paid_at'     => date('Y-m-d H:i:s'),
                    'notify_data' => $body,
                ]);
            if ($updated === 0) {
                return; // 并发兜底：原子更新失败说明已被其他回调处理
            }
            if ($order->bill_id) {
                $bill = FeeBill::find($order->bill_id);
                if ($bill && (int) $bill->status === 0) {
                    [$bill->paid_amount, $bill->status] = self::applyBillPayment((float) $bill->paid_amount, (float) $bill->amount, (float) $order->amount);
                    if ($bill->status === 1) {
                        $bill->paid_at = date('Y-m-d H:i:s');
                    }
                    $bill->save();
                    if ((int) $bill->status === 1) {
                        $paidBill = $bill;
                    }
                }
            }
        });

        if ($paidBill) {
            $this->fireFeePaid($paidBill, $notify['order_number'] ?? '', $notify['trade_no'] ?? '');
        }

        Log::info('payment_notify_processed', ['channel' => $channel, 'order' => $notify['order_number'], 'paid' => $notify['paid']]);
        return $channel === 'wechat' ? '{"code":"SUCCESS","message":"OK"}' : 'success';
    }

    /** 退款：先调渠道退款，成功后再更新本地 */
    public function refund(int $orderId, float $amount): array
    {
        $order = PaymentOrder::find($orderId);
        if (!$order) {
            throw new RuntimeException('支付订单不存在');
        }
        if ((int) $order->status !== 1) {
            throw new RuntimeException('仅已支付订单可退款');
        }
        if ($amount <= 0 || $amount > (float) $order->amount) {
            throw new RuntimeException('退款金额无效');
        }
        $this->assertChannelReady($order->channel);

        $refundNumber = (string) \app\common\SnowflakeService::generate();
        if ($order->channel === 'wechat') {
            $this->channel('wechat')->refund($order->order_number, $refundNumber, $amount, (float) $order->amount);
        } else {
            $this->channel('alipay')->refund($order->order_number, $refundNumber, $amount);
        }

        $order->status        = 3;
        $order->refund_at     = date('Y-m-d H:i:s');
        $order->refund_amount = $amount;
        $order->save();

        if ($order->bill_id) {
            $bill = FeeBill::find($order->bill_id);
            if ($bill) {
                $bill->paid_amount = max(0, (float) $bill->paid_amount - $amount);
                if ((float) $bill->paid_amount <= 0) {
                    $bill->status = 0;
                }
                $bill->save();
            }
        }

        Log::info('payment_refunded', ['order' => $order->order_number, 'amount' => $amount, 'refund_no' => $refundNumber]);
        return ['order_number' => $order->order_number, 'refund_amount' => $amount];
    }

    /**
     * 对账：回溯 N 天订单，逐单查询渠道状态并分类。
     * 渠道已支付且本地待支付且金额一致 → 自动补齐本地状态；其余标记差异。
     */
    public function reconcile(int $days): array
    {
        $since = date('Y-m-d 00:00:00', strtotime("-{$days} days"));
        $orders = PaymentOrder::where('created_at', '>=', $since)
            ->whereIn('status', [0, 1])
            ->orderBy('id', 'desc')
            ->limit(500)
            ->get();

        $findings = [];
        foreach ($orders as $order) {
            try {
                $gateway = $this->channel($order->channel)->queryOrder($order->order_number);
            } catch (\Throwable $e) {
                $findings[] = ['order_number' => $order->order_number, 'result' => 'query_failed', 'detail' => $e->getMessage()];
                continue;
            }
            $result = self::classify($gateway['paid'], (int) $order->status, (float) $gateway['amount'], (float) $order->amount);

            if ($result === 'gateway_paid_local_pending' && $gateway['amount'] === (float) $order->amount) {
                // 自动补齐（复用幂等更新路径）
                $this->handleGatewayPaid($order, $gateway['trade_no']);
            }
            $findings[] = ['order_number' => $order->order_number, 'result' => $result];
        }

        Log::info('payment_reconcile', ['days' => $days, 'checked' => count($orders), 'findings' => count($findings)]);
        return ['checked' => count($orders), 'findings' => $findings];
    }

    /** 幂等判定（纯函数）：仅待支付状态(0)的订单接受回调/对账入账，重复回调拒之 */
    public static function canApplyNotify(int $orderStatus): bool
    {
        return $orderStatus === 0;
    }

    /** 账单入账计算（纯函数）：返回 [新的已缴金额, 账单状态(0待支付/1已缴清)] */
    public static function applyBillPayment(float $paidAmount, float $amount, float $payAmount): array
    {
        $newPaid = $paidAmount + $payAmount;
        return [$newPaid, $newPaid >= $amount ? 1 : 0];
    }

    /** 对账差异分类（纯函数） */
    public static function classify(bool $gatewayPaid, int $localStatus, float $gatewayAmount, float $localAmount): string
    {
        if ($localStatus === 1) {
            if (!$gatewayPaid) {
                return 'local_paid_gateway_missing';
            }
            return abs($gatewayAmount - $localAmount) > 0.001 ? 'amount_mismatch' : 'ok';
        }
        if ($gatewayPaid) {
            return abs($gatewayAmount - $localAmount) > 0.001 ? 'amount_mismatch' : 'gateway_paid_local_pending';
        }
        return 'ok';
    }

    private function handleGatewayPaid(PaymentOrder $order, string $tradeNo): void
    {
        $paidBill = null;
        Db::transaction(function () use ($order, $tradeNo, &$paidBill) {
            $updated = PaymentOrder::where('order_number', $order->order_number)
                ->where('status', 0)
                ->update(['status' => 1, 'trade_no' => $tradeNo, 'paid_at' => date('Y-m-d H:i:s')]);
            if ($updated === 0) {
                return;
            }
            $bill = $order->bill_id ? FeeBill::find($order->bill_id) : null;
            if ($bill && (int) $bill->status === 0) {
                [$bill->paid_amount, $bill->status] = self::applyBillPayment((float) $bill->paid_amount, (float) $bill->amount, (float) $order->amount);
                $bill->save();
                if ((int) $bill->status === 1) {
                    $paidBill = $bill;
                }
            }
        });
        if ($paidBill) {
            $this->fireFeePaid($paidBill, (string) $order->order_number, $tradeNo);
        }
    }

    /** 费用账单缴清事件（幂等入账路径复用，仅账单由待支付转已缴清时触发） */
    private function fireFeePaid(FeeBill $bill, string $orderNumber, string $tradeNo): void
    {
        WebhookService::dispatch('fee_paid', [
            'bill_id'      => $bill->id,
            'order_number' => $orderNumber,
            'trade_no'     => $tradeNo,
            'amount'       => (float) $bill->paid_amount,
            'paid_at'      => (string) $bill->paid_at,
        ]);
    }

    private function channel(string $channel): WechatPayChannel|AlipayChannel
    {
        $cfg = config("payment.channels.{$channel}", []);
        $environment = (string) config('payment.environment', 'sandbox');
        $timeout = (int) config('payment.timeout', 10);
        return $channel === 'wechat'
            ? new WechatPayChannel($cfg, $environment, $timeout)
            : new AlipayChannel($cfg, $environment, $timeout);
    }

    private function assertChannelReady(string $channel): void
    {
        if (!in_array($channel, self::CHANNELS, true)) {
            throw new RuntimeException('不支持的支付渠道');
        }
        if (!(bool) config('payment.enabled', false) || !(bool) config("payment.channels.{$channel}.enabled", false)) {
            throw new RuntimeException('支付渠道未启用，请先完成支付配置');
        }
        if ((string) config('payment.notify_host', '') === '') {
            throw new RuntimeException('未配置 PAYMENT_NOTIFY_HOST 回调地址');
        }
    }
}
