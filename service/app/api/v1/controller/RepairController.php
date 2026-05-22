<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;

use app\common\BaseController;
use app\model\RepairOrder;
use app\model\Room;
use support\Request;
use support\Response;
use InvalidArgumentException;

/**
 * 报修管理
 * @Apidoc\Group("repair")
 * @Apidoc\Sort(1)
 */
class RepairController extends BaseController
{
    /**
     * 报修列表
     * GET /api/repairs?status=0&page=1
     */
    public function index(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);
        $page    = (int) $request->input('page', 1);
        $status  = $request->input('status');

        $query = RepairOrder::where('owner_id', $ownerId)
            ->with('room');

        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        }

        $repairs = $query->orderBy('created_at', 'desc')
            ->paginate(20, ['*'], 'page', $page)
            ->through(function ($repair) {
                return [
                    'id'           => $this->encodeId($repair->id),
                    'order_number' => $repair->order_number,
                    'category'     => $repair->category,
                    'urgency'      => $repair->urgency,
                    'status'       => $repair->status,
                    'rating'       => $repair->rating,
                    'room_number'  => $repair->room->room_number ?? '',
                    'description'  => $repair->description,
                    'created_at'   => $repair->created_at ? $repair->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($repairs);
    }

    /**
     * 报修详情
     * GET /api/repairs/{hashid}
     */
    public function show(Request $request, string $hashid): Response
    {
        try {
            $repairId = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的报修单ID', 404);
        }

        $ownerId = $this->getOwnerId($request);

        $repair = RepairOrder::where('owner_id', $ownerId)
            ->with(['room', 'progress'])
            ->find($repairId);

        if (!$repair) {
            return $this->fail('报修单不存在或无权访问', 404);
        }

        $data = [
            'id'            => $this->encodeId($repair->id),
            'order_number'  => $repair->order_number,
            'category'      => $repair->category,
            'urgency'       => $repair->urgency,
            'description'   => $repair->description,
            'images'        => $repair->images,
            'status'        => $repair->status,
            'scheduled_at'  => $repair->scheduled_at ? $repair->scheduled_at->format('Y-m-d H:i') : '',
            'completed_at'  => $repair->completed_at ? $repair->completed_at->format('Y-m-d H:i') : '',
            'rating'        => $repair->rating,
            'feedback'      => $repair->feedback,
            'contact_phone' => $repair->contact_phone,
            'created_at'    => $repair->created_at ? $repair->created_at->format('Y-m-d H:i') : '',
            'room'          => $repair->room ? [
                'id'          => $this->encodeId($repair->room->id),
                'room_number' => $repair->room->room_number,
            ] : null,
            'progress'      => $repair->progress->map(function ($p) {
                return [
                    'id'          => $this->encodeId($p->id),
                    'status_from' => $p->status_from,
                    'status_to'   => $p->status_to,
                    'remark'      => $p->remark,
                    'created_at'  => $p->created_at ? $p->created_at->format('Y-m-d H:i') : '',
                ];
            })->values(),
        ];

        return $this->success($data);
    }

    /**
     * 创建报修
     * POST /api/repairs
     */
    public function store(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);

        $roomHashid  = $request->input('room_id', '');
        $category    = $request->input('category', 0);
        $urgency     = $request->input('urgency', 0);
        $description = $request->input('description', '');
        $contactPhone = $request->input('contact_phone', '');
        $images      = $request->input('images', []);
        $scheduledAt = $request->input('scheduled_at', '');

        if (empty($roomHashid)) {
            return $this->fail('请选择报修房间', 422);
        }

        if (empty($description)) {
            return $this->fail('请填写报修描述', 422);
        }

        try {
            $roomId = $this->decodeId($roomHashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的房间ID', 404);
        }

        // 验证房间归属
        $room = Room::whereHas('owners', function ($q) use ($ownerId) {
            $q->where('owner_id', $ownerId);
        })->find($roomId);

        if (!$room) {
            return $this->fail('房间不存在或无权操作', 404);
        }

        $repairId = $this->generateId();
        $orderNumber = 'REP' . date('YmdHis') . str_pad((string) mt_rand(0, 9999), 4, '0', STR_PAD_LEFT);

        RepairOrder::create([
            'id'            => $repairId,
            'order_number'  => $orderNumber,
            'room_id'       => $roomId,
            'owner_id'      => $ownerId,
            'contact_phone' => $contactPhone,
            'category'      => (int) $category,
            'urgency'       => (int) $urgency,
            'description'   => $description,
            'images'        => $images,
            'scheduled_at'  => $scheduledAt ?: null,
            'status'        => 0,
        ]);

        return $this->success([
            'id'           => $this->encodeId($repairId),
            'order_number' => $orderNumber,
        ], '报修申请已提交');
    }

    /**
     * 取消报修
     * DELETE /api/repairs/{hashid}
     */
    public function destroy(Request $request, string $hashid): Response
    {
        $ownerId = $this->getOwnerId($request);
        $password = $request->input('password', '');

        $confirmError = $this->confirmPassword($ownerId, $password);
        if ($confirmError !== null) {
            return $this->fail($confirmError, 422);
        }

        try {
            $repairId = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的报修单ID', 404);
        }

        $repair = RepairOrder::where('owner_id', $ownerId)->find($repairId);
        if (!$repair) {
            return $this->fail('报修单不存在或无权操作', 404);
        }

        if ($repair->status !== 0) {
            return $this->fail('仅待处理状态的报修单可以取消', 422);
        }

        $repair->status = 4; // 已取消
        $repair->save();

        return $this->success([], '报修单已取消');
    }

    /**
     * 评价报修
     * POST /api/repairs/{hashid}/rate
     */
    public function rate(Request $request, string $hashid): Response
    {
        $ownerId = $this->getOwnerId($request);

        try {
            $repairId = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的报修单ID', 404);
        }

        $repair = RepairOrder::where('owner_id', $ownerId)->find($repairId);
        if (!$repair) {
            return $this->fail('报修单不存在或无权操作', 404);
        }

        if ($repair->status !== 3) {
            return $this->fail('仅已完成状态的报修单可以评价', 422);
        }

        $rating   = (int) $request->input('rating', 0);
        $feedback = $request->input('feedback', '');

        if ($rating < 1 || $rating > 5) {
            return $this->fail('评分必须在1-5之间', 422);
        }

        $repair->rating   = $rating;
        $repair->feedback = $feedback;
        $repair->save();

        return $this->success([], '评价成功');
    }
}
