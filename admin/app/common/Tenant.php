<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\common;

/**
 * 租户上下文（静态栈）。
 * 请求链：TenantContext 中间件包裹；定时任务/队列：Tenant::for() 显式指定；
 * 无上下文时 TenantScope 拒绝查询（fail-closed）。
 */
class Tenant
{
    private static array $stack = [];

    /** 当前租户 ID；null = 无上下文；0 = 平台（不过滤） */
    public static function current(): ?int
    {
        $top = end(self::$stack);
        return $top === false ? null : $top;
    }

    /** 显式租户上下文，闭包结束自动还原（支持嵌套） */
    public static function for(int $tenantId, callable $fn): mixed
    {
        self::$stack[] = $tenantId;
        try {
            return $fn();
        } finally {
            array_pop(self::$stack);
        }
    }

    /** 平台级旁路（仪表盘跨区汇总等平台接口） */
    public static function without(callable $fn): mixed
    {
        return self::for(0, $fn);
    }
}
