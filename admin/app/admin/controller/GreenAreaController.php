<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;

use app\common\SnowflakeService;
use app\model\GreenArea;
use support\Request;

class GreenAreaController extends BaseController
{
    /**
     * 绿化区域列表
     * ?community_id=xxx&status=xxx&keyword=搜索词
     */
    public function index(Request $request)
    {
        $communityId = $request->input('community_id');
        $status      = $request->input('status');
        $keyword     = $request->input('keyword', '');

        $query = GreenArea::query();

        if (!empty($communityId)) {
            $query->where('community_id', (int) $communityId);
        }
        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        }
        if (!empty($keyword)) {
            $query->where('name', 'like', "%{$keyword}%");
        }

        $list = $query->orderBy('sort', 'asc')
            ->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'                => $this->encodeId($item->id),
                    'community_id'      => $this->encodeId($item->community_id),
                    'name'              => $item->name,
                    'location'          => $item->location,
                    'area'              => $item->area,
                    'plant_types'       => $item->plant_types,
                    'responsible_staff' => $item->responsible_staff,
                    'sort'              => $item->sort,
                    'status'            => $item->status,
                    'created_at'        => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /** 绿化区域详情 */
    public function show(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = GreenArea::find($id);
        if (!$item) {
            return $this->fail('绿化区域不存在', 404);
        }

        return $this->success([
            'id'                => $this->encodeId($item->id),
            'community_id'      => $this->encodeId($item->community_id),
            'name'              => $item->name,
            'location'          => $item->location,
            'area'              => $item->area,
            'plant_types'       => $item->plant_types,
            'responsible_staff' => $item->responsible_staff,
            'sort'              => $item->sort,
            'status'            => $item->status,
            'created_at'        => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
            'updated_at'        => $item->updated_at ? $item->updated_at->format('Y-m-d H:i') : '',
        ]);
    }

    /** 创建绿化区域 */
    public function store(Request $request)
    {
        $data = $request->only([
            'community_id', 'name', 'location', 'area', 'plant_types',
            'responsible_staff', 'sort',
        ]);

        if (empty($data['community_id'])) {
            return $this->fail('请选择所属小区', 422);
        }
        if (empty($data['name'])) {
            return $this->fail('区域名称不能为空', 422);
        }

        $data['id']     = SnowflakeService::generate();
        $data['status'] = $request->input('status', 1);

        GreenArea::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /** 更新绿化区域 */
    public function update(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = GreenArea::find($id);
        if (!$item) {
            return $this->fail('绿化区域不存在', 404);
        }

        $item->fill($request->only([
            'community_id', 'name', 'location', 'area', 'plant_types',
            'responsible_staff', 'sort', 'status',
        ]));
        $item->save();

        return $this->success([], '更新成功');
    }

    /** 删除绿化区域（需密码确认） */
    public function destroy(Request $request, string $hashid)
    {
        $adminId  = $request->adminId;
        $password = $request->input('password', '');

        $error = $this->confirmPassword($adminId, $password, $request);
        if ($error !== null) {
            return $this->fail($error, 422);
        }

        $id   = $this->decodeId($hashid);
        $item = GreenArea::find($id);
        if (!$item) {
            return $this->fail('绿化区域不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }
}
