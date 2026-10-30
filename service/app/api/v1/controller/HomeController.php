<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;
use hg\apidoc\annotation as Apidoc;

use app\common\BaseController;
use app\model\FeeBill;
use app\model\Announcement;
use app\model\Room;
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
            ->whereIn('status', [FeeBill::STATUS_UNPAID, FeeBill::STATUS_PARTIAL, FeeBill::STATUS_OVERDUE])->get();
        $pendingAmount = $pendingBills->sum(function ($bill) {
            return (float) $bill->unpaidAmount();
        });

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
            'announcements' => $announcements,
        ]);
    }
}
