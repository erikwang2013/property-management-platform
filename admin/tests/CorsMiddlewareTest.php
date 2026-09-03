<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\middleware\Cors;
use PHPUnit\Framework\TestCase;
use support\Request;

class CorsMiddlewareTest extends TestCase
{
    private const ORIGINAL_ORIGIN = 'http://localhost:8787';

    protected function tearDown(): void
    {
        putenv('CORS_ALLOWED_ORIGIN');
        parent::tearDown();
    }

    private function makeRequest(string $method = 'GET'): Request
    {
        $buffer = "{$method} /admin/community HTTP/1.1\r\nHost: localhost\r\n\r\n";
        return new Request($buffer);
    }

    public function test_options_preflight_returns_204_with_cors_headers(): void
    {
        $response = (new Cors())->process($this->makeRequest('OPTIONS'), fn () => response('x'));
        $this->assertSame(204, $response->getStatusCode());
        $this->assertSame(self::ORIGINAL_ORIGIN, $response->getHeader('Access-Control-Allow-Origin'));
        $this->assertSame('GET,POST,PUT,DELETE,OPTIONS', $response->getHeader('Access-Control-Allow-Methods'));
        $this->assertSame('Authorization,Content-Type', $response->getHeader('Access-Control-Allow-Headers'));
    }

    public function test_normal_response_gets_security_headers(): void
    {
        $response = (new Cors())->process($this->makeRequest(), fn () => response('ok'));
        $this->assertSame(self::ORIGINAL_ORIGIN, $response->getHeader('Access-Control-Allow-Origin'));
        $this->assertSame('nosniff', $response->getHeader('X-Content-Type-Options'));
        $this->assertSame('DENY', $response->getHeader('X-Frame-Options'));
        $this->assertStringStartsWith('max-age=31536000', $response->getHeader('Strict-Transport-Security'));
        $this->assertStringContainsString('default-src', $response->getHeader('Content-Security-Policy'));
    }

    public function test_handler_response_body_preserved(): void
    {
        $response = (new Cors())->process($this->makeRequest(), fn () => response('ok'));
        $this->assertSame('ok', $response->rawBody());
    }

    public function test_env_origin_override(): void
    {
        putenv('CORS_ALLOWED_ORIGIN=https://admin.example.com');
        $response = (new Cors())->process($this->makeRequest(), fn () => response('ok'));
        $this->assertSame('https://admin.example.com', $response->getHeader('Access-Control-Allow-Origin'));
    }
}
