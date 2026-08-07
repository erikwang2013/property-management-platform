<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;
use hg\apidoc\annotation as Apidoc;

use app\common\SnowflakeService;
use app\model\EquipmentMaintenance;
use support\Request;

/**
 * 物业管理·辅助
 * @Apidoc\Group("property-aux")
 */
class EquipmentMaintenanceController extends BaseController
{
    /**
     * 维保记录列表
     * ?equipment_id=xxx&page_size=20
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/equipment-maintenance")
     */
    public function index(Request $request)
    {
        $equipmentId = $request->input('equipment_id');

        $query = EquipmentMaintenance::with('equipment');

        if (!empty($equipmentId)) {
            $query->where('equipment_id', (int) $equipmentId);
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'               => $this->encodeId($item->id),
                    'equipment_id'     => $this->encodeId($item->equipment_id),
                    'maintenance_type' => $item->maintenance_type,
                    'description'      => $item->description,
                    'staff_id'         => $this->encodeId($item->staff_id),
                    'cost'             => $item->cost,
                    'company'          => $item->company,
                    'started_at'       => $item->started_at ? $item->started_at->format('Y-m-d H:i') : '',
                    'completed_at'     => $item->completed_at ? $item->completed_at->format('Y-m-d H:i') : '',
                    'result'           => $item->result,
                    'next_at'          => $item->next_at ? $item->next_at->format('Y-m-d') : '',
                    'equipment_name'   => $item->equipment->name ?? '',
                    'created_at'       => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/equipment-maintenance/{hashid}")
     */
    public function show(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = EquipmentMaintenance::with('equipment')->find($id);
        if (!$item) {
            return $this->fail('维保记录不存在', 404);
        }

        return $this->success([
            'id'               => $this->encodeId($item->id),
            'equipment_id'     => $this->encodeId($item->equipment_id),
            'maintenance_type' => $item->maintenance_type,
            'description'      => $item->description,
            'staff_id'         => $this->encodeId($item->staff_id),
            'cost'             => $item->cost,
            'company'          => $item->company,
            'started_at'       => $item->started_at ? $item->started_at->format('Y-m-d H:i') : '',
            'completed_at'     => $item->completed_at ? $item->completed_at->format('Y-m-d H:i') : '',
            'result'           => $item->result,
            'next_at'          => $item->next_at ? $item->next_at->format('Y-m-d') : '',
            'equipment_name'   => $item->equipment->name ?? '',
            'created_at'       => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
            'updated_at'       => $item->updated_at ? $item->updated_at->format('Y-m-d H:i') : '',
        ]);
    }

    /**
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/equipment-maintenance")
     */
    public function store(Request $request)
    {
        $data = $request->only([
            'equipment_id', 'maintenance_type', 'description',
            'staff_id', 'cost', 'company',
            'started_at', 'completed_at', 'result', 'next_at',
        ]);

        if (empty($data['equipment_id'])) {
            return $this->fail('请选择设备', 422);
        }

        $data['id'] = SnowflakeService::generate();

        EquipmentMaintenance::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /**
     * @Apidoc\Method("PUT")
     * @Apidoc\Url("/admin/equipment-maintenance/{hashid}")
     */
    public function update(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = EquipmentMaintenance::find($id);
        if (!$item) {
            return $this->fail('维保记录不存在', 404);
        }

        $item->fill($request->only([
            'equipment_id', 'maintenance_type', 'description',
            'staff_id', 'cost', 'company',
            'started_at', 'completed_at', 'result', 'next_at',
        ]));
        $item->save();

        return $this->success([], '更新成功');
    }

    /**
     * @Apidoc\Method("DELETE")
     * @Apidoc\Url("/admin/equipment-maintenance/{hashid}")
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
        $item = EquipmentMaintenance::find($id);
        if (!$item) {
            return $this->fail('维保记录不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }
}
