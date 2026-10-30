<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;
use hg\apidoc\annotation as Apidoc;

use app\common\LockService;
use app\common\SnowflakeService;
use app\model\FeeBill;
use app\model\FeePayment;
use app\model\PaymentOrder;
use support\Db;
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
            ->paginate($this->pageSize($request))
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
        if (in_array($bill->status, [FeeBill::STATUS_PAID, FeeBill::STATUS_WAIVED], true)) {
            return $this->fail('账单已结清或已豁免，无需再次收款', 422);
        }

        // 与 PaymentService::createOrder 共用同一 Redis 锁，串行化线下收款与在线建单
        $lockKey = "lock:payment_create:{$bill->id}";
        $lock = LockService::acquire($lockKey, 15);
        if ($lock === null) {
            return $this->fail('该账单正在处理支付，请稍后再试', 429);
        }

        try {
            $payment = Db::transaction(function () use ($bill, $amount, $request) {
                // 行锁防止并发重复收款
                $locked = FeeBill::lockForUpdate()->find($bill->id);
                // 锁内复核，避免与并发收款/豁免竞态
                if (in_array($locked->status, [FeeBill::STATUS_PAID, FeeBill::STATUS_WAIVED], true)) {
                    throw new \RuntimeException('账单已结清或已豁免，无需再次收款');
                }
                // 与在线支付互斥：待支付订单未过期时禁止线下重复收款
                $pending = PaymentOrder::query()->where('bill_id', $locked->id)
                    ->where('status', 0)
                    ->where('expire_at', '>', date('Y-m-d H:i:s'))
                    ->exists();
                if ($pending) {
                    throw new \RuntimeException('该账单有待支付的在线订单，请等待支付结果或订单过期后再收款');
                }
                $unpaid = $locked->unpaidAmount();
                if (bccomp((string) $amount, $unpaid, 2) > 0) {
                    throw new \RuntimeException('收款金额超过未缴金额');
                }

                $paymentId = SnowflakeService::generate();
                $payment = new FeePayment();
                $payment->id              = $paymentId;
                $payment->bill_id         = $bill->id;
                $payment->owner_id        = $bill->owner_id;
                $payment->payment_number  = 'FP' . date('YmdHis') . substr((string) $paymentId, -8);
                $payment->amount          = $amount;
                $payment->payment_method  = (int) $request->input('payment_method', 3);
                $payment->payment_channel = 2; // 线下
                $payment->paid_at         = (string) $request->input('paid_at', date('Y-m-d H:i:s'));
                $payment->operator_id     = (int) ($request->adminId ?? 0);
                $payment->receipt_url     = (string) $request->input('receipt_url', '');
                $payment->remark          = (string) $request->input('remark', '');
                $payment->save();

                // 更新账单：累计已缴金额与状态（缴足含滞纳金才算已缴）
                $newPaid = bcadd((string) $locked->paid_amount, (string) $amount, 2);
                $locked->paid_amount = $newPaid;
                $locked->status      = FeeBill::statusAfterPayment($newPaid, (string) $locked->amount, (string) $locked->late_fee);
                if ($locked->status === FeeBill::STATUS_PAID) {
                    $locked->paid_at = date('Y-m-d H:i:s');
                }
                $locked->save();

                return $payment;
            });
        } catch (\RuntimeException $e) {
            return $this->fail($e->getMessage(), 422);
        } catch (\Throwable) {
            return $this->fail('收款失败，请稍后重试', 500);
        } finally {
            LockService::release($lockKey, $lock);
        }

        return $this->success([
            'id'      => $this->encodeId($payment->id),
            'bill_id' => $this->encodeId($bill->id),
        ], '收款成功');
    }
}
