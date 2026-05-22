<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;

use app\common\SnowflakeService;
use app\model\SecurityPatrol;
use app\model\PatrolRecord;
use support\Request;

class SecurityPatrolController extends BaseController
{
    /**
     * 安防巡逻列表
     * ?community_id=xxx&status=xxx&keyword=搜索词
     */
    public function index(Request $request)
    {
        $communityId = $request->input('community_id');
        $status      = $request->input('status');
        $keyword     = $request->input('keyword', '');

        $query = SecurityPatrol::query();

        if (!empty($communityId)) {
            $query->where('community_id', (int) $communityId);
        }
        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        }
        if (!empty($keyword)) {
            $query->where('name', 'like', "%{$keyword}%");
        }

        $list = $query->orderBy('sort', 'asc')
            ->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                $recordCount = PatrolRecord::where('patrol_id', $item->id)->count();
                return [
                    'id'           => $this->encodeId($item->id),
                    'community_id' => $this->encodeId($item->community_id),
                    'name'         => $item->name,
                    'route_points' => $item->route_points,
                    'checkpoints'  => $item->checkpoints,
                    'sort'         => $item->sort,
                    'status'       => $item->status,
                    'record_count' => $recordCount,
                    'created_at'   => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /** 巡逻详情 */
    public function show(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = SecurityPatrol::find($id);
        if (!$item) {
            return $this->fail('巡逻路线不存在', 404);
        }

        // 最近巡逻记录
        $recentRecords = PatrolRecord::where('patrol_id', $id)
            ->orderBy('created_at', 'desc')
            ->limit(10)
            ->get()
            ->map(function ($r) {
                return [
                    'id'                => $this->encodeId($r->id),
                    'staff_id'          => $r->staff_id ? $this->encodeId($r->staff_id) : '',
                    'started_at'        => $r->started_at ? $r->started_at->format('Y-m-d H:i') : '',
                    'ended_at'          => $r->ended_at ? $r->ended_at->format('Y-m-d H:i') : '',
                    'duration'          => $r->duration,
                    'checkpoints_done'  => $r->checkpoints_done,
                    'abnormal_note'     => $r->abnormal_note,
                    'created_at'        => $r->created_at ? $r->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success([
            'id'             => $this->encodeId($item->id),
            'community_id'   => $this->encodeId($item->community_id),
            'name'           => $item->name,
            'route_points'   => $item->route_points,
            'checkpoints'    => $item->checkpoints,
            'sort'           => $item->sort,
            'status'         => $item->status,
            'recent_records' => $recentRecords,
            'created_at'     => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
            'updated_at'     => $item->updated_at ? $item->updated_at->format('Y-m-d H:i') : '',
        ]);
    }

    /** 创建巡逻路线 */
    public function store(Request $request)
    {
        $data = $request->only([
            'community_id', 'name', 'route_points', 'checkpoints', 'sort',
        ]);

        if (empty($data['community_id'])) {
            return $this->fail('请选择所属小区', 422);
        }
        if (empty($data['name'])) {
            return $this->fail('路线名称不能为空', 422);
        }

        // checkpoints 存储为JSON
        if (isset($data['checkpoints']) && is_array($data['checkpoints'])) {
            $data['checkpoints'] = json_encode($data['checkpoints'], JSON_UNESCAPED_UNICODE);
        } else {
            $data['checkpoints'] = '[]';
        }

        $data['id']     = SnowflakeService::generate();
        $data['status'] = $request->input('status', 1);

        SecurityPatrol::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /** 更新巡逻路线 */
    public function update(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = SecurityPatrol::find($id);
        if (!$item) {
            return $this->fail('巡逻路线不存在', 404);
        }

        $updateData = $request->only([
            'community_id', 'name', 'route_points', 'checkpoints', 'sort', 'status',
        ]);

        if (isset($updateData['checkpoints']) && is_array($updateData['checkpoints'])) {
            $updateData['checkpoints'] = json_encode($updateData['checkpoints'], JSON_UNESCAPED_UNICODE);
        }

        $item->fill($updateData);
        $item->save();

        return $this->success([], '更新成功');
    }

    /** 删除巡逻路线（需密码确认） */
    public function destroy(Request $request, string $hashid)
    {
        $adminId  = $request->adminId;
        $password = $request->input('password', '');

        $error = $this->confirmPassword($adminId, $password, $request);
        if ($error !== null) {
            return $this->fail($error, 422);
        }

        $id   = $this->decodeId($hashid);
        $item = SecurityPatrol::find($id);
        if (!$item) {
            return $this->fail('巡逻路线不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }
}
