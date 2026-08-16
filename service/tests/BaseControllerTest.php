<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\common\BaseController;
use PHPUnit\Framework\TestCase;

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
}
