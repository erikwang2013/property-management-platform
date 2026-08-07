<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;
use hg\apidoc\annotation as Apidoc;

use app\common\BaseController;
use app\model\FeeBill;
use app\model\FeePayment;
use app\model\FeeType;
use support\Request;
use support\Response;
use support\Db;
use InvalidArgumentException;

/**
 * 费用管理
 * @Apidoc\Group("fee")
 * @Apidoc\Sort(1)
 */
class FeeController extends BaseController
{
    /**
     * 账单列表（分页）
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/service/fees/bills")
     */
    public function bills(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);
        $page    = (int) $request->input('page', 1);
        $status  = $request->input('status');

        $query = FeeBill::where('owner_id', $ownerId)
            ->with(['feeType', 'room']);

        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        }

        $bills = $query->orderBy('created_at', 'desc')
            ->paginate(20, ['*'], 'page', $page)
            ->through(function ($bill) {
                return [
                    'id'            => $this->encodeId($bill->id),
                    'bill_number'   => $bill->bill_number,
                    'amount'        => $bill->amount,
                    'paid_amount'   => $bill->paid_amount,
                    'late_fee'      => $bill->late_fee,
                    'unpaid_amount' => max($bill->amount - $bill->paid_amount + $bill->late_fee, 0),
                    'status'        => $bill->status,
                    'due_date'      => $bill->due_date ? $bill->due_date->format('Y-m-d') : '',
                    'fee_type_name' => $bill->feeType->name ?? '',
                    'room_number'   => $bill->room->room_number ?? '',
                    'start_date'    => $bill->start_date ? $bill->start_date->format('Y-m-d') : '',
                    'end_date'      => $bill->end_date ? $bill->end_date->format('Y-m-d') : '',
                    'created_at'    => $bill->created_at ? $bill->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($bills);
    }

    /**
     * 账单详情
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/service/fees/bill/{hashid}")
     */
    public function billDetail(Request $request, string $hashid): Response
    {
        try {
            $billId = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的账单ID', 404);
        }

        $ownerId = $this->getOwnerId($request);

        $bill = FeeBill::where('owner_id', $ownerId)
            ->with(['feeType', 'room', 'payments'])
            ->find($billId);

        if (!$bill) {
            return $this->fail('账单不存在或无权访问', 404);
        }

        $data = [
            'id'            => $this->encodeId($bill->id),
            'bill_number'   => $bill->bill_number,
            'amount'        => $bill->amount,
            'paid_amount'   => $bill->paid_amount,
            'late_fee'      => $bill->late_fee,
            'unpaid_amount' => max($bill->amount - $bill->paid_amount + $bill->late_fee, 0),
            'status'        => $bill->status,
            'start_date'    => $bill->start_date ? $bill->start_date->format('Y-m-d') : '',
            'end_date'      => $bill->end_date ? $bill->end_date->format('Y-m-d') : '',
            'due_date'      => $bill->due_date ? $bill->due_date->format('Y-m-d') : '',
            'paid_at'       => $bill->paid_at ? $bill->paid_at->format('Y-m-d H:i') : '',
            'remark'        => $bill->remark,
            'fee_type'      => $bill->feeType ? [
                'id'   => $this->encodeId($bill->feeType->id),
                'name' => $bill->feeType->name,
                'category' => $bill->feeType->category,
            ] : null,
            'room'          => $bill->room ? [
                'id'          => $this->encodeId($bill->room->id),
                'room_number' => $bill->room->room_number,
            ] : null,
            'payments'      => $bill->payments->map(function ($payment) {
                return [
                    'id'              => $this->encodeId($payment->id),
                    'payment_number'  => $payment->payment_number,
                    'amount'          => $payment->amount,
                    'payment_method'  => $payment->payment_method,
                    'payment_channel' => $payment->payment_channel,
                    'paid_at'         => $payment->paid_at ? $payment->paid_at->format('Y-m-d H:i') : '',
                ];
            })->values(),
        ];

        return $this->success($data);
    }

    /**
     * 缴费记录
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/service/fees/payments")
     */
    public function payments(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);
        $page    = (int) $request->input('page', 1);

        $payments = FeePayment::where('owner_id', $ownerId)
            ->with(['bill.feeType', 'bill.room'])
            ->orderBy('created_at', 'desc')
            ->paginate(20, ['*'], 'page', $page)
            ->through(function ($payment) {
                return [
                    'id'              => $this->encodeId($payment->id),
                    'payment_number'  => $payment->payment_number,
                    'amount'          => $payment->amount,
                    'payment_method'  => $payment->payment_method,
                    'payment_channel' => $payment->payment_channel,
                    'paid_at'         => $payment->paid_at ? $payment->paid_at->format('Y-m-d H:i') : '',
                    'bill_number'     => $payment->bill->bill_number ?? '',
                    'fee_type_name'   => $payment->bill->feeType->name ?? '',
                    'room_number'     => $payment->bill->room->room_number ?? '',
                ];
            });

        return $this->success($payments);
    }

    /**
     * 在线缴费
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/service/fees/pay")
     */
    public function pay(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);
        $billHashid = $request->input('bill_id', '');
        $amount     = (float) $request->input('amount', 0);
        $paymentMethod = $request->input('payment_method', 'online');
        $paymentChannel = $request->input('payment_channel', '');
        $password   = $request->input('password', '');

        // 密码确认
        $confirmError = $this->confirmPassword($ownerId, $password);
        if ($confirmError !== null) {
            return $this->fail($confirmError, 422);
        }

        if (empty($billHashid)) {
            return $this->fail('缺少账单ID', 422);
        }

        if ($amount <= 0) {
            return $this->fail('金额必须大于0', 422);
        }

        try {
            $billId = $this->decodeId($billHashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的账单ID', 404);
        }

        $bill = FeeBill::where('owner_id', $ownerId)->find($billId);
        if (!$bill) {
            return $this->fail('账单不存在或无权操作', 404);
        }

        if ($bill->status === 1) {
            return $this->fail('该账单已缴清', 422);
        }

        $unpaidAmount = $bill->amount - $bill->paid_amount + $bill->late_fee;
        if ($amount > $unpaidAmount) {
            return $this->fail('支付金额不能超过待缴金额', 422);
        }

        // 幂等：30 秒内同一账单同金额的重复请求直接返回既有支付记录，避免重复扣费
        $recent = FeePayment::where('bill_id', $billId)
            ->where('owner_id', $ownerId)
            ->where('amount', $amount)
            ->where('paid_at', '>=', date('Y-m-d H:i:s', time() - 30))
            ->first();
        if ($recent) {
            return $this->success([
                'payment_number' => $recent->payment_number,
                'amount'         => $amount,
                'paid_amount'    => $bill->paid_amount,
                'bill_status'    => $bill->status,
            ], '缴费成功');
        }

        // 支付流水与账单更新放入同一事务，避免创建成功但账单未更新的不一致状态
        try {
            [$paymentNumber, $newPaidAmount, $newStatus] = Db::transaction(function () use ($ownerId, $bill, $amount, $paymentMethod, $paymentChannel) {
                $paymentId = $this->generateId();
                $paymentNumber = 'PAY' . date('YmdHis') . mt_rand(100, 999);

                FeePayment::create([
                    'id'              => $paymentId,
                    'bill_id'         => $bill->id,
                    'owner_id'        => $ownerId,
                    'payment_number'  => $paymentNumber,
                    'amount'          => $amount,
                    'payment_method'  => $paymentMethod,
                    'payment_channel' => $paymentChannel,
                    'paid_at'         => date('Y-m-d H:i:s'),
                ]);

                $newPaidAmount = $bill->paid_amount + $amount;
                $newStatus = ($newPaidAmount >= $bill->amount + $bill->late_fee) ? 1 : 3;
                $bill->paid_amount = $newPaidAmount;
                $bill->status = $newStatus;
                if ($newStatus === 1) {
                    $bill->paid_at = date('Y-m-d H:i:s');
                }
                $bill->save();

                return [$paymentNumber, $newPaidAmount, $newStatus];
            });
        } catch (\Throwable) {
            return $this->fail('支付失败，请稍后重试', 500);
        }

        return $this->success([
            'payment_number' => $paymentNumber,
            'amount'         => $amount,
            'paid_amount'    => $newPaidAmount,
            'bill_status'    => $newStatus,
        ], '缴费成功');
    }

    /**
     * 费用统计
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/service/fees/statistics")
     */
    public function statistics(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);
        $year    = (int) $request->input('year', date('Y'));

        // 年度月度总额
        $monthlyTotals = FeeBill::where('owner_id', $ownerId)
            ->whereYear('created_at', (string) $year)
            ->select(Db::raw('MONTH(created_at) as month'), Db::raw('SUM(amount) as total'))
            ->groupBy(Db::raw('MONTH(created_at)'))
            ->get()
            ->keyBy('month');

        // 分类统计
        $categoryStats = FeeBill::where('owner_id', $ownerId)
            ->whereYear('created_at', (string) $year)
            ->join('erik_fee_type', 'erik_fee_bill.fee_type_id', '=', 'erik_fee_type.id')
            ->select(Db::raw('erik_fee_type.category'), Db::raw('SUM(erik_fee_bill.amount) as total'))
            ->groupBy('erik_fee_type.category')
            ->get()
            ->map(function ($item) {
                return [
                    'category' => $item->category,
                    'total'    => $item->total,
                ];
            });

        // 汇总
        $yearTotal = FeeBill::where('owner_id', $ownerId)
            ->whereYear('created_at', (string) $year)
            ->sum('amount');

        $months = [];
        for ($m = 1; $m <= 12; $m++) {
            $months[] = [
                'month' => $m,
                'total' => (float) ($monthlyTotals[$m]->total ?? 0),
            ];
        }

        return $this->success([
            'year'       => $year,
            'year_total' => (float) $yearTotal,
            'months'     => $months,
            'categories' => $categoryStats,
        ]);
    }
}
