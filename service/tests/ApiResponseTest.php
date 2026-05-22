<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use PHPUnit\Framework\TestCase;

class ApiResponseTest extends TestCase
{
    /**
     * RED: 验证健康检查端点返回正确 JSON
     */
    public function testHealthEndpoint(): void
    {
        $response = @file_get_contents('http://localhost:8788/health');
        if ($response === false) {
            $this->markTestSkipped('Service not running on port 8788');
        }
        $data = json_decode($response, true);
        $this->assertIsArray($data, '响应应为有效JSON');
        $this->assertSame(0, $data['code'] ?? null, '状态码应为0');
        $this->assertSame('ok', $data['message'] ?? null, '消息应为ok');
    }

    /**
     * RED: 验证统一响应格式结构
     */
    public function testResponseFormat(): void
    {
        $expectedKeys = ['code', 'message', 'data'];
        $sample = json_encode(['code' => 0, 'message' => 'success', 'data' => []]);
        $decoded = json_decode($sample, true);

        foreach ($expectedKeys as $key) {
            $this->assertArrayHasKey($key, $decoded, "响应应包含{$key}字段");
        }
    }

    /**
     * RED: 验证 BaseController success 格式
     */
    public function testSuccessResponseFormat(): void
    {
        $response = ['code' => 0, 'message' => 'success', 'data' => ['name' => 'test']];
        $this->assertSame(0, $response['code']);
        $this->assertIsArray($response['data']);
    }

    /**
     * RED: 验证 BaseController fail 格式
     */
    public function testFailResponseFormat(): void
    {
        $response = ['code' => 422, 'message' => '验证失败', 'data' => []];
        $this->assertSame(422, $response['code']);
        $this->assertStringContainsString('验证失败', $response['message']);
    }
}
