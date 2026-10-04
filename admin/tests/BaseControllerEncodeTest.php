<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\admin\controller\BaseController;
use app\common\HashidsService;
use app\exception\InvalidResourceIdException;
use PHPUnit\Framework\TestCase;
use ReflectionMethod;
use support\Request;

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

    public function test_decode_invalid_hashid_yields_clean_422(): void
    {
        try {
            $this->call('decodeId', ['not-a-hashid']);
            $this->fail('非法 hashid 应抛 InvalidResourceIdException');
        } catch (InvalidResourceIdException $e) {
            $this->assertClean422($e);
        }
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

    public function test_decode_ids_decodes_only_present_keys(): void
    {
        $hashid = $this->call('encodeId', [381924599631319040]);
        $data = $this->call('decodeIds', [['community_id' => $hashid, 'name' => '张三'], ['community_id']]);

        $this->assertSame(381924599631319040, $data['community_id']);
        $this->assertSame('张三', $data['name']);
    }

    public function test_decode_ids_does_not_inject_absent_keys(): void
    {
        // 更新路径只回填客户端传了的字段，未传的键不能被凭空补成 null/0
        $data = $this->call('decodeIds', [['name' => '张三'], ['community_id']]);

        $this->assertArrayNotHasKey('community_id', $data);
    }

    public function test_decode_ids_skips_empty_values(): void
    {
        $data = $this->call('decodeIds', [['community_id' => '', 'owner_id' => null], ['community_id', 'owner_id']]);

        $this->assertSame('', $data['community_id']);
        $this->assertNull($data['owner_id']);
    }

    public function test_decode_ids_garbage_hashid_yields_clean_422(): void
    {
        try {
            $this->call('decodeIds', [['community_id' => 'not-a-hashid'], ['community_id']]);
            $this->fail('非法 hashid 应抛 InvalidResourceIdException');
        } catch (InvalidResourceIdException $e) {
            $this->assertClean422($e);
        }
    }

    /** 422 响应体必须干净：只有 code/message/data，不带异常类名、文件路径或堆栈 */
    private function assertClean422(InvalidResourceIdException $e): void
    {
        $body = (string) $e->render(new Request("GET /admin/x HTTP/1.1\r\nHost: localhost\r\n\r\n"))->rawBody();
        $decoded = json_decode($body, true);

        $this->assertSame(422, $decoded['code']);
        $this->assertSame('无效的资源 ID', $decoded['message']);
        $this->assertSame(['code', 'message', 'data'], array_keys($decoded));
        $this->assertStringNotContainsString('Exception', $body);
        $this->assertStringNotContainsString('HashidsService', $body);
        $this->assertStringNotContainsString('.php', $body);
        $this->assertStringNotContainsString('/', $body);
    }

    /**
     * 契约守卫：凡 `where('*_id', (int) $x)` 即违规 —— 外键筛选一律收 hashid，
     * hashid 被 (int) 吃掉恒为 0（筛选恒空）/ 裸串直接进 where（命中 0 行）。
     * 唯一例外是 JWT 里的内部 adminId，不是 API 编码外键。
     */
    public function test_id_filters_have_no_bare_int_cast_outside_whitelist(): void
    {
        $allowed = [
            'ApprovalController.php#approver_id',    // 审批人取自 JWT adminId，非 API 编码外键
        ];

        $found = [];
        foreach (glob(__DIR__ . '/../app/admin/controller/*.php') as $file) {
            preg_match_all("/where\('([a-z_]*_id)',\s*\(int\)/", (string) file_get_contents($file), $matches);
            foreach ($matches[1] as $column) {
                $found[] = basename($file) . '#' . $column;
            }
        }
        sort($found);
        sort($allowed);

        $this->assertSame($allowed, $found, '发现未登记的外键 (int) 强转：读端 encodeId 出去的外键，筛选必须 decodeId 进来');
    }

    /**
     * 契约守卫（读端对称）：下列外键在列表/详情响应里必须 encodeId 出去，不许裸出 `$x->field`。
     * 筛选既然收 hashid，读端就得吐 hashid，否则「拿列表值回填筛选」必 500（两端盐不同时还会串端）。
     * 全部为 0 时保持 `''`（与同数组内 strategy_id/rule_id 的既有写法一致），0 的语义不变。
     * 局限：按字段名清单守，新增的裸外键字段不在清单内不报（由 e2e 断言实际响应字段覆盖）。
     */
    public function test_read_side_foreign_keys_are_encoded(): void
    {
        $fields = [
            'CollectionController.php' => ['bill_id', 'executed_by'],
            'InspectionController.php' => ['community_id', 'assigned_to'],
            'KnowledgeController.php'  => ['category_id', 'user_id', 'matched_kb_id'],
            'MallController.php'       => ['category_id', 'community_id'],
            'SlaController.php'        => ['repair_order_id'],
            'VoteController.php'       => ['community_id', 'publisher_id'],
        ];

        $raw = [];
        foreach ($fields as $file => $names) {
            $src = (string) file_get_contents(__DIR__ . '/../app/admin/controller/' . $file);
            foreach ($names as $name) {
                if (preg_match("/'{$name}'\s*=>\s*\\\$\w+->{$name}\s*,/", $src)) {
                    $raw[] = $file . '#' . $name;
                }
            }
        }

        $this->assertSame([], $raw, '下列读响应外键仍裸出：改为 `$x->f ? $this->encodeId($x->f) : \'\'`');
    }
}
