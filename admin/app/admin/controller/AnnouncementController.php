<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;
use hg\apidoc\annotation as Apidoc;

use app\common\SnowflakeService;
use app\model\Announcement;
use app\model\Community;
use support\Request;

/**
 * 公告管理
 * @Apidoc\Group("property-core")
 * @Apidoc\Sort(12)
 */
class AnnouncementController extends BaseController
{
    /**
     * 公告列表
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/announcement")
     * @Apidoc\Param("keyword", type="string", require=false, desc="搜索关键词（标题）")
     * @Apidoc\Param("community_id", type="string", require=false, desc="小区hashid")
     * @Apidoc\Param("category", type="int", require=false, desc="分类: 1=通知 2=公告 3=提醒 4=活动")
     * @Apidoc\Param("is_published", type="int", require=false, desc="发布状态: 0=草稿 1=已发布")
     * @Apidoc\Param(ref="pagination")
     * @Apidoc\Returned("id", type="string", desc="公告hashid")
     * @Apidoc\Returned("title", type="string", desc="标题")
     * @Apidoc\Returned("category", type="int", desc="分类")
     * @Apidoc\Returned("is_top", type="int", desc="是否置顶")
     * @Apidoc\Returned("is_published", type="int", desc="发布状态")
     * @Apidoc\Returned("created_at", type="string", desc="创建时间")
     */
    public function index(Request $request)
    {
        $keyword     = $request->input('keyword', '');
        $communityId = $request->input('community_id');
        $category    = $request->input('category');
        $published   = $request->input('is_published');

        $query = Announcement::query();
        if (!empty($keyword)) {
            $query->where('title', 'like', "%{$keyword}%");
        }
        if (!empty($communityId)) {
            $query->where('community_id', $this->decodeId($communityId));
        }
        if ($category !== null && $category !== '') {
            $query->where('category', (int) $category);
        }
        if ($published !== null && $published !== '') {
            $query->where('is_published', (int) $published);
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'            => $this->encodeId($item->id),
                    'community_id'  => $this->encodeId($item->community_id),
                    'title'         => $item->title,
                    'category'      => $item->category,
                    'is_top'        => $item->is_top,
                    'is_published'  => $item->is_published,
                    'published_at'  => $item->published_at ? $item->published_at->format('Y-m-d H:i') : '',
                    'created_at'    => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 公告详情
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/announcement/{hashid}")
     * @Apidoc\Param("hashid", type="string", require=true, desc="公告hashid", from="path")
     * @Apidoc\Returned("id", type="string", desc="公告hashid")
     * @Apidoc\Returned("title", type="string", desc="标题")
     */
    public function show(Request $request, string $hashid)
    {
        $id = $this->decodeId($hashid);
        $item = Announcement::find($id);
        if (!$item) {
            return $this->fail('公告不存在', 404);
        }

        return $this->success([
            'id'           => $this->encodeId($item->id),
            'community_id' => $this->encodeId($item->community_id),
            'title'        => $item->title,
            'content'      => $item->content,
            'category'     => $item->category,
            'is_top'       => $item->is_top,
            'is_published' => $item->is_published,
            'published_at' => $item->published_at ? $item->published_at->format('Y-m-d H:i') : '',
            'publisher_id' => $item->publisher_id,
        ]);
    }

    /**
     * 创建公告
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/announcement")
     * @Apidoc\Param("community_id", type="string", require=true, desc="小区hashid")
     * @Apidoc\Param("title", type="string", require=true, desc="标题")
     * @Apidoc\Param("content", type="string", require=false, desc="内容")
     * @Apidoc\Param("category", type="int", require=false, desc="分类: 1=通知 2=公告 3=提醒 4=活动")
     * @Apidoc\Param("is_top", type="int", require=false, desc="是否置顶: 0=否 1=是")
     * @Apidoc\Param("is_published", type="int", require=false, desc="发布状态: 0=草稿 1=已发布")
     * @Apidoc\Param("published_at", type="string", require=false, desc="发布时间")
     * @Apidoc\Returned("id", type="string", desc="新建公告的hashid")
     */
    public function store(Request $request)
    {
        $data = $request->only([
            'community_id', 'title', 'content', 'category',
            'is_top', 'is_published', 'published_at',
        ]);

        if (empty($data['community_id'])) {
            return $this->fail('请选择所属小区', 422);
        }
        $communityId = $this->decodeId($data['community_id']);
        if (!Community::find($communityId)) {
            return $this->fail('小区不存在', 422);
        }
        if (empty($data['title'])) {
            return $this->fail('公告标题不能为空', 422);
        }

        $data['community_id']  = $communityId;
        $data['id']            = SnowflakeService::generate();
        $data['publisher_id']  = (int) ($request->adminId ?? 0);
        $data['is_top']        = (int) ($data['is_top'] ?? 0);
        $data['is_published']  = (int) ($data['is_published'] ?? 0);

        Announcement::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /**
     * @Apidoc\Method("PUT")
     * @Apidoc\Url("/admin/announcement/{hashid}")
     */
    public function update(Request $request, string $hashid)
    {
        $id = $this->decodeId($hashid);
        $item = Announcement::find($id);
        if (!$item) {
            return $this->fail('公告不存在', 404);
        }

        $item->fill($request->only([
            'title', 'content', 'category', 'is_top',
            'is_published', 'published_at',
        ]));
        $item->save();

        return $this->success([], '更新成功');
    }

    /**
     * @Apidoc\Method("DELETE")
     * @Apidoc\Url("/admin/announcement/{hashid}")
     */
    public function destroy(Request $request, string $hashid)
    {
        $adminId = $request->adminId;
        $password = $request->input('password', '');

        $error = $this->confirmPassword($adminId, $password, $request);
        if ($error !== null) {
            return $this->fail($error, 422);
        }

        $id = $this->decodeId($hashid);
        $item = Announcement::find($id);
        if (!$item) {
            return $this->fail('公告不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }
}
