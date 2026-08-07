<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;
use hg\apidoc\annotation as Apidoc;

use app\common\BaseController;
use app\model\ActivitySignup;
use app\model\CommunityActivity;
use support\Request;
use support\Response;
use InvalidArgumentException;

/**
 * 社区活动
 * @Apidoc\Group("activity")
 * @Apidoc\Sort(1)
 */
class ActivityController extends BaseController
{
    /**
     * 社区活动列表（仅已发布）
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/service/activities")
     */
    public function index(Request $request): Response
    {
        $communityId = $request->input('community_id');
        $status      = $request->input('status');
        $page        = (int) $request->input('page', 1);

        $query = CommunityActivity::query()->withCount('signups');

        if (!empty($communityId)) {
            $query->where('community_id', (int) $communityId);
        }
        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        } else {
            // 默认只展示报名中和进行中的活动
            $query->whereIn('status', [1, 2]);
        }

        $activities = $query->orderBy('start_time', 'desc')
            ->paginate(20, ['*'], 'page', $page)
            ->through(function ($item) {
                return [
                    'id'               => $this->encodeId($item->id),
                    'title'            => $item->title,
                    'category'         => $item->category,
                    'cover_image'      => $item->cover_image,
                    'location'         => $item->location,
                    'start_time'       => $item->start_time ? $item->start_time->format('Y-m-d H:i') : '',
                    'end_time'         => $item->end_time ? $item->end_time->format('Y-m-d H:i') : '',
                    'max_participants' => $item->max_participants,
                    'signup_count'     => $item->signups_count ?? 0,
                    'is_free'          => $item->is_free,
                    'cost'             => $item->cost,
                    'organizer'        => $item->organizer,
                    'status'           => $item->status,
                    'created_at'       => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($activities);
    }

    /**
     * 活动详情（含报名人数）
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/service/activity/{hashid}")
     */
    public function show(Request $request, string $hashid): Response
    {
        try {
            $activityId = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的活动ID', 404);
        }

        $activity = CommunityActivity::withCount('signups')->find($activityId);
        if (!$activity) {
            return $this->fail('活动不存在', 404);
        }

        $data = [
            'id'               => $this->encodeId($activity->id),
            'community_id'     => $activity->community_id ? $this->encodeId($activity->community_id) : '',
            'title'            => $activity->title,
            'content'          => $activity->content,
            'category'         => $activity->category,
            'cover_image'      => $activity->cover_image,
            'location'         => $activity->location,
            'max_participants' => $activity->max_participants,
            'signup_count'     => $activity->signups_count ?? 0,
            'start_time'       => $activity->start_time ? $activity->start_time->format('Y-m-d H:i') : '',
            'end_time'         => $activity->end_time ? $activity->end_time->format('Y-m-d H:i') : '',
            'signup_start'     => $activity->signup_start ? $activity->signup_start->format('Y-m-d H:i') : '',
            'signup_end'       => $activity->signup_end ? $activity->signup_end->format('Y-m-d H:i') : '',
            'is_free'          => $activity->is_free,
            'cost'             => $activity->cost,
            'organizer'        => $activity->organizer,
            'contact_phone'    => $activity->contact_phone,
            'status'           => $activity->status,
            'created_at'       => $activity->created_at ? $activity->created_at->format('Y-m-d H:i') : '',
        ];

        return $this->success($data);
    }

    /**
     * 报名活动
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/service/activity/{hashid}/signup")
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

        $activity = CommunityActivity::find($activityId);
        if (!$activity) {
            return $this->fail('活动不存在', 404);
        }

        // 状态校验：仅开放报名状态(1=报名中)允许报名
        if ($activity->status != 1) {
            return $this->fail('当前活动暂未开放报名', 422);
        }

        // 名额校验
        $signupCount = ActivitySignup::where('activity_id', $activityId)
            ->where('signup_status', '<>', 2)
            ->count();
        if ($activity->max_participants > 0 && $signupCount >= $activity->max_participants) {
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

        return $this->success([
            'id'           => $this->encodeId($signup->id),
            'signup_count' => ActivitySignup::where('activity_id', $activityId)->count(),
        ], '报名成功');
    }

    /**
     * 取消报名
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/service/activity/{hashid}/cancel")
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

        return $this->success([], '取消报名成功');
    }
}
