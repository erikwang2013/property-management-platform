<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\middleware\MetricsCollector;
use PHPUnit\Framework\TestCase;
use support\Request;

class MetricsCollectorMiddlewareTest extends TestCase
{
    private function makeRequest(): Request
    {
        return new Request("GET /health HTTP/1.1\r\nHost: localhost\r\n\r\n");
    }

    public function test_handler_response_always_returned(): void
    {
        // Redis 不可用时静默跳过（fail-open），响应必须原样返回
        $response = (new MetricsCollector())->process($this->makeRequest(), fn () => response('ok'));
        $this->assertSame(200, $response->getStatusCode());
        $this->assertSame('ok', $response->rawBody());
    }

    public function test_error_response_status_preserved(): void
    {
        $response = (new MetricsCollector())->process($this->makeRequest(), fn () => response('err', 500));
        $this->assertSame(500, $response->getStatusCode());
    }
}
