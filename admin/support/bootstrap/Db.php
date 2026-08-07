<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace support\bootstrap;

use Illuminate\Database\Capsule\Manager as Capsule;
use Webman\Bootstrap;
use Workerman\Worker;

/**
 * Eloquent ORM 初始化引导
 * 读取 config/database.php 注册全局连接（表前缀 erik_）
 */
class Db implements Bootstrap
{
    public static function start(?Worker $worker): void
    {
        $config = config('database');
        $name = $config['default'] ?? 'mysql';
        $connection = $config['connections'][$name] ?? [];

        $capsule = new Capsule();
        $capsule->addConnection($connection, $name);
        // Capsule 默认 default 连接名为 'default'，需显式指向配置名，否则 Db::select() 报 "not configured"
        $capsule->getContainer()['config']['database.default'] = $name;
        $capsule->setAsGlobal();
        $capsule->bootEloquent();
    }
}
