<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;

use app\common\SnowflakeService;
use app\model\EnergyMeter;
use support\Request;

class EnergyMeterController extends BaseController
{
    /**
     * 能源仪表列表
     * ?room_id=xxx&meter_type=xxx&status=xxx&keyword=搜索词
     */
    public function index(Request $request)
    {
        $roomId    = $request->input('room_id');
        $meterType = $request->input('meter_type');
        $status    = $request->input('status');
        $keyword   = $request->input('keyword', '');

        $query = EnergyMeter::query();

        if (!empty($roomId)) {
            $query->where('room_id', (int) $roomId);
        }
        if ($meterType !== null && $meterType !== '') {
            $query->where('meter_type', (int) $meterType);
        }
        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        }
        if (!empty($keyword)) {
            $query->where('meter_number', 'like', "%{$keyword}%");
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'             => $this->encodeId($item->id),
                    'room_id'        => $this->encodeId($item->room_id),
                    'meter_type'     => $item->meter_type,
                    'meter_number'   => $item->meter_number,
                    'install_reading' => $item->install_reading,
                    'install_date'   => $item->install_date ? $item->install_date->format('Y-m-d') : '',
                    'status'         => $item->status,
                    'created_at'     => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /** 仪表详情 */
    public function show(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = EnergyMeter::find($id);
        if (!$item) {
            return $this->fail('仪表不存在', 404);
        }

        return $this->success([
            'id'              => $this->encodeId($item->id),
            'room_id'         => $this->encodeId($item->room_id),
            'meter_type'      => $item->meter_type,
            'meter_number'    => $item->meter_number,
            'install_reading' => $item->install_reading,
            'install_date'    => $item->install_date ? $item->install_date->format('Y-m-d') : '',
            'status'          => $item->status,
            'created_at'      => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
            'updated_at'      => $item->updated_at ? $item->updated_at->format('Y-m-d H:i') : '',
        ]);
    }

    /** 创建仪表 */
    public function store(Request $request)
    {
        $data = $request->only([
            'room_id', 'meter_type', 'meter_number', 'install_reading',
            'install_date',
        ]);

        if (empty($data['room_id'])) {
            return $this->fail('请选择所属房产', 422);
        }
        if (empty($data['meter_number'])) {
            return $this->fail('仪表编号不能为空', 422);
        }

        $data['id']     = SnowflakeService::generate();
        $data['status'] = $request->input('status', 1);

        EnergyMeter::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /** 更新仪表 */
    public function update(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = EnergyMeter::find($id);
        if (!$item) {
            return $this->fail('仪表不存在', 404);
        }

        $item->fill($request->only([
            'room_id', 'meter_type', 'meter_number', 'install_reading',
            'install_date', 'status',
        ]));
        $item->save();

        return $this->success([], '更新成功');
    }

    /** 删除仪表（需密码确认） */
    public function destroy(Request $request, string $hashid)
    {
        $adminId  = $request->adminId;
        $password = $request->input('password', '');

        $error = $this->confirmPassword($adminId, $password, $request);
        if ($error !== null) {
            return $this->fail($error, 422);
        }

        $id   = $this->decodeId($hashid);
        $item = EnergyMeter::find($id);
        if (!$item) {
            return $this->fail('仪表不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }
}
