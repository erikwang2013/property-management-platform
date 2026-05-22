<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;

use app\common\SnowflakeService;
use app\model\CollectionRecord;
use app\model\CollectionStrategy;
use app\model\FeeBill;
use app\model\Notification;
use InvalidArgumentException;
use support\Request;

class CollectionController extends BaseController
{
    /**
     * 催缴策略列表
     * GET /admin/collection-strategy
     */
    public function strategies(Request $request)
    {
        $keyword = $request->input('keyword', '');
        $status  = $request->input('status');

        $query = CollectionStrategy::query();
        if (!empty($keyword)) {
            $query->where('name', 'like', "%{$keyword}%");
        }
        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        }

        $list = $query->orderBy('sort', 'asc')
            ->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'            => $this->encodeId($item->id),
                    'name'          => $item->name,
                    'overdue_days'  => $item->overdue_days,
                    'action'        => $item->action,
                    'template_id'   => $item->template_id,
                    'late_fee_rate' => $item->late_fee_rate,
                    'sort'          => $item->sort,
                    'status'        => $item->status,
                    'created_at'    => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 创建催缴策略
     * POST /admin/collection-strategy
     */
    public function strategyStore(Request $request)
    {
        $data = $request->only([
            'name', 'overdue_days', 'action', 'template_id',
            'late_fee_rate', 'sort',
        ]);

        if (empty($data['name'])) {
            return $this->fail('策略名称不能为空', 422);
        }

        $data['id']     = SnowflakeService::generate();
        $data['status'] = 1;

        CollectionStrategy::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /**
     * 更新催缴策略
     * PUT /admin/collection-strategy/{hashid}
     */
    public function strategyUpdate(Request $request, string $hashid)
    {
        try {
            $id = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的策略ID', 404);
        }

        $item = CollectionStrategy::find($id);
        if (!$item) {
            return $this->fail('策略不存在', 404);
        }

        $item->fill($request->only([
            'name', 'overdue_days', 'action', 'template_id',
            'late_fee_rate', 'sort', 'status',
        ]));
        $item->save();

        return $this->success([], '更新成功');
    }

    /**
     * 删除催缴策略
     * DELETE /admin/collection-strategy/{hashid}
     */
    public function strategyDestroy(Request $request, string $hashid)
    {
        $adminId  = $request->adminId;
        $password = $request->input('password', '');

        $error = $this->confirmPassword($adminId, $password, $request);
        if ($error !== null) {
            return $this->fail($error, 422);
        }

        try {
            $id = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的策略ID', 404);
        }

        $item = CollectionStrategy::find($id);
        if (!$item) {
            return $this->fail('策略不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }

    /**
     * 催缴记录列表
     * GET /admin/collection-record?bill_id=&page=1
     */
    public function records(Request $request)
    {
        $billId = $request->input('bill_id');
        $page   = (int) $request->input('page', 1);

        $query = CollectionRecord::with('strategy');
        if (!empty($billId)) {
            $query->where('bill_id', (int) $billId);
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'          => $this->encodeId($item->id),
                    'bill_id'     => $item->bill_id,
                    'strategy_id' => $item->strategy_id ? $this->encodeId($item->strategy_id) : '',
                    'strategy_name' => $item->strategy->name ?? '',
                    'action'      => $item->action,
                    'executed_by' => $item->executed_by,
                    'remark'      => $item->remark,
                    'executed_at' => $item->executed_at ? $item->executed_at->format('Y-m-d H:i') : '',
                    'created_at'  => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 手动触发催缴
     * POST /admin/collection/run
     * 扫描逾期账单，匹配策略，生成催缴记录和通知
     */
    public function run(Request $request)
    {
        $now = date('Y-m-d');

        // 获取所有启用的催缴策略，按overdue_days排序
        $strategies = CollectionStrategy::where('status', 1)
            ->orderBy('overdue_days', 'asc')
            ->get();

        // 获取所有逾期未缴清的账单
        $overdueBills = FeeBill::where('status', '!=', 1)
            ->where('due_date', '<', $now)
            ->get();

        $recordCount = 0;

        foreach ($overdueBills as $bill) {
            $overdueDays = (int) ceil((strtotime($now) - strtotime($bill->due_date->format('Y-m-d'))) / 86400);

            // 匹配策略：找overdue_days最接近且不大于overdueDays的记录
            $matchedStrategy = null;
            foreach ($strategies as $strategy) {
                if ($strategy->overdue_days <= $overdueDays) {
                    $matchedStrategy = $strategy;
                }
            }

            if (!$matchedStrategy) {
                continue;
            }

            // 检查是否已执行过该策略（避免重复）
            $existingRecord = CollectionRecord::where('bill_id', $bill->id)
                ->where('strategy_id', $matchedStrategy->id)
                ->first();

            if ($existingRecord) {
                continue;
            }

            // 创建催缴记录
            CollectionRecord::create([
                'id'          => SnowflakeService::generate(),
                'bill_id'     => $bill->id,
                'strategy_id' => $matchedStrategy->id,
                'action'      => $matchedStrategy->action,
                'executed_by' => 0,
                'remark'      => "逾期{$overdueDays}天，触发策略：{$matchedStrategy->name}",
                'executed_at' => date('Y-m-d H:i:s'),
            ]);

            // 创建通知
            Notification::create([
                'id'        => SnowflakeService::generate(),
                'user_id'   => $bill->owner_id,
                'user_type' => 1,
                'title'     => '缴费提醒',
                'content'   => "您的账单 {$bill->bill_number} 已逾期{$overdueDays}天，金额：{$bill->amount}元，请尽快缴费。",
                'type'      => 2,
                'channel'   => '["system"]',
                'is_read'   => 0,
                'ref_type'  => 'bill',
                'ref_id'    => $bill->id,
            ]);

            $recordCount++;
        }

        return $this->success(['record_count' => $recordCount], '催缴执行完成');
    }

    /**
     * 计算滞纳金（cron调用）
     * 更新所有逾期未缴账单的late_fee
     */
    public function calculateLateFees(Request $request)
    {
        $now          = date('Y-m-d');
        $strategies   = CollectionStrategy::where('status', 1)
            ->where('late_fee_rate', '>', 0)
            ->get();
        $updatedCount = 0;

        // 获取所有逾期未缴清的账单
        $overdueBills = FeeBill::where('status', '!=', 1)
            ->where('due_date', '<', $now)
            ->get();

        foreach ($overdueBills as $bill) {
            $overdueDays = (int) ceil((strtotime($now) - strtotime($bill->due_date->format('Y-m-d'))) / 86400);

            // 找匹配策略的滞纳金率
            $feeRate = 0;
            foreach ($strategies as $strategy) {
                if ($strategy->overdue_days <= $overdueDays) {
                    $feeRate = (float) $strategy->late_fee_rate;
                }
            }

            if ($feeRate <= 0) {
                continue;
            }

            // 按滞纳金率计算：未缴金额 * 费率 * 天数
            $unpaidAmount = $bill->amount - $bill->paid_amount;
            $newLateFee   = round($unpaidAmount * $feeRate * $overdueDays, 2);

            if ($newLateFee != $bill->late_fee) {
                $bill->late_fee = $newLateFee;
                $bill->save();
                $updatedCount++;
            }
        }

        return $this->success(['updated_count' => $updatedCount], '滞纳金计算完成');
    }
}
