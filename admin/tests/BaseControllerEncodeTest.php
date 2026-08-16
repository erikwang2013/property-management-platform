<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\admin\controller\BaseController;
use app\common\HashidsService;
use PHPUnit\Framework\TestCase;
use ReflectionMethod;

/**
 * BaseController 受保护 ID 编解码助手（反射调用，纯逻辑无 DB）
 */
class BaseControllerEncodeTest extends TestCase
{
    private function call(string $method, array $args): mixed
    {
        $ref = new ReflectionMethod(BaseController::class, $method);
        $ref->setAccessible(true);
        return $ref->invokeArgs(new BaseController(), $args);
    }

    public function test_encode_decode_roundtrip(): void
    {
        foreach ([1, 42, 987654321] as $id) {
            $encoded = $this->call('encodeId', [$id]);
            $this->assertNotSame((string) $id, $encoded);
            $this->assertSame($id, $this->call('decodeId', [$encoded]));
        }
    }

    public function test_encode_is_deterministic_and_injective(): void
    {
        $this->assertSame(
            $this->call('encodeId', [123]),
            $this->call('encodeId', [123])
        );
        $this->assertNotSame(
            $this->call('encodeId', [123]),
            $this->call('encodeId', [124])
        );
    }

    public function test_decode_invalid_hashid_throws(): void
    {
        $this->expectException(\InvalidArgumentException::class);
        $this->call('decodeId', ['not-a-hashid']);
    }

    public function test_encode_ids_replaces_numeric_fields_only(): void
    {
        $data = ['id' => 1, 'owner_id' => 2, 'name' => '张三'];
        $encoded = $this->call('encodeIds', [$data, ['id', 'owner_id']]);

        $this->assertSame(1, HashidsService::decode($encoded['id']));
        $this->assertSame(2, HashidsService::decode($encoded['owner_id']));
        $this->assertSame('张三', $encoded['name']);
    }

    public function test_encode_ids_defaults_to_id_field(): void
    {
        $encoded = $this->call('encodeIds', [['id' => 5, 'owner_id' => 9]]);

        $this->assertSame(5, HashidsService::decode($encoded['id']));
        // 默认字段不含 owner_id，保持原值
        $this->assertSame(9, $encoded['owner_id']);
    }

    public function test_generate_id_is_positive_and_unique(): void
    {
        $a = $this->call('generateId', []);
        $b = $this->call('generateId', []);

        $this->assertGreaterThan(0, $a);
        $this->assertNotSame($a, $b);
    }
}
