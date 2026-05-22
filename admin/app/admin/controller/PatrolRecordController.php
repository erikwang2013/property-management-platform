<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;

use app\common\SnowflakeService;
use app\model\PatrolRecord;
use support\Request;

/**
 * 物业管理·高级
 * @Apidoc\Group("property-adv")
 */
class PatrolRecordController extends BaseController
{
    /**
     * 巡逻记录列表
     * ?patrol_id=xxx&staff_id=xxx&start_date=xxx&end_date=xxx&page_size=20
     */
    public function index(Request $request)
    {
        $patrolId  = $request->input('patrol_id');
        $staffId   = $request->input('staff_id');
        $startDate = $request->input('start_date');
        $endDate   = $request->input('end_date');

        $query = PatrolRecord::query();

        if (!empty($patrolId)) {
            $query->where('patrol_id', (int) $patrolId);
        }
        if (!empty($staffId)) {
            $query->where('staff_id', (int) $staffId);
        }
        if (!empty($startDate)) {
            $query->where('started_at', '>=', $startDate);
        }
        if (!empty($endDate)) {
            $query->where('started_at', '<=', $endDate . ' 23:59:59');
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'               => $this->encodeId($item->id),
                    'patrol_id'        => $this->encodeId($item->patrol_id),
                    'staff_id'         => $item->staff_id ? $this->encodeId($item->staff_id) : '',
                    'started_at'       => $item->started_at ? $item->started_at->format('Y-m-d H:i') : '',
                    'ended_at'         => $item->ended_at ? $item->ended_at->format('Y-m-d H:i') : '',
                    'duration'         => $item->duration,
                    'checkpoints_done' => $item->checkpoints_done,
                    'abnormal_note'    => $item->abnormal_note,
                    'created_at'       => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /** 创建巡逻记录 */
    public function store(Request $request)
    {
        $data = $request->only([
            'patrol_id', 'staff_id', 'started_at', 'ended_at',
            'checkpoints_done', 'abnormal_note',
        ]);

        if (empty($data['patrol_id'])) {
            return $this->fail('请选择巡逻路线', 422);
        }

        // 自动计算时长（分钟）
        if (!empty($data['started_at']) && !empty($data['ended_at'])) {
            $start = strtotime($data['started_at']);
            $end   = strtotime($data['ended_at']);
            if ($start && $end && $end > $start) {
                $data['duration'] = (int) round(($end - $start) / 60);
            }
        }

        $data['id'] = SnowflakeService::generate();

        PatrolRecord::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }
}
