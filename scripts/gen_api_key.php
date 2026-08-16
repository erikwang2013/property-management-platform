#!/usr/bin/env php
<?php

/**
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 *
 * 生成开放 API Key（X-API-Key 鉴权，写入 erik_api_key 表）
 *
 * 用法:
 *   php scripts/gen_api_key.php                # 生成 Key，名称默认 "default"
 *   php scripts/gen_api_key.php --name=三方物业平台
 *
 * 说明: 明文 Key 仅打印一次（64 位 hex），库中只存 SHA-256 摘要，请妥善保存。
 */

declare(strict_types=1);

use app\model\ApiKey;
use app\common\SnowflakeService;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Events\Dispatcher;

$baseDir = __DIR__ . '/../service';

require_once $baseDir . '/vendor/autoload.php';

if (class_exists('Dotenv\Dotenv') && file_exists($baseDir . '/.env')) {
    \Dotenv\Dotenv::createUnsafeMutable($baseDir)->load();
}

\Webman\Config::clear();
support\App::loadAllConfig(['route']);
support\bootstrap\Db::start(null);

// CLI 下 webman 未装配 Eloquent 事件分发器，非自增主键需手动挂载 snowflake
Model::setEventDispatcher($events = new Dispatcher());
$events->listen('eloquent.creating: *', function (...$args): void {
    $model = ($args[1] ?? null) instanceof Model ? $args[1] : ($args[1][0] ?? null);
    if (!$model instanceof Model || $model->getKey() || $model->incrementing) {
        return;
    }
    $model->setAttribute($model->getKeyName(), SnowflakeService::generate());
});

$name = 'default';
for ($i = 1; $i < count($argv); $i++) {
    if (str_starts_with($argv[$i], '--name=')) {
        $name = substr($argv[$i], 7);
    } else {
        fwrite(STDERR, "未知参数: {$argv[$i]}（用法: php scripts/gen_api_key.php [--name=用途]）\n");
        exit(1);
    }
}

$plainKey = bin2hex(random_bytes(32));

ApiKey::create([
    'name'         => $name,
    'api_key_hash' => hash('sha256', $plainKey),
    'status'       => 1,
]);

echo "==============================================\n";
echo "  开放 API Key 已生成（名称: {$name}）\n";
echo "  明文仅此一次，请妥善保存：\n";
echo "  X-API-Key: $plainKey\n";
echo "==============================================\n";
