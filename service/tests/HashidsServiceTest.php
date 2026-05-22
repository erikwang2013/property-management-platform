<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\common\HashidsService;
use InvalidArgumentException;
use PHPUnit\Framework\TestCase;

class HashidsServiceTest extends TestCase
{
    /**
     * RED: encode 整数返回非空字符串
     */
    public function testEncodeReturnsNonEmptyString()
    {
        $result = HashidsService::encode(123456789);
        $this->assertIsString($result, '编码结果应为字符串');
        $this->assertNotEmpty($result, '编码结果不应为空');
    }

    /**
     * RED: encode + decode 往返一致
     */
    public function testEncodeDecodeRoundtrip()
    {
        $original = 1750123456789;
        $encoded = HashidsService::encode($original);
        $decoded = HashidsService::decode($encoded);
        $this->assertSame($original, $decoded, '编码再解码后应与原始ID一致');
    }

    /**
     * RED: decode 无效 hashid 抛异常
     */
    public function testDecodeInvalidHashidThrowsException()
    {
        $this->expectException(InvalidArgumentException::class);
        HashidsService::decode('invalid-hash-id');
    }

    /**
     * RED: 不同输入产生不同 hashid
     */
    public function testDifferentIdsProduceDifferentHashids()
    {
        $hash1 = HashidsService::encode(111);
        $hash2 = HashidsService::encode(222);
        $this->assertNotSame($hash1, $hash2, '不同ID应编码为不同hashid');
    }

    /**
     * RED: 同一输入多次编码结果一致
     */
    public function testSameIdProducesSameHashid()
    {
        $hash1 = HashidsService::encode(999888777);
        $hash2 = HashidsService::encode(999888777);
        $this->assertSame($hash1, $hash2, '相同ID编码结果应一致');
    }
}
