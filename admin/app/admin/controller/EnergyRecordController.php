<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;

use app\common\SnowflakeService;
use app\model\EnergyRecord;
use app\model\EnergyMeter;
use support\Request;

/**
 * 物业管理·高级
 * @Apidoc\Group("property-adv")
 */
class EnergyRecordController extends BaseController
{
    /**
     * 能源抄表记录列表
     * ?meter_id=xxx&room_id=xxx&start_date=xxx&end_date=xxx
     */
    public function index(Request $request)
    {
        $meterId   = $request->input('meter_id');
        $roomId    = $request->input('room_id');
        $startDate = $request->input('start_date');
        $endDate   = $request->input('end_date');

        $query = EnergyRecord::query();

        if (!empty($meterId)) {
            $query->where('meter_id', (int) $meterId);
        }
        if (!empty($roomId)) {
            $query->where('room_id', (int) $roomId);
        }
        if (!empty($startDate)) {
            $query->where('record_date', '>=', $startDate);
        }
        if (!empty($endDate)) {
            $query->where('record_date', '<=', $endDate);
        }

        $list = $query->orderBy('record_date', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'              => $this->encodeId($item->id),
                    'meter_id'        => $this->encodeId($item->meter_id),
                    'room_id'         => $this->encodeId($item->room_id),
                    'reading'         => $item->reading,
                    'previous_reading' => $item->previous_reading,
                    'usage_amount'    => $item->usage_amount,
                    'unit_price'      => $item->unit_price,
                    'amount'          => $item->amount,
                    'record_date'     => $item->record_date ? $item->record_date->format('Y-m-d') : '',
                    'reader_id'       => $item->reader_id ? $this->encodeId($item->reader_id) : '',
                    'bill_id'         => $item->bill_id ? $this->encodeId($item->bill_id) : '',
                    'created_at'      => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /** 创建抄表记录 */
    public function store(Request $request)
    {
        $data = $request->only([
            'meter_id', 'room_id', 'reading', 'unit_price',
            'record_date', 'reader_id', 'bill_id',
        ]);

        if (empty($data['meter_id'])) {
            return $this->fail('请选择仪表', 422);
        }

        // 获取上次抄表读数作为上次读数
        $lastRecord = EnergyRecord::where('meter_id', $data['meter_id'])
            ->orderBy('record_date', 'desc')
            ->first();

        $data['previous_reading'] = $lastRecord ? $lastRecord->reading : 0;

        // 自动计算用量 = 本次读数 - 上次读数
        $currentReading  = (float) $data['reading'];
        $previousReading = (float) $data['previous_reading'];
        $data['usage_amount'] = max(0, round($currentReading - $previousReading, 2));

        // 计算金额 = 用量 * 单价
        $unitPrice = (float) ($data['unit_price'] ?? 0);
        $data['amount'] = round($data['usage_amount'] * $unitPrice, 2);

        $data['id'] = SnowflakeService::generate();

        EnergyRecord::create($data);

        return $this->success([
            'id'               => $this->encodeId($data['id']),
            'reading'          => $data['reading'],
            'previous_reading' => $data['previous_reading'],
            'usage_amount'     => $data['usage_amount'],
            'amount'           => $data['amount'],
        ], '创建成功');
    }
}
