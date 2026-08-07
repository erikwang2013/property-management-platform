<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;
use hg\apidoc\annotation as Apidoc;

use app\common\SnowflakeService;
use app\model\FinanceIncome;
use app\model\FinanceExpense;
use support\Db;
use support\Request;

/**
 * 物业管理·辅助
 * @Apidoc\Group("property-aux")
 */
class FinanceController extends BaseController
{
    /**
     * 检测当前请求是否为收入（否则为支出）
     */
    private function isIncome(Request $request): bool
    {
        return str_contains($request->path(), 'finance-income');
    }

    // ============================================================
    // 标准资源方法（Route::resource 需要，按 path 分流到收入/支出）
    // ============================================================

    /**
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/finance-income")
     */
    public function index(Request $request)
    {
        return $this->isIncome($request) ? $this->incomeIndex($request) : $this->expenseIndex($request);
    }

    /**
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/finance-income/{hashid}")
     */
    public function show(Request $request, string $hashid)
    {
        return $this->isIncome($request) ? $this->incomeShow($request, $hashid) : $this->expenseShow($request, $hashid);
    }

    /**
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/finance-income")
     */
    public function store(Request $request)
    {
        return $this->isIncome($request) ? $this->incomeStore($request) : $this->expenseStore($request);
    }

    /**
     * @Apidoc\Method("PUT")
     * @Apidoc\Url("/admin/finance-income/{hashid}")
     */
    public function update(Request $request, string $hashid)
    {
        return $this->isIncome($request) ? $this->incomeUpdate($request, $hashid) : $this->expenseUpdate($request, $hashid);
    }

    /**
     * @Apidoc\Method("DELETE")
     * @Apidoc\Url("/admin/finance-income/{hashid}")
     */
    public function destroy(Request $request, string $hashid)
    {
        return $this->isIncome($request) ? $this->incomeDestroy($request, $hashid) : $this->expenseDestroy($request, $hashid);
    }

    // ============================================================
    // 财务收入
    // ============================================================

    /**
     * 收入列表
     * GET /admin/finance-income
     * ?income_type=xxx&start_date=xxx&end_date=xxx&page_size=20
     */
    public function incomeIndex(Request $request)
    {
        $incomeType = $request->input('income_type');
        $startDate  = $request->input('start_date', '');
        $endDate    = $request->input('end_date', '');

        $query = FinanceIncome::query();

        if ($incomeType !== null && $incomeType !== '') {
            $query->where('income_type', (int) $incomeType);
        }
        if (!empty($startDate)) {
            $query->where('income_date', '>=', $startDate);
        }
        if (!empty($endDate)) {
            $query->where('income_date', '<=', $endDate);
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'             => $this->encodeId($item->id),
                    'income_number'  => $item->income_number,
                    'income_type'    => $item->income_type,
                    'amount'         => $item->amount,
                    'payer_type'     => $item->payer_type,
                    'payer_id'       => $item->payer_id ? $this->encodeId($item->payer_id) : '',
                    'payment_method'  => $item->payment_method,
                    'income_date'    => $item->income_date ? $item->income_date->format('Y-m-d') : '',
                    'operator_id'    => $item->operator_id ? $this->encodeId($item->operator_id) : '',
                    'remark'         => $item->remark,
                    'created_at'     => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /** 收入详情 */
    public function incomeShow(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = FinanceIncome::find($id);
        if (!$item) {
            return $this->fail('收入记录不存在', 404);
        }

        return $this->success([
            'id'             => $this->encodeId($item->id),
            'income_number'  => $item->income_number,
            'income_type'    => $item->income_type,
            'amount'         => $item->amount,
            'payer_type'     => $item->payer_type,
            'payer_id'       => $item->payer_id ? $this->encodeId($item->payer_id) : '',
            'payment_method' => $item->payment_method,
            'income_date'    => $item->income_date ? $item->income_date->format('Y-m-d') : '',
            'operator_id'    => $item->operator_id ? $this->encodeId($item->operator_id) : '',
            'remark'         => $item->remark,
            'created_at'     => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
            'updated_at'     => $item->updated_at ? $item->updated_at->format('Y-m-d H:i') : '',
        ]);
    }

    /** 创建收入 */
    public function incomeStore(Request $request)
    {
        $data = $request->only([
            'income_type', 'amount', 'payer_type', 'payer_id',
            'payment_method', 'income_date', 'operator_id', 'remark',
        ]);

        if (empty($data['amount'])) {
            return $this->fail('金额不能为空', 422);
        }

        $id = SnowflakeService::generate();
        $data['id']            = $id;
        $data['income_number'] = 'INC' . date('YmdHis') . str_pad((string) mt_rand(0, 9999), 4, '0', STR_PAD_LEFT);

        FinanceIncome::create($data);

        return $this->success(['id' => $this->encodeId($id)], '创建成功');
    }

    /** 更新收入 */
    public function incomeUpdate(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = FinanceIncome::find($id);
        if (!$item) {
            return $this->fail('收入记录不存在', 404);
        }

        $item->fill($request->only([
            'income_type', 'amount', 'payer_type', 'payer_id',
            'payment_method', 'income_date', 'operator_id', 'remark',
        ]));
        $item->save();

        return $this->success([], '更新成功');
    }

    /** 删除收入（需密码确认） */
    public function incomeDestroy(Request $request, string $hashid)
    {
        $adminId  = $request->adminId;
        $password = $request->input('password', '');

        $error = $this->confirmPassword($adminId, $password, $request);
        if ($error !== null) {
            return $this->fail($error, 422);
        }

        $id   = $this->decodeId($hashid);
        $item = FinanceIncome::find($id);
        if (!$item) {
            return $this->fail('收入记录不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }

    // ============================================================
    // 财务支出
    // ============================================================

    /**
     * 支出列表
     * GET /admin/finance-expense
     * ?expense_type=xxx&start_date=xxx&end_date=xxx&page_size=20
     */
    public function expenseIndex(Request $request)
    {
        $expenseType = $request->input('expense_type');
        $startDate   = $request->input('start_date', '');
        $endDate     = $request->input('end_date', '');

        $query = FinanceExpense::query();

        if ($expenseType !== null && $expenseType !== '') {
            $query->where('expense_type', (int) $expenseType);
        }
        if (!empty($startDate)) {
            $query->where('expense_date', '>=', $startDate);
        }
        if (!empty($endDate)) {
            $query->where('expense_date', '<=', $endDate);
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'             => $this->encodeId($item->id),
                    'expense_number' => $item->expense_number,
                    'expense_type'   => $item->expense_type,
                    'amount'         => $item->amount,
                    'payee'          => $item->payee,
                    'expense_date'   => $item->expense_date ? $item->expense_date->format('Y-m-d') : '',
                    'operator_id'    => $item->operator_id ? $this->encodeId($item->operator_id) : '',
                    'receipt_url'    => $item->receipt_url,
                    'remark'         => $item->remark,
                    'created_at'     => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /** 支出详情 */
    public function expenseShow(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = FinanceExpense::find($id);
        if (!$item) {
            return $this->fail('支出记录不存在', 404);
        }

        return $this->success([
            'id'             => $this->encodeId($item->id),
            'expense_number' => $item->expense_number,
            'expense_type'   => $item->expense_type,
            'amount'         => $item->amount,
            'payee'          => $item->payee,
            'expense_date'   => $item->expense_date ? $item->expense_date->format('Y-m-d') : '',
            'operator_id'    => $item->operator_id ? $this->encodeId($item->operator_id) : '',
            'receipt_url'    => $item->receipt_url,
            'remark'         => $item->remark,
            'created_at'     => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
            'updated_at'     => $item->updated_at ? $item->updated_at->format('Y-m-d H:i') : '',
        ]);
    }

    /** 创建支出 */
    public function expenseStore(Request $request)
    {
        $data = $request->only([
            'expense_type', 'amount', 'payee',
            'expense_date', 'operator_id', 'receipt_url', 'remark',
        ]);

        if (empty($data['amount'])) {
            return $this->fail('金额不能为空', 422);
        }

        $id = SnowflakeService::generate();
        $data['id']             = $id;
        $data['expense_number'] = 'EXP' . date('YmdHis') . str_pad((string) mt_rand(0, 9999), 4, '0', STR_PAD_LEFT);

        FinanceExpense::create($data);

        return $this->success(['id' => $this->encodeId($id)], '创建成功');
    }

    /** 更新支出 */
    public function expenseUpdate(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = FinanceExpense::find($id);
        if (!$item) {
            return $this->fail('支出记录不存在', 404);
        }

        $item->fill($request->only([
            'expense_type', 'amount', 'payee',
            'expense_date', 'operator_id', 'receipt_url', 'remark',
        ]));
        $item->save();

        return $this->success([], '更新成功');
    }

    /** 删除支出（需密码确认） */
    public function expenseDestroy(Request $request, string $hashid)
    {
        $adminId  = $request->adminId;
        $password = $request->input('password', '');

        $error = $this->confirmPassword($adminId, $password, $request);
        if ($error !== null) {
            return $this->fail($error, 422);
        }

        $id   = $this->decodeId($hashid);
        $item = FinanceExpense::find($id);
        if (!$item) {
            return $this->fail('支出记录不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }

    // ============================================================
    // 财务统计
    // ============================================================

    /**
     * 财务统计（按月汇总收入/支出）
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/finance/statistics")
     */
    public function statistics(Request $request)
    {
        $year = (int) $request->input('year', date('Y'));

        // 月度收入汇总
        $incomeMonthly = FinanceIncome::whereYear('income_date', (string) $year)
            ->select(
                Db::raw('MONTH(income_date) as month'),
                Db::raw('SUM(amount) as total')
            )
            ->groupBy(Db::raw('MONTH(income_date)'))
            ->get()
            ->keyBy('month');

        // 月度支出汇总
        $expenseMonthly = FinanceExpense::whereYear('expense_date', (string) $year)
            ->select(
                Db::raw('MONTH(expense_date) as month'),
                Db::raw('SUM(amount) as total')
            )
            ->groupBy(Db::raw('MONTH(expense_date)'))
            ->get()
            ->keyBy('month');

        // 年度汇总
        $yearIncome  = FinanceIncome::whereYear('income_date', (string) $year)->sum('amount');
        $yearExpense = FinanceExpense::whereYear('expense_date', (string) $year)->sum('amount');

        $months = [];
        for ($m = 1; $m <= 12; $m++) {
            $months[] = [
                'month'   => $m,
                'income'  => (float) ($incomeMonthly[$m]->total ?? 0),
                'expense' => (float) ($expenseMonthly[$m]->total ?? 0),
                'balance' => (float) (($incomeMonthly[$m]->total ?? 0) - ($expenseMonthly[$m]->total ?? 0)),
            ];
        }

        return $this->success([
            'year'          => $year,
            'year_income'   => (float) $yearIncome,
            'year_expense'  => (float) $yearExpense,
            'year_balance'  => (float) ($yearIncome - $yearExpense),
            'months'        => $months,
        ]);
    }
}
