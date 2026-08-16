<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\admin\controller\PermissionController;
use app\common\HashidsService;
use PHPUnit\Framework\TestCase;
use ReflectionMethod;

/**
 * PermissionController::buildTree 权限树构建（纯逻辑，反射调用私有方法）
 */
class PermissionTreeTest extends TestCase
{
    private function buildTree(array $permissions, int $parentId = 0): array
    {
        $method = new ReflectionMethod(PermissionController::class, 'buildTree');
        $method->setAccessible(true);
        return $method->invoke(new PermissionController(), $permissions, $parentId);
    }

    public function test_flat_list_builds_nested_tree(): void
    {
        $permissions = [
            ['id' => 1, 'parent_id' => 0, 'name' => '系统管理'],
            ['id' => 2, 'parent_id' => 1, 'name' => '用户管理'],
            ['id' => 3, 'parent_id' => 1, 'name' => '角色管理'],
            ['id' => 4, 'parent_id' => 2, 'name' => '新增用户'],
        ];
        $tree = $this->buildTree($permissions);

        $this->assertCount(1, $tree);
        $this->assertCount(2, $tree[0]['children']);
        $this->assertSame('用户管理', $tree[0]['children'][0]['name']);
        $this->assertCount(1, $tree[0]['children'][0]['children']);
        $this->assertSame('新增用户', $tree[0]['children'][0]['children'][0]['name']);
    }

    public function test_multiple_roots_preserved_in_input_order(): void
    {
        $permissions = [
            ['id' => 1, 'parent_id' => 0, 'name' => 'A'],
            ['id' => 2, 'parent_id' => 0, 'name' => 'B'],
            ['id' => 3, 'parent_id' => 0, 'name' => 'C'],
        ];
        $tree = $this->buildTree($permissions);

        $this->assertSame(['A', 'B', 'C'], array_column($tree, 'name'));
        foreach ($tree as $node) {
            $this->assertArrayNotHasKey('children', $node);
        }
    }

    public function test_orphan_nodes_are_dropped(): void
    {
        $permissions = [
            ['id' => 1, 'parent_id' => 0, 'name' => '根'],
            ['id' => 9, 'parent_id' => 99, 'name' => '孤儿'],
        ];
        $tree = $this->buildTree($permissions);

        $this->assertCount(1, $tree);
        $this->assertArrayNotHasKey('children', $tree[0]);
    }

    public function test_empty_input_returns_empty_tree(): void
    {
        $this->assertSame([], $this->buildTree([]));
    }

    public function test_ids_are_hashid_encoded_in_tree(): void
    {
        $permissions = [
            ['id' => 1, 'parent_id' => 0, 'name' => '根'],
            ['id' => 2, 'parent_id' => 1, 'name' => '子'],
        ];
        $tree = $this->buildTree($permissions);

        $this->assertSame(1, HashidsService::decode($tree[0]['id']));
        $this->assertSame(2, HashidsService::decode($tree[0]['children'][0]['id']));
        // 仅 id 字段编码，parent_id 保持原始数字
        $this->assertSame(1, $tree[0]['children'][0]['parent_id']);
    }
}
