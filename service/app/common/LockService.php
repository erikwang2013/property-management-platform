<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\common;

use support\Redis;
use support\Log;

/**
 * Redis 分布式锁：NX+EX 原子获取，Lua 校验 token 后释放，防误删他人锁。
 * 覆盖多进程（workerman）与多机部署。Redis 异常时 acquire 返回 null（fail-open），由调用方决定兜底策略。
 */
class LockService
{
    public static function acquire(string $key, int $ttl = 10): ?string
    {
        try {
            $token = bin2hex(random_bytes(16));
            return Redis::set($key, $token, ['NX', 'EX' => $ttl]) ? $token : null;
        } catch (\Throwable $e) {
            Log::error('LockService acquire failed: ' . $e->getMessage());
            return null;
        }
    }

    public static function release(string $key, string $token): void
    {
        try {
            Redis::eval(
                "if redis.call('get',KEYS[1])==ARGV[1] then return redis.call('del',KEYS[1]) else return 0 end",
                [$key, $token],
                1
            );
        } catch (\Throwable $e) {
            Log::error('LockService release failed: ' . $e->getMessage());
        }
    }
}
