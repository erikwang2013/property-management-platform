<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\middleware;

use app\common\Tenant;
use support\Request;
use support\Response;

/**
 * 租户上下文中间件：将 AdminAuth 注入的 $request->tenantId 压入租户栈，
 * TenantScope 依此过滤；0 = 平台（不过滤）。登录/安装/支付回调等
 * 无此中间件的路径不产生上下文，查询租户表时由 TenantScope fail-closed。
 */
class TenantContext
{
    public function process(Request $request, callable $next): Response
    {
        $tenantId = (int) ($request->tenantId ?? 0);
        return Tenant::for($tenantId, fn() => $next($request));
    }
}
