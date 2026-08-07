<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;

use app\common\SnowflakeService;
use app\model\FeeType;
use support\Request;

/**
 * 费用类型管理
 * @Apidoc\Group("property-core")
 * @Apidoc\Sort(8)
 */
class FeeTypeController extends BaseController
{
    /**
     * 费用类型列表
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/fee-type")
     * @Apidoc\Param("keyword", type="string", require=false, desc="搜索关键词")
     * @Apidoc\Param("category", type="int", require=false, desc="分类: 1=物业费 2=水费 3=电费 4=燃气 5=暖气 6=停车 7=维修基金 8=其他")
     * @Apidoc\Param(ref="pagination")
     * @Apidoc\Returned("id", type="string", desc="费用类型hashid")
     * @Apidoc\Returned("name", type="string", desc="费用名称")
     * @Apidoc\Returned("unit_price", type="float", desc="单价")
     * @Apidoc\Returned("is_required", type="int", desc="是否必须")
     * @Apidoc\Returned("created_at", type="string", desc="创建时间")
     */
    public function index(Request $request)
    {
        $keyword  = $request->input('keyword', '');
        $category = $request->input('category');

        $query = FeeType::query();
        if (!empty($keyword)) {
            $query->where('name', 'like', "%{$keyword}%");
        }
        if ($category !== null && $category !== '') {
            $query->where('category', (int) $category);
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'          => $this->encodeId($item->id),
                    'name'        => $item->name,
                    'category'    => $item->category,
                    'unit_price'  => $item->unit_price,
                    'unit_type'   => $item->unit_type,
                    'cycle_type'  => $item->cycle_type,
                    'is_required' => $item->is_required,
                    'sort'        => $item->sort,
                    'created_at'  => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 费用类型详情
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/fee-type/{hashid}")
     * @Apidoc\Param("hashid", type="string", require=true, desc="费用类型hashid", from="path")
     * @Apidoc\Returned("id", type="string", desc="费用类型hashid")
     * @Apidoc\Returned("name", type="string", desc="费用名称")
     */
    public function show(Request $request, string $hashid)
    {
        $id = $this->decodeId($hashid);
        $item = FeeType::find($id);
        if (!$item) {
            return $this->fail('费用类型不存在', 404);
        }

        return $this->success([
            'id'          => $this->encodeId($item->id),
            'name'        => $item->name,
            'category'    => $item->category,
            'unit_price'  => $item->unit_price,
            'unit_type'   => $item->unit_type,
            'cycle_type'  => $item->cycle_type,
            'is_required' => $item->is_required,
            'sort'        => $item->sort,
        ]);
    }

    /**
     * 创建费用类型
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/fee-type")
     * @Apidoc\Param("name", type="string", require=true, desc="费用名称")
     * @Apidoc\Param("category", type="int", require=false, desc="分类: 1=物业费 2=水费 3=电费 4=燃气 5=暖气 6=停车 7=维修基金 8=其他")
     * @Apidoc\Param("unit_price", type="float", require=false, desc="单价")
     * @Apidoc\Param("unit_type", type="int", require=false, desc="单位: 1=元/m²/月 2=元/吨 3=元/度 4=元/月/辆 5=固定金额")
     * @Apidoc\Param("cycle_type", type="int", require=false, desc="周期: 1=每月 2=每季 3=每半年 4=每年 5=一次性")
     * @Apidoc\Param("is_required", type="int", require=false, desc="是否必须: 0=可选 1=必须")
     * @Apidoc\Param("sort", type="int", require=false, desc="排序")
     * @Apidoc\Returned("id", type="string", desc="新建费用类型的hashid")
     */
    public function store(Request $request)
    {
        $data = $request->only([
            'name', 'category', 'unit_price', 'unit_type',
            'cycle_type', 'is_required', 'sort',
        ]);

        if (empty($data['name'])) {
            return $this->fail('费用名称不能为空', 422);
        }

        $data['id'] = SnowflakeService::generate();

        FeeType::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /** 更新费用类型 */
    public function update(Request $request, string $hashid)
    {
        $id = $this->decodeId($hashid);
        $item = FeeType::find($id);
        if (!$item) {
            return $this->fail('费用类型不存在', 404);
        }

        $item->fill($request->only([
            'name', 'category', 'unit_price', 'unit_type',
            'cycle_type', 'is_required', 'sort',
        ]));
        $item->save();

        return $this->success([], '更新成功');
    }

    /** 删除费用类型（需密码确认） */
    public function destroy(Request $request, string $hashid)
    {
        $adminId = $request->adminId;
        $password = $request->input('password', '');

        $error = $this->confirmPassword($adminId, $password, $request);
        if ($error !== null) {
            return $this->fail($error, 422);
        }

        $id = $this->decodeId($hashid);
        $item = FeeType::find($id);
        if (!$item) {
            return $this->fail('费用类型不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }
}
