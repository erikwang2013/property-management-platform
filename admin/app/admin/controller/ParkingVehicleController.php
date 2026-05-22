<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;

use app\common\SnowflakeService;
use app\model\ParkingVehicle;
use support\Request;

/**
 * 物业管理·辅助
 * @Apidoc\Group("property-aux")
 */
class ParkingVehicleController extends BaseController
{
    /**
     * 车辆列表
     * ?owner_id=xxx&space_id=xxx&status=xxx&page_size=20
     */
    public function index(Request $request)
    {
        $ownerId = $request->input('owner_id');
        $spaceId = $request->input('space_id');
        $status  = $request->input('status');

        $query = ParkingVehicle::with('space');

        if (!empty($ownerId)) {
            $query->where('owner_id', (int) $ownerId);
        }
        if (!empty($spaceId)) {
            $query->where('space_id', (int) $spaceId);
        }
        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'            => $this->encodeId($item->id),
                    'owner_id'      => $this->encodeId($item->owner_id),
                    'space_id'      => $item->space_id ? $this->encodeId($item->space_id) : '',
                    'plate_number'  => $item->plate_number,
                    'vehicle_brand' => $item->vehicle_brand,
                    'vehicle_color' => $item->vehicle_color,
                    'vehicle_type'  => $item->vehicle_type,
                    'start_date'    => $item->start_date ? $item->start_date->format('Y-m-d') : '',
                    'end_date'      => $item->end_date ? $item->end_date->format('Y-m-d') : '',
                    'status'        => $item->status,
                    'space'         => $item->space ? [
                        'id'           => $this->encodeId($item->space->id),
                        'space_number' => $item->space->space_number,
                        'space_type'   => $item->space->space_type,
                    ] : null,
                    'created_at'    => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /** 车辆详情 */
    public function show(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = ParkingVehicle::with('space')->find($id);
        if (!$item) {
            return $this->fail('车辆不存在', 404);
        }

        return $this->success([
            'id'            => $this->encodeId($item->id),
            'owner_id'      => $this->encodeId($item->owner_id),
            'space_id'      => $item->space_id ? $this->encodeId($item->space_id) : '',
            'plate_number'  => $item->plate_number,
            'vehicle_brand' => $item->vehicle_brand,
            'vehicle_color' => $item->vehicle_color,
            'vehicle_type'  => $item->vehicle_type,
            'start_date'    => $item->start_date ? $item->start_date->format('Y-m-d') : '',
            'end_date'      => $item->end_date ? $item->end_date->format('Y-m-d') : '',
            'status'        => $item->status,
            'space'         => $item->space ? [
                'id'           => $this->encodeId($item->space->id),
                'space_number' => $item->space->space_number,
            ] : null,
            'created_at'    => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
            'updated_at'    => $item->updated_at ? $item->updated_at->format('Y-m-d H:i') : '',
        ]);
    }

    /** 创建车辆 */
    public function store(Request $request)
    {
        $data = $request->only([
            'owner_id', 'space_id', 'plate_number',
            'vehicle_brand', 'vehicle_color', 'vehicle_type',
            'start_date', 'end_date',
        ]);

        if (empty($data['owner_id'])) {
            return $this->fail('请选择车主', 422);
        }
        if (empty($data['plate_number'])) {
            return $this->fail('车牌号不能为空', 422);
        }

        $data['id']     = SnowflakeService::generate();
        $data['status'] = $request->input('status', 1);

        ParkingVehicle::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /** 更新车辆 */
    public function update(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = ParkingVehicle::find($id);
        if (!$item) {
            return $this->fail('车辆不存在', 404);
        }

        $item->fill($request->only([
            'owner_id', 'space_id', 'plate_number',
            'vehicle_brand', 'vehicle_color', 'vehicle_type',
            'start_date', 'end_date', 'status',
        ]));
        $item->save();

        return $this->success([], '更新成功');
    }

    /** 删除车辆（需密码确认） */
    public function destroy(Request $request, string $hashid)
    {
        $adminId  = $request->adminId;
        $password = $request->input('password', '');

        $error = $this->confirmPassword($adminId, $password, $request);
        if ($error !== null) {
            return $this->fail($error, 422);
        }

        $id   = $this->decodeId($hashid);
        $item = ParkingVehicle::find($id);
        if (!$item) {
            return $this->fail('车辆不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }
}
