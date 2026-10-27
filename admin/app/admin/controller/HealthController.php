<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;
use hg\apidoc\annotation as Apidoc;

use support\Request;
use support\Response;
use support\Db;
use support\Redis;
use Throwable;

/**
 * 仪表盘与运维
 * @Apidoc\Group("dashboard")
 */
class HealthController
{
    /**
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/health")
     */
    public function index(Request $request): Response
    {
        // 健康检查仅暴露服务可用性，不返回 PHP 版本、ES 集群状态等内部信息
        return json([
            'code' => 0,
            'message' => 'success',
            'data' => [
                'app'           => 'open-admin',
                'version'       => '1.0',
                'database'      => $this->checkDb(),
                'redis'         => $this->checkRedis(),
                'timestamp'     => time(),
            ],
        ]);
    }

    private function checkDb(): string
    {
        try {
            Db::select('SELECT 1');
            return 'ok';
        } catch (Throwable) {
            return 'unavailable';
        }
    }

    private function checkRedis(): string
    {
        try {
            Redis::ping();
            return 'ok';
        } catch (Throwable) {
            return 'unavailable';
        }
    }

}
