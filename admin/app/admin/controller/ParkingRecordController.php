<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;

use app\model\ParkingRecord;
use support\Request;

/**
 * 物业管理·辅助
 * @Apidoc\Group("property-aux")
 */
class ParkingRecordController extends BaseController
{
    /**
     * 停车记录列表
     * ?vehicle_id=xxx&start_date=2026-01-01&end_date=2026-12-31&page_size=20
     */
    public function index(Request $request)
    {
        $vehicleId = $request->input('vehicle_id');
        $startDate = $request->input('start_date', '');
        $endDate   = $request->input('end_date', '');

        $query = ParkingRecord::with('vehicle');

        if (!empty($vehicleId)) {
            $query->where('vehicle_id', (int) $vehicleId);
        }
        if (!empty($startDate)) {
            $query->where('entry_time', '>=', $startDate);
        }
        if (!empty($endDate)) {
            $query->where('entry_time', '<=', $endDate . ' 23:59:59');
        }

        $list = $query->orderBy('entry_time', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'           => $this->encodeId($item->id),
                    'vehicle_id'   => $this->encodeId($item->vehicle_id),
                    'space_id'     => $this->encodeId($item->space_id),
                    'entry_time'   => $item->entry_time ? $item->entry_time->format('Y-m-d H:i') : '',
                    'exit_time'    => $item->exit_time ? $item->exit_time->format('Y-m-d H:i') : '',
                    'duration'     => $item->duration,
                    'fee'          => $item->fee,
                    'plate_number' => $item->vehicle->plate_number ?? '',
                    'created_at'   => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }
}
