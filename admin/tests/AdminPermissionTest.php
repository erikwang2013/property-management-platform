<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\middleware\AdminPermission;
use PHPUnit\Framework\TestCase;
use ReflectionMethod;

/**
 * AdminPermission slug 解析（参数段剥离 + 前缀回退）契约守卫。
 * 输入是注册路由模式（含 {hashid} 占位），与 process() 里取 $request->route->getPath() 一致。
 */
class AdminPermissionTest extends TestCase
{
    private function resolve(string $method, string $path, array $permissions): string
    {
        $ref = new ReflectionMethod(AdminPermission::class, 'resolvePermission');
        $ref->setAccessible(true);
        return $ref->invoke(new AdminPermission(), $method, $path, $permissions);
    }

    /** 核心修复：种子按不带参数的逻辑路径写，剥掉 {hashid} 段后必须命中 */
    public function test_param_segment_stripped_before_match(): void
    {
        $this->assertSame(
            'put.admin/complaint/handle',
            $this->resolve('PUT', '/admin/complaint/{hashid}/handle', ['put.admin/complaint/handle'])
        );
        $this->assertSame(
            'put.admin/visitor/approve',
            $this->resolve('PUT', '/admin/visitor/{hashid}/approve', ['put.admin/visitor/approve'])
        );
        // 参数段名不必叫 hashid（如 {taskHashid}），凡 {...} 段一律剥
        $this->assertSame(
            'get.admin/inspection-task/checkpoints',
            $this->resolve('GET', '/admin/inspection-task/{taskHashid}/checkpoints', ['get.admin/inspection-task/checkpoints'])
        );
        // 末尾参数段（详情/更新路由）
        $this->assertSame(
            'put.admin/building',
            $this->resolve('PUT', '/admin/building/{hashid}', ['put.admin/building'])
        );
    }

    /** 前缀回退保留：短前缀授权角色行为不变（put.admin/complaint 未种，属既有语义） */
    public function test_prefix_fallback_still_works(): void
    {
        $this->assertSame(
            'put.admin/complaint',
            $this->resolve('PUT', '/admin/complaint/{hashid}/handle', ['put.admin/complaint'])
        );
        $this->assertSame(
            'get.admin/user',
            $this->resolve('GET', '/admin/user/{hashid}', ['get.admin/user'])
        );
    }

    /** 对照组：不带参数的路径精确命中，不参与剥离/回退 */
    public function test_exact_match_without_stripping(): void
    {
        $this->assertSame('get.admin/repair', $this->resolve('GET', '/admin/repair', ['get.admin/repair']));
        $this->assertSame('get.admin/report', $this->resolve('GET', '/admin/report', ['get.admin/report']));
    }

    /** 该拒的仍拒：无任何祖先命中时解析结果不在权限列表内（调用方 403） */
    public function test_unmatched_slug_is_not_in_permissions(): void
    {
        $cases = [
            ['GET', '/admin/report', ['get.admin/repair']],
            ['PUT', '/admin/complaint/{hashid}/handle', ['put.admin/visitor/approve']],
            ['POST', '/admin/payment-order/reconcile', []],
        ];
        foreach ($cases as [$method, $path, $permissions]) {
            $this->assertNotContains($this->resolve($method, $path, $permissions), $permissions, "$method $path 不该命中");
        }
    }
}
