<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;
use hg\apidoc\annotation as Apidoc;

use app\common\SnowflakeService;
use app\model\Equipment;
use support\Request;

/**
 * 物业管理·辅助
 * @Apidoc\Group("property-aux")
 */
class EquipmentController extends BaseController
{
    /**
     * 设备列表
     * ?community_id=xxx&category=xxx&status=xxx&keyword=搜索词&page_size=20
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/equipment")
     */
    public function index(Request $request)
    {
        $communityId = $request->input('community_id');
        $category    = $request->input('category');
        $status      = $request->input('status');
        $keyword     = $request->input('keyword', '');

        $query = Equipment::query();

        if (!empty($communityId)) {
            $query->where('community_id', (int) $communityId);
        }
        if ($category !== null && $category !== '') {
            $query->where('category', (int) $category);
        }
        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        }
        if (!empty($keyword)) {
            $query->where(function ($q) use ($keyword) {
                $q->where('name', 'like', "%{$keyword}%")
                  ->orWhere('equipment_number', 'like', "%{$keyword}%");
            });
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'               => $this->encodeId($item->id),
                    'community_id'     => $this->encodeId($item->community_id),
                    'name'             => $item->name,
                    'equipment_number' => $item->equipment_number,
                    'category'         => $item->category,
                    'brand'            => $item->brand,
                    'model'            => $item->model,
                    'location'         => $item->location,
                    'status'           => $item->status,
                    'install_date'     => $item->install_date ? $item->install_date->format('Y-m-d') : '',
                    'warranty_end'    => $item->warranty_end ? $item->warranty_end->format('Y-m-d') : '',
                    'created_at'      => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/equipment/{hashid}")
     */
    public function show(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = Equipment::find($id);
        if (!$item) {
            return $this->fail('设备不存在', 404);
        }

        return $this->success([
            'id'               => $this->encodeId($item->id),
            'community_id'     => $this->encodeId($item->community_id),
            'name'             => $item->name,
            'equipment_number' => $item->equipment_number,
            'category'         => $item->category,
            'brand'            => $item->brand,
            'model'            => $item->model,
            'location'         => $item->location,
            'install_date'     => $item->install_date ? $item->install_date->format('Y-m-d') : '',
            'warranty_end'     => $item->warranty_end ? $item->warranty_end->format('Y-m-d') : '',
            'service_life'     => $item->service_life,
            'status'           => $item->status,
            'created_at'       => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
            'updated_at'       => $item->updated_at ? $item->updated_at->format('Y-m-d H:i') : '',
        ]);
    }

    /**
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/equipment")
     */
    public function store(Request $request)
    {
        $data = $request->only([
            'community_id', 'name', 'equipment_number', 'category',
            'brand', 'model', 'location', 'install_date',
            'warranty_end', 'service_life',
        ]);

        if (empty($data['community_id'])) {
            return $this->fail('请选择所属小区', 422);
        }
        if (empty($data['name'])) {
            return $this->fail('设备名称不能为空', 422);
        }

        $data['id']     = SnowflakeService::generate();
        $data['status'] = $request->input('status', 1);

        Equipment::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /**
     * @Apidoc\Method("PUT")
     * @Apidoc\Url("/admin/equipment/{hashid}")
     */
    public function update(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = Equipment::find($id);
        if (!$item) {
            return $this->fail('设备不存在', 404);
        }

        $item->fill($request->only([
            'community_id', 'name', 'equipment_number', 'category',
            'brand', 'model', 'location', 'install_date',
            'warranty_end', 'service_life', 'status',
        ]));
        $item->save();

        return $this->success([], '更新成功');
    }

    /**
     * @Apidoc\Method("DELETE")
     * @Apidoc\Url("/admin/equipment/{hashid}")
     */
    public function destroy(Request $request, string $hashid)
    {
        $adminId  = $request->adminId;
        $password = $request->input('password', '');

        $error = $this->confirmPassword($adminId, $password, $request);
        if ($error !== null) {
            return $this->fail($error, 422);
        }

        $id   = $this->decodeId($hashid);
        $item = Equipment::find($id);
        if (!$item) {
            return $this->fail('设备不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }
}
