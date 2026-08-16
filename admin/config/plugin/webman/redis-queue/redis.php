<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

/**
 * Redis 队列连接配置（webman/redis-queue）
 *
 * 复用项目现有 REDIS_* 环境变量（同 config/redis.php）：
 *   host: redis://<host>:<port>
 *   auth: 无密码时留空字符串（phpredis auth 传 null/'' 均视为无密码）
 *   db:   REDIS_DATABASE（与缓存/限流共用库，队列键带业务前缀避免冲突）
 *
 * max_attempts：消费失败自动重试上限（不含首次）；retry_seconds：重试退避基数，
 * 第 n 次重试延迟 = retry_seconds × n 秒。超过上限的消息进入 failed 队列（QUEUE_FAILED）。
 */
return [
    'default' => [
        'host' => 'redis://' . (getenv('REDIS_HOST') ?: '127.0.0.1') . ':' . (int)(getenv('REDIS_PORT') ?: 6379),
        'options' => [
            'auth' => getenv('REDIS_PASSWORD') ?: null,
            'db' => (int)(getenv('REDIS_DATABASE') ?: 0),
            'prefix' => 'queue:',
            'max_attempts'  => 5,
            'retry_seconds' => 5,
        ],
        // 连接池（仅 Swoole/Swow 驱动生效，webman 默认 workerman 事件循环下不用）
        'pool' => [
            'max_connections' => 5,
            'min_connections' => 1,
            'wait_timeout' => 3,
            'idle_timeout' => 60,
            'heartbeat_interval' => 50,
        ]
    ],
];
