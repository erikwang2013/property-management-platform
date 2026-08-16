<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;
use hg\apidoc\annotation as Apidoc;

use app\common\SnowflakeService;
use app\model\CollectionRecord;
use app\model\CollectionStrategy;
use app\model\FeeBill;
use InvalidArgumentException;
use support\Request;
use Webman\RedisQueue\Redis as QueueRedis;

/**
 * 扩展功能
 * @Apidoc\Group("extensions")
 */
class CollectionController extends BaseController
{
    /**
     * 催缴策略列表
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/collection-strategy")
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
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/collection-strategy")
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
     * @Apidoc\Method("PUT")
     * @Apidoc\Url("/admin/collection-strategy/{hashid}")
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
     * @Apidoc\Method("DELETE")
     * @Apidoc\Url("/admin/collection-strategy/{hashid}")
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
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/collection-record")
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
     * 全量扫描/匹配/通知逻辑移入队列（CollectionNotify 消费进程执行），
     * 请求路径仅入队后立即返回，避免同步阻塞。
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/collection/run")
     */
    public function run(Request $request)
    {
        QueueRedis::send('collection_notify', []);

        // 处理异步执行，record_count 无法即时返回，恒为 0；前端只展示结果消息
        return $this->success(['record_count' => 0], '催缴已提交，后台处理中');
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
        // 只纳入未缴(0)/逾期(3)，排除部分缴(1)、已缴(2)、豁免(4)
        $overdueBills = FeeBill::whereIn('status', [0, 3])
            ->where('due_date', '<', $now)
            ->get();

        foreach ($overdueBills as $bill) {
            $overdueDays = self::calcOverdueDays($bill->due_date->format('Y-m-d'), $now);

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
            $newLateFee   = self::calcLateFee((float) $unpaidAmount, $feeRate, $overdueDays);

            if ($newLateFee != $bill->late_fee) {
                $bill->late_fee = $newLateFee;
                $bill->save();
                $updatedCount++;
            }
        }

        return $this->success(['updated_count' => $updatedCount], '滞纳金计算完成');
    }

    /**
     * 逾期天数：截止日期距今天的自然日差（向上取整，当天为 0）
     */
    public static function calcOverdueDays(string $dueDate, string $nowDate): int
    {
        return (int) ceil((strtotime($nowDate) - strtotime($dueDate)) / 86400);
    }

    /**
     * 滞纳金：未缴金额 × 日费率 × 逾期天数，保留两位小数
     */
    public static function calcLateFee(float $unpaidAmount, float $feeRate, int $overdueDays): float
    {
        return round($unpaidAmount * $feeRate * $overdueDays, 2);
    }
}
