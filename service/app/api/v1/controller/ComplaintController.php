<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;

use app\common\BaseController;
use support\Request;
use support\Response;
use support\Db;
use InvalidArgumentException;

class ComplaintController extends BaseController
{
    /**
     * 投诉列表
     * GET /api/complaints?page=1
     */
    public function index(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);
        $page    = (int) $request->input('page', 1);

        $total = Db::table('erik_complaint')
            ->where('owner_id', $ownerId)
            ->count();

        $perPage = 20;
        $offset  = ($page - 1) * $perPage;

        $items = Db::table('erik_complaint')
            ->where('owner_id', $ownerId)
            ->orderBy('created_at', 'desc')
            ->offset($offset)
            ->limit($perPage)
            ->get()
            ->map(function ($item) {
                return [
                    'id'         => $this->encodeId($item->id),
                    'type'       => $item->type,
                    'category'   => $item->category ?? '',
                    'title'      => $item->title,
                    'status'     => $item->status,
                    'is_anonymous' => $item->is_anonymous ?? 0,
                    'created_at' => $item->created_at ?? '',
                ];
            });

        $data = [
            'data'         => $items->values(),
            'current_page' => $page,
            'last_page'    => (int) ceil($total / $perPage),
            'per_page'     => $perPage,
            'total'        => $total,
        ];

        return $this->success($data);
    }

    /**
     * 投诉详情
     * GET /api/complaints/{hashid}
     */
    public function show(Request $request, string $hashid): Response
    {
        try {
            $complaintId = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的投诉ID', 404);
        }

        $ownerId = $this->getOwnerId($request);

        $complaint = Db::table('erik_complaint')
            ->where('owner_id', $ownerId)
            ->where('id', $complaintId)
            ->first();

        if (!$complaint) {
            return $this->fail('投诉不存在或无权访问', 404);
        }

        $data = [
            'id'           => $this->encodeId($complaint->id),
            'type'         => $complaint->type,
            'category'     => $complaint->category ?? '',
            'title'        => $complaint->title,
            'content'      => $complaint->content,
            'status'       => $complaint->status,
            'is_anonymous' => $complaint->is_anonymous ?? 0,
            'images'       => $complaint->images ?? [],
            'reply'        => $complaint->reply ?? '',
            'replied_at'   => $complaint->replied_at ?? '',
            'satisfaction' => $complaint->satisfaction ?? 0,
            'created_at'   => $complaint->created_at ?? '',
        ];

        return $this->success($data);
    }

    /**
     * 创建投诉
     * POST /api/complaints
     */
    public function store(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);

        $type        = $request->input('type', '');
        $category    = $request->input('category', '');
        $title       = $request->input('title', '');
        $content     = $request->input('content', '');
        $isAnonymous = $request->input('is_anonymous', 0);
        $images      = $request->input('images', []);

        if (empty($title)) {
            return $this->fail('请填写投诉标题', 422);
        }

        if (empty($content)) {
            return $this->fail('请填写投诉内容', 422);
        }

        $complaintId = $this->generateId();
        $now = date('Y-m-d H:i:s');

        Db::table('erik_complaint')->insert([
            'id'           => $complaintId,
            'owner_id'     => $ownerId,
            'type'         => $type,
            'category'     => $category,
            'title'        => $title,
            'content'      => $content,
            'is_anonymous' => (int) $isAnonymous,
            'images'       => json_encode($images),
            'status'       => 0,
            'created_at'   => $now,
            'updated_at'   => $now,
        ]);

        return $this->success([
            'id' => $this->encodeId($complaintId),
        ], '投诉已提交');
    }

    /**
     * 满意度评价
     * POST /api/complaints/{hashid}/satisfaction
     */
    public function satisfaction(Request $request, string $hashid): Response
    {
        $ownerId = $this->getOwnerId($request);

        try {
            $complaintId = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的投诉ID', 404);
        }

        $complaint = Db::table('erik_complaint')
            ->where('owner_id', $ownerId)
            ->where('id', $complaintId)
            ->first();

        if (!$complaint) {
            return $this->fail('投诉不存在或无权操作', 404);
        }

        if ($complaint->status != 2) {
            return $this->fail('仅已处理状态的投诉可以评价', 422);
        }

        $score = (int) $request->input('score', 0);

        if ($score < 1 || $score > 5) {
            return $this->fail('评分必须在1-5之间', 422);
        }

        Db::table('erik_complaint')
            ->where('id', $complaintId)
            ->update([
                'satisfaction' => $score,
                'updated_at'   => date('Y-m-d H:i:s'),
            ]);

        return $this->success([], '评价成功');
    }
}
