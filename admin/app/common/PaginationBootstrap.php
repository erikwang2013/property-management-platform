<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\common;

use Illuminate\Pagination\Paginator;
use Workerman\Worker;

/**
 * 分页页码解析（bootstrap）
 *
 * `$query->paginate($perPage)` 不显式传页码时，illuminate 会经
 * Paginator::resolveCurrentPage() 取当前页，该值来自静态 resolver；
 * **未注册 resolver 时它恒返回默认值 1**，表现为所有分页列表接口忽略
 * `?page=N`、永远返回第一页（总页数、total 都是对的，只有数据不动）。
 *
 * Laravel 由 PaginationState::resolveUsing() 注册该 resolver，webman 不加载它，
 * 故在此注册，取值语义与 illuminate 保持一致。显式传页码的调用
 * （如 `paginate(20, ['*'], 'page', $page)`）不受影响。
 */
class PaginationBootstrap
{
    public static function start(?Worker $worker): void
    {
        Paginator::currentPageResolver(static function (string $pageName = 'page'): int {
            $request = request();
            if ($request === null) {
                return 1; // 非请求上下文（队列/命令行）保持 illuminate 默认行为
            }
            return static::resolvePage($request->input($pageName));
        });
    }

    /**
     * 把请求里的原始页码规整为合法页码（与 illuminate PaginationState 同语义）
     */
    public static function resolvePage(mixed $page): int
    {
        if (filter_var($page, FILTER_VALIDATE_INT) !== false && (int) $page >= 1) {
            return (int) $page;
        }
        return 1;
    }
}
