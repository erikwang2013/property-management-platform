<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\common;

use app\model\SystemConfig;
use support\Log;
use Webman\RedisQueue\Redis as QueueRedis;

/**
 * Webhook 投递：订阅配置 → HMAC-SHA256 签名 → POST JSON → 失败入队异步重试
 *
 * 配置存 erik_system_config（group=webhook, key=webhook_config, type=json）：
 *   {"url":"https://example.com/hook","secret":"...","events":["fee_paid"],"enabled":true}
 *
 * 首次投递同步执行（保持调用方语义，"一次成功零延迟"），失败后把事件入队
 * （webhook_delivery），由 queue 消费进程异步重试（框架自带退避，见
 * WebhookDelivery）；请求路径内无 sleep、无 Timer。重试耗尽仅记日志。
 */
class WebhookService
{
    public const EVENTS = ['fee_paid', 'repair_created', 'announcement_published'];

    /** 可测注入点：返回配置数组（默认读 erik_system_config），null 表示未配置 */
    public static $configResolver = null;

    /** 可测注入点：fn(string $url, string $payload, string $signature): int 返回 HTTP 状态码，0=网络失败 */
    public static $httpClient = null;

    /** 可测注入点：fn(array $payload): void 投递失败后入队（默认 Webman\RedisQueue\Redis::send） */
    public static $queueSender = null;

    public static function sign(string $payload, string $secret): string
    {
        return 'sha256=' . hash_hmac('sha256', $payload, $secret);
    }

    /** 接收方校验路径：签名不匹配返回 false，供测试覆盖“签名错误拒收” */
    public static function verify(string $payload, string $signature, string $secret): bool
    {
        return hash_equals(self::sign($payload, $secret), $signature);
    }

    /** 触发业务事件：未配置/未启用/未订阅时静默跳过，返回 false */
    public static function dispatch(string $event, array $data): bool
    {
        if (!self::isSubscribed($event)) {
            return false;
        }
        if (!self::deliver($event, $data)) {
            self::enqueue($event, $data);
            return false;
        }
        return true;
    }

    /** 是否已配置、启用且订阅了该事件（入队前校验，避免禁用事件进入重试队列） */
    public static function isSubscribed(string $event): bool
    {
        $config = self::config();
        return (bool) ($config && !empty($config['enabled']) && in_array($event, $config['events'] ?? [], true));
    }

    /**
     * 实际 HTTP 投递（供请求路径与队列任务共用）：
     * 成功返回 true；失败返回 false，由调用方决定是否重试。
     */
    public static function deliver(string $event, array $data): bool
    {
        $config = self::config();
        if (!$config || empty($config['enabled']) || !in_array($event, $config['events'] ?? [], true)) {
            return false;
        }

        $payload = json_encode(
            ['event' => $event, 'occurred_at' => date('c'), 'data' => $data],
            JSON_UNESCAPED_UNICODE
        );
        $signature = self::sign($payload, (string) ($config['secret'] ?? ''));
        $client = self::$httpClient ?? fn (string $url, string $body, string $sig): int => self::post($url, $body, $sig);

        $status = $client((string) $config['url'], $payload, $signature);
        if ($status >= 200 && $status < 300) {
            Log::info('webhook_delivered', ['event' => $event, 'status' => $status]);
            return true;
        }
        Log::info('webhook_failed', ['event' => $event, 'status' => $status]);
        return false;
    }

    /** 投递失败后入队（事件名 + 原始 data），重试策略由队列框架负责 */
    private static function enqueue(string $event, array $data): void
    {
        try {
            $sender = self::$queueSender ?? function (array $payload): void { QueueRedis::send('webhook_delivery', $payload); };
            $sender(['event' => $event, 'data' => $data]);
        } catch (\Throwable $e) {
            Log::error('webhook_enqueue_failed', ['event' => $event, 'error' => $e->getMessage()]);
        }
    }

    private static function config(): ?array
    {
        if (self::$configResolver) {
            $config = (self::$configResolver)();
        } else {
            $json = SystemConfig::where('group', 'webhook')
                ->where('key', 'webhook_config')
                ->value('value');
            $config = $json ? json_decode((string) $json, true) : null;
        }
        return is_array($config) ? $config : null;
    }

    private static function post(string $url, string $payload, string $signature): int
    {
        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => $payload,
            CURLOPT_HTTPHEADER     => ['Content-Type: application/json', "X-Signature: {$signature}"],
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 5,
            CURLOPT_CONNECTTIMEOUT => 3,
        ]);
        curl_exec($ch);
        $status = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        return $status;
    }
}
