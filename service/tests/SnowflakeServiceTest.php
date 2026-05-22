<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\common\SnowflakeService;
use PHPUnit\Framework\TestCase;

class SnowflakeServiceTest extends TestCase
{
    /**
     * RED: 验证 snowflake 能生成非零 BIGINT ID
     */
    public function testGenerateReturnsPositiveBigInt()
    {
        $id = SnowflakeService::generate();
        $this->assertIsInt($id, '生成结果应是整数');
        $this->assertGreaterThan(0, $id, '生成的ID应大于0');
    }

    /**
     * RED: 验证连续生成的 ID 不重复
     */
    public function testGenerateReturnsUniqueIds()
    {
        $ids = [];
        for ($i = 0; $i < 100; $i++) {
            $ids[] = SnowflakeService::generate();
        }
        $this->assertCount(100, array_unique($ids), '连续100次生成的ID应全部唯一');
    }

    /**
     * RED: 验证生成的 ID 单调递增
     */
    public function testGenerateReturnsMonotonicallyIncreasingIds()
    {
        $prev = SnowflakeService::generate();
        usleep(2000); // 等2ms确保时间戳推进
        $next = SnowflakeService::generate();
        $this->assertGreaterThan($prev, $next, '后生成的ID应大于先生成的ID');
    }
}
