<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\admin\controller\MetricsController;
use PHPUnit\Framework\TestCase;
use support\Request;

/**
 * Prometheus 指标端点测试
 * 无 DB/Redis 环境下所有查询均被控制器 try/catch 兜底为 0，可完整验证文本结构
 */
class MetricsControllerTest extends TestCase
{
    public function test_metrics_returns_prometheus_text(): void
    {
        $resp = (new MetricsController())->index(new Request('', 'GET'));
        $this->assertSame(200, $resp->getStatusCode());
        $this->assertStringContainsString('text/plain', (string) $resp->getHeader('Content-Type'));
        $this->assertStringStartsWith('# HELP', $resp->rawBody());
    }

    public function test_metrics_contains_all_required_metric_families(): void
    {
        $body = (new MetricsController())->index(new Request('', 'GET'))->rawBody();
        foreach ([
            'open_admin_http_requests_total',
            'open_admin_active_users',
            'open_admin_total_users',
            'open_admin_db_up',
            'open_admin_redis_up',
            'open_admin_info',
        ] as $metric) {
            $this->assertStringContainsString("# HELP {$metric}", $body, "缺少 {$metric} HELP 行");
            $this->assertStringContainsString("# TYPE {$metric}", $body, "缺少 {$metric} TYPE 行");
        }
    }

    public function test_metrics_request_counters_have_code_labels(): void
    {
        $body = (new MetricsController())->index(new Request('', 'GET'))->rawBody();
        $this->assertStringContainsString('open_admin_http_requests_total{code="all"} ', $body);
        $this->assertStringContainsString('open_admin_http_requests_total{code="5xx"} ', $body);
    }

    public function test_metrics_reports_dependency_status(): void
    {
        // 测试环境 MySQL 不可用 → db_up 必须为 0（try/catch 兜底）；Redis 可用性随环境浮动，取 0/1 之一
        $body = (new MetricsController())->index(new Request('', 'GET'))->rawBody();
        $this->assertMatchesRegularExpression('/open_admin_db_up 0\n/', $body);
        $this->assertMatchesRegularExpression('/open_admin_redis_up [01]\n/', $body);
        $this->assertMatchesRegularExpression('/open_admin_active_users \d+/', $body);
    }

    public function test_metrics_info_carries_php_version(): void
    {
        $body = (new MetricsController())->index(new Request('', 'GET'))->rawBody();
        $this->assertStringContainsString('php="' . PHP_VERSION . '"', $body);
    }
}
