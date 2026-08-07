<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;
use hg\apidoc\annotation as Apidoc;

use app\common\SnowflakeService;
use app\model\Building;
use app\model\Community;
use support\Request;

/**
 * 楼栋管理
 * @Apidoc\Group("property-core")
 * @Apidoc\Sort(2)
 */
class BuildingController extends BaseController
{
    /**
     * 楼栋列表
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/building")
     * @Apidoc\Param("keyword", type="string", require=false, desc="搜索关键词")
     * @Apidoc\Param("community_id", type="string", require=false, desc="小区hashid")
     * @Apidoc\Param(ref="pagination")
     * @Apidoc\Returned("id", type="string", desc="楼栋hashid")
     * @Apidoc\Returned("community_id", type="string", desc="小区hashid")
     * @Apidoc\Returned("name", type="string", desc="楼栋名称")
     * @Apidoc\Returned("floor_count", type="int", desc="总层数")
     * @Apidoc\Returned("unit_count", type="int", desc="单元数")
     * @Apidoc\Returned("created_at", type="string", desc="创建时间")
     */
    public function index(Request $request)
    {
        $keyword     = $request->input('keyword', '');
        $communityId = $request->input('community_id');

        $query = Building::query();
        if (!empty($keyword)) {
            $query->where('name', 'like', "%{$keyword}%");
        }
        if (!empty($communityId)) {
            $query->where('community_id', $this->decodeId($communityId));
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'           => $this->encodeId($item->id),
                    'community_id' => $this->encodeId($item->community_id),
                    'name'         => $item->name,
                    'building_type' => $item->building_type,
                    'floor_count'  => $item->floor_count,
                    'unit_count'   => $item->unit_count,
                    'elevator_count' => $item->elevator_count,
                    'build_year'   => $item->build_year,
                    'structure_type' => $item->structure_type,
                    'sort'         => $item->sort,
                    'created_at'   => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 楼栋详情
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/building/{hashid}")
     * @Apidoc\Param("hashid", type="string", require=true, desc="楼栋hashid", from="path")
     * @Apidoc\Returned("id", type="string", desc="楼栋hashid")
     * @Apidoc\Returned("name", type="string", desc="楼栋名称")
     */
    public function show(Request $request, string $hashid)
    {
        $id = $this->decodeId($hashid);
        $item = Building::find($id);
        if (!$item) {
            return $this->fail('楼栋不存在', 404);
        }

        return $this->success([
            'id'             => $this->encodeId($item->id),
            'community_id'   => $this->encodeId($item->community_id),
            'name'           => $item->name,
            'building_type'  => $item->building_type,
            'floor_count'    => $item->floor_count,
            'unit_count'     => $item->unit_count,
            'elevator_count' => $item->elevator_count,
            'build_year'     => $item->build_year,
            'structure_type' => $item->structure_type,
            'sort'           => $item->sort,
        ]);
    }

    /**
     * 创建楼栋
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/building")
     * @Apidoc\Param("community_id", type="string", require=true, desc="小区hashid")
     * @Apidoc\Param("name", type="string", require=true, desc="楼栋名称")
     * @Apidoc\Param("building_type", type="int", require=false, desc="类型: 1=塔楼 2=板楼 3=别墅 4=商业")
     * @Apidoc\Param("floor_count", type="int", require=false, desc="总层数")
     * @Apidoc\Param("unit_count", type="int", require=false, desc="单元数")
     * @Apidoc\Param("elevator_count", type="int", require=false, desc="电梯数")
     * @Apidoc\Param("build_year", type="int", require=false, desc="建成年份")
     * @Apidoc\Param("structure_type", type="string", require=false, desc="结构类型")
     * @Apidoc\Param("sort", type="int", require=false, desc="排序")
     * @Apidoc\Returned("id", type="string", desc="新建楼栋的hashid")
     */
    public function store(Request $request)
    {
        $data = $request->only([
            'community_id', 'name', 'building_type',
            'floor_count', 'unit_count', 'elevator_count',
            'build_year', 'structure_type', 'sort',
        ]);

        if (empty($data['community_id'])) {
            return $this->fail('请选择所属小区', 422);
        }
        $communityId = $this->decodeId($data['community_id']);
        if (!Community::find($communityId)) {
            return $this->fail('小区不存在', 422);
        }
        if (empty($data['name'])) {
            return $this->fail('楼栋名称不能为空', 422);
        }

        $data['community_id'] = $communityId;
        $data['id'] = SnowflakeService::generate();

        Building::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /**
     * @Apidoc\Method("PUT")
     * @Apidoc\Url("/admin/building/{hashid}")
     */
    public function update(Request $request, string $hashid)
    {
        $id = $this->decodeId($hashid);
        $item = Building::find($id);
        if (!$item) {
            return $this->fail('楼栋不存在', 404);
        }

        $item->fill($request->only([
            'name', 'building_type', 'floor_count', 'unit_count',
            'elevator_count', 'build_year', 'structure_type', 'sort',
        ]));
        $item->save();

        return $this->success([], '更新成功');
    }

    /**
     * @Apidoc\Method("DELETE")
     * @Apidoc\Url("/admin/building/{hashid}")
     */
    public function destroy(Request $request, string $hashid)
    {
        $adminId = $request->adminId;
        $password = $request->input('password', '');

        $error = $this->confirmPassword($adminId, $password, $request);
        if ($error !== null) {
            return $this->fail($error, 422);
        }

        $id = $this->decodeId($hashid);
        $item = Building::find($id);
        if (!$item) {
            return $this->fail('楼栋不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }
}
