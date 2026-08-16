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
    private const KEY = 'lock:test:admin';

    protected function setUp(): void
    {
        try {
            Redis::connection()->ping();
        } catch (\Throwable) {
            $this->markTestSkipped('Redis 不可用');
        }
        Redis::del(self::KEY);
    }

    public function testAcquireMutex()
    {
        $token1 = LockService::acquire(self::KEY);
        $this->assertNotNull($token1, '首次 acquire 应成功');
        $token2 = LockService::acquire(self::KEY);
        $this->assertNull($token2, '同一 key 未释放时二次 acquire 应失败');
    }

    public function testReleaseAllowsReacquire()
    {
        $token = LockService::acquire(self::KEY);
        $this->assertNotNull($token);
        LockService::release(self::KEY, $token);
        $this->assertNotNull(LockService::acquire(self::KEY), 'release 后应可重新 acquire');
    }

    public function testWrongTokenReleaseKeepsLock()
    {
        $token = LockService::acquire(self::KEY);
        $this->assertNotNull($token);
        LockService::release(self::KEY, bin2hex(random_bytes(16)));
        $this->assertNull(LockService::acquire(self::KEY), '错误 token 不应删除他人锁');
    }

    public function testTtlExpiryAllowsReacquire()
    {
        $token = LockService::acquire(self::KEY, 1);
        $this->assertNotNull($token);
        sleep(2);
        $this->assertNotNull(LockService::acquire(self::KEY), 'TTL 过期后应可重新 acquire');
    }
}
