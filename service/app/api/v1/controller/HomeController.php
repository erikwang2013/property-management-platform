<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;

use app\common\BaseController;
use app\model\FeeBill;
use app\model\RepairOrder;
use app\model\Announcement;
use app\model\Room;
use support\Request;
use support\Response;

class HomeController extends BaseController
{
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
            'announcements' => $announcements,
        ]);
    }
}
