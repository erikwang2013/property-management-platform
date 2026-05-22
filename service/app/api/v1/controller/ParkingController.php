<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;

use app\common\BaseController;
use app\model\ParkingSpace;
use app\model\ParkingVehicle;
use app\model\ParkingRecord;
use support\Request;
use support\Response;

/**
 * 停车管理
 * @Apidoc\Group("parking")
 * @Apidoc\Sort(1)
 */
class ParkingController extends BaseController
{
    /**
     * 我的车辆列表（含车位信息）
     * GET /service/parking/vehicles
     */
    public function vehicles(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);
        $page    = (int) $request->input('page', 1);

        $vehicles = ParkingVehicle::where('owner_id', $ownerId)
            ->with('space')
            ->orderBy('created_at', 'desc')
            ->paginate(20, ['*'], 'page', $page)
            ->through(function ($vehicle) {
                return [
                    'id'            => $this->encodeId($vehicle->id),
                    'space_id'      => $vehicle->space_id ? $this->encodeId($vehicle->space_id) : '',
                    'plate_number'  => $vehicle->plate_number,
                    'vehicle_brand' => $vehicle->vehicle_brand,
                    'vehicle_color' => $vehicle->vehicle_color,
                    'vehicle_type'  => $vehicle->vehicle_type,
                    'start_date'    => $vehicle->start_date ? $vehicle->start_date->format('Y-m-d') : '',
                    'end_date'      => $vehicle->end_date ? $vehicle->end_date->format('Y-m-d') : '',
                    'status'        => $vehicle->status,
                    'space'         => $vehicle->space ? [
                        'id'           => $this->encodeId($vehicle->space->id),
                        'space_number' => $vehicle->space->space_number,
                        'space_type'   => $vehicle->space->space_type,
                        'fee_monthly'  => $vehicle->space->fee_monthly,
                    ] : null,
                    'created_at'    => $vehicle->created_at ? $vehicle->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($vehicles);
    }

    /**
     * 我的车位列表
     * GET /service/parking/spaces
     */
    public function spaces(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);
        $page    = (int) $request->input('page', 1);

        // 通过车辆关联查询车位
        $spaceIds = ParkingVehicle::where('owner_id', $ownerId)
            ->where('space_id', '>', 0)
            ->pluck('space_id')
            ->unique()
            ->toArray();

        $spaces = ParkingSpace::whereIn('id', $spaceIds)
            ->orderBy('created_at', 'desc')
            ->paginate(20, ['*'], 'page', $page)
            ->through(function ($space) {
                return [
                    'id'           => $this->encodeId($space->id),
                    'space_number' => $space->space_number,
                    'space_type'   => $space->space_type,
                    'area'         => $space->area,
                    'status'       => $space->status,
                    'fee_monthly'  => $space->fee_monthly,
                    'created_at'   => $space->created_at ? $space->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($spaces);
    }

    /**
     * 停车记录列表
     * GET /service/parking/records?page=1
     */
    public function records(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);
        $page    = (int) $request->input('page', 1);

        // 获取车主车辆ID列表
        $vehicleIds = ParkingVehicle::where('owner_id', $ownerId)
            ->pluck('id')
            ->toArray();

        if (empty($vehicleIds)) {
            return $this->success([
                'data'         => [],
                'current_page' => $page,
                'last_page'    => 0,
                'per_page'     => 20,
                'total'        => 0,
            ]);
        }

        $records = ParkingRecord::whereIn('vehicle_id', $vehicleIds)
            ->with('vehicle')
            ->orderBy('entry_time', 'desc')
            ->paginate(20, ['*'], 'page', $page)
            ->through(function ($record) {
                return [
                    'id'            => $this->encodeId($record->id),
                    'vehicle_id'    => $this->encodeId($record->vehicle_id),
                    'space_id'      => $this->encodeId($record->space_id),
                    'entry_time'    => $record->entry_time ? $record->entry_time->format('Y-m-d H:i') : '',
                    'exit_time'     => $record->exit_time ? $record->exit_time->format('Y-m-d H:i') : '',
                    'duration'      => $record->duration,
                    'fee'           => $record->fee,
                    'plate_number'  => $record->vehicle->plate_number ?? '',
                    'created_at'    => $record->created_at ? $record->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($records);
    }
}
