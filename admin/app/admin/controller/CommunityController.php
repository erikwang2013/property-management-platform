<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;

use app\common\SnowflakeService;
use app\model\Community;
use support\Request;

/**
 * @Apidoc\Group("property-core")
 */
class CommunityController extends BaseController
{
    /**
     * 小区列表
     * ?keyword=搜索词&status=状态
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

    /** 小区详情 */
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

    /** 创建小区 */
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

    /** 更新小区 */
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

    /** 删除小区（需密码确认） */
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
