<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;
use hg\apidoc\annotation as Apidoc;

use app\common\SnowflakeService;
use app\model\RoomType;
use support\Request;

/**
 * 户型管理
 * @Apidoc\Group("property-core")
 * @Apidoc\Sort(4)
 */
class RoomTypeController extends BaseController
{
    /**
     * 户型列表
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/room-type")
     * @Apidoc\Param("keyword", type="string", require=false, desc="搜索关键词")
     * @Apidoc\Param(ref="pagination")
     * @Apidoc\Returned("id", type="string", desc="户型hashid")
     * @Apidoc\Returned("name", type="string", desc="户型名称")
     * @Apidoc\Returned("bedrooms", type="int", desc="室")
     * @Apidoc\Returned("halls", type="int", desc="厅")
     * @Apidoc\Returned("bathrooms", type="int", desc="卫")
     * @Apidoc\Returned("created_at", type="string", desc="创建时间")
     */
    public function index(Request $request)
    {
        $keyword = $request->input('keyword', '');

        $query = RoomType::query();
        if (!empty($keyword)) {
            $query->where('name', 'like', "%{$keyword}%");
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'         => $this->encodeId($item->id),
                    'name'       => $item->name,
                    'bedrooms'   => $item->bedrooms,
                    'halls'      => $item->halls,
                    'bathrooms'  => $item->bathrooms,
                    'image'      => $item->image,
                    'created_at' => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 户型详情
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/room-type/{hashid}")
     * @Apidoc\Param("hashid", type="string", require=true, desc="户型hashid", from="path")
     * @Apidoc\Returned("id", type="string", desc="户型hashid")
     * @Apidoc\Returned("name", type="string", desc="户型名称")
     */
    public function show(Request $request, string $hashid)
    {
        $id = $this->decodeId($hashid);
        $item = RoomType::find($id);
        if (!$item) {
            return $this->fail('户型不存在', 404);
        }

        return $this->success([
            'id'        => $this->encodeId($item->id),
            'name'      => $item->name,
            'bedrooms'  => $item->bedrooms,
            'halls'     => $item->halls,
            'bathrooms' => $item->bathrooms,
            'image'     => $item->image,
        ]);
    }

    /**
     * 创建户型
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/room-type")
     * @Apidoc\Param("name", type="string", require=true, desc="户型名称")
     * @Apidoc\Param("bedrooms", type="int", require=false, desc="室")
     * @Apidoc\Param("halls", type="int", require=false, desc="厅")
     * @Apidoc\Param("bathrooms", type="int", require=false, desc="卫")
     * @Apidoc\Param("image", type="string", require=false, desc="户型图URL")
     * @Apidoc\Returned("id", type="string", desc="新建户型的hashid")
     */
    public function store(Request $request)
    {
        $data = $request->only([
            'name', 'bedrooms', 'halls', 'bathrooms', 'image',
        ]);

        if (empty($data['name'])) {
            return $this->fail('户型名称不能为空', 422);
        }

        $data['id'] = SnowflakeService::generate();

        RoomType::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /**
     * @Apidoc\Method("PUT")
     * @Apidoc\Url("/admin/room-type/{hashid}")
     */
    public function update(Request $request, string $hashid)
    {
        $id = $this->decodeId($hashid);
        $item = RoomType::find($id);
        if (!$item) {
            return $this->fail('户型不存在', 404);
        }

        $item->fill($request->only([
            'name', 'bedrooms', 'halls', 'bathrooms', 'image',
        ]));
        $item->save();

        return $this->success([], '更新成功');
    }

    /**
     * @Apidoc\Method("DELETE")
     * @Apidoc\Url("/admin/room-type/{hashid}")
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
        $item = RoomType::find($id);
        if (!$item) {
            return $this->fail('户型不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }
}
