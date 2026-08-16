<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\common;

use app\model\SystemConfig;
use support\Log;
use Workerman\Timer;

/**
 * Webhook 投递：订阅配置 → HMAC-SHA256 签名 → POST JSON → 失败重试（最多 3 次）
 *
 * 配置存 erik_system_config（group=webhook, key=webhook_config, type=json）：
 *   {"url":"https://example.com/hook","secret":"...","events":["fee_paid"],"enabled":true}
 *
 * 首次投递同步执行（保持调用方语义），失败后由 workerman Timer 延迟重试（1s → 2s），
 * 请求路径内无 sleep；重试耗尽仅记日志，不影响主流程结果。
 */
class WebhookService
{
    public const EVENTS = ['fee_paid', 'repair_created', 'announcement_published'];

    /** 失败重试间隔（秒，指数退避）；总尝试次数 = 数组长度 + 1，默认 3 次 */
    public static array $retryDelays = [1, 2];

    /** 可测注入点：返回配置数组（默认读 erik_system_config），null 表示未配置 */
    public static $configResolver = null;

    /** 可测注入点：fn(string $url, string $payload, string $signature): int 返回 HTTP 状态码，0=网络失败 */
    public static $httpClient = null;

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
            Log::info('webhook_delivered', ['event' => $event, 'attempt' => 1, 'status' => $status]);
            return true;
        }
        self::scheduleRetry($event, (string) $config['url'], $payload, $signature, $status);
        return false;
    }

    /** 首次投递失败后调度 Timer 延迟重试；非 workerman 环境（CLI/测试）无 Timer 可用时仅记日志 */
    private static function scheduleRetry(string $event, string $url, string $payload, string $signature, int $lastStatus): void
    {
        $client = self::$httpClient ?? fn (string $u, string $b, string $s): int => self::post($u, $b, $s);
        $attempt  = 1; // 首次同步尝试已消耗
        $attempts = count(self::$retryDelays) + 1;
        if ($attempt >= $attempts) {
            Log::error('webhook_failed', ['event' => $event, 'attempts' => $attempts, 'last_status' => $lastStatus]);
            return;
        }

        $retry = function () use (&$retry, &$attempt, &$lastStatus, $event, $url, $payload, $signature, $client, $attempts): void {
            $attempt++;
            $lastStatus = $client($url, $payload, $signature);
            if ($lastStatus >= 200 && $lastStatus < 300) {
                Log::info('webhook_delivered', ['event' => $event, 'attempt' => $attempt, 'status' => $lastStatus]);
                return;
            }
            if ($attempt < $attempts) {
                Timer::add(self::$retryDelays[$attempt - 1], $retry, [], false);
                return;
            }
            Log::error('webhook_failed', ['event' => $event, 'attempts' => $attempts, 'last_status' => $lastStatus]);
        };

        try {
            Timer::add(self::$retryDelays[0], $retry, [], false);
        } catch (\Throwable $e) {
            Log::error('webhook_failed', ['event' => $event, 'attempts' => $attempts, 'last_status' => $lastStatus, 'error' => $e->getMessage()]);
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
