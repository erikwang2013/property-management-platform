<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\common\BaseController;
use app\exception\InvalidResourceIdException;
use Erikwang2013\Hashids\HashidsFactory;
use Erikwang2013\Hashids\HashidsManager;
use PHPUnit\Framework\TestCase;
use support\Request;

class BaseControllerTest extends TestCase
{
    private function makeController(): BaseController
    {
        return new class extends BaseController {
            public function callSuccess($data = [], string $message = 'success', int $code = 0)
            {
                return $this->success($data, $message, $code);
            }

            public function callFail(string $message = 'fail', int $code = 500, $data = [])
            {
                return $this->fail($message, $code, $data);
            }

            public function callEncodeId(int $id): string
            {
                return $this->encodeId($id);
            }

            public function callDecodeId(string $hashid): int
            {
                return $this->decodeId($hashid);
            }
        };
    }

    public function test_success_body_contract(): void
    {
        $response = $this->makeController()->callSuccess(['name' => '测试'], '操作成功');
        $body = json_decode($response->rawBody(), true);

        $this->assertIsArray($body);
        $this->assertSame(0, $body['code']);
        $this->assertSame('操作成功', $body['message']);
        $this->assertSame(['name' => '测试'], $body['data']);
    }

    public function test_success_default_message(): void
    {
        $body = json_decode($this->makeController()->callSuccess()->rawBody(), true);
        $this->assertSame('success', $body['message']);
        $this->assertSame([], $body['data']);
    }

    public function test_fail_body_contract(): void
    {
        $response = $this->makeController()->callFail('参数错误', 422, ['field' => 'amount']);
        $body = json_decode($response->rawBody(), true);

        $this->assertIsArray($body);
        $this->assertSame(422, $body['code']);
        $this->assertSame('参数错误', $body['message']);
        $this->assertSame(['field' => 'amount'], $body['data']);
    }

    public function test_fail_defaults(): void
    {
        $body = json_decode($this->makeController()->callFail()->rawBody(), true);
        $this->assertSame(500, $body['code']);
        $this->assertSame('fail', $body['message']);
        $this->assertSame([], $body['data']);
    }

    public function test_success_and_fail_are_valid_json(): void
    {
        $this->assertNotFalse(json_decode($this->makeController()->callSuccess(['a' => 1])->rawBody()));
        $this->assertNotFalse(json_decode($this->makeController()->callFail('错误', 400)->rawBody()));
    }

    public function test_decode_id_roundtrip_unaffected(): void
    {
        $c = $this->makeController();
        foreach ([1, 42, 381924599631319040] as $id) {
            $hashid = $c->callEncodeId($id);
            $this->assertNotSame((string) $id, $hashid);
            $this->assertSame($id, $c->callDecodeId($hashid));
        }
    }

    public function test_decode_id_invalid_string_yields_clean_422(): void
    {
        try {
            $this->makeController()->callDecodeId('not-a-hashid');
            $this->fail('非法 hashid 应抛 InvalidResourceIdException');
        } catch (InvalidResourceIdException $e) {
            $this->assertClean422($e);
        }
    }

    public function test_decode_id_old_salt_hashid_yields_clean_422(): void
    {
        // 旧盐串：结构合法（同字母表同长度）但当前 salt 解不出 —— 换盐/串端时的典型输入
        $cfg = ['default' => 'main', 'connections' => ['main' => [
            'salt' => 'property-service-hashids-salt-OLD', 'length' => 16,
            'alphabet' => 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890',
        ]]];
        $oldSaltHashid = (new HashidsManager($cfg, new HashidsFactory()))->encode(381924599631319040);
        $this->assertNotSame($this->makeController()->callEncodeId(381924599631319040), $oldSaltHashid);

        try {
            $this->makeController()->callDecodeId($oldSaltHashid);
            $this->fail('旧盐 hashid 应抛 InvalidResourceIdException');
        } catch (InvalidResourceIdException $e) {
            $this->assertClean422($e);
        }
    }

    public function test_decode_id_empty_string_yields_clean_422(): void
    {
        try {
            $this->makeController()->callDecodeId('');
            $this->fail('空串应抛 InvalidResourceIdException');
        } catch (InvalidResourceIdException $e) {
            $this->assertClean422($e);
        }
    }

    /**
     * 未捕获路径：走框架异常处理器（support\exception\Handler）必须命中异常自带 render()，
     * 出 HTTP 200 + code 422；debug=true 时也不得落 traces/类名/路径（旧 500 分支的泄漏点）。
     */
    public function test_framework_handler_renders_clean_422_on_uncaught(): void
    {
        $handler = new \support\exception\Handler(new \Monolog\Logger('test'), true);
        $response = $handler->render(
            new Request("GET /service/v1/announcement/ZZZ HTTP/1.1\r\nHost: localhost\r\n\r\n"),
            new InvalidResourceIdException('无效的资源 ID')
        );

        $this->assertSame(200, $response->getStatusCode());
        $body = (string) $response->rawBody();
        $this->assertSame(422, json_decode($body, true)['code']);
        $this->assertCleanBody($body);
    }

    /** 422 响应体必须干净：只有 code/message/data，不带异常类名、文件路径或堆栈 */
    private function assertClean422(InvalidResourceIdException $e): void
    {
        $body = (string) $e->render(new Request("GET /service/v1/x HTTP/1.1\r\nHost: localhost\r\n\r\n"))->rawBody();
        $decoded = json_decode($body, true);

        $this->assertSame(422, $decoded['code']);
        $this->assertSame('无效的资源 ID', $decoded['message']);
        $this->assertCleanBody($body);
    }

    private function assertCleanBody(string $body): void
    {
        $decoded = json_decode($body, true);
        $this->assertSame(['code', 'message', 'data'], array_keys($decoded));
        $this->assertStringNotContainsString('Exception', $body);
        $this->assertStringNotContainsString('HashidsService', $body);
        $this->assertStringNotContainsString('.php', $body);
        $this->assertStringNotContainsString('/', $body);
    }
}
