<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;

use app\common\SnowflakeService;
use app\model\ParkingSpace;
use support\Request;

class ParkingSpaceController extends BaseController
{
    /**
     * 停车位列表
     * ?community_id=xxx&keyword=搜索词&status=状态&page_size=20
     */
    public function index(Request $request)
    {
        $communityId = $request->input('community_id');
        $keyword     = $request->input('keyword', '');
        $status      = $request->input('status');

        $query = ParkingSpace::query();

        if (!empty($communityId)) {
            $query->where('community_id', (int) $communityId);
        }
        if (!empty($keyword)) {
            $query->where('space_number', 'like', "%{$keyword}%");
        }
        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'           => $this->encodeId($item->id),
                    'community_id' => $this->encodeId($item->community_id),
                    'space_number' => $item->space_number,
                    'space_type'   => $item->space_type,
                    'area'         => $item->area,
                    'status'       => $item->status,
                    'fee_monthly'  => $item->fee_monthly,
                    'created_at'   => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /** 停车位详情 */
    public function show(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = ParkingSpace::find($id);
        if (!$item) {
            return $this->fail('停车位不存在', 404);
        }

        return $this->success([
            'id'           => $this->encodeId($item->id),
            'community_id' => $this->encodeId($item->community_id),
            'space_number' => $item->space_number,
            'space_type'   => $item->space_type,
            'area'         => $item->area,
            'status'       => $item->status,
            'fee_monthly'  => $item->fee_monthly,
            'created_at'   => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
            'updated_at'   => $item->updated_at ? $item->updated_at->format('Y-m-d H:i') : '',
        ]);
    }

    /** 创建停车位 */
    public function store(Request $request)
    {
        $data = $request->only([
            'community_id', 'space_number', 'space_type', 'area', 'fee_monthly',
        ]);

        if (empty($data['community_id'])) {
            return $this->fail('请选择所属小区', 422);
        }
        if (empty($data['space_number'])) {
            return $this->fail('车位编号不能为空', 422);
        }

        $data['id']     = SnowflakeService::generate();
        $data['status'] = $request->input('status', 0);

        ParkingSpace::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /** 更新停车位 */
    public function update(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = ParkingSpace::find($id);
        if (!$item) {
            return $this->fail('停车位不存在', 404);
        }

        $item->fill($request->only([
            'community_id', 'space_number', 'space_type', 'area',
            'status', 'fee_monthly',
        ]));
        $item->save();

        return $this->success([], '更新成功');
    }

    /** 删除停车位（需密码确认） */
    public function destroy(Request $request, string $hashid)
    {
        $adminId  = $request->adminId;
        $password = $request->input('password', '');

        $error = $this->confirmPassword($adminId, $password, $request);
        if ($error !== null) {
            return $this->fail($error, 422);
        }

        $id   = $this->decodeId($hashid);
        $item = ParkingSpace::find($id);
        if (!$item) {
            return $this->fail('停车位不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }
}
