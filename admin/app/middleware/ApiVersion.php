<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\middleware;

use support\Request;
use Webman\Http\Response;

/**
 * API 版本中间件
 *
 * 从请求头 API-Version 读取版本号，支持版本路由转发。
 * 客户端请求示例: curl -H "API-Version: v1" /api/auth/login
 */
class ApiVersion
{
    /** 支持的版本列表 */
    private const SUPPORTED = ['v1'];

    /** 默认版本（请求头未携带版本号时使用） */
    private const DEFAULT = 'v1';

    public function process(Request $request, callable $next): Response
    {
        $version = (string) $request->header('API-Version', self::DEFAULT);

        if (!in_array($version, self::SUPPORTED, true)) {
            // 注意：webman 的 json() 助手第二参为 JSON 编码选项且固定 HTTP 200，
            // 这里必须显式构造 400 状态响应，保证 REST 语义正确
            return response(
                json_encode([
                    'code'    => 400,
                    'message' => "不支持的API版本: {$version}，当前支持: " . implode(', ', self::SUPPORTED),
                    'data'    => [],
                ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR),
                400,
                ['Content-Type' => 'application/json']
            );
        }

        $request->apiVersion = $version;

        return $next($request);
    }
}
