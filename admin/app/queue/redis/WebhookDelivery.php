<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\queue\redis;

use app\common\WebhookService;
use RuntimeException;
use Webman\RedisQueue\Consumer;

/**
 * Webhook 投递重试任务：首次同步投递失败后由队列异步重试。
 *
 * 非 2xx 抛异常触发队列框架自动重试（max_attempts=5，retry_seconds×n 退避），
 * 重试次数耗尽后消息进入 failed 队列（runtime/logs/redis-queue/queue.log 可查），
 * 不在此处自造重试循环。
 */
class WebhookDelivery implements Consumer
{
    // 要消费的队列名，对应 WebhookService::dispatch 失败后的入队目标
    public $queue = 'webhook_delivery';

    // 连接名，对应 config/plugin/webman/redis-queue/redis.php 里的连接
    public $connection = 'default';

    public function consume($data)
    {
        $event   = $data['event'] ?? '';
        $payload = $data['data'] ?? [];
        if (!$event) {
            return;
        }
        if (!WebhookService::deliver($event, is_array($payload) ? $payload : [])) {
            throw new RuntimeException('webhook_delivery_failed event=' . $event);
        }
    }
}
