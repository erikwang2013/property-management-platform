<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;

use app\common\SnowflakeService;
use app\model\Community;
use app\model\FeeBill;
use app\model\Group;
use app\model\GroupCommunity;
use app\model\Owner;
use app\model\Room;
use InvalidArgumentException;
use support\Db;
use support\Request;

class GroupController extends BaseController
{
    /**
     * 集团列表
     * GET /admin/group
     */
    public function index(Request $request)
    {
        $keyword = $request->input('keyword', '');
        $status  = $request->input('status');

        $query = Group::query();
        if (!empty($keyword)) {
            $query->where('name', 'like', "%{$keyword}%");
        }
        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'             => $this->encodeId($item->id),
                    'name'           => $item->name,
                    'contact_person' => $item->contact_person,
                    'contact_phone'  => $item->contact_phone,
                    'description'    => $item->description,
                    'status'         => $item->status,
                    'created_at'     => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 创建集团
     * POST /admin/group
     */
    public function store(Request $request)
    {
        $data = $request->only([
            'name', 'contact_person', 'contact_phone', 'description',
        ]);

        if (empty($data['name'])) {
            return $this->fail('集团名称不能为空', 422);
        }

        $data['id']     = SnowflakeService::generate();
        $data['status'] = 1;

        Group::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /**
     * 集团详情
     * GET /admin/group/{hashid}
     */
    public function show(Request $request, string $hashid)
    {
        try {
            $id = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的集团ID', 404);
        }

        $item = Group::find($id);
        if (!$item) {
            return $this->fail('集团不存在', 404);
        }

        return $this->success([
            'id'             => $this->encodeId($item->id),
            'name'           => $item->name,
            'contact_person' => $item->contact_person,
            'contact_phone'  => $item->contact_phone,
            'description'    => $item->description,
            'status'         => $item->status,
            'created_at'     => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
            'updated_at'     => $item->updated_at ? $item->updated_at->format('Y-m-d H:i') : '',
        ]);
    }

    /**
     * 更新集团
     * PUT /admin/group/{hashid}
     */
    public function update(Request $request, string $hashid)
    {
        try {
            $id = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的集团ID', 404);
        }

        $item = Group::find($id);
        if (!$item) {
            return $this->fail('集团不存在', 404);
        }

        $item->fill($request->only([
            'name', 'contact_person', 'contact_phone', 'description', 'status',
        ]));
        $item->save();

        return $this->success([], '更新成功');
    }

    /**
     * 删除集团
     * DELETE /admin/group/{hashid}
     */
    public function destroy(Request $request, string $hashid)
    {
        $adminId  = $request->adminId;
        $password = $request->input('password', '');

        $error = $this->confirmPassword($adminId, $password, $request);
        if ($error !== null) {
            return $this->fail($error, 422);
        }

        try {
            $id = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的集团ID', 404);
        }

        $item = Group::find($id);
        if (!$item) {
            return $this->fail('集团不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }

    /**
     * 集团下的小区列表
     * GET /admin/group/{hashid}/communities
     */
    public function communities(Request $request, string $groupHashid)
    {
        try {
            $groupId = $this->decodeId($groupHashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的集团ID', 404);
        }

        $group = Group::find($groupId);
        if (!$group) {
            return $this->fail('集团不存在', 404);
        }

        $communityIds = GroupCommunity::where('group_id', $groupId)
            ->pluck('community_id')
            ->toArray();

        $list = Community::whereIn('id', $communityIds)
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($item) {
                return [
                    'id'              => $this->encodeId($item->id),
                    'name'            => $item->name,
                    'address'         => $item->address,
                    'city'            => $item->city,
                    'building_count'  => $item->building_count,
                    'room_count'      => $item->room_count,
                    'property_company' => $item->property_company,
                    'status'          => $item->status,
                    'created_at'      => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 添加小区到集团
     * POST /admin/group/{hashid}/community
     */
    public function addCommunity(Request $request, string $groupHashid)
    {
        try {
            $groupId = $this->decodeId($groupHashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的集团ID', 404);
        }

        $group = Group::find($groupId);
        if (!$group) {
            return $this->fail('集团不存在', 404);
        }

        $communityId = (int) $request->input('community_id', 0);
        if ($communityId <= 0) {
            return $this->fail('小区ID不能为空', 422);
        }

        // 检查是否已存在
        $existing = GroupCommunity::where('group_id', $groupId)
            ->where('community_id', $communityId)
            ->first();

        if ($existing) {
            return $this->fail('该小区已在集团中', 422);
        }

        GroupCommunity::create([
            'id'           => SnowflakeService::generate(),
            'group_id'     => $groupId,
            'community_id' => $communityId,
        ]);

        return $this->success([], '添加成功');
    }

    /**
     * 从集团移除小区
     * DELETE /admin/group/{hashid}/community/{communityHashid}
     */
    public function removeCommunity(Request $request, string $groupHashid, string $communityHashid)
    {
        try {
            $groupId      = $this->decodeId($groupHashid);
            $communityId  = $this->decodeId($communityHashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的参数', 404);
        }

        $item = GroupCommunity::where('group_id', $groupId)
            ->where('community_id', $communityId)
            ->first();

        if (!$item) {
            return $this->fail('关联记录不存在', 404);
        }

        $item->delete();

        return $this->success([], '移除成功');
    }

    /**
     * 集团汇总统计
     * GET /admin/group/{hashid}/summary
     */
    public function summary(Request $request, string $groupHashid)
    {
        try {
            $groupId = $this->decodeId($groupHashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的集团ID', 404);
        }

        $group = Group::find($groupId);
        if (!$group) {
            return $this->fail('集团不存在', 404);
        }

        $communityIds = GroupCommunity::where('group_id', $groupId)
            ->pluck('community_id')
            ->toArray();

        if (empty($communityIds)) {
            return $this->success([
                'total_rooms'      => 0,
                'total_owners'     => 0,
                'total_billed'     => '0.00',
                'total_paid'       => '0.00',
                'occupancy_rate'   => '0.00',
                'community_count'  => 0,
            ]);
        }

        // 总房产数
        $totalRooms = Room::whereIn('community_id', $communityIds)->count();

        // 总业主数（通过房产关联）
        $totalOwners = Owner::whereHas('rooms', function ($q) use ($communityIds) {
            $q->whereIn('room_id', function ($sub) use ($communityIds) {
                $sub->select('id')->from('erik_room')->whereIn('community_id', $communityIds);
            });
        })->count();

        // 总已入住房产
        $occupiedRooms = Room::whereIn('community_id', $communityIds)
            ->where('status', 1)
            ->count();

        // 入住率
        $occupancyRate = $totalRooms > 0 ? round(($occupiedRooms / $totalRooms) * 100, 2) : 0;

        // 总应收（账单金额汇总）
        $totalBilled = (float) FeeBill::whereHas('room', function ($q) use ($communityIds) {
            $q->whereIn('community_id', $communityIds);
        })->sum('amount');

        // 总已收（已缴金额汇总）
        $totalPaid = (float) FeeBill::whereHas('room', function ($q) use ($communityIds) {
            $q->whereIn('community_id', $communityIds);
        })->sum('paid_amount');

        return $this->success([
            'total_rooms'     => $totalRooms,
            'total_owners'    => $totalOwners,
            'total_billed'    => number_format($totalBilled, 2, '.', ''),
            'total_paid'      => number_format($totalPaid, 2, '.', ''),
            'occupancy_rate'  => number_format($occupancyRate, 2, '.', ''),
            'community_count' => count($communityIds),
        ]);
    }
}
