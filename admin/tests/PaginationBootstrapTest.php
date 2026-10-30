<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\common\PaginationBootstrap;
use Illuminate\Pagination\Paginator;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\TestCase;

/**
 * 分页页码解析（纯逻辑无 DB）
 *
 * 背景：resolver 未注册时 illuminate 的 resolveCurrentPage() 恒返回 1，
 * 所有 `->paginate($perPage)` 的列表接口会忽略 ?page=N 永远返回第一页。
 */
class PaginationBootstrapTest extends TestCase
{
    #[Test]
    public function start_registers_resolver(): void
    {
        $before = Paginator::resolveCurrentPage();
        PaginationBootstrap::start(null);
        // CLI 无请求上下文：resolver 已注册但取不到请求，应与默认值一致
        $this->assertSame($before, Paginator::resolveCurrentPage());
        $this->assertSame(1, Paginator::resolveCurrentPage());
    }

    #[Test]
    public function valid_pages_are_passed_through(): void
    {
        $this->assertSame(2, PaginationBootstrap::resolvePage('2'));
        $this->assertSame(2, PaginationBootstrap::resolvePage(2));
        $this->assertSame(17, PaginationBootstrap::resolvePage('17'));
        $this->assertSame(1, PaginationBootstrap::resolvePage('1'));
        $this->assertSame(1, PaginationBootstrap::resolvePage(1));
    }

    #[Test]
    public function invalid_pages_fall_back_to_one(): void
    {
        $this->assertSame(1, PaginationBootstrap::resolvePage(null));
        $this->assertSame(1, PaginationBootstrap::resolvePage(''));
        $this->assertSame(1, PaginationBootstrap::resolvePage('abc'));
        $this->assertSame(1, PaginationBootstrap::resolvePage('0'));
        $this->assertSame(1, PaginationBootstrap::resolvePage(0));
        $this->assertSame(1, PaginationBootstrap::resolvePage('-3'));
        $this->assertSame(1, PaginationBootstrap::resolvePage('2.5'));
        $this->assertSame(1, PaginationBootstrap::resolvePage([]));
    }
}
