<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;
use hg\apidoc\annotation as Apidoc;

use app\common\SnowflakeService;
use app\model\FeeBill;
use app\model\FeePayment;
use support\Request;

/**
 * 缴费记录管理
 * @Apidoc\Group("property-core")
 * @Apidoc\Sort(10)
 */
class FeePaymentController extends BaseController
{
    /**
     * 缴费记录列表
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/fee-payment")
     * @Apidoc\Param("keyword", type="string", require=false, desc="搜索关键词（支付单号）")
     * @Apidoc\Param("bill_id", type="string", require=false, desc="账单hashid")
     * @Apidoc\Param("payment_method", type="int", require=false, desc="支付方式: 1=微信 2=支付宝 3=现金 4=银行转账 5=刷卡")
     * @Apidoc\Param("payment_channel", type="int", require=false, desc="渠道: 1=在线 2=线下")
     * @Apidoc\Param(ref="pagination")
     * @Apidoc\Returned("id", type="string", desc="缴费记录hashid")
     * @Apidoc\Returned("payment_number", type="string", desc="支付单号")
     * @Apidoc\Returned("amount", type="float", desc="支付金额")
     * @Apidoc\Returned("paid_at", type="string", desc="支付时间")
     */
    public function index(Request $request)
    {
        $keyword        = $request->input('keyword', '');
        $billId         = $request->input('bill_id');
        $paymentMethod  = $request->input('payment_method');
        $paymentChannel = $request->input('payment_channel');

        $query = FeePayment::query();
        if (!empty($keyword)) {
            $query->where('payment_number', 'like', "%{$keyword}%");
        }
        if (!empty($billId)) {
            $query->where('bill_id', $this->decodeId($billId));
        }
        if ($paymentMethod !== null && $paymentMethod !== '') {
            $query->where('payment_method', (int) $paymentMethod);
        }
        if ($paymentChannel !== null && $paymentChannel !== '') {
            $query->where('payment_channel', (int) $paymentChannel);
        }

        $list = $query->orderBy('paid_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'              => $this->encodeId($item->id),
                    'bill_id'         => $this->encodeId($item->bill_id),
                    'owner_id'        => $item->owner_id ? $this->encodeId($item->owner_id) : '',
                    'payment_number'  => $item->payment_number,
                    'amount'          => $item->amount,
                    'payment_method'  => $item->payment_method,
                    'payment_channel' => $item->payment_channel,
                    'paid_at'         => $item->paid_at ? $item->paid_at->format('Y-m-d H:i') : '',
                    'operator_id'     => $item->operator_id,
                    'receipt_url'     => $item->receipt_url,
                    'remark'          => $item->remark,
                    'created_at'      => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 线下收款
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/fee-payment/offline")
     * @Apidoc\Param("bill_id", type="string", require=true, desc="账单hashid")
     * @Apidoc\Param("amount", type="float", require=true, desc="收款金额")
     * @Apidoc\Param("payment_method", type="int", require=false, desc="支付方式: 1=微信 2=支付宝 3=现金 4=银行转账 5=刷卡")
     * @Apidoc\Param("paid_at", type="string", require=false, desc="收款时间，缺省为当前时间")
     * @Apidoc\Param("receipt_url", type="string", require=false, desc="收据URL")
     * @Apidoc\Param("remark", type="string", require=false, desc="备注")
     * @Apidoc\Returned("id", type="string", desc="缴费记录hashid")
     * @Apidoc\Returned("bill_id", type="string", desc="账单hashid")
     */
    public function offlinePay(Request $request)
    {
        $billId = $request->input('bill_id', '');
        $amount = (float) $request->input('amount', 0);

        if (empty($billId)) {
            return $this->fail('请选择账单', 422);
        }
        $bill = FeeBill::find($this->decodeId($billId));
        if (!$bill) {
            return $this->fail('账单不存在', 404);
        }
        if ($amount <= 0) {
            return $this->fail('收款金额必须大于0', 422);
        }
        if ($bill->status == 2) {
            return $this->fail('账单已缴清，无需再次收款', 422);
        }

        $payment = new FeePayment();
        $payment->id              = SnowflakeService::generate();
        $payment->bill_id         = $bill->id;
        $payment->owner_id        = $bill->owner_id;
        $payment->payment_number  = 'FP' . date('YmdHis') . rand(1000, 9999);
        $payment->amount          = $amount;
        $payment->payment_method  = (int) $request->input('payment_method', 3);
        $payment->payment_channel = 2; // 线下
        $payment->paid_at         = (string) $request->input('paid_at', date('Y-m-d H:i:s'));
        $payment->operator_id     = (int) ($request->adminId ?? 0);
        $payment->receipt_url     = (string) $request->input('receipt_url', '');
        $payment->remark          = (string) $request->input('remark', '');
        $payment->save();

        // 更新账单：累计已缴金额与状态
        $bill->paid_amount = bcadd((string) $bill->paid_amount, (string) $amount, 2);
        $bill->status      = $bill->paid_amount >= $bill->amount ? 2 : 1;
        if ($bill->status == 2) {
            $bill->paid_at = date('Y-m-d H:i:s');
        }
        $bill->save();

        return $this->success([
            'id'      => $this->encodeId($payment->id),
            'bill_id' => $this->encodeId($bill->id),
        ], '收款成功');
    }
}
