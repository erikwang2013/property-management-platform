<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

/**
 * Redis 连接配置
 */
return [
    'default' => [
        'host'     => getenv('REDIS_HOST') ?: '127.0.0.1',
        'port'     => (int)(getenv('REDIS_PORT') ?: 6379),
        'password' => getenv('REDIS_PASSWORD') ?: '',
        'database' => (int)(getenv('REDIS_DATABASE') ?: 0),
    ],
];
