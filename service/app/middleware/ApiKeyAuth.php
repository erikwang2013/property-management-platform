<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\middleware;

use app\model\ApiKey;
use support\Request;
use support\Response;

/**
 * 开放 API Key 鉴权中间件（/open/* 只读接口）
 * 校验 X-API-Key 头，与 erik_api_key 表中启用的 Key（SHA-256 摘要）比对
 */
class ApiKeyAuth
{
    public function process(Request $request, callable $next): Response
    {
        $key = $request->header('X-API-Key', '');

        if ($key === '' || strlen($key) > 128 || !ApiKey::where('api_key_hash', hash('sha256', $key))->where('status', 1)->exists()) {
            return json(['code' => 401, 'message' => '无效的API Key', 'data' => []])->withStatus(401);
        }

        return $next($request);
    }
}
