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
                    'unpaid_amount' => $bill->unpaidAmount(),
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
            'unpaid_amount' => $bill->unpaidAmount(),
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
        $billHashid = $request->input('bill_id');

        $query = FeePayment::where('owner_id', $ownerId);
        if ($billHashid !== null && $billHashid !== '') {
            try {
                $query->where('bill_id', $this->decodeId((string) $billHashid));
            } catch (InvalidArgumentException) {
                return $this->fail('无效的账单ID', 404);
            }
        }

        $payments = $query
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
        // 业务端未接入支付网关，禁止自助记账：避免无实际扣款却将账单标记为已缴
        return $this->fail('在线支付暂未开通，请通过管理端支付订单或到物业前台缴费', 503);
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
            ->join('management_fee_type', 'management_fee_bill.fee_type_id', '=', 'management_fee_type.id')
            ->select(Db::raw('management_fee_type.category'), Db::raw('SUM(management_fee_bill.amount) as total'))
            ->groupBy('management_fee_type.category')
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
