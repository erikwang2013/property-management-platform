<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;
use hg\apidoc\annotation as Apidoc;

use app\common\SnowflakeService;
use app\model\Building;
use app\model\Unit;
use support\Request;

/**
 * 单元管理
 * @Apidoc\Group("property-core")
 * @Apidoc\Sort(3)
 */
class UnitController extends BaseController
{
    /**
     * 单元列表
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/unit")
     * @Apidoc\Param("keyword", type="string", require=false, desc="搜索关键词")
     * @Apidoc\Param("building_id", type="string", require=false, desc="楼栋hashid")
     * @Apidoc\Param(ref="pagination")
     * @Apidoc\Returned("id", type="string", desc="单元hashid")
     * @Apidoc\Returned("building_id", type="string", desc="楼栋hashid")
     * @Apidoc\Returned("name", type="string", desc="单元名称")
     * @Apidoc\Returned("room_count_per_floor", type="int", desc="每层户数")
     * @Apidoc\Returned("created_at", type="string", desc="创建时间")
     */
    public function index(Request $request)
    {
        $keyword    = $request->input('keyword', '');
        $buildingId = $request->input('building_id');

        $query = Unit::query();
        if (!empty($keyword)) {
            $query->where('name', 'like', "%{$keyword}%");
        }
        if (!empty($buildingId)) {
            $query->where('building_id', $this->decodeId($buildingId));
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'                  => $this->encodeId($item->id),
                    'building_id'         => $this->encodeId($item->building_id),
                    'name'                => $item->name,
                    'room_count_per_floor' => $item->room_count_per_floor,
                    'sort'                => $item->sort,
                    'created_at'          => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 单元详情
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/unit/{hashid}")
     * @Apidoc\Param("hashid", type="string", require=true, desc="单元hashid", from="path")
     * @Apidoc\Returned("id", type="string", desc="单元hashid")
     * @Apidoc\Returned("name", type="string", desc="单元名称")
     */
    public function show(Request $request, string $hashid)
    {
        $id = $this->decodeId($hashid);
        $item = Unit::find($id);
        if (!$item) {
            return $this->fail('单元不存在', 404);
        }

        return $this->success([
            'id'                   => $this->encodeId($item->id),
            'building_id'          => $this->encodeId($item->building_id),
            'name'                 => $item->name,
            'room_count_per_floor' => $item->room_count_per_floor,
            'sort'                 => $item->sort,
        ]);
    }

    /**
     * 创建单元
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/unit")
     * @Apidoc\Param("building_id", type="string", require=true, desc="楼栋hashid")
     * @Apidoc\Param("name", type="string", require=true, desc="单元名称")
     * @Apidoc\Param("room_count_per_floor", type="int", require=false, desc="每层户数")
     * @Apidoc\Param("sort", type="int", require=false, desc="排序")
     * @Apidoc\Returned("id", type="string", desc="新建单元的hashid")
     */
    public function store(Request $request)
    {
        $data = $request->only([
            'building_id', 'name', 'room_count_per_floor', 'sort',
        ]);

        if (empty($data['building_id'])) {
            return $this->fail('请选择所属楼栋', 422);
        }
        $buildingId = $this->decodeId($data['building_id']);
        if (!Building::find($buildingId)) {
            return $this->fail('楼栋不存在', 422);
        }
        if (empty($data['name'])) {
            return $this->fail('单元名称不能为空', 422);
        }

        $data['building_id'] = $buildingId;
        $data['id'] = SnowflakeService::generate();

        Unit::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /**
     * @Apidoc\Method("PUT")
     * @Apidoc\Url("/admin/unit/{hashid}")
     */
    public function update(Request $request, string $hashid)
    {
        $id = $this->decodeId($hashid);
        $item = Unit::find($id);
        if (!$item) {
            return $this->fail('单元不存在', 404);
        }

        $item->fill($request->only([
            'name', 'room_count_per_floor', 'sort',
        ]));
        $item->save();

        return $this->success([], '更新成功');
    }

    /**
     * @Apidoc\Method("DELETE")
     * @Apidoc\Url("/admin/unit/{hashid}")
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
        $item = Unit::find($id);
        if (!$item) {
            return $this->fail('单元不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }
}
