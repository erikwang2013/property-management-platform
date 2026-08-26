<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\middleware\StaticFile;
use PHPUnit\Framework\TestCase;
use support\Request;

class StaticFileMiddlewareTest extends TestCase
{
    private function makeRequest(string $path): Request
    {
        $buffer = "GET {$path} HTTP/1.1\r\nHost: localhost\r\n\r\n";
        return new Request($buffer);
    }

    public function test_dot_path_is_forbidden(): void
    {
        foreach (['/.env', '/public/.git/config', '/admin/.hidden/file'] as $path) {
            $response = (new StaticFile())->process($this->makeRequest($path), fn () => response('ok'));
            $this->assertSame(403, $response->getStatusCode(), "路径 {$path} 应被拒绝");
            $this->assertStringContainsString('403', $response->rawBody());
        }
    }

    public function test_normal_path_passes_through(): void
    {
        $response = (new StaticFile())->process($this->makeRequest('/app.js'), fn () => response('ok'));
        $this->assertSame(200, $response->getStatusCode());
        $this->assertSame('ok', $response->rawBody());
    }
}
