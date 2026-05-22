<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;

use app\common\SnowflakeService;
use app\model\Approval;
use app\model\ApprovalRecord;
use app\model\ApprovalType;
use app\model\Notification;
use support\Request;
use support\Response;

/**
 * 扩展功能
 * @Apidoc\Group("extensions")
 */
class ApprovalController extends BaseController
{
    /**
     * 审批类型列表
     * GET /admin/approval-type
     */
    public function types(Request $request): Response
    {
        $list = ApprovalType::orderBy('created_at', 'desc')
            ->paginate(20)
            ->through(fn($i) => [
                'id'     => $this->encodeId($i->id),
                'code'   => $i->code,
                'name'   => $i->name,
                'steps'  => $i->steps,
                'status' => $i->status,
            ]);
        return $this->success($list);
    }

    /**
     * 创建审批类型
     * POST /admin/approval-type
     */
    public function typeStore(Request $request): Response
    {
        $data = $request->only(['code', 'name', 'steps', 'status']);
        $data['id'] = SnowflakeService::generate();
        if (isset($data['steps']) && is_array($data['steps'])) {
            $data['steps'] = json_encode($data['steps']);
        }
        ApprovalType::create($data);
        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /**
     * 更新审批类型
     * PUT /admin/approval-type/{hashid}
     */
    public function typeUpdate(Request $request, string $hashid): Response
    {
        $id = $this->decodeId($hashid);
        $t = ApprovalType::findOrFail($id);
        $t->fill($request->only(['code', 'name', 'steps', 'status']));
        if ($s = $request->input('steps')) {
            $t->steps = is_array($s) ? json_encode($s) : $s;
        }
        $t->save();
        return $this->success([], '更新成功');
    }

    /**
     * 删除审批类型
     * DELETE /admin/approval-type/{hashid}
     */
    public function typeDestroy(Request $request, string $hashid): Response
    {
        $id = $this->decodeId($hashid);
        ApprovalType::findOrFail($id)->delete();
        return $this->success([], '删除成功');
    }

    /**
     * 审批实例列表
     * GET /admin/approval?status=&page=
     */
    public function index(Request $request): Response
    {
        $query = Approval::query()->with(['approvalType:id,name']);

        if ($s = $request->input('status')) {
            $query->where('status', (int) $s);
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate(20)
            ->through(fn($i) => [
                'id'               => $this->encodeId($i->id),
                'approval_type_id' => $this->encodeId($i->approval_type_id),
                'type_name'        => $i->approvalType->name ?? '',
                'title'            => $i->title,
                'applicant_id'     => $i->applicant_id,
                'applicant_type'   => $i->applicant_type,
                'ref_type'         => $i->ref_type,
                'ref_id'           => $i->ref_id,
                'current_step'     => $i->current_step,
                'status'           => $i->status,
                'remark'           => $i->remark,
                'completed_at'     => $i->completed_at ? $i->completed_at->format('Y-m-d H:i') : null,
                'created_at'       => $i->created_at->format('Y-m-d H:i'),
            ]);

        return $this->success($list);
    }

    /**
     * 审批详情（含审批记录）
     * GET /admin/approval/{hashid}
     */
    public function show(Request $request, string $hashid): Response
    {
        $id = $this->decodeId($hashid);
        $approval = Approval::with(['approvalType:id,name,steps', 'records'])->findOrFail($id);

        $data = [
            'id'               => $this->encodeId($approval->id),
            'approval_type_id' => $this->encodeId($approval->approval_type_id),
            'type_name'        => $approval->approvalType->name ?? '',
            'type_steps'       => $approval->approvalType->steps ?? [],
            'title'            => $approval->title,
            'applicant_id'     => $approval->applicant_id,
            'applicant_type'   => $approval->applicant_type,
            'ref_type'         => $approval->ref_type,
            'ref_id'           => $approval->ref_id,
            'current_step'     => $approval->current_step,
            'status'           => $approval->status,
            'remark'           => $approval->remark,
            'completed_at'     => $approval->completed_at ? $approval->completed_at->format('Y-m-d H:i') : null,
            'created_at'       => $approval->created_at->format('Y-m-d H:i'),
            'records'          => $approval->records->map(fn($r) => [
                'id'          => $this->encodeId($r->id),
                'step'        => $r->step,
                'approver_id' => $r->approver_id,
                'action'      => $r->action,
                'remark'      => $r->remark,
                'acted_at'    => $r->acted_at ? $r->acted_at->format('Y-m-d H:i') : null,
            ])->toArray(),
        ];

        return $this->success($data);
    }

    /**
     * 提交审批
     * POST /admin/approval
     */
    public function submit(Request $request): Response
    {
        $approvalTypeId = $request->input('approval_type_id');
        $title          = $request->input('title', '');
        $refType        = $request->input('ref_type', '');
        $refId          = $request->input('ref_id', 0);
        $remark         = $request->input('remark', '');

        $approvalType = ApprovalType::findOrFail($this->decodeId($approvalTypeId));
        $steps = $approvalType->steps;
        if (empty($steps) || !is_array($steps)) {
            return $this->fail('审批类型未配置审批步骤', 422);
        }

        // 创建审批实例
        $id = SnowflakeService::generate();
        Approval::create([
            'id'               => $id,
            'approval_type_id' => $this->decodeId($approvalTypeId),
            'title'            => $title,
            'applicant_id'     => $request->input('applicant_id', 0),
            'applicant_type'   => $request->input('applicant_type', 0),
            'ref_type'         => $refType,
            'ref_id'           => (int) $refId,
            'current_step'     => 1,
            'status'           => 0,
            'remark'           => $remark,
        ]);

        // 创建第一步审批记录
        $firstStep = $steps[0];
        ApprovalRecord::create([
            'id'          => SnowflakeService::generate(),
            'approval_id' => $id,
            'step'        => 1,
            'approver_id' => $firstStep['approver_id'] ?? 0,
        ]);

        // 发送通知给审批人
        Notification::create([
            'id'        => SnowflakeService::generate(),
            'user_id'   => $firstStep['approver_id'] ?? 0,
            'user_type' => $firstStep['approver_type'] ?? 1,
            'title'     => '待审批: ' . $title,
            'content'   => '您有一条新的审批待处理: ' . $title,
            'type'      => 2,
            'channel'   => 'in_app',
            'ref_type'  => 'approval',
            'ref_id'    => $id,
        ]);

        return $this->success(['id' => $this->encodeId($id)], '提交成功');
    }

    /**
     * 审批操作
     * PUT /admin/approval/{hashid}/approve
     */
    public function approve(Request $request, string $hashid): Response
    {
        $id = $this->decodeId($hashid);
        $action = (int) $request->input('action'); // 1=通过, 2=驳回
        $remark = $request->input('remark', '');
        $approverId = $request->input('approver_id', 0);

        if (!in_array($action, [1, 2])) {
            return $this->fail('无效的操作', 422);
        }

        $approval = Approval::findOrFail($id);
        if ($approval->status != 0) {
            return $this->fail('该审批已处理', 422);
        }

        // 更新当前步骤的审批记录
        $record = ApprovalRecord::where('approval_id', $id)
            ->where('step', $approval->current_step)
            ->where('action', 0)
            ->first();

        if (!$record) {
            return $this->fail('未找到待审批记录', 404);
        }

        $record->action   = $action;
        $record->remark   = $remark;
        $record->acted_at = date('Y-m-d H:i:s');
        $record->save();

        if ($action == 2) {
            // 驳回：结束审批
            $approval->status       = 2;
            $approval->completed_at = date('Y-m-d H:i:s');
            $approval->save();
        } else {
            // 通过：检查是否有下一步
            $approvalType = ApprovalType::find($approval->approval_type_id);
            $steps = $approvalType->steps ?? [];
            $nextStep = $approval->current_step + 1;

            if (isset($steps[$nextStep - 1])) {
                // 有下一步，创建下一条审批记录
                $approval->current_step = $nextStep;
                $approval->save();

                $next = $steps[$nextStep - 1];
                ApprovalRecord::create([
                    'id'          => SnowflakeService::generate(),
                    'approval_id' => $id,
                    'step'        => $nextStep,
                    'approver_id' => $next['approver_id'] ?? 0,
                ]);

                // 通知下一级审批人
                Notification::create([
                    'id'        => SnowflakeService::generate(),
                    'user_id'   => $next['approver_id'] ?? 0,
                    'user_type' => $next['approver_type'] ?? 1,
                    'title'     => '待审批: ' . $approval->title,
                    'content'   => '您有一条新的审批待处理: ' . $approval->title,
                    'type'      => 2,
                    'channel'   => 'in_app',
                    'ref_type'  => 'approval',
                    'ref_id'    => $id,
                ]);
            } else {
                // 所有步骤通过
                $approval->status       = 1;
                $approval->completed_at = date('Y-m-d H:i:s');
                $approval->save();
            }
        }

        return $this->success([], '操作成功');
    }

    /**
     * 我的待审批列表
     * GET /admin/approval/pending?approver_id=
     */
    public function myPending(Request $request): Response
    {
        $approverId = $request->input('approver_id', 0);

        // 查找待审批记录对应的审批实例
        $recordIds = ApprovalRecord::where('approver_id', (int) $approverId)
            ->where('action', 0)
            ->pluck('approval_id')
            ->unique();

        $list = Approval::with(['approvalType:id,name'])
            ->whereIn('id', $recordIds)
            ->where('status', 0)
            ->orderBy('created_at', 'desc')
            ->paginate(20)
            ->through(fn($i) => [
                'id'               => $this->encodeId($i->id),
                'approval_type_id' => $this->encodeId($i->approval_type_id),
                'type_name'        => $i->approvalType->name ?? '',
                'title'            => $i->title,
                'applicant_id'     => $i->applicant_id,
                'current_step'     => $i->current_step,
                'status'           => $i->status,
                'remark'           => $i->remark,
                'created_at'       => $i->created_at->format('Y-m-d H:i'),
            ]);

        return $this->success($list);
    }
}
