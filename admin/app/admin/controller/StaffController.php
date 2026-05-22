<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;

use app\common\SnowflakeService;
use app\model\Staff;
use support\Request;

class StaffController extends BaseController
{
    /**
     * 员工列表
     * ?community_id=xxx&department=xxx&status=xxx&keyword=搜索词
     */
    public function index(Request $request)
    {
        $communityId = $request->input('community_id');
        $department  = $request->input('department');
        $status      = $request->input('status');
        $keyword     = $request->input('keyword', '');

        $query = Staff::query();

        if (!empty($communityId)) {
            $query->where('community_id', (int) $communityId);
        }
        if ($department !== null && $department !== '') {
            $query->where('department', (int) $department);
        }
        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        }
        if (!empty($keyword)) {
            $query->where(function ($q) use ($keyword) {
                $q->where('name', 'like', "%{$keyword}%")
                  ->orWhere('phone', 'like', "%{$keyword}%")
                  ->orWhere('job_title', 'like', "%{$keyword}%");
            });
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'           => $this->encodeId($item->id),
                    'community_id' => $this->encodeId($item->community_id),
                    'name'         => $item->name,
                    'phone'        => $item->phone,
                    'job_title'    => $item->job_title,
                    'department'   => $item->department,
                    'hire_date'    => $item->hire_date ? $item->hire_date->format('Y-m-d') : '',
                    'status'       => $item->status,
                    'created_at'   => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /** 员工详情 */
    public function show(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = Staff::find($id);
        if (!$item) {
            return $this->fail('员工不存在', 404);
        }

        return $this->success([
            'id'           => $this->encodeId($item->id),
            'community_id' => $this->encodeId($item->community_id),
            'name'         => $item->name,
            'phone'        => $item->phone,
            'id_card'      => $item->id_card,
            'job_title'    => $item->job_title,
            'department'   => $item->department,
            'hire_date'    => $item->hire_date ? $item->hire_date->format('Y-m-d') : '',
            'salary'       => $item->salary,
            'status'       => $item->status,
            'created_at'   => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
            'updated_at'   => $item->updated_at ? $item->updated_at->format('Y-m-d H:i') : '',
        ]);
    }

    /** 创建员工 */
    public function store(Request $request)
    {
        $data = $request->only([
            'community_id', 'name', 'phone', 'id_card',
            'job_title', 'department', 'hire_date', 'salary',
        ]);

        if (empty($data['community_id'])) {
            return $this->fail('请选择所属小区', 422);
        }
        if (empty($data['name'])) {
            return $this->fail('员工姓名不能为空', 422);
        }

        $data['id']     = SnowflakeService::generate();
        $data['status'] = $request->input('status', 1);

        Staff::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /** 更新员工 */
    public function update(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = Staff::find($id);
        if (!$item) {
            return $this->fail('员工不存在', 404);
        }

        $item->fill($request->only([
            'community_id', 'name', 'phone', 'id_card',
            'job_title', 'department', 'hire_date', 'salary', 'status',
        ]));
        $item->save();

        return $this->success([], '更新成功');
    }

    /** 删除员工（需密码确认） */
    public function destroy(Request $request, string $hashid)
    {
        $adminId  = $request->adminId;
        $password = $request->input('password', '');

        $error = $this->confirmPassword($adminId, $password, $request);
        if ($error !== null) {
            return $this->fail($error, 422);
        }

        $id   = $this->decodeId($hashid);
        $item = Staff::find($id);
        if (!$item) {
            return $this->fail('员工不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }

    /**
     * 批量修改员工状态
     * POST /admin/staff/batch/status
     */
    public function batchStatus(Request $request)
    {
        $ids     = $request->input('ids', []);
        $status  = (int) $request->input('status');

        if (empty($ids) || !is_array($ids)) {
            return $this->fail('请选择要操作的员工', 422);
        }
        if (!in_array($status, [0, 1], true)) {
            return $this->fail('状态值无效', 422);
        }

        $decodedIds = [];
        foreach ($ids as $hashid) {
            $decodedIds[] = $this->decodeId($hashid);
        }

        Staff::whereIn('id', $decodedIds)->update(['status' => $status]);

        $statusText = $status === 1 ? '启用' : '禁用';
        return $this->success([], "批量{$statusText}成功");
    }
}
