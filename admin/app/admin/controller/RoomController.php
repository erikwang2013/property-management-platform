<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;

use app\common\SnowflakeService;
use app\model\Building;
use app\model\Community;
use app\model\Room;
use app\model\RoomType;
use app\model\Unit;
use support\Request;

/**
 * 房产管理
 * @Apidoc\Group("property-core")
 * @Apidoc\Sort(5)
 */
class RoomController extends BaseController
{
    /**
     * 房产列表
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/room")
     * @Apidoc\Param("keyword", type="string", require=false, desc="搜索关键词（房号）")
     * @Apidoc\Param("community_id", type="string", require=false, desc="小区hashid")
     * @Apidoc\Param("building_id", type="string", require=false, desc="楼栋hashid")
     * @Apidoc\Param("unit_id", type="string", require=false, desc="单元hashid")
     * @Apidoc\Param("status", type="int", require=false, desc="状态: 0=空置 1=已售 2=出租 3=自住")
     * @Apidoc\Param(ref="pagination")
     * @Apidoc\Returned("id", type="string", desc="房产hashid")
     * @Apidoc\Returned("room_number", type="string", desc="房号")
     * @Apidoc\Returned("floor", type="int", desc="楼层")
     * @Apidoc\Returned("area_total", type="float", desc="总面积")
     * @Apidoc\Returned("status", type="int", desc="状态")
     * @Apidoc\Returned("created_at", type="string", desc="创建时间")
     */
    public function index(Request $request)
    {
        $keyword     = $request->input('keyword', '');
        $communityId = $request->input('community_id');
        $buildingId  = $request->input('building_id');
        $unitId      = $request->input('unit_id');
        $status      = $request->input('status');

        $query = Room::query();
        if (!empty($keyword)) {
            $query->where('room_number', 'like', "%{$keyword}%");
        }
        if (!empty($communityId)) {
            $query->where('community_id', $this->decodeId($communityId));
        }
        if (!empty($buildingId)) {
            $query->where('building_id', $this->decodeId($buildingId));
        }
        if (!empty($unitId)) {
            $query->where('unit_id', $this->decodeId($unitId));
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
                    'building_id'  => $this->encodeId($item->building_id),
                    'unit_id'      => $this->encodeId($item->unit_id),
                    'room_number'  => $item->room_number,
                    'floor'        => $item->floor,
                    'room_type_id' => $item->room_type_id ? $this->encodeId($item->room_type_id) : '',
                    'area_indoor'  => $item->area_indoor,
                    'area_total'   => $item->area_total,
                    'orientation'  => $item->orientation,
                    'usage_type'   => $item->usage_type,
                    'status'       => $item->status,
                    'created_at'   => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 房产层级树（小区→楼栋→单元→房产）
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/room/tree")
     * @Apidoc\Param("community_id", type="string", require=false, desc="小区hashid，缺省返回全部小区")
     * @Apidoc\Returned("children", type="array", desc="子节点数组")
     */
    public function tree(Request $request)
    {
        $communityId = $request->input('community_id');

        $communityQuery = Community::query();
        if (!empty($communityId)) {
            $communityQuery->where('id', $this->decodeId($communityId));
        }

        $tree = [];
        foreach ($communityQuery->orderBy('created_at', 'asc')->get() as $community) {
            $node = [
                'id'       => $this->encodeId($community->id),
                'name'     => $community->name,
                'type'     => 'community',
                'children' => [],
            ];
            $buildings = Building::where('community_id', $community->id)
                ->orderBy('sort')->orderBy('id')->get();
            foreach ($buildings as $building) {
                $bNode = [
                    'id'       => $this->encodeId($building->id),
                    'name'     => $building->name,
                    'type'     => 'building',
                    'children' => [],
                ];
                $units = Unit::where('building_id', $building->id)
                    ->orderBy('sort')->orderBy('id')->get();
                foreach ($units as $unit) {
                    $uNode = [
                        'id'       => $this->encodeId($unit->id),
                        'name'     => $unit->name,
                        'type'     => 'unit',
                        'children' => [],
                    ];
                    $rooms = Room::where('unit_id', $unit->id)
                        ->orderBy('floor')->orderBy('room_number')->get();
                    foreach ($rooms as $room) {
                        $uNode['children'][] = [
                            'id'     => $this->encodeId($room->id),
                            'name'   => $room->room_number,
                            'type'   => 'room',
                            'status' => $room->status,
                        ];
                    }
                    $bNode['children'][] = $uNode;
                }
                $node['children'][] = $bNode;
            }
            $tree[] = $node;
        }

        return $this->success($tree);
    }

    /**
     * 房产详情
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/room/{hashid}")
     * @Apidoc\Param("hashid", type="string", require=true, desc="房产hashid", from="path")
     * @Apidoc\Returned("id", type="string", desc="房产hashid")
     * @Apidoc\Returned("room_number", type="string", desc="房号")
     */
    public function show(Request $request, string $hashid)
    {
        $id = $this->decodeId($hashid);
        $item = Room::find($id);
        if (!$item) {
            return $this->fail('房产不存在', 404);
        }

        return $this->success([
            'id'           => $this->encodeId($item->id),
            'community_id' => $this->encodeId($item->community_id),
            'building_id'  => $this->encodeId($item->building_id),
            'unit_id'      => $this->encodeId($item->unit_id),
            'room_number'  => $item->room_number,
            'floor'        => $item->floor,
            'room_type_id' => $item->room_type_id ? $this->encodeId($item->room_type_id) : '',
            'area_indoor'  => $item->area_indoor,
            'area_shared'  => $item->area_shared,
            'area_total'   => $item->area_total,
            'orientation'  => $item->orientation,
            'decoration'   => $item->decoration,
            'usage_type'   => $item->usage_type,
            'status'       => $item->status,
            'remark'       => $item->remark,
        ]);
    }

    /**
     * 创建房产
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/room")
     * @Apidoc\Param("community_id", type="string", require=true, desc="小区hashid")
     * @Apidoc\Param("building_id", type="string", require=true, desc="楼栋hashid")
     * @Apidoc\Param("unit_id", type="string", require=true, desc="单元hashid")
     * @Apidoc\Param("room_number", type="string", require=true, desc="房号")
     * @Apidoc\Param("floor", type="int", require=false, desc="楼层")
     * @Apidoc\Param("room_type_id", type="string", require=false, desc="户型hashid")
     * @Apidoc\Param("area_indoor", type="float", require=false, desc="套内面积")
     * @Apidoc\Param("area_shared", type="float", require=false, desc="公摊面积")
     * @Apidoc\Param("area_total", type="float", require=false, desc="总面积")
     * @Apidoc\Param("orientation", type="string", require=false, desc="朝向")
     * @Apidoc\Param("decoration", type="int", require=false, desc="装修: 1=毛坯 2=简装 3=精装 4=豪装")
     * @Apidoc\Param("usage_type", type="int", require=false, desc="用途: 1=住宅 2=商业 3=办公 4=仓储")
     * @Apidoc\Param("status", type="int", require=false, desc="状态: 0=空置 1=已售 2=出租 3=自住")
     * @Apidoc\Param("remark", type="string", require=false, desc="备注")
     * @Apidoc\Returned("id", type="string", desc="新建房产的hashid")
     */
    public function store(Request $request)
    {
        $data = $request->only([
            'community_id', 'building_id', 'unit_id', 'room_number',
            'floor', 'room_type_id', 'area_indoor', 'area_shared',
            'area_total', 'orientation', 'decoration', 'usage_type',
            'status', 'remark',
        ]);

        if (empty($data['community_id'])) {
            return $this->fail('请选择所属小区', 422);
        }
        if (empty($data['building_id'])) {
            return $this->fail('请选择所属楼栋', 422);
        }
        if (empty($data['unit_id'])) {
            return $this->fail('请选择所属单元', 422);
        }
        if (empty($data['room_number'])) {
            return $this->fail('房号不能为空', 422);
        }

        $data['community_id'] = $this->decodeId($data['community_id']);
        $data['building_id']  = $this->decodeId($data['building_id']);
        $data['unit_id']      = $this->decodeId($data['unit_id']);
        if (!empty($data['room_type_id'])) {
            $roomTypeId = $this->decodeId($data['room_type_id']);
            if (!RoomType::find($roomTypeId)) {
                return $this->fail('户型不存在', 422);
            }
            $data['room_type_id'] = $roomTypeId;
        } else {
            $data['room_type_id'] = 0;
        }
        $data['id'] = SnowflakeService::generate();

        Room::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /** 更新房产 */
    public function update(Request $request, string $hashid)
    {
        $id = $this->decodeId($hashid);
        $item = Room::find($id);
        if (!$item) {
            return $this->fail('房产不存在', 404);
        }

        $data = $request->only([
            'room_number', 'floor', 'room_type_id', 'area_indoor',
            'area_shared', 'area_total', 'orientation', 'decoration',
            'usage_type', 'status', 'remark',
        ]);
        if (!empty($data['room_type_id'])) {
            $data['room_type_id'] = $this->decodeId($data['room_type_id']);
        }
        $item->fill($data);
        $item->save();

        return $this->success([], '更新成功');
    }

    /** 删除房产（需密码确认） */
    public function destroy(Request $request, string $hashid)
    {
        $adminId = $request->adminId;
        $password = $request->input('password', '');

        $error = $this->confirmPassword($adminId, $password, $request);
        if ($error !== null) {
            return $this->fail($error, 422);
        }

        $id = $this->decodeId($hashid);
        $item = Room::find($id);
        if (!$item) {
            return $this->fail('房产不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }
}
