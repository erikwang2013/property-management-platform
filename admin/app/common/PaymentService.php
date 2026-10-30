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
use Webman\RedisQueue\Redis as QueueRedis;

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

        // 同一账单建单串行化：防止双击/多端并发生成多笔支付单导致超收
        $token = LockService::acquire("lock:payment_create:{$billId}", 15);
        if ($token === null) {
            throw new RuntimeException('创建支付单繁忙，请稍后重试');
        }
        try {
            return $this->createOrderLocked($channel, $billId, $userId, $userType, $subject);
        } finally {
            LockService::release("lock:payment_create:{$billId}", $token);
        }
    }
    private function createOrderLocked(string $channel, int $billId, int $userId, int $userType, string $subject): array
    {
        $bill = FeeBill::find($billId);
        if (!$bill) {
            throw new RuntimeException('账单不存在');
        }
        // 未缴/部分缴/逾期可继续支付；已缴清/已豁免拒绝
        if (!in_array((int) $bill->status, [FeeBill::STATUS_UNPAID, FeeBill::STATUS_PARTIAL, FeeBill::STATUS_OVERDUE], true)) {
            throw new RuntimeException('账单非待支付状态');
        }
        // 按待缴金额（含滞纳金）下单，避免部分缴后重复收取全额
        $payAmount = $bill->unpaidAmount();
        if (bccomp($payAmount, '0.00', 2) <= 0) {
            throw new RuntimeException('账单待缴金额无效');
        }

        // 已过期的旧待支付单关闭重建，仍在有效期内的拒绝重复建单
        PaymentOrder::where('bill_id', $billId)
            ->where('status', 0)
            ->where('expire_at', '<', date('Y-m-d H:i:s'))
            ->update(['status' => 4]);
        if (PaymentOrder::where('bill_id', $billId)->where('status', 0)->exists()) {
            throw new RuntimeException('该账单已有待支付订单');
        }

        $orderNumber = (string) \app\common\SnowflakeService::generate();
        $expireAt = date('Y-m-d H:i:s', time() + (int) config('payment.expire_minutes', 15) * 60);
        $notifyUrl = rtrim((string) config('payment.notify_host', ''), '/') . "/payment/{$channel}/callback";

        $order = new PaymentOrder();
        $order->order_number = $orderNumber;
        $order->bill_id      = $billId;
        $order->user_id      = $userId;
        $order->user_type    = $userType;
        $order->amount       = $payAmount;
        $order->channel      = $channel;
        $order->status       = 0;
        $order->expire_at    = $expireAt;
        $order->save();

        try {
            $payParams = $this->gatewayCall(fn () => $this->channel($channel)->prepay($orderNumber, $subject, (float) $payAmount, $notifyUrl, $expireAt));
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
     * 处理支付回调（幂等）：待支付(0)或已关闭(4)订单可入账，重复回调直接应答成功
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

        // 未支付事件回调（挂起/关闭等）应答成功但不入账，避免 WAIT_BUYER_PAY 等被当作已支付
        if (empty($notify['paid'])) {
            Log::info('payment_notify_skipped', ['channel' => $channel, 'order' => $notify['order_number']]);
            return $channel === 'wechat' ? '{"code":"SUCCESS","message":"OK"}' : 'success';
        }

        // 单订单串行化回调处理：获取失败应答失败，渠道会重试（微信/支付宝回调重试语义）
        $orderNumber = (string) $notify['order_number'];
        $token       = LockService::acquire("lock:payment_notify:{$orderNumber}", 30);
        if ($token === null) {
            return $channel === 'wechat' ? '{"code":"FAIL","message":"处理中，请稍后重试"}' : 'failure';
        }

        // 渠道验签后的实付金额（两位小数字符串），与订单金额逐分核对
        $notifyAmount = (string) ($notify['amount'] ?? '0.00');

        // 入账上限模型：订单实付最多抵扣账单剩余待缴金额，超出部分记入订单 credited_amount，
        // 差额在锁外异步退款；退款时先冲溢缴部分，再回退账单已缴金额
        $paidBill = null;
        $overpayOrderId = null;
        try {
            Db::transaction(function () use ($notify, $body, $channel, $notifyAmount, &$paidBill, &$overpayOrderId) {
                $order = PaymentOrder::where('order_number', $notify['order_number'])->first();
                // 幂等：待支付(0)或已关闭(4)订单接受实付回调；已支付/已退款等重复回调直接应答成功
                // 已关闭订单仍可能被渠道晚付，不能静默丢钱
                if (!$order || (!self::canApplyNotify((int) $order->status) && (int) $order->status !== 4)) {
                    return;
                }
                // 金额不符不入账：应答成功止住渠道重试，订单保留待支付等对账人工处理
                if (bccomp((string) $order->amount, $notifyAmount, 2) !== 0) {
                    Log::error('payment_amount_mismatch', ['channel' => $channel, 'order' => $order->order_number, 'expected' => (string) $order->amount, 'notified' => $notifyAmount]);
                    return;
                }
                // 先锁账单行再更新订单，与对账路径保持同一加锁顺序避免死锁
                $bill = $order->bill_id ? FeeBill::lockForUpdate()->find($order->bill_id) : null;
                $credit = $bill ? self::creditAmount((string) $order->amount, $bill->unpaidAmount()) : '0.00';
                $updated = PaymentOrder::where('order_number', $notify['order_number'])
                    ->whereIn('status', [0, 4])
                    ->update([
                        'status'          => 1,
                        'trade_no'        => $notify['trade_no'],
                        'paid_at'         => date('Y-m-d H:i:s'),
                        'credited_amount' => $credit,
                        'notify_data'     => $body,
                    ]);
                if ($updated === 0) {
                    return; // 并发兜底：原子更新失败说明已被其他回调处理
                }
                if ($bill && bccomp($credit, '0.00', 2) > 0) {
                    [$bill->paid_amount, $bill->status] = self::applyBillPayment((string) $bill->paid_amount, (string) $bill->amount, $credit, (string) $bill->late_fee);
                    if ((int) $bill->status === FeeBill::STATUS_PAID) {
                        $bill->paid_at = date('Y-m-d H:i:s');
                        $paidBill = $bill;
                    }
                    $bill->save();
                }
                if (bccomp((string) $order->amount, $credit, 2) > 0) {
                    $overpayOrderId = (int) $order->id;
                }
            });
        } finally {
            LockService::release("lock:payment_notify:{$orderNumber}", $token);
        }

        // 锁已释放再投递 webhook/退款任务：避免持锁执行外部 HTTP
        if ($paidBill) {
            $this->fireFeePaid($paidBill, $notify['order_number'] ?? '', $notify['trade_no'] ?? '');
        }
        if ($overpayOrderId !== null) {
            $overpaidOrder = PaymentOrder::find($overpayOrderId);
            if ($overpaidOrder) {
                $this->enqueueOverpaymentRefund($overpaidOrder);
            }
        }

        Log::info('payment_notify_processed', ['channel' => $channel, 'order' => $notify['order_number'], 'paid' => $notify['paid']]);
        return $channel === 'wechat' ? '{"code":"SUCCESS","message":"OK"}' : 'success';
    }
    /**
     * 退款：加锁串行化 + 锁内重查状态，防止并发双重退款；渠道退款成功后再更新本地。
     * request_id 非空时作为渠道退款幂等键，供调用方响应丢失后安全重试。
     */
    public function refund(int $orderId, float $amount, string $requestId = ''): array
    {
        $token = LockService::acquire("lock:payment_refund:{$orderId}", 30);
        if ($token === null) {
            throw new RuntimeException('退款处理中，请稍后重试');
        }
        try {
            return $this->refundLocked($orderId, $amount, $requestId);
        } finally {
            LockService::release("lock:payment_refund:{$orderId}", $token);
        }
    }
    private function refundLocked(int $orderId, float $amount, string $requestId = ''): array
    {
        $order = PaymentOrder::find($orderId);
        if (!$order) { throw new RuntimeException('支付订单不存在'); }
        // 锁内重查：已支付(1)或已部分退款(3)可继续退；累计金额上限在下方核对
        if (!in_array((int) $order->status, [1, 3], true)) {
            throw new RuntimeException('仅已支付订单可退款');
        }
        // 同一 request_id 已成功落账：直接返回既有结果，避免渠道幂等但本地重复扣减账单
        if ($requestId !== '' && (string) $order->refund_request_id === $requestId) {
            return ['order_number' => (string) $order->order_number, 'refund_amount' => (float) $order->refund_amount];
        }
        $refund = number_format($amount, 2, '.', '');
        if (bccomp($refund, '0.00', 2) <= 0) { throw new RuntimeException('退款金额无效'); }
        $refunded = (string) ($order->refund_amount ?: '0.00');
        $newCumulative = bcadd($refunded, $refund, 2);
        if (bccomp($newCumulative, (string) $order->amount, 2) > 0) { throw new RuntimeException('退款金额超过订单金额'); }
        $this->assertChannelReady($order->channel);

        // 幂等键：调用方 request_id 优先（响应丢失重试复用同一退款单号），否则按累计退款金额生成
        if ($requestId !== '') {
            $refundNumber = substr('RF' . hash('sha256', $orderId . '|' . $requestId . '|' . $refund), 0, 64);
        } else {
            $refundNumber = substr('RF' . $order->order_number . '_' . (int) round((float) $newCumulative * 100), 0, 64);
        }
        // 渠道调用必须在 DB 事务外：不持库锁执行外部 HTTP
        $this->gatewayCall(function () use ($order, $refundNumber, $refund) {
            if ($order->channel === 'wechat') {
                $this->channel('wechat')->refund($order->order_number, $refundNumber, (float) $refund, (float) $order->amount);
            } else {
                $this->channel('alipay')->refund($order->order_number, $refundNumber, (float) $refund);
            }
        });

        $result = ['order_number' => $order->order_number, 'refund_amount' => (float) $newCumulative];
        $replayed = false;
        Db::transaction(function () use ($order, $orderId, $refund, $newCumulative, $refundNumber, $requestId, &$result, &$replayed) {
            // 与回调/对账路径同序：先锁账单行再锁订单行，避免交叉死锁
            $bill = $order->bill_id ? FeeBill::lockForUpdate()->find($order->bill_id) : null;
            $locked = PaymentOrder::lockForUpdate()->find($orderId);
            if (!$locked) { throw new RuntimeException('支付订单不存在'); }
            // 并发重放同一 request_id：渠道调用已幂等，本地不再落账
            if ($requestId !== '' && (string) $locked->refund_request_id === $requestId) {
                $result['refund_amount'] = (float) $locked->refund_amount;
                $replayed = true;
                return;
            }
            // Redis 锁已串行化同单退款，锁内状态/累计异常只可能是 bug，直接抛出暴露
            if (!in_array((int) $locked->status, [1, 3], true)) { throw new RuntimeException('订单状态已变更，退款未落账'); }
            $refunded = (string) ($locked->refund_amount ?: '0.00');
            $cumulative = bcadd($refunded, $refund, 2);
            if (bccomp($cumulative, (string) $locked->amount, 2) > 0) { throw new RuntimeException('退款金额超过订单金额'); }
            // 正常应一致；不一致说明订单状态被外部改动，以锁定行 + 本次实际退款金额为准继续落账
            if (bccomp($cumulative, $newCumulative, 2) !== 0) { Log::warning('payment_refund_cumulative_changed', ['order' => $locked->order_number, 'expected' => $newCumulative, 'actual' => $cumulative, 'refund_no' => $refundNumber]); }
            // 未落 credited_amount 的历史订单按全额入账处理，避免误判溢缴
            $credited = (string) $locked->credited_amount;
            if ($credited === '') { $credited = (string) $locked->amount; }
            $excess = bcsub((string) $locked->amount, $credited, 2);
            // 先退溢缴部分：只有累计退款超出溢缴额的部分才回退账单已缴金额
            $prevReduction = bcsub($refunded, $excess, 2);
            $newReduction = bcsub($cumulative, $excess, 2);
            $excess = bccomp($excess, '0.00', 2) < 0 ? '0.00' : $excess;
            $prevReduction = bccomp($prevReduction, '0.00', 2) < 0 ? '0.00' : $prevReduction;
            $newReduction = bccomp($newReduction, '0.00', 2) < 0 ? '0.00' : $newReduction;
            $billDelta = bcsub($newReduction, $prevReduction, 2);

            $locked->refund_amount = $cumulative;
            // 累计退满转已退款(3)，部分退款保持已支付(1)
            $locked->status    = bccomp($cumulative, (string) $locked->amount, 2) >= 0 ? 3 : 1;
            $locked->refund_at = date('Y-m-d H:i:s');
            if ($requestId !== '') {
                $locked->refund_request_id = $requestId;
            }
            $locked->save();

            // billDelta=0 表示本次只是退溢缴部分，账单不受影响
            if ($bill && bccomp($billDelta, '0.00', 2) > 0) {
                $bill->paid_amount = bcsub((string) $bill->paid_amount, $billDelta, 2);
                if (bccomp((string) $bill->paid_amount, '0.00', 2) < 0) { $bill->paid_amount = '0.00'; }
                // 豁免账单退款只回退已缴金额，不得把 WAIVED 重新变回欠费状态
                if ((int) $bill->status !== FeeBill::STATUS_WAIVED) {
                    $bill->status = bccomp((string) $bill->paid_amount, '0.00', 2) <= 0
                        ? FeeBill::STATUS_UNPAID
                        : FeeBill::statusAfterPayment((string) $bill->paid_amount, (string) $bill->amount, (string) $bill->late_fee);
                    if ((int) $bill->status !== FeeBill::STATUS_PAID) {
                        $bill->paid_at = null;
                    }
                }
                $bill->save();
            }
            $result['refund_amount'] = (float) $cumulative;
        });

        Log::info('payment_refunded', ['order' => $result['order_number'], 'amount' => $refund, 'total_refunded' => $result['refund_amount'], 'refund_no' => $refundNumber, 'replayed' => $replayed]);
        return $result;
    }

    /**
     * 对账：回溯 N 天订单，逐单查询渠道状态并分类。
     * 渠道已支付且本地待支付且金额一致 → 自动补齐本地状态；其余标记差异。
     */
    public function reconcile(int $days): array
    {
        $since = date('Y-m-d 00:00:00', strtotime("-{$days} days"));
        $orders = PaymentOrder::where('created_at', '>=', $since)
            ->whereIn('status', [0, 1, 4])
            ->orderBy('id', 'desc')
            ->limit(500)
            ->get();

        $findings = [];
        foreach ($orders as $order) {
            try {
                $gateway = $this->gatewayCall(fn () => $this->channel($order->channel)->queryOrder($order->order_number));
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

        // 修复队列发送失败/消费者丢失：已支付但未退足溢缴的订单重新入队（幂等，已退足会跳过）
        $overpaid = PaymentOrder::where('status', 1)->whereRaw('credited_amount < amount')->orderBy('id', 'desc')->limit(500)->get();
        foreach ($overpaid as $overpaidOrder) { $this->enqueueOverpaymentRefund($overpaidOrder); }

        Log::info('payment_reconcile', ['days' => $days, 'checked' => count($orders), 'findings' => count($findings), 'overpay_scanned' => count($overpaid)]);
        return ['checked' => count($orders), 'findings' => $findings, 'overpay_scanned' => count($overpaid)];
    }

    /** 幂等判定（纯函数）：仅待支付状态(0)的订单接受回调/对账入账，重复回调拒之 */
    public static function canApplyNotify(int $orderStatus): bool
    {
        return $orderStatus === 0;
    }

    /** 账单入账计算（纯函数）：返回 [新的已缴金额(两位小数字符串), 账单状态] */
    public static function applyBillPayment(string $paidAmount, string $amount, string $payAmount, string $lateFee = '0.00'): array
    {
        $newPaid = bcadd($paidAmount, $payAmount, 2);
        return [$newPaid, FeeBill::statusAfterPayment($newPaid, $amount, $lateFee)];
    }

    /**
     * 入账上限（纯函数）：账单剩余待缴为 0 时不入账，否则取实付与待缴的较小值。
     * 返回所选原字符串，不做重格式化。
     */
    public static function creditAmount(string $orderAmount, string $unpaid): string
    {
        if (bccomp($unpaid, '0.00', 2) <= 0) {
            return '0.00';
        }
        return bccomp($orderAmount, $unpaid, 2) < 0 ? $orderAmount : $unpaid;
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
        $overpayOrderId = null;
        Db::transaction(function () use ($order, $tradeNo, &$paidBill, &$overpayOrderId) {
            // 与回调路径同序：先锁账单行，再原子更新订单，最后回填账单
            $bill = $order->bill_id ? FeeBill::lockForUpdate()->find($order->bill_id) : null;
            $credit = $bill ? self::creditAmount((string) $order->amount, $bill->unpaidAmount()) : '0.00';
            $updated = PaymentOrder::where('order_number', $order->order_number)
                ->whereIn('status', [0, 4])
                ->update([
                    'status'          => 1,
                    'trade_no'        => $tradeNo,
                    'paid_at'         => date('Y-m-d H:i:s'),
                    'credited_amount' => $credit,
                ]);
            if ($updated === 0) {
                return;
            }
            if ($bill && bccomp($credit, '0.00', 2) > 0) {
                [$bill->paid_amount, $bill->status] = self::applyBillPayment((string) $bill->paid_amount, (string) $bill->amount, $credit, (string) $bill->late_fee);
                if ((int) $bill->status === FeeBill::STATUS_PAID) {
                    $bill->paid_at = date('Y-m-d H:i:s');
                    $paidBill = $bill;
                }
                $bill->save();
            }
            if (bccomp((string) $order->amount, $credit, 2) > 0) {
                $overpayOrderId = (int) $order->id;
            }
        });
        if ($paidBill) {
            $this->fireFeePaid($paidBill, (string) $order->order_number, $tradeNo);
        }
        if ($overpayOrderId !== null) {
            $overpaidOrder = PaymentOrder::find($overpayOrderId);
            if ($overpaidOrder) {
                $this->enqueueOverpaymentRefund($overpaidOrder);
            }
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

    /** 溢缴退款入队（锁外调用）：未退足差额时投递，失败只记日志不影响回调结果 */
    private function enqueueOverpaymentRefund(PaymentOrder $order): void
    {
        $credited = (string) $order->credited_amount;
        if ($credited === '') { $credited = (string) $order->amount; }
        $excess = bcsub((string) $order->amount, $credited, 2);
        if (bccomp($excess, '0.00', 2) <= 0) {
            return;
        }
        $refunded = (string) ($order->refund_amount ?: '0.00');
        if (bccomp($excess, $refunded, 2) <= 0) {
            return; // 已退足
        }
        try {
            QueueRedis::send('payment_overpay_refund', ['order_id' => $order->id]);
        } catch (\Throwable $e) {
            Log::error('payment_overpay_enqueue_failed', ['order' => $order->order_number, 'error' => $e->getMessage()]);
        }
    }

    /** 熔断保护的外部网关调用：open 快速失败，成功复位计数，失败累计计数 */
    private function gatewayCall(callable $fn)
    {
        $breaker = new CircuitBreaker('payment', config('circuit.payment', []));
        if (!$breaker->canProceed()) {
            throw new RuntimeException('支付网关暂不可用，请稍后重试');
        }
        try {
            $result = $fn();
            $breaker->recordSuccess();
            return $result;
        } catch (\Throwable $e) {
            $breaker->recordFailure();
            throw $e;
        }
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
