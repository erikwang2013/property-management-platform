<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\common\CircuitBreaker;
use PHPUnit\Framework\TestCase;
use support\Redis;

class CircuitBreakerTest extends TestCase
{
    private const NAME = 'test';

    protected function setUp(): void
    {
        try {
            Redis::connection()->ping();
        } catch (\Throwable) {
            $this->markTestSkipped('Redis 不可用');
        }
        (new CircuitBreaker(self::NAME))->reset();
    }

    public function testClosedAllowsAndFailureTrips()
    {
        $breaker = new CircuitBreaker(self::NAME, ['failure_threshold' => 3, 'window' => 60, 'timeout' => 60]);
        $this->assertTrue($breaker->canProceed(), 'closed 状态应放行');
        $breaker->recordFailure();
        $breaker->recordFailure();
        $this->assertTrue($breaker->canProceed(), '失败未达阈值前仍放行');
        $breaker->recordFailure();
        $this->assertFalse($breaker->canProceed(), '达到阈值后应熔断（open）');
    }

    public function testOpenFastFailsAndRecoversAfterTimeout()
    {
        $breaker = new CircuitBreaker(self::NAME, ['failure_threshold' => 2, 'window' => 60, 'timeout' => 1]);
        $breaker->recordFailure();
        $breaker->recordFailure();
        $this->assertFalse($breaker->canProceed(), 'open 应快速失败');

        // 冷却期内继续拒绝
        usleep(200 * 1000);
        $this->assertFalse($breaker->canProceed(), '冷却期内仍拒绝');

        // 冷却结束：恰好一个探测请求放行，成功后转 closed
        usleep(900 * 1000);
        $this->assertTrue($breaker->canProceed(), '冷却结束应放行一个探测请求（half_open）');
        $this->assertFalse($breaker->canProceed(), '探测权已被抢占，其余请求拒绝');
        $breaker->recordSuccess();
        $this->assertTrue($breaker->canProceed(), '探测成功应恢复 closed');
    }

    public function testHalfOpenProbeFailureReopens()
    {
        $breaker = new CircuitBreaker(self::NAME, ['failure_threshold' => 2, 'window' => 60, 'timeout' => 1]);
        $breaker->recordFailure();
        $breaker->recordFailure();
        $this->assertFalse($breaker->canProceed());
        usleep(1100 * 1000);
        $this->assertTrue($breaker->canProceed(), '探测放行');
        $breaker->recordFailure();
        $this->assertFalse($breaker->canProceed(), '探测失败应重新 open');
    }

    public function testSuccessClearsFailureCount()
    {
        $breaker = new CircuitBreaker(self::NAME, ['failure_threshold' => 3, 'window' => 60, 'timeout' => 60]);
        $breaker->recordFailure();
        $breaker->recordFailure();
        $breaker->recordSuccess();
        $this->assertTrue($breaker->canProceed(), '成功应清零失败计数');
    }
}
