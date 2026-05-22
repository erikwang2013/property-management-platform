<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;

use app\common\SnowflakeService;
use app\model\Notification;
use app\model\RepairOrder;
use app\model\SlaRecord;
use app\model\SlaRule;
use InvalidArgumentException;
use support\Db;
use support\Request;

/**
 * 扩展功能
 * @Apidoc\Group("extensions")
 */
class SlaController extends BaseController
{
    /**
     * SLA规则列表
     * GET /admin/sla-rule
     */
    public function rules(Request $request)
    {
        $keyword = $request->input('keyword', '');
        $status  = $request->input('status');

        $query = SlaRule::query();
        if (!empty($keyword)) {
            $query->where('name', 'like', "%{$keyword}%");
        }
        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'                => $this->encodeId($item->id),
                    'name'              => $item->name,
                    'category'          => $item->category,
                    'urgency'           => $item->urgency,
                    'response_minutes'  => $item->response_minutes,
                    'resolve_minutes'   => $item->resolve_minutes,
                    'escalate_to_role'  => $item->escalate_to_role,
                    'escalate_minutes'  => $item->escalate_minutes,
                    'penalty_amount'    => $item->penalty_amount,
                    'status'            => $item->status,
                    'created_at'        => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 创建SLA规则
     * POST /admin/sla-rule
     */
    public function ruleStore(Request $request)
    {
        $data = $request->only([
            'name', 'category', 'urgency', 'response_minutes', 'resolve_minutes',
            'escalate_to_role', 'escalate_minutes', 'penalty_amount',
        ]);

        if (empty($data['name'])) {
            return $this->fail('规则名称不能为空', 422);
        }

        $data['id']     = SnowflakeService::generate();
        $data['status'] = 1;

        SlaRule::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /**
     * 更新SLA规则
     * PUT /admin/sla-rule/{hashid}
     */
    public function ruleUpdate(Request $request, string $hashid)
    {
        try {
            $id = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的规则ID', 404);
        }

        $item = SlaRule::find($id);
        if (!$item) {
            return $this->fail('规则不存在', 404);
        }

        $item->fill($request->only([
            'name', 'category', 'urgency', 'response_minutes', 'resolve_minutes',
            'escalate_to_role', 'escalate_minutes', 'penalty_amount', 'status',
        ]));
        $item->save();

        return $this->success([], '更新成功');
    }

    /**
     * 删除SLA规则
     * DELETE /admin/sla-rule/{hashid}
     */
    public function ruleDestroy(Request $request, string $hashid)
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
            return $this->fail('无效的规则ID', 404);
        }

        $item = SlaRule::find($id);
        if (!$item) {
            return $this->fail('规则不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }

    /**
     * SLA记录列表
     * GET /admin/sla-record?repair_order_id=&page=1
     */
    public function records(Request $request)
    {
        $repairOrderId = $request->input('repair_order_id');

        $query = SlaRecord::with('rule');
        if (!empty($repairOrderId)) {
            $query->where('repair_order_id', (int) $repairOrderId);
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'                   => $this->encodeId($item->id),
                    'repair_order_id'      => $item->repair_order_id,
                    'rule_id'              => $item->rule_id ? $this->encodeId($item->rule_id) : '',
                    'rule_name'            => $item->rule->name ?? '',
                    'response_deadline'    => $item->response_deadline ? $item->response_deadline->format('Y-m-d H:i') : '',
                    'resolve_deadline'     => $item->resolve_deadline ? $item->resolve_deadline->format('Y-m-d H:i') : '',
                    'escalated_at'         => $item->escalated_at ? $item->escalated_at->format('Y-m-d H:i') : '',
                    'escalate_level'       => $item->escalate_level,
                    'is_response_overtime' => $item->is_response_overtime,
                    'is_resolve_overtime'  => $item->is_resolve_overtime,
                    'penalty_amount'       => $item->penalty_amount,
                    'created_at'           => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 超时检查（cron调用）
     * 扫描进行中的报修单，检查是否超过SLA时限，必要时升级并创建通知
     * 返回升级数量
     */
    public function checkOvertime(Request $request)
    {
        $now          = date('Y-m-d H:i:s');
        $escalateCount = 0;

        // 获取所有启用的SLA规则
        $rules = SlaRule::where('status', 1)->get();

        // 获取所有进行中的报修单（status=1 维修中，或 status=0 待处理）
        $activeOrders = RepairOrder::whereIn('status', [0, 1])->get();

        foreach ($activeOrders as $order) {
            // 匹配SLA规则（按category和urgency）
            $rule = $rules->first(function ($r) use ($order) {
                return $r->category === $order->category && $r->urgency === $order->urgency;
            });

            if (!$rule) {
                // 尝试按category匹配，忽略urgency
                $rule = $rules->first(function ($r) use ($order) {
                    return $r->category === $order->category;
                });
            }

            if (!$rule) {
                continue;
            }

            // 查找或创建SLA记录
            $slaRecord = SlaRecord::where('repair_order_id', $order->id)->first();
            if (!$slaRecord) {
                $responseDeadline = date('Y-m-d H:i:s', strtotime($order->created_at->format('Y-m-d H:i:s')) + ($rule->response_minutes * 60));
                $resolveDeadline  = date('Y-m-d H:i:s', strtotime($order->created_at->format('Y-m-d H:i:s')) + ($rule->resolve_minutes * 60));

                $slaRecord = SlaRecord::create([
                    'id'              => SnowflakeService::generate(),
                    'repair_order_id' => $order->id,
                    'rule_id'         => $rule->id,
                    'response_deadline' => $responseDeadline,
                    'resolve_deadline'  => $resolveDeadline,
                    'escalate_level'    => 0,
                    'is_response_overtime' => 0,
                    'is_resolve_overtime'  => 0,
                    'penalty_amount'       => 0,
                ]);
            }

            // 检查响应超时
            if (!$slaRecord->is_response_overtime && $now > $slaRecord->response_deadline->format('Y-m-d H:i:s')) {
                $slaRecord->is_response_overtime = 1;
                $slaRecord->save();
            }

            // 检查解决超时
            if (!$slaRecord->is_resolve_overtime && $now > $slaRecord->resolve_deadline->format('Y-m-d H:i:s')) {
                $slaRecord->is_resolve_overtime = 1;
                $slaRecord->save();
            }

            // 检查是否需要升级
            $escalateDeadline = date('Y-m-d H:i:s', strtotime($order->created_at->format('Y-m-d H:i:s')) + ($rule->escalate_minutes * 60));
            if (!$slaRecord->escalated_at && $rule->escalate_minutes > 0 && $now > $escalateDeadline) {
                $slaRecord->escalated_at    = $now;
                $slaRecord->escalate_level  = $slaRecord->escalate_level + 1;
                $slaRecord->penalty_amount  = ($slaRecord->penalty_amount ?? 0) + ($rule->penalty_amount ?? 0);
                $slaRecord->save();

                // 创建通知
                Notification::create([
                    'id'        => SnowflakeService::generate(),
                    'user_id'   => 0,
                    'user_type' => 2,
                    'title'     => 'SLA超时升级',
                    'content'   => "报修单 {$order->order_number} 已超过SLA升级时限（{$rule->name}），请及时处理。",
                    'type'      => 3,
                    'channel'   => '["system"]',
                    'is_read'   => 0,
                    'ref_type'  => 'repair',
                    'ref_id'    => $order->id,
                ]);

                $escalateCount++;
            }
        }

        return $this->success(['escalate_count' => $escalateCount], '超时检查完成');
    }
}
