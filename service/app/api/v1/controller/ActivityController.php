<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;

use app\common\BaseController;
use app\model\Activity;
use app\model\ActivitySignup;
use support\Request;
use support\Response;
use InvalidArgumentException;

class ActivityController extends BaseController
{
    /**
     * 社区活动列表（仅已发布）
     * GET /service/activities?community_id=xxx&status=xxx&page=1
     */
    public function index(Request $request): Response
    {
        $communityId = $request->input('community_id');
        $status      = $request->input('status');
        $page        = (int) $request->input('page', 1);

        $query = Activity::query();

        if (!empty($communityId)) {
            $query->where('community_id', (int) $communityId);
        }
        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        } else {
            // 默认只展示已发布和进行中的活动
            $query->whereIn('status', [1, 2]);
        }

        $activities = $query->orderBy('start_time', 'desc')
            ->paginate(20, ['*'], 'page', $page)
            ->through(function ($item) {
                return [
                    'id'           => $this->encodeId($item->id),
                    'title'        => $item->title,
                    'cover_image'  => $item->cover_image,
                    'location'     => $item->location,
                    'start_time'   => $item->start_time ? $item->start_time->format('Y-m-d H:i') : '',
                    'end_time'     => $item->end_time ? $item->end_time->format('Y-m-d H:i') : '',
                    'max_signup'   => $item->max_signup,
                    'signup_count' => $item->signup_count,
                    'status'       => $item->status,
                    'created_at'   => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($activities);
    }

    /**
     * 活动详情（含报名人数）
     * GET /service/activity/{hashid}
     */
    public function show(Request $request, string $hashid): Response
    {
        try {
            $activityId = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的活动ID', 404);
        }

        $activity = Activity::find($activityId);
        if (!$activity) {
            return $this->fail('活动不存在', 404);
        }

        $data = [
            'id'           => $this->encodeId($activity->id),
            'community_id' => $activity->community_id ? $this->encodeId($activity->community_id) : '',
            'title'        => $activity->title,
            'description'  => $activity->description,
            'cover_image'  => $activity->cover_image,
            'location'     => $activity->location,
            'start_time'   => $activity->start_time ? $activity->start_time->format('Y-m-d H:i') : '',
            'end_time'     => $activity->end_time ? $activity->end_time->format('Y-m-d H:i') : '',
            'max_signup'   => $activity->max_signup,
            'signup_count' => $activity->signup_count,
            'status'       => $activity->status,
            'created_at'   => $activity->created_at ? $activity->created_at->format('Y-m-d H:i') : '',
        ];

        return $this->success($data);
    }

    /**
     * 报名活动
     * POST /service/activity/{hashid}/signup
     */
    public function signup(Request $request, string $hashid): Response
    {
        $ownerId = $this->getOwnerId($request);
        if (empty($ownerId)) {
            return $this->fail('请先登录', 401);
        }

        try {
            $activityId = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的活动ID', 404);
        }

        $activity = Activity::find($activityId);
        if (!$activity) {
            return $this->fail('活动不存在', 404);
        }

        // 状态校验：仅开放报名状态(1=open)允许报名
        if ($activity->status != 1) {
            return $this->fail('当前活动暂未开放报名', 422);
        }

        // 名额校验
        if ($activity->max_signup > 0 && $activity->signup_count >= $activity->max_signup) {
            return $this->fail('报名已满', 422);
        }

        // 是否已报名
        $exists = ActivitySignup::where('activity_id', $activityId)
            ->where('owner_id', $ownerId)
            ->exists();
        if ($exists) {
            return $this->fail('您已报名该活动', 422);
        }

        $participantCount = (int) $request->input('participant_count', 1);
        $contactPhone     = $request->input('contact_phone', '');
        $remark           = $request->input('remark', '');

        $signup = new ActivitySignup();
        $signup->id                = $this->generateId();
        $signup->activity_id       = $activityId;
        $signup->owner_id          = $ownerId;
        $signup->participant_count = max(1, $participantCount);
        $signup->contact_phone     = $contactPhone;
        $signup->remark            = $remark;
        $signup->signup_status     = 0;
        $signup->signup_at         = date('Y-m-d H:i:s');
        $signup->save();

        // 更新活动报名人数
        $activity->signup_count = ActivitySignup::where('activity_id', $activityId)->count();
        $activity->save();

        return $this->success([
            'id' => $this->encodeId($signup->id),
        ], '报名成功');
    }

    /**
     * 取消报名
     * POST /service/activity/{hashid}/cancel
     */
    public function cancel(Request $request, string $hashid): Response
    {
        $ownerId = $this->getOwnerId($request);
        if (empty($ownerId)) {
            return $this->fail('请先登录', 401);
        }

        try {
            $activityId = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的活动ID', 404);
        }

        $signup = ActivitySignup::where('activity_id', $activityId)
            ->where('owner_id', $ownerId)
            ->first();

        if (!$signup) {
            return $this->fail('未找到您的报名记录', 404);
        }

        // 已签到不可取消
        if ($signup->signup_status == 1) {
            return $this->fail('已签到，无法取消报名', 422);
        }

        $signup->delete();

        // 更新活动报名人数
        $activity = Activity::find($activityId);
        if ($activity) {
            $activity->signup_count = ActivitySignup::where('activity_id', $activityId)->count();
            $activity->save();
        }

        return $this->success([], '取消报名成功');
    }
}
