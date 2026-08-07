<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;
use hg\apidoc\annotation as Apidoc;

use app\common\SnowflakeService;
use app\model\GreenMaintenance;
use support\Request;

/**
 * 物业管理·高级
 * @Apidoc\Group("property-adv")
 */
class GreenMaintenanceController extends BaseController
{
    /**
     * 绿化维护记录列表
     * ?area_id=xxx&maintenance_type=xxx&start_date=xxx&end_date=xxx
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/green-maintenance")
     */
    public function index(Request $request)
    {
        $areaId          = $request->input('area_id');
        $maintenanceType = $request->input('maintenance_type');
        $startDate       = $request->input('start_date');
        $endDate         = $request->input('end_date');

        $query = GreenMaintenance::query();

        if (!empty($areaId)) {
            $query->where('area_id', (int) $areaId);
        }
        if ($maintenanceType !== null && $maintenanceType !== '') {
            $query->where('maintenance_type', (int) $maintenanceType);
        }
        if (!empty($startDate)) {
            $query->where('maintained_at', '>=', $startDate);
        }
        if (!empty($endDate)) {
            $query->where('maintained_at', '<=', $endDate . ' 23:59:59');
        }

        $list = $query->orderBy('maintained_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'               => $this->encodeId($item->id),
                    'area_id'          => $this->encodeId($item->area_id),
                    'maintenance_type' => $item->maintenance_type,
                    'staff_id'         => $item->staff_id ? $this->encodeId($item->staff_id) : '',
                    'description'      => $item->description,
                    'cost'             => $item->cost,
                    'maintained_at'    => $item->maintained_at ? $item->maintained_at->format('Y-m-d H:i') : '',
                    'created_at'       => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/green-maintenance")
     */
    public function store(Request $request)
    {
        $data = $request->only([
            'area_id', 'maintenance_type', 'staff_id', 'description',
            'cost', 'maintained_at',
        ]);

        if (empty($data['area_id'])) {
            return $this->fail('请选择绿化区域', 422);
        }

        $data['id'] = SnowflakeService::generate();

        GreenMaintenance::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }
}
