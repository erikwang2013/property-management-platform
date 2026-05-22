<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;

use app\common\SnowflakeService;
use app\model\CleaningRecord;
use support\Request;

/**
 * 物业管理·高级
 * @Apidoc\Group("property-adv")
 */
class CleaningRecordController extends BaseController
{
    /**
     * 保洁记录列表
     * ?area_id=xxx&staff_id=xxx&status=xxx&start_date=xxx&end_date=xxx
     */
    public function index(Request $request)
    {
        $areaId    = $request->input('area_id');
        $staffId   = $request->input('staff_id');
        $status    = $request->input('status');
        $startDate = $request->input('start_date');
        $endDate   = $request->input('end_date');

        $query = CleaningRecord::query();

        if (!empty($areaId)) {
            $query->where('area_id', (int) $areaId);
        }
        if (!empty($staffId)) {
            $query->where('staff_id', (int) $staffId);
        }
        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        }
        if (!empty($startDate)) {
            $query->where('cleaned_at', '>=', $startDate);
        }
        if (!empty($endDate)) {
            $query->where('cleaned_at', '<=', $endDate . ' 23:59:59');
        }

        $list = $query->orderBy('cleaned_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'                => $this->encodeId($item->id),
                    'area_id'           => $this->encodeId($item->area_id),
                    'staff_id'          => $item->staff_id ? $this->encodeId($item->staff_id) : '',
                    'cleaned_at'        => $item->cleaned_at ? $item->cleaned_at->format('Y-m-d H:i') : '',
                    'status'            => $item->status,
                    'inspector_id'      => $item->inspector_id ? $this->encodeId($item->inspector_id) : '',
                    'inspection_remark' => $item->inspection_remark,
                    'inspection_at'     => $item->inspection_at ? $item->inspection_at->format('Y-m-d H:i') : '',
                    'images'            => $item->images,
                    'created_at'        => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /** 创建保洁记录 */
    public function store(Request $request)
    {
        $data = $request->only([
            'area_id', 'staff_id', 'cleaned_at', 'status',
            'inspector_id', 'inspection_remark', 'inspection_at', 'images',
        ]);

        if (empty($data['area_id'])) {
            return $this->fail('请选择保洁区域', 422);
        }

        if (isset($data['images']) && is_array($data['images'])) {
            $data['images'] = json_encode($data['images'], JSON_UNESCAPED_UNICODE);
        }

        $data['id'] = SnowflakeService::generate();

        CleaningRecord::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }
}
