<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;

use app\common\BaseController;
use app\model\Announcement;
use app\model\FeeBill;
use support\Request;
use support\Response;

/**
 * 开放 API（入站对外只读接口，X-API-Key 鉴权，见 /open 路由）
 * 复用业主端现有查询逻辑，不新增业务规则
 */
class OpenApiController extends BaseController
{
    /**
     * 公告列表（复用 AnnouncementController::index 查询）
     */
    public function announcements(Request $request): Response
    {
        $page     = (int) $request->input('page', 1);
        $category = $request->input('category');

        $query = Announcement::where('is_published', 1);

        if ($category !== null && $category !== '') {
            $query->where('category', $category);
        }

        $announcements = $query
            ->orderBy('is_top', 'desc')
            ->orderBy('published_at', 'desc')
            ->paginate(20, ['*'], 'page', $page)
            ->through(function ($item) {
                return [
                    'id'           => $this->encodeId($item->id),
                    'title'        => $item->title,
                    'category'     => $item->category,
                    'is_top'       => $item->is_top,
                    'published_at' => $item->published_at ? $item->published_at->format('Y-m-d H:i') : '',
                    'created_at'   => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($announcements);
    }

    /**
     * 账单查询（?bill_number=，复用 FeeController::bills 查询形状）
     */
    public function bills(Request $request): Response
    {
        $billNumber = (string) $request->input('bill_number', '');

        if ($billNumber === '') {
            return $this->fail('缺少 bill_number 参数', 400)->withStatus(400);
        }

        $bill = FeeBill::with(['feeType'])
            ->where('bill_number', $billNumber)
            ->first();

        if (!$bill) {
            return $this->fail('账单不存在', 404)->withStatus(404);
        }

        return $this->success([
            'id'            => $this->encodeId($bill->id),
            'bill_number'   => $bill->bill_number,
            'amount'        => $bill->amount,
            'paid_amount'   => $bill->paid_amount,
            'late_fee'      => $bill->late_fee,
            'unpaid_amount' => $bill->unpaidAmount(),
            'status'        => $bill->status,
            'due_date'      => $bill->due_date ? $bill->due_date->format('Y-m-d') : '',
            'fee_type_name' => $bill->feeType->name ?? '',
            'start_date'    => $bill->start_date ? $bill->start_date->format('Y-m-d') : '',
            'end_date'      => $bill->end_date ? $bill->end_date->format('Y-m-d') : '',
        ]);
    }
}
