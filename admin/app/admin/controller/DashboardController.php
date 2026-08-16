<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;
use hg\apidoc\annotation as Apidoc;

use app\model\AdminUser;
use app\model\OperationLog;
use support\Redis;
use support\Request;
use support\Response;

/**
 * 仪表盘与运维
 * @Apidoc\Group("dashboard")
 */
class DashboardController extends BaseController
{
    /**
     * 仪表盘数据
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/dashboard")
     */
    public function index(Request $request): Response
    {
        // Redis 缓存 5 分钟，避免每次请求跑 5+ 条 SQL
        $cacheKey = 'dashboard:data';
        $cached = Redis::get($cacheKey);
        if ($cached) {
            return $this->success(json_decode($cached, true));
        }

        $today = date('Y-m-d');
        $startOfRange = date('Y-m-d', strtotime('-29 days'));

        $data = [
            'stats' => $this->getStats($today),
            'trends' => $this->getTrends($startOfRange),
            'distribution' => $this->getDistribution(),
            'recent_logs' => $this->getRecentLogs(),
        ];

        Redis::setex($cacheKey, 300, json_encode($data, JSON_UNESCAPED_UNICODE));

        return $this->success($data);
    }

    private function getStats(string $today): array
    {
        $totalUsers = AdminUser::count();
        $todayNew = AdminUser::whereDate('created_at', $today)->count();
        $todayActive = AdminUser::whereDate('last_login_at', $today)->count();
        $todayLogs = OperationLog::whereDate('created_at', $today)->count();

        return [
            [
                'label' => '用户总数',
                'value' => (string) $totalUsers,
                'icon' => 'people',
                'color' => '#1677FF',
                'trend' => $this->calcTrend(AdminUser::class),
            ],
            [
                'label' => '今日新增',
                'value' => (string) $todayNew,
                'icon' => 'person_add',
                'color' => '#52C41A',
            ],
            [
                'label' => '活跃用户',
                'value' => (string) $todayActive,
                'icon' => 'bolt',
                'color' => '#FA8C16',
            ],
            [
                'label' => '操作日志',
                'value' => (string) $todayLogs,
                'icon' => 'description',
                'color' => '#722ED1',
            ],
        ];
    }

    private function getTrends(string $startOfRange): array
    {
        $dates = [];
        $userGrowth = [];
        $logCounts = [];

        // 生成日期序列
        for ($i = 29; $i >= 0; $i--) {
            $dates[] = date('Y-m-d', strtotime("+{$i} days", strtotime($startOfRange)));
        }

        // 一次查询获取用户每日新增数，PHP 内累加
        $dailyNewUsers = AdminUser::whereDate('created_at', '>=', $startOfRange)
            ->selectRaw('DATE(created_at) as date, COUNT(*) as count')
            ->groupBy('date')
            ->pluck('count', 'date')
            ->toArray();

        $cumulative = AdminUser::whereDate('created_at', '<', $startOfRange)->count();
        foreach ($dates as $date) {
            $cumulative += $dailyNewUsers[$date] ?? 0;
            $userGrowth[] = $cumulative;
        }

        // 一次查询获取操作日志每日数量
        $dailyLogs = OperationLog::whereDate('created_at', '>=', $startOfRange)
            ->selectRaw('DATE(created_at) as date, COUNT(*) as count')
            ->groupBy('date')
            ->pluck('count', 'date')
            ->toArray();

        foreach ($dates as $date) {
            $logCounts[] = $dailyLogs[$date] ?? 0;
        }

        return [
            'dates' => $dates,
            'series' => [
                ['name' => '累计用户', 'data' => $userGrowth, 'color' => '#1677FF'],
                ['name' => '操作日志', 'data' => $logCounts, 'color' => '#52C41A'],
            ],
        ];
    }

    private function getDistribution(): array
    {
        return [
            'user_status' => [
                ['name' => '启用', 'value' => AdminUser::where('status', 1)->count()],
                ['name' => '禁用', 'value' => AdminUser::where('status', 0)->count()],
            ],
        ];
    }

    private function getRecentLogs(): array
    {
        return OperationLog::with('user')
            ->orderBy('id', 'desc')
            ->limit(10)
            ->get()
            ->map(function ($log) {
                $data = $log->toArray();
                $data['id'] = $this->encodeId($data['id']);
                $data['user_name'] = $log->user->username ?? '系统';
                unset($data['user'], $data['user_id']);
                return $data;
            })
            ->toArray();
    }

    /**
     * 物业管理面板统计
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/dashboard/property")
     */
    public function propertyStats(Request $request): Response
    {
        $communityId = $request->input('community_id');

        // 应收/实收/欠费统计
        $billQuery = \app\model\FeeBill::query();
        if ($communityId) {
            $billQuery->whereHas('room', fn($q) => $q->where('community_id', $communityId));
        }
        $totalBilled = (float) $billQuery->sum('amount');
        $totalPaid = (float) \app\model\FeeBill::query()->when($communityId, fn($q) => $q->whereHas('room', fn($r) => $r->where('community_id', $communityId)))->sum('paid_amount');

        // 入住率
        $totalRooms = \app\model\Room::when($communityId, fn($q) => $q->where('community_id', $communityId))->count();
        $occupiedRooms = \app\model\Room::when($communityId, fn($q) => $q->where('community_id', $communityId))->whereIn('status', [1, 2, 3])->count();
        $occupancyRate = $totalRooms > 0 ? round($occupiedRooms / $totalRooms * 100, 1) : 0;

        // 报修统计（按分类）
        $repairStats = \app\model\RepairOrder::query()
            ->when($communityId, fn($q) => $q->whereHas('room', fn($r) => $r->where('community_id', $communityId)))
            ->selectRaw('category, COUNT(*) as count')
            ->groupBy('category')->get();

        // 报修状态统计
        $repairStatusStats = \app\model\RepairOrder::query()
            ->when($communityId, fn($q) => $q->whereHas('room', fn($r) => $r->where('community_id', $communityId)))
            ->selectRaw('status, COUNT(*) as count')
            ->groupBy('status')->get();

        // 投诉统计
        $complaintStats = \app\model\Complaint::query()
            ->selectRaw('type, status, COUNT(*) as count')
            ->groupBy('type', 'status')->get();

        // 月度收入趋势（近12个月）
        $monthlyIncome = \app\model\FinanceIncome::query()
            ->selectRaw("DATE_FORMAT(income_date, '%Y-%m') as month, SUM(amount) as total")
            ->where('income_date', '>=', date('Y-m-d', strtotime('-11 months')))
            ->groupBy('month')->orderBy('month')->get();

        // 月度支出趋势
        $monthlyExpense = \app\model\FinanceExpense::query()
            ->selectRaw("DATE_FORMAT(expense_date, '%Y-%m') as month, SUM(amount) as total")
            ->where('expense_date', '>=', date('Y-m-d', strtotime('-11 months')))
            ->groupBy('month')->orderBy('month')->get();

        return $this->success([
            'billing' => ['total_billed' => $totalBilled, 'total_paid' => $totalPaid, 'arrears_rate' => $totalBilled > 0 ? round(($totalBilled - $totalPaid) / $totalBilled * 100, 1) : 0],
            'occupancy' => ['total_rooms' => $totalRooms, 'occupied_rooms' => $occupiedRooms, 'rate' => $occupancyRate],
            'repair_by_category' => $repairStats,
            'repair_by_status' => $repairStatusStats,
            'complaint_stats' => $complaintStats,
            'monthly_income' => $monthlyIncome,
            'monthly_expense' => $monthlyExpense,
        ]);
    }

    private function calcTrend(string $modelClass): ?float
    {
        $today = $modelClass::whereDate('created_at', date('Y-m-d'))->count();
        $yesterday = $modelClass::whereDate('created_at', date('Y-m-d', strtotime('-1 day')))->count();

        if ($yesterday === 0) {
            return $today > 0 ? 100.0 : 0.0;
        }
        return round(($today - $yesterday) / $yesterday * 100, 1);
    }
}
