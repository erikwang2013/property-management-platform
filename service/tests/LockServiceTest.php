<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\common\LockService;
use PHPUnit\Framework\TestCase;
use support\Redis;

class LockServiceTest extends TestCase
{
    // 按进程隔离 key：多套 phpunit 并行运行时（如后台 agent 同时跑本仓库用例）
    // 会共享 Redis 同名 key，TTL 用例 sleep 期间被对方重设导致偶发失败
    private const KEY = 'lock:test:service:';
    private string $key;

    protected function setUp(): void
    {
        try {
            Redis::connection()->ping();
        } catch (\Throwable) {
            $this->markTestSkipped('Redis 不可用');
        }
        $this->key = self::KEY . getmypid();
        Redis::del($this->key);
    }

    public function testAcquireMutex()
    {
        $token1 = LockService::acquire($this->key);
        $this->assertNotNull($token1, '首次 acquire 应成功');
        $token2 = LockService::acquire($this->key);
        $this->assertNull($token2, '同一 key 未释放时二次 acquire 应失败');
    }

    public function testReleaseAllowsReacquire()
    {
        $token = LockService::acquire($this->key);
        $this->assertNotNull($token);
        LockService::release($this->key, $token);
        $this->assertNotNull(LockService::acquire($this->key), 'release 后应可重新 acquire');
    }

    public function testWrongTokenReleaseKeepsLock()
    {
        $token = LockService::acquire($this->key);
        $this->assertNotNull($token);
        LockService::release($this->key, bin2hex(random_bytes(16)));
        $this->assertNull(LockService::acquire($this->key), '错误 token 不应删除他人锁');
    }

    public function testTtlExpiryAllowsReacquire()
    {
        $token = LockService::acquire($this->key, 1);
        $this->assertNotNull($token);
        sleep(2);
        $this->assertNotNull(LockService::acquire($this->key), 'TTL 过期后应可重新 acquire');
    }
}
