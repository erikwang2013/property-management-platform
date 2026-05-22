<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;

use app\common\SnowflakeService;
use app\model\Activity;
use support\Request;

/**
 * 物业管理·高级
 * @Apidoc\Group("property-adv")
 */
class ActivityController extends BaseController
{
    /**
     * 社区活动列表
     * ?community_id=xxx&status=xxx&keyword=搜索词
     */
    public function index(Request $request)
    {
        $communityId = $request->input('community_id');
        $status      = $request->input('status');
        $keyword     = $request->input('keyword', '');

        $query = Activity::query();

        if (!empty($communityId)) {
            $query->where('community_id', (int) $communityId);
        }
        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        }
        if (!empty($keyword)) {
            $query->where('title', 'like', "%{$keyword}%");
        }

        $list = $query->orderBy('start_time', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'           => $this->encodeId($item->id),
                    'community_id' => $this->encodeId($item->community_id),
                    'title'        => $item->title,
                    'location'     => $item->location,
                    'start_time'   => $item->start_time ? $item->start_time->format('Y-m-d H:i') : '',
                    'end_time'     => $item->end_time ? $item->end_time->format('Y-m-d H:i') : '',
                    'max_signup'   => $item->max_signup,
                    'signup_count' => $item->signup_count,
                    'status'       => $item->status,
                    'created_at'   => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /** 活动详情 */
    public function show(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = Activity::find($id);
        if (!$item) {
            return $this->fail('活动不存在', 404);
        }

        return $this->success([
            'id'           => $this->encodeId($item->id),
            'community_id' => $this->encodeId($item->community_id),
            'title'        => $item->title,
            'description'  => $item->description,
            'cover_image'  => $item->cover_image,
            'location'     => $item->location,
            'start_time'   => $item->start_time ? $item->start_time->format('Y-m-d H:i') : '',
            'end_time'     => $item->end_time ? $item->end_time->format('Y-m-d H:i') : '',
            'max_signup'   => $item->max_signup,
            'signup_count' => $item->signup_count,
            'status'       => $item->status,
            'created_at'   => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
            'updated_at'   => $item->updated_at ? $item->updated_at->format('Y-m-d H:i') : '',
        ]);
    }

    /** 创建活动 */
    public function store(Request $request)
    {
        $data = $request->only([
            'community_id', 'title', 'description', 'cover_image',
            'location', 'start_time', 'end_time', 'max_signup',
        ]);

        if (empty($data['community_id'])) {
            return $this->fail('请选择所属小区', 422);
        }
        if (empty($data['title'])) {
            return $this->fail('活动标题不能为空', 422);
        }

        $data['id']           = SnowflakeService::generate();
        $data['status']       = $request->input('status', 0); // 0=草稿
        $data['signup_count'] = 0;

        Activity::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /** 更新活动 */
    public function update(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = Activity::find($id);
        if (!$item) {
            return $this->fail('活动不存在', 404);
        }

        $item->fill($request->only([
            'community_id', 'title', 'description', 'cover_image',
            'location', 'start_time', 'end_time', 'max_signup', 'status',
        ]));
        $item->save();

        return $this->success([], '更新成功');
    }

    /** 删除活动（需密码确认） */
    public function destroy(Request $request, string $hashid)
    {
        $adminId  = $request->adminId;
        $password = $request->input('password', '');

        $error = $this->confirmPassword($adminId, $password, $request);
        if ($error !== null) {
            return $this->fail($error, 422);
        }

        $id   = $this->decodeId($hashid);
        $item = Activity::find($id);
        if (!$item) {
            return $this->fail('活动不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }
}
