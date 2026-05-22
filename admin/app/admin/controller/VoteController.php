<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;

use app\common\SnowflakeService;
use app\model\Vote;
use app\model\VoteOption;
use app\model\VoteRecord;
use support\Request;
use support\Response;

/**
 * 扩展功能
 * @Apidoc\Group("extensions")
 */
class VoteController extends BaseController
{
    /**
     * 投票列表
     * GET /admin/vote?community_id=&status=&page=
     */
    public function index(Request $request): Response
    {
        $query = Vote::query();

        if ($c = $request->input('community_id')) {
            $query->where('community_id', (int) $c);
        }
        if ($s = $request->input('status')) {
            $query->where('status', (int) $s);
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate(20)
            ->through(fn($i) => [
                'id'                      => $this->encodeId($i->id),
                'community_id'            => $i->community_id,
                'title'                   => $i->title,
                'description'             => $i->description,
                'vote_type'               => $i->vote_type,
                'start_time'              => $i->start_time ? $i->start_time->format('Y-m-d H:i') : '',
                'end_time'                => $i->end_time ? $i->end_time->format('Y-m-d H:i') : '',
                'is_anonymous'            => $i->is_anonymous,
                'min_participation_rate'  => $i->min_participation_rate,
                'status'                  => $i->status,
                'publisher_id'            => $i->publisher_id,
                'created_at'              => $i->created_at ? $i->created_at->format('Y-m-d H:i') : '',
            ]);

        return $this->success($list);
    }

    /**
     * 创建投票
     * POST /admin/vote
     */
    public function store(Request $request): Response
    {
        $data = $request->only([
            'community_id', 'title', 'description', 'vote_type',
            'start_time', 'end_time', 'is_anonymous', 'min_participation_rate',
            'status', 'publisher_id',
        ]);
        $data['id'] = SnowflakeService::generate();
        Vote::create($data);
        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /**
     * 投票详情
     * GET /admin/vote/{hashid}
     */
    public function show(Request $request, string $hashid): Response
    {
        $id = $this->decodeId($hashid);
        $vote = Vote::findOrFail($id);

        $data = [
            'id'                      => $this->encodeId($vote->id),
            'community_id'            => $vote->community_id,
            'title'                   => $vote->title,
            'description'             => $vote->description,
            'vote_type'               => $vote->vote_type,
            'start_time'              => $vote->start_time ? $vote->start_time->format('Y-m-d H:i') : '',
            'end_time'                => $vote->end_time ? $vote->end_time->format('Y-m-d H:i') : '',
            'is_anonymous'            => $vote->is_anonymous,
            'min_participation_rate'  => $vote->min_participation_rate,
            'status'                  => $vote->status,
            'publisher_id'            => $vote->publisher_id,
            'created_at'              => $vote->created_at ? $vote->created_at->format('Y-m-d H:i') : '',
            'updated_at'              => $vote->updated_at ? $vote->updated_at->format('Y-m-d H:i') : '',
        ];

        return $this->success($data);
    }

    /**
     * 更新投票
     * PUT /admin/vote/{hashid}
     */
    public function update(Request $request, string $hashid): Response
    {
        $id = $this->decodeId($hashid);
        $vote = Vote::findOrFail($id);

        $vote->fill($request->only([
            'community_id', 'title', 'description', 'vote_type',
            'start_time', 'end_time', 'is_anonymous', 'min_participation_rate',
            'status', 'publisher_id',
        ]));
        $vote->save();

        return $this->success([], '更新成功');
    }

    /**
     * 删除投票
     * DELETE /admin/vote/{hashid}
     */
    public function destroy(Request $request, string $hashid): Response
    {
        $id = $this->decodeId($hashid);
        Vote::findOrFail($id)->delete();
        // 同时删除关联的选项和记录
        VoteOption::where('vote_id', $id)->delete();
        VoteRecord::where('vote_id', $id)->delete();
        return $this->success([], '删除成功');
    }

    /**
     * 投票选项列表
     * GET /admin/vote/{hashid}/options
     */
    public function options(Request $request, string $hashid): Response
    {
        $voteId = $this->decodeId($hashid);

        $list = VoteOption::where('vote_id', $voteId)
            ->orderBy('sort', 'asc')
            ->orderBy('id', 'asc')
            ->get()
            ->map(fn($i) => [
                'id'                  => $this->encodeId($i->id),
                'vote_id'             => $this->encodeId($i->vote_id),
                'content'             => $i->content,
                'sort'                => $i->sort,
                'vote_count'          => $i->vote_count,
                'area_weighted_count' => $i->area_weighted_count,
                'created_at'          => $i->created_at ? $i->created_at->format('Y-m-d H:i') : '',
            ]);

        return $this->success($list);
    }

    /**
     * 添加投票选项
     * POST /admin/vote/{hashid}/option
     */
    public function optionStore(Request $request, string $hashid): Response
    {
        $voteId = $this->decodeId($hashid);
        // 验证投票是否存在
        Vote::findOrFail($voteId);

        $data = $request->only(['content', 'sort']);
        $data['id'] = SnowflakeService::generate();
        $data['vote_id'] = $voteId;

        VoteOption::create($data);
        return $this->success(['id' => $this->encodeId($data['id'])], '添加成功');
    }

    /**
     * 更新投票选项
     * PUT /admin/vote-option/{hashid}
     */
    public function optionUpdate(Request $request, string $hashid): Response
    {
        $id = $this->decodeId($hashid);
        $option = VoteOption::findOrFail($id);
        $option->fill($request->only(['content', 'sort']));
        $option->save();
        return $this->success([], '更新成功');
    }

    /**
     * 删除投票选项
     * DELETE /admin/vote-option/{hashid}
     */
    public function optionDestroy(Request $request, string $hashid): Response
    {
        $id = $this->decodeId($hashid);
        VoteOption::findOrFail($id)->delete();
        // 删除关联的投票记录
        VoteRecord::where('option_id', $id)->delete();
        return $this->success([], '删除成功');
    }

    /**
     * 投票记录列表
     * GET /admin/vote/{hashid}/records
     */
    public function records(Request $request, string $hashid): Response
    {
        $voteId = $this->decodeId($hashid);

        $list = VoteRecord::with(['option:id,content'])
            ->where('vote_id', $voteId)
            ->orderBy('voted_at', 'desc')
            ->paginate(20)
            ->through(fn($i) => [
                'id'          => $this->encodeId($i->id),
                'vote_id'     => $this->encodeId($i->vote_id),
                'option_id'   => $this->encodeId($i->option_id),
                'option_text' => $i->option->content ?? '',
                'owner_id'    => $i->owner_id,
                'room_id'     => $i->room_id,
                'area_ratio'  => $i->area_ratio,
                'voted_at'    => $i->voted_at ? $i->voted_at->format('Y-m-d H:i') : '',
            ]);

        return $this->success($list);
    }

    /**
     * 投票结果统计
     * GET /admin/vote/{hashid}/statistics
     */
    public function statistics(Request $request, string $hashid): Response
    {
        $voteId = $this->decodeId($hashid);
        $vote = Vote::findOrFail($voteId);

        $options = VoteOption::where('vote_id', $voteId)
            ->orderBy('sort', 'asc')
            ->orderBy('id', 'asc')
            ->get();

        $totalVotes = $options->sum('vote_count');
        $totalWeighted = $options->sum('area_weighted_count');

        $result = $options->map(function ($o) use ($totalVotes, $totalWeighted) {
            return [
                'id'                  => $this->encodeId($o->id),
                'content'             => $o->content,
                'sort'                => $o->sort,
                'vote_count'          => $o->vote_count,
                'area_weighted_count' => $o->area_weighted_count,
                'ratio'               => $totalVotes > 0 ? round($o->vote_count / $totalVotes * 100, 2) : 0,
                'weighted_ratio'      => $totalWeighted > 0 ? round($o->area_weighted_count / $totalWeighted * 100, 2) : 0,
            ];
        });

        return $this->success([
            'vote'         => [
                'id'     => $this->encodeId($vote->id),
                'title'  => $vote->title,
                'status' => $vote->status,
            ],
            'total_votes'    => $totalVotes,
            'total_weighted' => $totalWeighted,
            'options'        => $result,
        ]);
    }

    /**
     * 发布投票（设为进行中）
     * PUT /admin/vote/{hashid}/publish
     */
    public function publish(Request $request, string $hashid): Response
    {
        $id = $this->decodeId($hashid);
        $vote = Vote::findOrFail($id);
        $vote->status = 1;
        $vote->save();
        return $this->success([], '发布成功');
    }

    /**
     * 结束投票（设为已结束）
     * PUT /admin/vote/{hashid}/end
     */
    public function end(Request $request, string $hashid): Response
    {
        $id = $this->decodeId($hashid);
        $vote = Vote::findOrFail($id);
        $vote->status = 2;
        $vote->save();
        return $this->success([], '已结束');
    }
}
