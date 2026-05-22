<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;

use app\common\BaseController;
use app\model\Announcement;
use support\Request;
use support\Response;
use InvalidArgumentException;

/**
 * 公告通知
 * @Apidoc\Group("feedback")
 * @Apidoc\Sort(3)
 */
class AnnouncementController extends BaseController
{
    /**
     * 公告列表
     * GET /api/announcements?category=通知&page=1
     */
    public function index(Request $request): Response
    {
        $page     = (int) $request->input('page', 1);
        $category = $request->input('category');

        $query = Announcement::where('is_published', 1);

        if ($category !== null && $category !== '') {
            $query->where('category', $category);
        }

        $announcements = $query
            ->orderBy('is_top', 'desc')
            ->orderBy('published_at', 'desc')
            ->paginate(20, ['*'], 'page', $page)
            ->through(function ($item) {
                return [
                    'id'           => $this->encodeId($item->id),
                    'title'        => $item->title,
                    'category'     => $item->category,
                    'is_top'       => $item->is_top,
                    'published_at' => $item->published_at ? $item->published_at->format('Y-m-d H:i') : '',
                    'created_at'   => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($announcements);
    }

    /**
     * 公告详情
     * GET /api/announcements/{hashid}
     */
    public function show(Request $request, string $hashid): Response
    {
        try {
            $announcementId = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的公告ID', 404);
        }

        $announcement = Announcement::where('is_published', 1)
            ->find($announcementId);

        if (!$announcement) {
            return $this->fail('公告不存在', 404);
        }

        $data = [
            'id'           => $this->encodeId($announcement->id),
            'title'        => $announcement->title,
            'content'      => $announcement->content,
            'category'     => $announcement->category,
            'is_top'       => $announcement->is_top,
            'published_at' => $announcement->published_at ? $announcement->published_at->format('Y-m-d H:i') : '',
            'publisher_id' => $announcement->publisher_id,
        ];

        return $this->success($data);
    }
}
