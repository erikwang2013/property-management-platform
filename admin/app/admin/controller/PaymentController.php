<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;
use hg\apidoc\annotation as Apidoc;

use app\common\PaymentService;
use app\model\FeeBill;
use app\model\PaymentOrder;
use RuntimeException;
use support\Log;
use support\Request;
use support\Response;

/**
 * 扩展功能
 * @Apidoc\Group("extensions")
 */
class PaymentController extends BaseController
{
    /**
     * 支付订单列表
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/payment-order")
     */
    public function orders(Request $request): Response
    {
        $query = PaymentOrder::query();

        if ($s = $request->input('status')) {
            $query->where('status', (int) $s);
        }
        if ($c = $request->input('channel')) {
            $query->where('channel', $c);
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate(20)
            ->through(fn($i) => [
                'id'            => $this->encodeId($i->id),
                'order_number'  => $i->order_number,
                'bill_id'       => $i->bill_id ? $this->encodeId($i->bill_id) : '',
                'user_id'       => $i->user_id,
                'user_type'     => $i->user_type,
                'amount'        => $i->amount,
                'channel'       => $i->channel,
                'trade_no'      => $i->trade_no,
                'status'        => $i->status,
                'paid_at'       => $i->paid_at ? $i->paid_at->format('Y-m-d H:i') : null,
                'refund_at'     => $i->refund_at ? $i->refund_at->format('Y-m-d H:i') : null,
                'refund_amount' => $i->refund_amount,
                'created_at'    => $i->created_at->format('Y-m-d H:i'),
            ]);

        return $this->success($list);
    }

    /**
     * 支付订单详情（含账单信息）
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/payment-order/{hashid}")
     */
    public function orderShow(Request $request, string $hashid): Response
    {
        $id = $this->decodeId($hashid);
        $order = PaymentOrder::findOrFail($id);

        $bill = null;
        if ($order->bill_id) {
            $bill = FeeBill::with(['feeType:id,name', 'room:id,room_name'])->find($order->bill_id);
        }

        $data = [
            'id'            => $this->encodeId($order->id),
            'order_number'  => $order->order_number,
            'bill_id'       => $order->bill_id ? $this->encodeId($order->bill_id) : '',
            'user_id'       => $order->user_id,
            'user_type'     => $order->user_type,
            'amount'        => $order->amount,
            'channel'       => $order->channel,
            'trade_no'      => $order->trade_no,
            'status'        => $order->status,
            'paid_at'       => $order->paid_at ? $order->paid_at->format('Y-m-d H:i') : null,
            'refund_at'     => $order->refund_at ? $order->refund_at->format('Y-m-d H:i') : null,
            'refund_amount' => $order->refund_amount,
            'expire_at'     => $order->expire_at ? $order->expire_at->format('Y-m-d H:i') : null,
            'created_at'    => $order->created_at->format('Y-m-d H:i'),
            'bill'          => $bill ? [
                'id'          => $this->encodeId($bill->id),
                'bill_number' => $bill->bill_number,
                'amount'      => $bill->amount,
                'paid_amount' => $bill->paid_amount,
                'status'      => $bill->status,
                'fee_type'    => $bill->feeType->name ?? '',
                'room_name'   => $bill->room->room_name ?? '',
            ] : null,
        ];

        return $this->success($data);
    }

    /**
     * 创建支付订单（渠道下单，返回收款二维码）
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/payment-order/create")
     */
    public function create(Request $request): Response
    {
        $billId = $this->decodeId((string) $request->input('bill_id', ''));
        $channel = (string) $request->input('channel', '');
        $userId = (int) $request->input('user_id', 0);
        $userType = (int) $request->input('user_type', 1);
        $subject = (string) $request->input('subject', '物业缴费');

        if (!$billId || !$userId) {
            return $this->fail('缺少账单或支付人', 422);
        }
        if (!in_array($channel, ['wechat', 'alipay'], true)) {
            return $this->fail('不支持的支付渠道', 422);
        }

        try {
            $result = (new PaymentService())->createOrder($channel, $billId, $userId, $userType, $subject);
            return $this->success($result);
        } catch (RuntimeException $e) {
            return $this->fail($e->getMessage(), 422);
        }
    }

    /**
     * 退款（先调渠道退款，成功后再更新本地）
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/payment-order/{hashid}/refund")
     */
    public function refund(Request $request, string $hashid): Response
    {
        $id = $this->decodeId($hashid);
        $amount = (float) $request->input('amount', 0);

        try {
            $result = (new PaymentService())->refund($id, $amount);
            return $this->success($result, '退款成功');
        } catch (RuntimeException $e) {
            return $this->fail($e->getMessage(), 422);
        }
    }

    /**
     * 对账：回溯 N 天订单，逐单与渠道核对并自动补齐漏单
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/payment-order/reconcile")
     */
    public function reconcile(Request $request): Response
    {
        $days = min((int) $request->input('days', 7), 30);
        $days = max($days, 1);

        try {
            return $this->success((new PaymentService())->reconcile($days));
        } catch (RuntimeException $e) {
            return $this->fail($e->getMessage(), 422);
        }
    }

    /**
     * 微信支付回调（v3 验签 + 幂等处理）
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/payment/wechat/callback")
     */
    public function callbackWechat(Request $request): Response
    {
        try {
            $ack = (new PaymentService())->handleNotify('wechat', $request);
            return response($ack, 200, ['Content-Type' => 'application/json']);
        } catch (RuntimeException $e) {
            Log::warning('payment_callback_rejected', ['channel' => 'wechat', 'error' => $e->getMessage()]);
            return response('', 403);
        }
    }

    /**
     * 支付宝支付回调（RSA2 验签 + 幂等处理）
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/payment/alipay/callback")
     */
    public function callbackAlipay(Request $request): Response
    {
        try {
            return response((new PaymentService())->handleNotify('alipay', $request));
        } catch (RuntimeException $e) {
            Log::warning('payment_callback_rejected', ['channel' => 'alipay', 'error' => $e->getMessage()]);
            return response('failure', 400);
        }
    }

    /**
     * 支付统计
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/payment-order/statistics")
     */
    public function statistics(Request $request): Response
    {
        $totalAmount = PaymentOrder::where('status', 1)->sum('amount');
        $totalRefund = PaymentOrder::where('status', 3)->sum('refund_amount');
        $totalOrders = PaymentOrder::count();
        $paidOrders  = PaymentOrder::where('status', 1)->count();

        // 按渠道统计
        $byChannel = PaymentOrder::selectRaw('channel, count(*) as count, sum(amount) as total')
            ->where('status', 1)
            ->groupBy('channel')
            ->get()
            ->map(fn($i) => [
                'channel' => $i->channel,
                'count'   => $i->count,
                'total'   => $i->total,
            ]);

        // 按日期统计（近30天）
        $thirtyDaysAgo = date('Y-m-d', strtotime('-30 days'));
        $byDate = PaymentOrder::selectRaw('DATE(created_at) as date, count(*) as count, sum(amount) as total')
            ->where('status', 1)
            ->where('created_at', '>=', $thirtyDaysAgo)
            ->groupBy('date')
            ->orderBy('date', 'asc')
            ->get()
            ->map(fn($i) => [
                'date'  => $i->date,
                'count' => $i->count,
                'total' => $i->total,
            ]);

        return $this->success([
            'total_amount' => $totalAmount,
            'total_refund' => $totalRefund,
            'total_orders' => $totalOrders,
            'paid_orders'  => $paidOrders,
            'by_channel'   => $byChannel,
            'by_date'      => $byDate,
        ]);
    }
}
