<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;

use app\common\BaseController;
use app\model\Visitor;
use support\Request;
use support\Response;
use InvalidArgumentException;

/**
 * 访客管理
 * @Apidoc\Group("parking")
 * @Apidoc\Sort(2)
 */
class VisitorController extends BaseController
{
    /**
     * 访客预约列表
     * GET /service/visitors?status=0&page=1
     */
    public function index(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);
        $page    = (int) $request->input('page', 1);
        $status  = $request->input('status');

        $query = Visitor::where('owner_id', $ownerId);

        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        }

        $visitors = $query->orderBy('created_at', 'desc')
            ->paginate(20, ['*'], 'page', $page)
            ->through(function ($visitor) {
                return [
                    'id'             => $this->encodeId($visitor->id),
                    'room_id'        => $this->encodeId($visitor->room_id),
                    'visitor_name'   => $visitor->visitor_name,
                    'visitor_phone'  => $visitor->visitor_phone,
                    'plate_number'   => $visitor->plate_number,
                    'visitor_count'  => $visitor->visitor_count,
                    'purpose'        => $visitor->purpose,
                    'expected_start' => $visitor->expected_start ? $visitor->expected_start->format('Y-m-d H:i') : '',
                    'expected_end'   => $visitor->expected_end ? $visitor->expected_end->format('Y-m-d H:i') : '',
                    'pass_code'      => $visitor->pass_code,
                    'status'         => $visitor->status,
                    'created_at'     => $visitor->created_at ? $visitor->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($visitors);
    }

    /**
     * 创建访客预约
     * POST /service/visitor
     */
    public function store(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);

        $roomHashid   = $request->input('room_id', '');
        $visitorName  = $request->input('visitor_name', '');
        $visitorPhone = $request->input('visitor_phone', '');
        $visitorIdCard = $request->input('visitor_id_card', '');
        $plateNumber  = $request->input('plate_number', '');
        $visitorCount = (int) $request->input('visitor_count', 1);
        $purpose      = $request->input('purpose', '');
        $expectedStart = $request->input('expected_start', '');
        $expectedEnd   = $request->input('expected_end', '');

        if (empty($visitorName)) {
            return $this->fail('请填写访客姓名', 422);
        }

        if (empty($visitorPhone)) {
            return $this->fail('请填写访客电话', 422);
        }

        $roomId = 0;
        if (!empty($roomHashid)) {
            try {
                $roomId = $this->decodeId($roomHashid);
            } catch (InvalidArgumentException) {
                return $this->fail('无效的房间ID', 404);
            }
        }

        $visitorId = $this->generateId();
        $passCode  = str_pad((string) mt_rand(0, 999999), 6, '0', STR_PAD_LEFT);

        Visitor::create([
            'id'             => $visitorId,
            'room_id'        => $roomId,
            'owner_id'       => $ownerId,
            'visitor_name'   => $visitorName,
            'visitor_phone'  => $visitorPhone,
            'visitor_id_card' => $visitorIdCard,
            'plate_number'   => $plateNumber,
            'visitor_count'  => $visitorCount,
            'purpose'        => $purpose,
            'expected_start' => $expectedStart ?: null,
            'expected_end'   => $expectedEnd ?: null,
            'pass_code'      => $passCode,
            'status'         => 0,
        ]);

        return $this->success([
            'id'        => $this->encodeId($visitorId),
            'pass_code' => $passCode,
        ], '访客预约已创建');
    }

    /**
     * 更新访客预约
     * PUT /service/visitor/{hashid}
     */
    public function update(Request $request, string $hashid): Response
    {
        $ownerId = $this->getOwnerId($request);

        try {
            $visitorId = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的访客ID', 404);
        }

        $visitor = Visitor::where('owner_id', $ownerId)->find($visitorId);
        if (!$visitor) {
            return $this->fail('访客预约不存在或无权操作', 404);
        }

        if (!in_array($visitor->status, [0, 3])) {
            return $this->fail('当前状态不允许修改', 422);
        }

        $visitor->fill($request->only([
            'visitor_name', 'visitor_phone', 'visitor_id_card',
            'plate_number', 'visitor_count', 'purpose',
            'expected_start', 'expected_end',
        ]));
        $visitor->save();

        return $this->success([], '更新成功');
    }

    /**
     * 取消访客预约（需密码确认）
     * DELETE /service/visitor/{hashid}
     */
    public function destroy(Request $request, string $hashid): Response
    {
        $ownerId  = $this->getOwnerId($request);
        $password = $request->input('password', '');

        $confirmError = $this->confirmPassword($ownerId, $password);
        if ($confirmError !== null) {
            return $this->fail($confirmError, 422);
        }

        try {
            $visitorId = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的访客ID', 404);
        }

        $visitor = Visitor::where('owner_id', $ownerId)->find($visitorId);
        if (!$visitor) {
            return $this->fail('访客预约不存在或无权操作', 404);
        }

        if (!in_array($visitor->status, [0, 3])) {
            return $this->fail('当前状态不允许取消', 422);
        }

        $visitor->status = 3; // 已取消
        $visitor->save();

        return $this->success([], '访客预约已取消');
    }
}
