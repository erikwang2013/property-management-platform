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
        // timeout 取 2（不是 1）：熔断器用整数秒 time() 判定冷却（Lua 里 now - opened_at >= timeout），
        // 开闸时刻被截断到秒起点，实际冷却 = [timeout-1, timeout] 秒。timeout=1 时，若开闸落在
        // 秒内 0.8 之后，仅 200ms 就跨秒使 floor 差 = 1 >= 1，探测权提前放行——测试而非实现的问题。
        // timeout=2 给 200ms 断言留出确定余量：200ms 内 floor 差最大 1 < 2，必拒绝；
        // 累计 2.1s > 2s 时 floor 差必 >= 2，必放行。两端都不依赖开闸落在秒内什么位置。
        $breaker = new CircuitBreaker(self::NAME, ['failure_threshold' => 2, 'window' => 60, 'timeout' => 2]);
        $breaker->recordFailure();
        $breaker->recordFailure();
        $this->assertFalse($breaker->canProceed(), 'open 应快速失败');

        // 冷却期内继续拒绝
        usleep(200 * 1000);
        $this->assertFalse($breaker->canProceed(), '冷却期内仍拒绝');

        // 冷却结束：恰好一个探测请求放行，成功后转 closed
        usleep(1900 * 1000);
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
