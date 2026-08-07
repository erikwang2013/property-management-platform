<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;
use hg\apidoc\annotation as Apidoc;

use app\model\ActivitySignup;
use support\Carbon;
use support\Request;

/**
 * 物业管理·高级
 * @Apidoc\Group("property-adv")
 */
class ActivitySignupController extends BaseController
{
    /**
     * 活动报名列表
     * ?activity_id=xxx&signup_status=xxx
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/activity-signup")
     */
    public function index(Request $request)
    {
        $activityId   = $request->input('activity_id');
        $signupStatus = $request->input('signup_status');

        $query = ActivitySignup::query();

        if (!empty($activityId)) {
            $query->where('activity_id', (int) $activityId);
        }
        if ($signupStatus !== null && $signupStatus !== '') {
            $query->where('signup_status', (int) $signupStatus);
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'               => $this->encodeId($item->id),
                    'activity_id'      => $this->encodeId($item->activity_id),
                    'owner_id'         => $item->owner_id ? $this->encodeId($item->owner_id) : '',
                    'participant_count' => $item->participant_count,
                    'contact_phone'    => $item->contact_phone,
                    'remark'           => $item->remark,
                    'signup_status'    => $item->signup_status,
                    'signup_at'        => $item->signup_at ? $item->signup_at->format('Y-m-d H:i') : '',
                    'checkin_at'       => $item->checkin_at ? $item->checkin_at->format('Y-m-d H:i') : '',
                    'created_at'       => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 签到
     * @Apidoc\Method("PUT")
     * @Apidoc\Url("/admin/activity-signup/{id}/checkin")
     */
    public function checkin(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = ActivitySignup::find($id);
        if (!$item) {
            return $this->fail('报名记录不存在', 404);
        }

        if ($item->signup_status == 1) {
            return $this->fail('已签到，请勿重复操作', 422);
        }

        $item->signup_status = 1;
        $item->checkin_at    = date('Y-m-d H:i:s');
        $item->save();

        return $this->success([
            'id'            => $this->encodeId($item->id),
            'signup_status' => $item->signup_status,
            'checkin_at'    => $item->checkin_at,
        ], '签到成功');
    }
}
