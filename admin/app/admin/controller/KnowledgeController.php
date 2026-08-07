<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;
use hg\apidoc\annotation as Apidoc;

use app\common\SnowflakeService;
use app\model\ChatRecord;
use app\model\KnowledgeBase;
use InvalidArgumentException;
use support\Db;
use support\Request;

/**
 * 扩展功能
 * @Apidoc\Group("extensions")
 */
class KnowledgeController extends BaseController
{
    // ============================================================
    // 分类管理
    // ============================================================

    /**
     * 分类列表
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/knowledge-category")
     */
    public function categories(Request $request)
    {
        $list = KnowledgeBase::where('category_id', 0)
            ->orderBy('sort', 'asc')
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($item) {
                return [
                    'id'         => $this->encodeId($item->id),
                    'name'       => $item->question,
                    'sort'       => $item->sort,
                    'status'     => $item->status,
                    'created_at' => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 创建分类
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/knowledge-category")
     */
    public function categoryStore(Request $request)
    {
        $name = $request->input('name', '');
        $sort = $request->input('sort', 0);

        if (empty($name)) {
            return $this->fail('分类名称不能为空', 422);
        }

        $data = [
            'id'          => SnowflakeService::generate(),
            'category_id' => 0,
            'question'    => $name,
            'answer'      => '',
            'keywords'    => '',
            'sort'        => (int) $sort,
            'status'      => 1,
        ];

        KnowledgeBase::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /**
     * 更新分类
     * @Apidoc\Method("PUT")
     * @Apidoc\Url("/admin/knowledge-category/{hashid}")
     */
    public function categoryUpdate(Request $request, string $hashid)
    {
        try {
            $id = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的分类ID', 404);
        }

        $item = KnowledgeBase::where('category_id', 0)->find($id);
        if (!$item) {
            return $this->fail('分类不存在', 404);
        }

        $name = $request->input('name', $item->question);
        $sort = $request->input('sort', $item->sort);
        $status = $request->input('status', $item->status);

        $item->question = $name;
        $item->sort     = (int) $sort;
        $item->status   = (int) $status;
        $item->save();

        return $this->success([], '更新成功');
    }

    /**
     * 删除分类
     * @Apidoc\Method("DELETE")
     * @Apidoc\Url("/admin/knowledge-category/{hashid}")
     */
    public function categoryDestroy(Request $request, string $hashid)
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
            return $this->fail('无效的分类ID', 404);
        }

        $item = KnowledgeBase::where('category_id', 0)->find($id);
        if (!$item) {
            return $this->fail('分类不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }

    // ============================================================
    // 文章/知识管理
    // ============================================================

    /**
     * 知识库文章列表
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/knowledge")
     */
    public function articles(Request $request)
    {
        $categoryId = $request->input('category_id');
        $keyword    = $request->input('keyword', '');

        $query = KnowledgeBase::where('category_id', '>', 0);
        if (!empty($categoryId)) {
            $query->where('category_id', (int) $categoryId);
        }
        if (!empty($keyword)) {
            $query->where(function ($q) use ($keyword) {
                $q->where('question', 'like', "%{$keyword}%")
                  ->orWhere('keywords', 'like', "%{$keyword}%");
            });
        }

        $list = $query->orderBy('sort', 'asc')
            ->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'            => $this->encodeId($item->id),
                    'category_id'   => $item->category_id,
                    'question'      => $item->question,
                    'answer'        => $item->answer,
                    'keywords'      => $item->keywords,
                    'view_count'    => $item->view_count,
                    'helpful_count' => $item->helpful_count,
                    'sort'          => $item->sort,
                    'status'        => $item->status,
                    'created_at'    => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 创建知识文章
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/knowledge")
     */
    public function articleStore(Request $request)
    {
        $data = $request->only([
            'category_id', 'question', 'answer', 'keywords', 'sort',
        ]);

        if (empty($data['question'])) {
            return $this->fail('问题不能为空', 422);
        }

        $data['id']     = SnowflakeService::generate();
        $data['status'] = 1;

        KnowledgeBase::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /**
     * 更新知识文章
     * @Apidoc\Method("PUT")
     * @Apidoc\Url("/admin/knowledge/{hashid}")
     */
    public function articleUpdate(Request $request, string $hashid)
    {
        try {
            $id = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的文章ID', 404);
        }

        $item = KnowledgeBase::where('category_id', '>', 0)->find($id);
        if (!$item) {
            // 也允许查找category_id=0的记录
            $item = KnowledgeBase::find($id);
            if (!$item) {
                return $this->fail('文章不存在', 404);
            }
        }

        $item->fill($request->only([
            'category_id', 'question', 'answer', 'keywords', 'sort', 'status',
        ]));
        $item->save();

        return $this->success([], '更新成功');
    }

    /**
     * 删除知识文章
     * @Apidoc\Method("DELETE")
     * @Apidoc\Url("/admin/knowledge/{hashid}")
     */
    public function articleDestroy(Request $request, string $hashid)
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
            return $this->fail('无效的文章ID', 404);
        }

        $item = KnowledgeBase::find($id);
        if (!$item) {
            return $this->fail('文章不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }

    // ============================================================
    // 聊天记录
    // ============================================================

    /**
     * 聊天记录列表
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/chat-record")
     */
    public function chatRecords(Request $request)
    {
        $userId   = $request->input('user_id');
        $userType = $request->input('user_type');

        $query = ChatRecord::query();
        if (!empty($userId)) {
            $query->where('user_id', (int) $userId);
        }
        if ($userType !== null && $userType !== '') {
            $query->where('user_type', (int) $userType);
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'            => $this->encodeId($item->id),
                    'user_id'       => $item->user_id,
                    'user_type'     => $item->user_type,
                    'question'      => $item->question,
                    'answer'        => $item->answer,
                    'match_type'    => $item->match_type,
                    'matched_kb_id' => $item->matched_kb_id,
                    'is_helpful'    => $item->is_helpful,
                    'created_at'    => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 聊天统计
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/chat-stats")
     */
    public function chatStats(Request $request)
    {
        // 总对话数
        $totalChats = ChatRecord::count();

        // 匹配率（match_type != 2 即非转人工）
        $matchCount = ChatRecord::where('match_type', '!=', 2)->count();
        $matchRate  = $totalChats > 0 ? round(($matchCount / $totalChats) * 100, 2) : 0;

        // 有用率（is_helpful = 1 / (is_helpful = 1 + 2)）
        $helpfulCount   = ChatRecord::where('is_helpful', 1)->count();
        $notHelpfulCount = ChatRecord::where('is_helpful', 2)->count();
        $ratedCount     = $helpfulCount + $notHelpfulCount;
        $helpfulRate    = $ratedCount > 0 ? round(($helpfulCount / $ratedCount) * 100, 2) : 0;

        return $this->success([
            'total_chats'   => $totalChats,
            'match_count'   => $matchCount,
            'match_rate'    => number_format($matchRate, 2, '.', '') . '%',
            'helpful_count' => $helpfulCount,
            'helpful_rate'  => number_format($helpfulRate, 2, '.', '') . '%',
        ]);
    }
}
