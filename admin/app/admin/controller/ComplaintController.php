<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;

use app\model\Complaint;
use support\Request;

/**
 * 物业管理·辅助
 * @Apidoc\Group("property-aux")
 */
class ComplaintController extends BaseController
{
    /**
     * 投诉列表
     * ?type=xxx&status=xxx&page_size=20
     */
    public function index(Request $request)
    {
        $type   = $request->input('type');
        $status = $request->input('status');

        $query = Complaint::query();

        if ($type !== null && $type !== '') {
            $query->where('type', (int) $type);
        }
        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'           => $this->encodeId($item->id),
                    'owner_id'     => $this->encodeId($item->owner_id),
                    'room_id'      => $item->room_id ? $this->encodeId($item->room_id) : '',
                    'type'         => $item->type,
                    'category'     => $item->category,
                    'title'        => $item->title,
                    'status'       => $item->status,
                    'is_anonymous' => $item->is_anonymous,
                    'handler_id'   => $item->handler_id ? $this->encodeId($item->handler_id) : '',
                    'handled_at'   => $item->handled_at ? $item->handled_at->format('Y-m-d H:i') : '',
                    'satisfaction' => $item->satisfaction,
                    'created_at'   => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /** 投诉详情（含处理人信息） */
    public function show(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = Complaint::find($id);
        if (!$item) {
            return $this->fail('投诉不存在', 404);
        }

        return $this->success([
            'id'             => $this->encodeId($item->id),
            'owner_id'       => $this->encodeId($item->owner_id),
            'room_id'        => $item->room_id ? $this->encodeId($item->room_id) : '',
            'type'           => $item->type,
            'category'       => $item->category,
            'title'          => $item->title,
            'content'        => $item->content,
            'images'         => $item->images,
            'is_anonymous'   => $item->is_anonymous,
            'status'         => $item->status,
            'handler_id'     => $item->handler_id ? $this->encodeId($item->handler_id) : '',
            'handler_remark' => $item->handler_remark,
            'handled_at'     => $item->handled_at ? $item->handled_at->format('Y-m-d H:i') : '',
            'visitor_id'     => $item->visitor_id ? $this->encodeId($item->visitor_id) : '',
            'visitor_remark' => $item->visitor_remark,
            'visitor_at'     => $item->visitor_at ? $item->visitor_at->format('Y-m-d H:i') : '',
            'satisfaction'   => $item->satisfaction,
            'created_at'     => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
            'updated_at'     => $item->updated_at ? $item->updated_at->format('Y-m-d H:i') : '',
        ]);
    }

    /**
     * 处理投诉（受理）
     * PUT /admin/complaint/{id}/handle
     * status: 1(待处理) → 2(处理中)
     */
    public function handle(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = Complaint::find($id);
        if (!$item) {
            return $this->fail('投诉不存在', 404);
        }

        if ($item->status != 1) {
            return $this->fail('仅待处理状态的投诉可以受理', 422);
        }

        $item->handler_id     = $request->adminId;
        $item->handler_remark = $request->input('handler_remark', '');
        $item->status         = 2; // 处理中
        $item->handled_at     = date('Y-m-d H:i:s');
        $item->save();

        return $this->success([], '投诉已受理');
    }

    /**
     * 回访投诉
     * POST /admin/complaint/{id}/visit
     * status: 2(处理中) → 3(已回访)
     */
    public function visit(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = Complaint::find($id);
        if (!$item) {
            return $this->fail('投诉不存在', 404);
        }

        if ($item->status != 2) {
            return $this->fail('仅处理中状态的投诉可以回访', 422);
        }

        $item->visitor_id     = $request->adminId;
        $item->visitor_remark = $request->input('visitor_remark', '');
        $item->status         = 3; // 已回访
        $item->visitor_at     = date('Y-m-d H:i:s');
        $item->save();

        return $this->success([], '回访完成');
    }
}
