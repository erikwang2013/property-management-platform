<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;
use hg\apidoc\annotation as Apidoc;

use app\model\FeeBill;
use app\model\FeePayment;
use app\model\FinanceExpense;
use app\model\FinanceIncome;
use app\model\RepairOrder;
use app\model\Complaint;
use app\model\Visitor;
use app\model\ParkingRecord;
use app\model\Room;
use app\model\Owner;
use support\Redis;
use support\Request;
use support\Response;
use InvalidArgumentException;

/**
 * 报表中心
 * @Apidoc\Group("report")
 */
class ReportController extends BaseController
{
    private const PAY_METHOD_NAMES = [1 => '微信', 2 => '支付宝', 3 => '现金', 4 => '银行转账', 5 => '刷卡'];

    /**
     * 报表总览（汇总卡片 + 收支趋势 + 业务分布 + 欠费排行）
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/report")
     * @param string start_date 开始日期 Y-m-d（默认近 30 天）
     * @param string end_date 结束日期 Y-m-d
     * @param string community_id 小区 ID（hashid，可选）
     */
    public function index(Request $request): Response
    {
        $start = $request->input('start_date', date('Y-m-d', strtotime('-29 days')));
        $end = $request->input('end_date', date('Y-m-d'));
        if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $start) || !preg_match('/^\d{4}-\d{2}-\d{2}$/', $end) || $start > $end) {
            return $this->fail('无效的日期范围', 422);
        }

        $communityId = null;
        if ($cid = $request->input('community_id')) {
            try {
                $communityId = $this->decodeId((string) $cid);
            } catch (InvalidArgumentException) {
                return $this->fail('无效的小区ID', 404);
            }
        }

        // Redis 缓存 5 分钟，键含日期范围与小区维度
        $cacheKey = 'report:' . ($communityId ?: 'all') . ":{$start}:{$end}";
        $cached = Redis::get($cacheKey);
        if ($cached) {
            return $this->success(json_decode($cached, true));
        }

        $data = [
            'summary' => $this->getSummary($start, $end, $communityId),
            'income_trend' => $this->getIncomeTrend($start, $end),
            'expense_trend' => $this->getExpenseTrend($start, $end),
            'payment_methods' => $this->getPaymentMethods($start, $end, $communityId),
            'repair_status' => $this->getRepairStatus($start, $end, $communityId),
            'complaint_status' => $this->getComplaintStatus($start, $end, $communityId),
            'visitor_status' => $this->getVisitorStatus($start, $end, $communityId),
            'repair_category' => $this->getRepairCategory($start, $end, $communityId),
            'arrears_ranking' => $this->getArrearsRanking($communityId, 10),
        ];

        Redis::setex($cacheKey, 300, json_encode($data, JSON_UNESCAPED_UNICODE));

        return $this->success($data);
    }

    private function scopeByCommunity($query, ?int $communityId)
    {
        if ($communityId) {
            $query->whereHas('room', fn($q) => $q->where('community_id', $communityId));
        }
        return $query;
    }

    private function getSummary(string $start, string $end, ?int $communityId): array
    {
        $billQuery = $this->scopeByCommunity(FeeBill::whereBetween('created_at', [$start . ' 00:00:00', $end . ' 23:59:59']), $communityId);
        $totalBilled = (float) $billQuery->sum('amount');
        $totalPaid = (float) $this->scopeByCommunity(FeeBill::whereBetween('created_at', [$start . ' 00:00:00', $end . ' 23:59:59']), $communityId)->sum('paid_amount');

        $totalRooms = Room::when($communityId, fn($q) => $q->where('community_id', $communityId))->count();
        $occupiedRooms = Room::when($communityId, fn($q) => $q->where('community_id', $communityId))->whereIn('status', [1, 2, 3])->count();

        $pendingRepairs = $this->scopeByCommunity(RepairOrder::whereBetween('created_at', [$start . ' 00:00:00', $end . ' 23:59:59']), $communityId)->whereIn('status', [0, 1, 2])->count();
        $pendingComplaints = $this->scopeByCommunity(Complaint::whereBetween('created_at', [$start . ' 00:00:00', $end . ' 23:59:59']), $communityId)->where('status', 0)->count();
        $visitorsToday = Visitor::when($communityId, fn($q) => $q->whereIn('room_id', Room::where('community_id', $communityId)->select('id')))
            ->whereDate('created_at', date('Y-m-d'))->count();
        $parkingNow = ParkingRecord::whereNull('exit_time')->count();

        return [
            'total_billed' => round($totalBilled, 2),
            'total_paid' => round($totalPaid, 2),
            'arrears' => round(max($totalBilled - $totalPaid, 0), 2),
            'collection_rate' => $totalBilled > 0 ? round($totalPaid / $totalBilled * 100, 1) : 0,
            'total_rooms' => $totalRooms,
            'occupied_rooms' => $occupiedRooms,
            'occupancy_rate' => $totalRooms > 0 ? round($occupiedRooms / $totalRooms * 100, 1) : 0,
            'pending_repairs' => $pendingRepairs,
            'pending_complaints' => $pendingComplaints,
            'visitors_today' => $visitorsToday,
            'parking_now' => $parkingNow,
        ];
    }

    private function getIncomeTrend(string $start, string $end): array
    {
        return FinanceIncome::selectRaw("DATE_FORMAT(income_date, '%Y-%m') as month, SUM(amount) as total")
            ->whereBetween('income_date', [$start, $end])
            ->groupBy('month')->orderBy('month')->get()
            ->map(fn($i) => ['month' => $i->month, 'total' => round((float) $i->total, 2)])->toArray();
    }

    private function getExpenseTrend(string $start, string $end): array
    {
        return FinanceExpense::selectRaw("DATE_FORMAT(expense_date, '%Y-%m') as month, SUM(amount) as total")
            ->whereBetween('expense_date', [$start, $end])
            ->groupBy('month')->orderBy('month')->get()
            ->map(fn($i) => ['month' => $i->month, 'total' => round((float) $i->total, 2)])->toArray();
    }

    private function getPaymentMethods(string $start, string $end, ?int $communityId): array
    {
        $rows = FeePayment::when($communityId, fn($q) => $q->whereHas('bill', fn($b) => $b->whereHas('room', fn($r) => $r->where('community_id', $communityId))))
            ->whereBetween('paid_at', [$start . ' 00:00:00', $end . ' 23:59:59'])
            ->selectRaw('payment_method, COUNT(*) as count, SUM(amount) as total')
            ->groupBy('payment_method')->get();

        return $rows->map(fn($r) => [
            'name' => self::PAY_METHOD_NAMES[$r->payment_method] ?? "方式{$r->payment_method}",
            'count' => (int) $r->count,
            'total' => round((float) $r->total, 2),
        ])->toArray();
    }

    private function getRepairStatus(string $start, string $end, ?int $communityId): array
    {
        return $this->scopeByCommunity(RepairOrder::whereBetween('created_at', [$start . ' 00:00:00', $end . ' 23:59:59']), $communityId)
            ->selectRaw('status, COUNT(*) as count')->groupBy('status')->get()
            ->map(fn($r) => ['status' => (int) $r->status, 'count' => (int) $r->count])->toArray();
    }

    private function getComplaintStatus(string $start, string $end, ?int $communityId): array
    {
        $query = Complaint::whereBetween('created_at', [$start . ' 00:00:00', $end . ' 23:59:59']);
        if ($communityId) {
            $query->whereIn('room_id', Room::where('community_id', $communityId)->select('id'));
        }
        return $query->selectRaw('status, COUNT(*) as count')->groupBy('status')->get()
            ->map(fn($r) => ['status' => (int) $r->status, 'count' => (int) $r->count])->toArray();
    }

    private function getVisitorStatus(string $start, string $end, ?int $communityId): array
    {
        $query = Visitor::whereBetween('created_at', [$start . ' 00:00:00', $end . ' 23:59:59']);
        if ($communityId) {
            $query->whereIn('room_id', Room::where('community_id', $communityId)->select('id'));
        }
        return $query->selectRaw('status, COUNT(*) as count')->groupBy('status')->get()
            ->map(fn($r) => ['status' => (int) $r->status, 'count' => (int) $r->count])->toArray();
    }

    private function getRepairCategory(string $start, string $end, ?int $communityId): array
    {
        return $this->scopeByCommunity(RepairOrder::whereBetween('created_at', [$start . ' 00:00:00', $end . ' 23:59:59']), $communityId)
            ->selectRaw('category, COUNT(*) as count')->groupBy('category')->get()
            ->map(fn($r) => ['category' => $r->category, 'count' => (int) $r->count])->toArray();
    }

    private function getArrearsRanking(?int $communityId, int $limit): array
    {
        // 未结清账单按欠费金额倒序（账单金额 - 已缴 - 违约金）
        $bills = FeeBill::whereIn('status', [0, 3])
            ->when($communityId, fn($q) => $q->whereHas('room', fn($r) => $r->where('community_id', $communityId)))
            ->selectRaw('owner_id, room_id, SUM(amount - paid_amount + late_fee) as arrears')
            ->groupBy('owner_id', 'room_id')
            ->orderByDesc('arrears')
            ->limit($limit)
            ->get();

        $ownerIds = $bills->pluck('owner_id')->unique()->all();
        $owners = Owner::whereIn('id', $ownerIds)->get()->keyBy('id');
        $roomIds = $bills->pluck('room_id')->unique()->all();
        $rooms = Room::whereIn('id', $roomIds)->get()->keyBy('id');

        return $bills->map(function ($b) use ($owners, $rooms) {
            $owner = $owners->get($b->owner_id);
            $room = $rooms->get($b->room_id);
            return [
                'owner_name' => $owner->name ?? '未知业主',
                'owner_phone' => isset($owner->phone) ? substr($owner->phone, 0, 3) . '****' . substr($owner->phone, -4) : '',
                'room_name' => $room->room_number ?? '',
                'arrears' => round((float) $b->arrears, 2),
            ];
        })->values()->toArray();
    }
}
