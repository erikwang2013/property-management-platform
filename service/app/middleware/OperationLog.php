<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\middleware;

use Webman\MiddlewareInterface;
use Webman\Http\Response;
use Webman\Http\Request;
use app\common\SnowflakeService;

/**
 * 业主端操作审计日志中间件
 * 记录 POST/PUT/DELETE 操作，支持 8 平台来源端自动检测
 */
class OperationLog implements MiddlewareInterface
{
    public function process(Request $request, callable $handler): Response
    {
        $method = $request->method();

        if (!in_array($method, ['POST', 'PUT', 'DELETE'], true)) {
            return $handler($request);
        }

        $response = $handler($request);

        try {
            $input = $this->filterSensitive($request->all());

            $log = new \app\model\OperationLog();
            $log->id         = SnowflakeService::generate();
            $log->user_id    = $request->ownerId ?? 0;
            $log->action     = $method;
            $log->method     = $method;
            $log->path       = $request->path();
            $log->ip         = $request->getRealIp();
            $log->source     = $this->detectSource($request);
            $log->input      = json_encode($input, JSON_UNESCAPED_UNICODE);
            $log->created_at = date('Y-m-d H:i:s');
            $log->save();
        } catch (\Throwable $e) {
            // 日志记录失败不影响业务请求
        }

        return $response;
    }

    /**
     * 递归过滤敏感字段
     */
    private function filterSensitive(array $data): array
    {
        $keys = ['password', 'old_password', 'new_password', 'token', 'secret', 'access_token', 'refresh_token'];
        foreach ($data as $key => $value) {
            if (in_array($key, $keys, true)) {
                $data[$key] = '***';
            } elseif (is_array($value)) {
                $data[$key] = $this->filterSensitive($value);
            }
        }
        return $data;
    }

    /**
     * 检测操作来源端（8 平台）
     * 优先级: X-Client-Platform 请求头 > User-Agent 推断 > web 降级
     */
    private function detectSource(Request $request): string
    {
        // 原生客户端显式声明平台
        $platform = $request->header('X-Client-Platform', '');
        if ($platform && in_array(strtolower($platform), [
            'ipados', 'macos', 'windows', 'linux', 'ios', 'android', 'harmonyos', 'web',
        ], true)) {
            return strtolower($platform);
        }

        // User-Agent 推断
        $ua = $request->header('User-Agent', '');

        if (stripos($ua, 'HarmonyOS') !== false || stripos($ua, 'OpenHarmony') !== false) {
            return 'harmonyos';
        }
        if (stripos($ua, 'iPad') !== false) {
            return 'ipados';
        }
        if (stripos($ua, 'iPhone') !== false || stripos($ua, 'iOS') !== false || stripos($ua, 'CFNetwork') !== false) {
            return 'ios';
        }
        if (stripos($ua, 'Android') !== false) {
            return 'android';
        }
        if (stripos($ua, 'Macintosh') !== false || stripos($ua, 'Mac OS') !== false) {
            return 'macos';
        }
        if (stripos($ua, 'Windows') !== false) {
            return 'windows';
        }
        if (stripos($ua, 'Linux') !== false && stripos($ua, 'Android') === false) {
            return 'linux';
        }

        return 'web';
    }
}
