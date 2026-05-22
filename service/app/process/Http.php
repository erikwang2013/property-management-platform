<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\process;

use Webman\App;
use support\Log;
use support\Request;
use Workerman\Worker;

class Http
{
    public static function init(): void
    {
        $config = config('server');
        $worker = new Worker(
            $config['listen'] ?? 'http://0.0.0.0:8788',
            $config['context'] ?? []
        );
        $worker->name = $config['name'] ?? 'property-service';
        $worker->count = $config['count'] ?? cpu_count() * 2;
        $worker->user = $config['user'] ?? '';

        $worker->onWorkerStart = function ($worker) {
            require_once base_path() . '/support/bootstrap.php';
            $app = new App(
                config('app.request_class', Request::class),
                Log::channel('default'),
                app_path(),
                public_path()
            );
            $worker->onMessage = [$app, 'onMessage'];
            call_user_func([$app, 'onWorkerStart'], $worker);
        };
    }

    public static function run(): void
    {
        Worker::runAll();
    }
}
