<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\process;

use Workerman\Worker;
use support\App;

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
        $worker->onMessage = [App::class, 'onMessage'];
    }

    public static function run(): void
    {
        Worker::runAll();
    }
}
