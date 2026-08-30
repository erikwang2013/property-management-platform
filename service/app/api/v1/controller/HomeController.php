<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;
use hg\apidoc\annotation as Apidoc;

use app\common\BaseController;
use app\model\FeeBill;
use app\model\RepairOrder;
use app\model\Announcement;
use app\model\Room;
use app\model\Complaint;
use app\model\CommunityActivity;
use app\model\Vote;
use app\model\Notification;
use support\Request;
use support\Response;

/**
 * 首页
 * @Apidoc\Group("home")
 * @Apidoc\Sort(1)
 */
class HomeController extends BaseController
{
    /**
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/service/home")
     */
    public function index(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);

        $roomCount = Room::whereHas('owners', function ($q) use ($ownerId) {
            $q->where('owner_id', $ownerId);
        })->count();

        $pendingBills = FeeBill::where('owner_id', $ownerId)
            ->whereIn('status', [0, 3])->get();
        $pendingAmount = $pendingBills->sum(function ($bill) {
            return $bill->amount - $bill->paid_amount + $bill->late_fee;
        });

        $repairingCount = RepairOrder::where('owner_id', $ownerId)
            ->whereIn('status', [0, 1, 2])->count();

        // 起始页统计：待处理投诉 / 报名中活动 / 进行中投票 / 未读通知
        $pendingComplaints = Complaint::where('owner_id', $ownerId)
            ->where('status', 0)->count();
        $activeActivities = CommunityActivity::whereIn('status', [1, 2])
            ->whereDate('end_time', '>=', date('Y-m-d'))->count();
        $openVotes = Vote::where('status', 1)->count();
        $unreadNotifications = Notification::where('user_id', $ownerId)
            ->where('user_type', 1)->where('is_read', 0)->count();

        $announcements = Announcement::where('is_published', 1)
            ->orderBy('is_top', 'desc')
            ->orderBy('published_at', 'desc')
            ->limit(5)
            ->get()
            ->map(function ($item) {
                return [
                    'id' => $this->encodeId($item->id),
                    'title' => $item->title,
                    'category' => $item->category,
                    'published_at' => $item->published_at ? $item->published_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success([
            'room_count' => $roomCount,
            'pending_amount' => number_format($pendingAmount, 2, '.', ''),
            'pending_bill_count' => $pendingBills->count(),
            'repairing_count' => $repairingCount,
            'pending_complaint_count' => $pendingComplaints,
            'active_activity_count' => $activeActivities,
            'open_vote_count' => $openVotes,
            'unread_count' => $unreadNotifications,
            'announcements' => $announcements,
        ]);
    }
}
