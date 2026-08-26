<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\middleware\ApiVersion;
use PHPUnit\Framework\TestCase;
use support\Request;

class ApiVersionMiddlewareTest extends TestCase
{
    private function makeRequest(string $header = ''): Request
    {
        $buffer = "GET /api/auth/login HTTP/1.1\r\n{$header}Host: localhost\r\n\r\n";
        return new Request($buffer);
    }

    public function test_default_version_is_v1(): void
    {
        $seen = null;
        $response = (new ApiVersion())->process($this->makeRequest(), function (Request $request) use (&$seen) {
            $seen = $request->apiVersion ?? null;
            return response('ok');
        });
        $this->assertSame('v1', $seen);
        $this->assertSame(200, $response->getStatusCode());
    }

    public function test_supported_version_injected_into_request(): void
    {
        $seen = null;
        (new ApiVersion())->process($this->makeRequest("API-Version: v1\r\n"), function (Request $request) use (&$seen) {
            $seen = $request->apiVersion ?? null;
            return response('ok');
        });
        $this->assertSame('v1', $seen);
    }

    public function test_unsupported_version_returns_400(): void
    {
        $response = (new ApiVersion())->process($this->makeRequest("API-Version: v2\r\n"), fn () => response('ok'));
        $this->assertSame(400, $response->getStatusCode());
        $body = json_decode($response->rawBody(), true);
        $this->assertSame(400, $body['code']);
        $this->assertStringContainsString('不支持的API版本: v2', $body['message']);
    }
}
