<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;

use app\model\FeeBill;
use app\model\PaymentOrder;
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
     * GET /admin/payment-order?status=&channel=&page=
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
     * GET /admin/payment-order/{hashid}
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
     * 退款
     * POST /admin/payment-order/{hashid}/refund
     */
    public function refund(Request $request, string $hashid): Response
    {
        $id = $this->decodeId($hashid);
        $order = PaymentOrder::findOrFail($id);

        if ($order->status != 1) {
            return $this->fail('仅已支付订单可退款', 422);
        }

        $amount = (float) $request->input('amount', 0);
        if ($amount <= 0 || $amount > $order->amount) {
            return $this->fail('退款金额无效', 422);
        }

        $order->status        = 3;
        $order->refund_at     = date('Y-m-d H:i:s');
        $order->refund_amount = $amount;
        $order->save();

        // 同步更新账单的已付金额
        if ($order->bill_id) {
            $bill = FeeBill::find($order->bill_id);
            if ($bill) {
                $bill->paid_amount = max(0, $bill->paid_amount - $amount);
                if ($bill->paid_amount <= 0) {
                    $bill->status = 0;
                }
                $bill->save();
            }
        }

        return $this->success([], '退款成功');
    }

    /**
     * 微信支付回调
     * POST /admin/payment/callback/wechat (公开路由)
     */
    public function callbackWechat(Request $request): Response
    {
        $notifyData = $request->all();

        // 记录回调数据用于排查
        if (empty($notifyData)) {
            $notifyData = $request->rawBody();
        }

        // 验证签名（实际项目中应使用微信SDK验签）
        // $verified = $this->verifyWechatSign($notifyData);
        // if (!$verified) { return $this->fail('签名验证失败', 400); }

        // 解析订单号并更新状态
        $orderNumber = $notifyData['out_trade_no'] ?? '';
        if (empty($orderNumber)) {
            return $this->fail('缺少订单号', 400);
        }

        $order = PaymentOrder::where('order_number', $orderNumber)->first();
        if (!$order) {
            return $this->fail('订单不存在', 404);
        }

        if ($order->status == 0) {
            $order->status    = 1;
            $order->trade_no  = $notifyData['transaction_id'] ?? '';
            $order->paid_at   = date('Y-m-d H:i:s');
            $order->notify_data = $notifyData;
            $order->save();

            // 更新账单状态
            if ($order->bill_id) {
                $bill = FeeBill::find($order->bill_id);
                if ($bill && $bill->status == 0) {
                    $bill->paid_amount = $bill->paid_amount + $order->amount;
                    $bill->status = $bill->paid_amount >= $bill->amount ? 1 : 0;
                    if ($bill->status == 1) {
                        $bill->paid_at = date('Y-m-d H:i:s');
                    }
                    $bill->save();
                }
            }
        }

        // 返回成功应答给微信
        return response('<xml><return_code><![CDATA[SUCCESS]]></return_code><return_msg><![CDATA[OK]]></return_msg></xml>', 200, ['Content-Type' => 'application/xml']);
    }

    /**
     * 支付宝支付回调
     * POST /admin/payment/callback/alipay (公开路由)
     */
    public function callbackAlipay(Request $request): Response
    {
        $notifyData = $request->all();

        if (empty($notifyData)) {
            $notifyData = $request->rawBody();
        }

        // 验证签名（实际项目中应使用支付宝SDK验签）
        // $verified = $this->verifyAlipaySign($notifyData);
        // if (!$verified) { return $this->fail('签名验证失败', 400); }

        $orderNumber = $notifyData['out_trade_no'] ?? '';
        $tradeStatus = $notifyData['trade_status'] ?? '';

        if (empty($orderNumber)) {
            return $this->fail('缺少订单号', 400);
        }

        $order = PaymentOrder::where('order_number', $orderNumber)->first();
        if (!$order) {
            return $this->fail('订单不存在', 404);
        }

        // TRADE_SUCCESS 或 TRADE_FINISHED 表示支付成功
        if (in_array($tradeStatus, ['TRADE_SUCCESS', 'TRADE_FINISHED']) && $order->status == 0) {
            $order->status      = 1;
            $order->trade_no    = $notifyData['trade_no'] ?? '';
            $order->paid_at     = date('Y-m-d H:i:s');
            $order->notify_data = $notifyData;
            $order->save();

            // 更新账单状态
            if ($order->bill_id) {
                $bill = FeeBill::find($order->bill_id);
                if ($bill && $bill->status == 0) {
                    $bill->paid_amount = $bill->paid_amount + $order->amount;
                    $bill->status = $bill->paid_amount >= $bill->amount ? 1 : 0;
                    if ($bill->status == 1) {
                        $bill->paid_at = date('Y-m-d H:i:s');
                    }
                    $bill->save();
                }
            }
        }

        return response('success');
    }

    /**
     * 支付统计
     * GET /admin/payment/statistics
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
