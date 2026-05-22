<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;

use app\common\BaseController;
use app\model\Notification;
use InvalidArgumentException;
use support\Request;
use support\Response;

/**
 * 消息通知
 * @Apidoc\Group("extensions")
 * @Apidoc\Sort(1)
 */
class NotificationController extends BaseController
{
    /**
     * 消息通知列表（当前业主）
     * GET /service/notifications
     */
    public function index(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);
        $type    = $request->input('type');

        $query = Notification::where('user_id', $ownerId)
            ->where('user_type', 1);

        if ($type !== null && $type !== '') {
            $query->where('type', (int) $type);
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'         => $this->encodeId($item->id),
                    'title'      => $item->title,
                    'content'    => $item->content,
                    'type'       => $item->type,
                    'is_read'    => $item->is_read,
                    'ref_type'   => $item->ref_type,
                    'ref_id'     => $item->ref_id,
                    'read_at'    => $item->read_at ? $item->read_at->format('Y-m-d H:i') : '',
                    'created_at' => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 标记已读
     * PUT /service/notification/{hashid}/read
     */
    public function markRead(Request $request, string $hashid): Response
    {
        $ownerId = $this->getOwnerId($request);

        try {
            $id = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的通知ID', 404);
        }

        $item = Notification::where('user_id', $ownerId)
            ->where('user_type', 1)
            ->find($id);

        if (!$item) {
            return $this->fail('通知不存在或无权操作', 404);
        }

        $item->is_read = 1;
        $item->read_at = date('Y-m-d H:i:s');
        $item->save();

        return $this->success([], '已标记为已读');
    }

    /**
     * 一键全部已读
     * PUT /service/notifications/read-all
     */
    public function markAllRead(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);

        $count = Notification::where('user_id', $ownerId)
            ->where('user_type', 1)
            ->where('is_read', 0)
            ->update([
                'is_read' => 1,
                'read_at' => date('Y-m-d H:i:s'),
            ]);

        return $this->success(['count' => $count], '已全部标记为已读');
    }
}
