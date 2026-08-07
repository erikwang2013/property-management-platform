<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;
use hg\apidoc\annotation as Apidoc;

use app\common\SnowflakeService;
use app\model\Community;
use support\Request;

/**
 * 小区管理
 * @Apidoc\Group("property-core")
 * @Apidoc\Sort(1)
 */
class CommunityController extends BaseController
{
    /**
     * 小区列表
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/community")
     * @Apidoc\Param("keyword", type="string", require=false, desc="搜索关键词")
     * @Apidoc\Param("status", type="int", require=false, desc="状态: 0=停用 1=正常")
     * @Apidoc\Param(ref="pagination")
     * @Apidoc\Returned("id", type="string", desc="小区hashid")
     * @Apidoc\Returned("name", type="string", desc="小区名称")
     * @Apidoc\Returned("address", type="string", desc="详细地址")
     * @Apidoc\Returned("city", type="string", desc="城市")
     * @Apidoc\Returned("building_count", type="int", desc="楼栋总数")
     * @Apidoc\Returned("room_count", type="int", desc="房屋总套数")
     * @Apidoc\Returned("property_company", type="string", desc="物业公司")
     * @Apidoc\Returned("status", type="int", desc="状态")
     * @Apidoc\Returned("created_at", type="string", desc="创建时间")
     */
    public function index(Request $request)
    {
        $keyword = $request->input('keyword', '');
        $status = $request->input('status');

        $query = Community::query();
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
                    'id' => $this->encodeId($item->id),
                    'name' => $item->name,
                    'address' => $item->address,
                    'city' => $item->city,
                    'building_count' => $item->building_count,
                    'room_count' => $item->room_count,
                    'property_company' => $item->property_company,
                    'status' => $item->status,
                    'created_at' => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 小区详情
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/community/{hashid}")
     * @Apidoc\Param("hashid", type="string", require=true, desc="小区hashid", from="path")
     * @Apidoc\Returned("id", type="string", desc="小区hashid")
     * @Apidoc\Returned("name", type="string", desc="名称")
     * @Apidoc\Returned("address", type="string", desc="地址")
     * @Apidoc\Returned("area_total", type="float", desc="总面积(m²)")
     */
    public function show(Request $request, string $hashid)
    {
        $id = $this->decodeId($hashid);
        $item = Community::find($id);
        if (!$item) {
            return $this->fail('小区不存在', 404);
        }

        return $this->success([
            'id' => $this->encodeId($item->id),
            'name' => $item->name,
            'address' => $item->address,
            'province' => $item->province,
            'city' => $item->city,
            'district' => $item->district,
            'area_total' => $item->area_total,
            'building_count' => $item->building_count,
            'room_count' => $item->room_count,
            'developer' => $item->developer,
            'property_company' => $item->property_company,
            'contact_phone' => $item->contact_phone,
            'description' => $item->description,
            'status' => $item->status,
        ]);
    }

    /**
     * 创建小区
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/community")
     * @Apidoc\Param("name", type="string", require=true, desc="小区名称")
     * @Apidoc\Param("address", type="string", require=false, desc="详细地址")
     * @Apidoc\Param("province", type="string", require=false, desc="省")
     * @Apidoc\Param("city", type="string", require=false, desc="市")
     * @Apidoc\Param("district", type="string", require=false, desc="区")
     * @Apidoc\Param("area_total", type="float", require=false, desc="总建筑面积(m²)")
     * @Apidoc\Param("developer", type="string", require=false, desc="开发商")
     * @Apidoc\Param("property_company", type="string", require=false, desc="物业公司")
     * @Apidoc\Param("contact_phone", type="string", require=false, desc="联系电话")
     * @Apidoc\Param("description", type="string", require=false, desc="简介")
     * @Apidoc\Returned("id", type="string", desc="新建小区的hashid")
     */
    public function store(Request $request)
    {
        $data = $request->only([
            'name', 'address', 'province', 'city', 'district',
            'area_total', 'developer', 'property_company',
            'contact_phone', 'description',
        ]);

        if (empty($data['name'])) {
            return $this->fail('小区名称不能为空', 422);
        }

        $data['id'] = SnowflakeService::generate();
        $data['status'] = 1;

        Community::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /**
     * @Apidoc\Method("PUT")
     * @Apidoc\Url("/admin/community/{hashid}")
     */
    public function update(Request $request, string $hashid)
    {
        $id = $this->decodeId($hashid);
        $item = Community::find($id);
        if (!$item) {
            return $this->fail('小区不存在', 404);
        }

        $item->fill($request->only([
            'name', 'address', 'province', 'city', 'district',
            'area_total', 'developer', 'property_company',
            'contact_phone', 'description', 'status',
        ]));
        $item->save();

        return $this->success([], '更新成功');
    }

    /**
     * @Apidoc\Method("DELETE")
     * @Apidoc\Url("/admin/community/{hashid}")
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
        $item = Community::find($id);
        if (!$item) {
            return $this->fail('小区不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }
}
