<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\queue\redis;

use app\admin\controller\CollectionController;
use app\common\SnowflakeService;
use app\model\CollectionRecord;
use app\model\CollectionStrategy;
use app\model\FeeBill;
use app\model\Notification;
use Webman\RedisQueue\Consumer;

/**
 * 催缴群发任务：请求路径不再同步执行全量扫描/通知，由 CollectionController::run
 * 入队后在本 worker 进程内循环处理（队列任务内循环 OK，阻塞只在消费进程）。
 *
 * 与原控制器逻辑保持一致：匹配策略 → 去重 → 生成催缴记录 + 系统通知。
 */
class CollectionNotify implements Consumer
{
    // 要消费的队列名，对应 CollectionController::run 的入队目标
    public $queue = 'collection_notify';

    // 连接名，对应 config/plugin/webman/redis-queue/redis.php 里的连接
    public $connection = 'default';

    public function consume($data)
    {
        $now = date('Y-m-d');

        // 获取所有启用的催缴策略，按overdue_days排序
        $strategies = CollectionStrategy::where('status', 1)
            ->orderBy('overdue_days', 'asc')
            ->get();

        // 获取所有逾期未缴清的账单
        // 只纳入未缴(0)/逾期(3)，排除部分缴(1)、已缴(2)、豁免(4)
        $overdueBills = FeeBill::whereIn('status', [0, 3])
            ->where('due_date', '<', $now)
            ->get();

        foreach ($overdueBills as $bill) {
            $overdueDays = CollectionController::calcOverdueDays($bill->due_date->format('Y-m-d'), $now);

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
        }
    }
}
