<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

/**
 * 注册 Webhook 配置（幂等，写入 erik_system_config group=webhook key=webhook_config）
 *
 * 用法: cd admin && php scripts/register_webhook.php <url> <secret> [events] [enabled]
 *   events  : 逗号分隔，默认 fee_paid,repair_created,announcement_published
 *   enabled : 1/0，默认 1
 * 示例:
 *   php scripts/register_webhook.php https://example.com/hook my-secret
 *   php scripts/register_webhook.php https://example.com/hook my-secret fee_paid,repair_created 0
 *
 * 也可走管理端「系统配置」UI 直接增改同一行（type=json）。
 * 接收方校验: header X-Signature = sha256=<HMAC-SHA256(原始JSON载荷, secret)>
 */

use app\common\SnowflakeService;
use app\model\SystemConfig;

$baseDir = __DIR__ . '/../admin';

require_once $baseDir . '/vendor/autoload.php';

if (class_exists('Dotenv\Dotenv') && file_exists($baseDir . '/.env')) {
    \Dotenv\Dotenv::createUnsafeMutable($baseDir)->load();
}

\Webman\Config::clear();
support\App::loadAllConfig(['route']);
support\bootstrap\Db::start(null);

if (count($argv) < 4) {
    fwrite(STDERR, "用法: php scripts/register_webhook.php <url> <secret> [events] [enabled]\n");
    exit(1);
}

$events = $argv[3] ?? 'fee_paid,repair_created,announcement_published';
$enabled = (int) ($argv[4] ?? 1);

$value = json_encode([
    'url'     => $argv[1],
    'secret'  => $argv[2],
    'events'  => array_values(array_filter(array_map('trim', explode(',', $events)))),
    'enabled' => $enabled === 1,
], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);

$config = SystemConfig::where('group', 'webhook')->where('key', 'webhook_config')->first();
if ($config) {
    $config->value = $value;
    $config->save();
} else {
    $config = new SystemConfig();
    $config->id = SnowflakeService::generate();
    $config->group = 'webhook';
    $config->key = 'webhook_config';
    $config->value = $value;
    $config->type = 'json';
    $config->description = 'Webhook 投递配置: url/secret/events/enabled';
    $config->save();
}

echo "已注册 webhook 配置: {$argv[1]} events={$events} enabled={$enabled}\n";
