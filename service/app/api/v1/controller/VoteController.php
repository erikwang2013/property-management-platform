<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;

use app\common\BaseController;
use app\model\RoomOwner;
use app\model\Vote;
use app\model\VoteOption;
use app\model\VoteRecord;
use InvalidArgumentException;
use support\Request;
use support\Response;

/**
 * 业主投票
 * @Apidoc\Group("extensions")
 * @Apidoc\Sort(2)
 */
class VoteController extends BaseController
{
    /**
     * 投票列表（业主所在小区的进行中投票）
     * GET /service/votes
     */
    public function index(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);

        // 获取业主所在的小区ID集合
        $communityIds = RoomOwner::where('owner_id', $ownerId)
            ->join('erik_room', 'erik_room_owner.room_id', '=', 'erik_room.id')
            ->pluck('erik_room.community_id')
            ->unique()
            ->toArray();

        if (empty($communityIds)) {
            return $this->success(['data' => [], 'total' => 0]);
        }

        $now = date('Y-m-d H:i:s');

        $list = Vote::whereIn('community_id', $communityIds)
            ->where('status', 1)
            ->where('start_time', '<=', $now)
            ->where('end_time', '>=', $now)
            ->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($vote) use ($ownerId) {
                // 检查是否已投票
                $hasVoted = VoteRecord::where('vote_id', $vote->id)
                    ->where('owner_id', $ownerId)
                    ->exists();

                return [
                    'id'          => $this->encodeId($vote->id),
                    'title'       => $vote->title,
                    'description' => $vote->description,
                    'vote_type'   => $vote->vote_type,
                    'is_anonymous' => $vote->is_anonymous,
                    'start_time'  => $vote->start_time ? $vote->start_time->format('Y-m-d H:i') : '',
                    'end_time'    => $vote->end_time ? $vote->end_time->format('Y-m-d H:i') : '',
                    'has_voted'   => $hasVoted,
                    'created_at'  => $vote->created_at ? $vote->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 投票详情（含选项）
     * GET /service/vote/{hashid}
     */
    public function show(Request $request, string $hashid): Response
    {
        $ownerId = $this->getOwnerId($request);

        try {
            $voteId = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的投票ID', 404);
        }

        $vote = Vote::find($voteId);
        if (!$vote) {
            return $this->fail('投票不存在', 404);
        }

        // 检查是否已投票
        $myVote = VoteRecord::where('vote_id', $voteId)
            ->where('owner_id', $ownerId)
            ->first();

        // 选项列表
        $options = VoteOption::where('vote_id', $voteId)
            ->orderBy('sort', 'asc')
            ->get()
            ->map(function ($option) {
                return [
                    'id'                 => $this->encodeId($option->id),
                    'content'            => $option->content,
                    'vote_count'         => $option->vote_count,
                    'area_weighted_count' => $option->area_weighted_count,
                ];
            });

        return $this->success([
            'id'          => $this->encodeId($vote->id),
            'title'       => $vote->title,
            'description' => $vote->description,
            'vote_type'   => $vote->vote_type,
            'is_anonymous' => $vote->is_anonymous,
            'min_participation_rate' => $vote->min_participation_rate,
            'status'      => $vote->status,
            'start_time'  => $vote->start_time ? $vote->start_time->format('Y-m-d H:i') : '',
            'end_time'    => $vote->end_time ? $vote->end_time->format('Y-m-d H:i') : '',
            'has_voted'   => $myVote !== null,
            'my_option_id' => $myVote ? $this->encodeId($myVote->option_id) : '',
            'options'     => $options,
            'created_at'  => $vote->created_at ? $vote->created_at->format('Y-m-d H:i') : '',
        ]);
    }

    /**
     * 投票
     * POST /service/vote/{hashid}/cast
     */
    public function cast(Request $request, string $hashid): Response
    {
        $ownerId = $this->getOwnerId($request);

        try {
            $voteId = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的投票ID', 404);
        }

        $vote = Vote::find($voteId);
        if (!$vote) {
            return $this->fail('投票不存在', 404);
        }

        if ($vote->status !== 1) {
            return $this->fail('投票已结束或未开始', 422);
        }

        $now = date('Y-m-d H:i:s');
        if ($now < $vote->start_time->format('Y-m-d H:i:s')) {
            return $this->fail('投票尚未开始', 422);
        }
        if ($now > $vote->end_time->format('Y-m-d H:i:s')) {
            return $this->fail('投票已结束', 422);
        }

        // 检查是否已投票
        $existing = VoteRecord::where('vote_id', $voteId)
            ->where('owner_id', $ownerId)
            ->first();
        if ($existing) {
            return $this->fail('您已经投过票了', 422);
        }

        $optionHashid = $request->input('option_id', '');
        if (empty($optionHashid)) {
            return $this->fail('请选择投票选项', 422);
        }

        try {
            $optionId = $this->decodeId($optionHashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的选项ID', 404);
        }

        $option = VoteOption::where('vote_id', $voteId)->find($optionId);
        if (!$option) {
            return $this->fail('选项不存在', 404);
        }

        // 获取业主的房产面积权重
        $areaRatio = 0.0;
        $roomId    = 0;

        if ($vote->vote_type === 2) {
            // 面积加权投票：获取业主名下在该小区的房产
            $room = RoomOwner::where('owner_id', $ownerId)
                ->join('erik_room', 'erik_room_owner.room_id', '=', 'erik_room.id')
                ->where('erik_room.community_id', $vote->community_id)
                ->select('erik_room.id', 'erik_room.area_total')
                ->first();

            if ($room) {
                $roomId    = $room->id;
                $areaRatio = (float) $room->area_total;
            }
        }

        // 创建投票记录
        VoteRecord::create([
            'id'         => $this->generateId(),
            'vote_id'    => $voteId,
            'option_id'  => $optionId,
            'owner_id'   => $ownerId,
            'room_id'    => $roomId,
            'area_ratio' => $areaRatio,
            'voted_at'   => $now,
        ]);

        // 更新选项计数
        $option->vote_count = $option->vote_count + 1;
        if ($vote->vote_type === 2) {
            $option->area_weighted_count = $option->area_weighted_count + $areaRatio;
        }
        $option->save();

        return $this->success([], '投票成功');
    }
}
