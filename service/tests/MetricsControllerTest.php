<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\api\v1\controller\MetricsController;
use PHPUnit\Framework\TestCase;
use support\Request;

class MetricsControllerTest extends TestCase
{
    public function test_index_returns_prometheus_text(): void
    {
        $response = (new MetricsController())->index(new Request("GET /metrics HTTP/1.1\r\nHost: localhost\r\n\r\n"));
        $this->assertSame(200, $response->getStatusCode());
        $this->assertSame('text/plain; charset=utf-8', $response->getHeader('Content-Type'));
        $body = $response->rawBody();

        $this->assertStringContainsString('# HELP property_service_http_requests_total', $body);
        $this->assertStringContainsString('# TYPE property_service_http_requests_total counter', $body);
        $this->assertStringContainsString('property_service_http_requests_total{code="all"}', $body);
        $this->assertStringContainsString('property_service_http_requests_total{code="5xx"}', $body);
    }

    public function test_index_reports_db_and_redis_up(): void
    {
        $body = (new MetricsController())->index(new Request("GET /metrics HTTP/1.1\r\nHost: localhost\r\n\r\n"))->rawBody();
        $this->assertMatchesRegularExpression('/property_service_db_up 1/', $body);
        $this->assertMatchesRegularExpression('/property_service_redis_up 1/', $body);
    }

    public function test_index_reports_app_info(): void
    {
        $body = (new MetricsController())->index(new Request("GET /metrics HTTP/1.1\r\nHost: localhost\r\n\r\n"))->rawBody();
        $this->assertStringContainsString('# HELP property_service_info', $body);
        $this->assertMatchesRegularExpression(
            '/property_service_info\{version="1\.0",php="' . preg_quote(PHP_VERSION, '/') . '"\} 1/',
            $body
        );
    }
}
