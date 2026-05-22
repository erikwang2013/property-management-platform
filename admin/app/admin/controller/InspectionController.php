<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;

use app\common\SnowflakeService;
use app\model\InspectionCheckpoint;
use app\model\InspectionTask;
use InvalidArgumentException;
use support\Request;

/**
 * 扩展功能
 * @Apidoc\Group("extensions")
 */
class InspectionController extends BaseController
{
    // ============================================================
    // 标准资源方法（Route::resource 需要，委托到 tasks 方法）
    // ============================================================

    public function index(Request $request)
    {
        return $this->tasks($request);
    }

    public function store(Request $request)
    {
        return $this->taskStore($request);
    }

    public function show(Request $request, string $hashid)
    {
        return $this->taskShow($request, $hashid);
    }

    public function update(Request $request, string $hashid)
    {
        return $this->taskUpdate($request, $hashid);
    }

    public function destroy(Request $request, string $hashid)
    {
        return $this->taskDestroy($request, $hashid);
    }

    // ============================================================
    // 巡检任务业务方法
    // ============================================================

    /**
     * 巡检任务列表
     * GET /admin/inspection-task?community_id=&status=&scheduled_date=
     */
    public function tasks(Request $request)
    {
        $communityId   = $request->input('community_id');
        $status        = $request->input('status');
        $scheduledDate = $request->input('scheduled_date');

        $query = InspectionTask::query();
        if (!empty($communityId)) {
            $query->where('community_id', (int) $communityId);
        }
        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        }
        if (!empty($scheduledDate)) {
            $query->where('scheduled_date', $scheduledDate);
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'             => $this->encodeId($item->id),
                    'community_id'   => $item->community_id,
                    'title'          => $item->title,
                    'task_type'      => $item->task_type,
                    'route_points'   => $item->route_points,
                    'checkpoints'    => $item->checkpoints,
                    'assigned_to'    => $item->assigned_to,
                    'scheduled_date' => $item->scheduled_date ? $item->scheduled_date->format('Y-m-d') : '',
                    'status'         => $item->status,
                    'started_at'     => $item->started_at ? $item->started_at->format('Y-m-d H:i') : '',
                    'completed_at'   => $item->completed_at ? $item->completed_at->format('Y-m-d H:i') : '',
                    'created_at'     => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 创建巡检任务
     * POST /admin/inspection-task
     */
    public function taskStore(Request $request)
    {
        $data = $request->only([
            'community_id', 'title', 'task_type', 'route_points',
            'checkpoints', 'assigned_to', 'scheduled_date',
        ]);

        if (empty($data['title'])) {
            return $this->fail('任务标题不能为空', 422);
        }

        $data['id']     = SnowflakeService::generate();
        $data['status'] = 0;

        InspectionTask::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /**
     * 更新巡检任务
     * PUT /admin/inspection-task/{hashid}
     */
    public function taskUpdate(Request $request, string $hashid)
    {
        try {
            $id = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的任务ID', 404);
        }

        $item = InspectionTask::find($id);
        if (!$item) {
            return $this->fail('任务不存在', 404);
        }

        $item->fill($request->only([
            'community_id', 'title', 'task_type', 'route_points',
            'checkpoints', 'assigned_to', 'scheduled_date', 'status',
        ]));
        $item->save();

        return $this->success([], '更新成功');
    }

    /**
     * 删除巡检任务
     * DELETE /admin/inspection-task/{hashid}
     */
    public function taskDestroy(Request $request, string $hashid)
    {
        $adminId  = $request->adminId;
        $password = $request->input('password', '');

        $error = $this->confirmPassword($adminId, $password, $request);
        if ($error !== null) {
            return $this->fail($error, 422);
        }

        try {
            $id = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的任务ID', 404);
        }

        $item = InspectionTask::find($id);
        if (!$item) {
            return $this->fail('任务不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }

    /**
     * 任务详情（含巡检点记录）
     * GET /admin/inspection-task/{hashid}
     */
    public function taskShow(Request $request, string $hashid)
    {
        try {
            $id = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的任务ID', 404);
        }

        $item = InspectionTask::with('checkpointRecords')->find($id);
        if (!$item) {
            return $this->fail('任务不存在', 404);
        }

        $checkpoints = $item->checkpointRecords->map(function ($cp) {
            return [
                'id'               => $this->encodeId($cp->id),
                'checkpoint_index' => $cp->checkpoint_index,
                'checkpoint_name'  => $cp->checkpoint_name,
                'latitude'         => $cp->latitude,
                'longitude'        => $cp->longitude,
                'photo_url'        => $cp->photo_url,
                'status'           => $cp->status,
                'remark'           => $cp->remark,
                'checked_at'       => $cp->checked_at ? $cp->checked_at->format('Y-m-d H:i') : '',
            ];
        })->values();

        return $this->success([
            'id'             => $this->encodeId($item->id),
            'community_id'   => $item->community_id,
            'title'          => $item->title,
            'task_type'      => $item->task_type,
            'route_points'   => $item->route_points,
            'checkpoints'    => $item->checkpoints,
            'assigned_to'    => $item->assigned_to,
            'scheduled_date' => $item->scheduled_date ? $item->scheduled_date->format('Y-m-d') : '',
            'status'         => $item->status,
            'started_at'     => $item->started_at ? $item->started_at->format('Y-m-d H:i') : '',
            'completed_at'   => $item->completed_at ? $item->completed_at->format('Y-m-d H:i') : '',
            'created_at'     => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
            'checkpoint_records' => $checkpoints,
        ]);
    }

    /**
     * 获取任务的巡检点列表
     * GET /admin/inspection-task/{hashid}/checkpoints
     */
    public function checkpoints(Request $request, string $taskHashid)
    {
        try {
            $taskId = $this->decodeId($taskHashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的任务ID', 404);
        }

        $list = InspectionCheckpoint::where('task_id', $taskId)
            ->orderBy('checkpoint_index', 'asc')
            ->get()
            ->map(function ($item) {
                return [
                    'id'               => $this->encodeId($item->id),
                    'task_id'          => $this->encodeId($item->task_id),
                    'checkpoint_index' => $item->checkpoint_index,
                    'checkpoint_name'  => $item->checkpoint_name,
                    'latitude'         => $item->latitude,
                    'longitude'        => $item->longitude,
                    'photo_url'        => $item->photo_url,
                    'status'           => $item->status,
                    'remark'           => $item->remark,
                    'checked_at'       => $item->checked_at ? $item->checked_at->format('Y-m-d H:i') : '',
                    'created_at'       => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 开始巡检
     * PUT /admin/inspection-task/{hashid}/start
     */
    public function startTask(Request $request, string $hashid)
    {
        try {
            $id = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的任务ID', 404);
        }

        $item = InspectionTask::find($id);
        if (!$item) {
            return $this->fail('任务不存在', 404);
        }

        if ($item->status !== 0) {
            return $this->fail('仅待巡检任务可以开始', 422);
        }

        $item->status     = 1;
        $item->started_at = date('Y-m-d H:i:s');
        $item->save();

        return $this->success([], '任务已开始');
    }

    /**
     * 完成巡检
     * PUT /admin/inspection-task/{hashid}/complete
     */
    public function completeTask(Request $request, string $hashid)
    {
        try {
            $id = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的任务ID', 404);
        }

        $item = InspectionTask::find($id);
        if (!$item) {
            return $this->fail('任务不存在', 404);
        }

        if ($item->status !== 1) {
            return $this->fail('仅进行中任务可以完成', 422);
        }

        $item->status       = 2;
        $item->completed_at = date('Y-m-d H:i:s');
        $item->save();

        return $this->success([], '任务已完成');
    }

    /**
     * 巡检点打卡
     * PUT /admin/inspection-checkpoint/{hashid}/checkin
     */
    public function checkin(Request $request, string $checkpointHashid)
    {
        try {
            $checkpointId = $this->decodeId($checkpointHashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的巡检点ID', 404);
        }

        $item = InspectionCheckpoint::find($checkpointId);
        if (!$item) {
            return $this->fail('巡检点不存在', 404);
        }

        $latitude  = $request->input('latitude');
        $longitude = $request->input('longitude');
        $photoUrl  = $request->input('photo_url', '');
        $status    = $request->input('status', 1);
        $remark    = $request->input('remark', '');

        $item->latitude   = $latitude;
        $item->longitude  = $longitude;
        $item->photo_url  = $photoUrl;
        $item->status     = (int) $status;
        $item->remark     = $remark;
        $item->checked_at = date('Y-m-d H:i:s');
        $item->save();

        return $this->success(['id' => $this->encodeId($item->id)], '打卡成功');
    }
}
