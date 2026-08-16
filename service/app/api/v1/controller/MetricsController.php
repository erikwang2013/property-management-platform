<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;
use hg\apidoc\annotation as Apidoc;

use support\Db;
use support\Redis;
use support\Request;
use support\Response;
use Throwable;

/**
 * Prometheus 指标端点
 * GET /metrics
 */
/**
 * @Apidoc\Group("monitor")
 */
class MetricsController
{
    /**
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/metrics")
     */
    public function index(Request $request): Response
    {
        $metrics = [];

        // HTTP 请求计数（MetricsCollector 中间件累计到 Redis）
        try {
            $all = (int)(Redis::get('property_service_metrics:http_all') ?: 0);
            $fails = (int)(Redis::get('property_service_metrics:http_5xx') ?: 0);
        } catch (Throwable) {
            $all = 0;
            $fails = 0;
        }
        $metrics[] = "# HELP property_service_http_requests_total Total HTTP requests processed";
        $metrics[] = "# TYPE property_service_http_requests_total counter";
        $metrics[] = "property_service_http_requests_total{code=\"all\"} {$all}";
        $metrics[] = "property_service_http_requests_total{code=\"5xx\"} {$fails}";

        // 数据库连接状态
        try {
            Db::select('SELECT 1');
            $dbStatus = 1;
        } catch (Throwable) {
            $dbStatus = 0;
        }
        $metrics[] = "# HELP property_service_db_up Database connection status (1=up, 0=down)";
        $metrics[] = "# TYPE property_service_db_up gauge";
        $metrics[] = "property_service_db_up {$dbStatus}";

        // Redis 连接状态
        try {
            Redis::ping();
            $redisStatus = 1;
        } catch (Throwable) {
            $redisStatus = 0;
        }
        $metrics[] = "# HELP property_service_redis_up Redis connection status (1=up, 0=down)";
        $metrics[] = "# TYPE property_service_redis_up gauge";
        $metrics[] = "property_service_redis_up {$redisStatus}";

        // 应用信息
        $metrics[] = "# HELP property_service_info Application info";
        $metrics[] = "# TYPE property_service_info gauge";
        $metrics[] = 'property_service_info{version="1.0",php="' . PHP_VERSION . '"} 1';

        return response(implode("\n", $metrics) . "\n", 200, [
            'Content-Type' => 'text/plain; charset=utf-8',
        ]);
    }
}
