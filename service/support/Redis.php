<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace support;

use Redis as PhpRedis;
use RuntimeException;

/**
 * webman v2 框架已移除 support\Redis 门面，此文件恢复 v1 兼容层，
 * 所有 support\Redis::xxx() 静态调用经 __callStatic 转发到 ext-redis 实例。
 */
class Redis
{
    protected static ?PhpRedis $connection = null;

    public static function connection(): PhpRedis
    {
        if (static::$connection === null) {
            if (!extension_loaded('redis')) {
                throw new RuntimeException('Please make sure redis extension is installed');
            }
            $config = config('redis.default') ?? [];
            $connection = new PhpRedis();
            $connection->connect($config['host'] ?? '127.0.0.1', (int)($config['port'] ?? 6379));
            if (!empty($config['password'])) {
                $connection->auth($config['password']);
            }
            if (!empty($config['database'])) {
                $connection->select((int)$config['database']);
            }
            static::$connection = $connection;
        }
        return static::$connection;
    }

    public static function __callStatic(string $name, array $arguments): mixed
    {
        return static::connection()->{$name}(...$arguments);
    }
}
