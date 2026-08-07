<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;
use hg\apidoc\annotation as Apidoc;

use app\model\Visitor;
use support\Request;

/**
 * 物业管理·辅助
 * @Apidoc\Group("property-aux")
 */
class VisitorController extends BaseController
{
    /**
     * 访客列表
     * ?status=xxx&page_size=20
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/visitor")
     */
    public function index(Request $request)
    {
        $status = $request->input('status');

        $query = Visitor::query();

        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'             => $this->encodeId($item->id),
                    'room_id'        => $this->encodeId($item->room_id),
                    'owner_id'       => $this->encodeId($item->owner_id),
                    'visitor_name'   => $item->visitor_name,
                    'visitor_phone'  => $item->visitor_phone,
                    'plate_number'   => $item->plate_number,
                    'visitor_count'  => $item->visitor_count,
                    'purpose'        => $item->purpose,
                    'expected_start' => $item->expected_start ? $item->expected_start->format('Y-m-d H:i') : '',
                    'expected_end'   => $item->expected_end ? $item->expected_end->format('Y-m-d H:i') : '',
                    'actual_start'   => $item->actual_start ? $item->actual_start->format('Y-m-d H:i') : '',
                    'actual_end'     => $item->actual_end ? $item->actual_end->format('Y-m-d H:i') : '',
                    'pass_code'      => $item->pass_code,
                    'status'         => $item->status,
                    'created_at'     => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 审批通过（确认到访）
     * status: 0(已预约) → 1(已到访)
     * @Apidoc\Method("PUT")
     * @Apidoc\Url("/admin/visitor/{id}/approve")
     */
    public function approve(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = Visitor::find($id);
        if (!$item) {
            return $this->fail('访客记录不存在', 404);
        }

        if ($item->status != 0) {
            return $this->fail('仅已预约状态的访客可以审批', 422);
        }

        $item->status       = 1; // 已到访
        $item->actual_start = date('Y-m-d H:i:s');
        $item->save();

        return $this->success([], '访客已确认到访');
    }
}
