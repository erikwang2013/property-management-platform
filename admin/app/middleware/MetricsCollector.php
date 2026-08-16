<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\middleware;

use support\Redis;
use support\Request;
use support\Response;
use Throwable;

/**
 * 请求计数中间件：累计 HTTP 请求总数与 5xx 数量到 Redis，
 * 供 /metrics 端点输出，支撑 5xx 比例告警。
 * Redis 异常时静默跳过，不影响业务。
 */
class MetricsCollector
{
    public function process(Request $request, callable $handler): Response
    {
        $response = $handler($request);

        try {
            Redis::incr('open_admin_metrics:http_all');
            if ($response->getStatusCode() >= 500) {
                Redis::incr('open_admin_metrics:http_5xx');
            }
        } catch (Throwable) {
        }

        return $response;
    }
}
