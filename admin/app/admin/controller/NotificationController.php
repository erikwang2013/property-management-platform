<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;

use app\common\SnowflakeService;
use app\model\NotificationTemplate;
use app\model\Notification;
use support\Request;
use support\Response;

class NotificationController extends BaseController
{
    /**
     * 模板列表
     * GET /admin/notification-template
     */
    public function templates(Request $request): Response
    {
        $list = NotificationTemplate::orderBy('created_at', 'desc')
            ->paginate(20)
            ->through(fn($i) => [
                'id'       => $this->encodeId($i->id),
                'code'     => $i->code,
                'name'     => $i->name,
                'channels' => json_decode($i->channels),
                'status'   => $i->status,
            ]);
        return $this->success($list);
    }

    /**
     * 创建模板
     * POST /admin/notification-template
     */
    public function templateStore(Request $request): Response
    {
        $data = $request->only(['code', 'name', 'title_template', 'content_template', 'channels']);
        $data['channels'] = json_encode($data['channels'] ?? ['in_app']);
        $data['id'] = SnowflakeService::generate();
        NotificationTemplate::create($data);
        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /**
     * 更新模板
     * PUT /admin/notification-template/{hashid}
     */
    public function templateUpdate(Request $request, string $hashid): Response
    {
        $id = $this->decodeId($hashid);
        $t = NotificationTemplate::findOrFail($id);
        $t->fill($request->only(['name', 'title_template', 'content_template', 'channels', 'status']));
        if ($c = $request->input('channels')) {
            $t->channels = json_encode($c);
        }
        $t->save();
        return $this->success([], '更新成功');
    }

    /**
     * 删除模板
     * DELETE /admin/notification-template/{hashid}
     */
    public function templateDestroy(Request $request, string $hashid): Response
    {
        $id = $this->decodeId($hashid);
        NotificationTemplate::findOrFail($id)->delete();
        return $this->success([], '删除成功');
    }

    /**
     * 消息列表
     * GET /admin/notification?type=&is_read=
     */
    public function index(Request $request): Response
    {
        $query = Notification::query()->with(['template:id,name']);

        if ($t = $request->input('type')) {
            $query->where('type', (int) $t);
        }
        if ($r = $request->input('is_read')) {
            $query->where('is_read', (int) $r == 1 ? 1 : 0);
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate(20)
            ->through(fn($i) => [
                'id'            => $this->encodeId($i->id),
                'user_id'       => $i->user_id,
                'user_type'     => $i->user_type,
                'title'         => $i->title,
                'type'          => $i->type,
                'channel'       => $i->channel,
                'is_read'       => $i->is_read,
                'ref_type'      => $i->ref_type,
                'template_name' => $i->template->name ?? '',
                'created_at'    => $i->created_at->format('Y-m-d H:i'),
            ]);

        return $this->success($list);
    }

    /**
     * 手动发送通知
     * POST /admin/notification/send
     */
    public function send(Request $request): Response
    {
        $data = $request->only(['user_id', 'user_type', 'title', 'content', 'type', 'channel', 'ref_type', 'ref_id']);
        $data['id'] = SnowflakeService::generate();
        Notification::create($data);
        return $this->success([], '发送成功');
    }
}
