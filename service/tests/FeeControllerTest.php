<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\api\v1\controller\FeeController;
use PHPUnit\Framework\TestCase;
use ReflectionMethod;
use support\Request;

class FeeControllerTest extends TestCase
{
    private static function makeRequest(array $inputs = [], int $ownerId = 0): Request
    {
        return new class($inputs, $ownerId) extends Request {
            public $ownerId;

            public function __construct(private array $inputs = [], int $ownerId = 0)
            {
                $this->ownerId = $ownerId;
            }

            public function input(string $name, mixed $default = null)
            {
                return $this->inputs[$name] ?? $default;
            }
        };
    }

    /** confirmPassword 置空，跳过 DB 密码校验，直达参数校验路径 */
    private static function makeController(): FeeController
    {
        return new class extends FeeController {
            public function confirmPassword(int $ownerId, string $password): ?string
            {
                return null;
            }
        };
    }

    private static function call(string $method, array $inputs): array
    {
        $response = self::makeController()->{$method}(self::makeRequest($inputs, 1));
        return json_decode($response->rawBody(), true);
    }

    public function test_pay_missing_bill_id(): void
    {
        $body = self::call('pay', ['amount' => 100]);
        $this->assertSame(422, $body['code']);
        $this->assertSame('缺少账单ID', $body['message']);
    }

    public function test_pay_amount_zero_rejected(): void
    {
        $body = self::call('pay', ['bill_id' => 'abc', 'amount' => 0]);
        $this->assertSame(422, $body['code']);
        $this->assertSame('金额必须大于0', $body['message']);
    }

    public function test_pay_amount_negative_rejected(): void
    {
        $body = self::call('pay', ['bill_id' => 'abc', 'amount' => -5]);
        $this->assertSame(422, $body['code']);
        $this->assertSame('金额必须大于0', $body['message']);
    }

    public function test_pay_invalid_hashid_returns_404(): void
    {
        $body = self::call('pay', ['bill_id' => 'not-a-hashid', 'amount' => 100]);
        $this->assertSame(404, $body['code']);
        $this->assertSame('无效的账单ID', $body['message']);
    }

    public function test_bill_detail_invalid_hashid_returns_404(): void
    {
        $response = self::makeController()->billDetail(self::makeRequest([], 1), 'not-a-hashid');
        $body = json_decode($response->rawBody(), true);
        $this->assertSame(404, $body['code']);
        $this->assertSame('无效的账单ID', $body['message']);
    }

    public function test_confirm_password_empty_rejects_before_db(): void
    {
        $method = new ReflectionMethod(FeeController::class, 'confirmPassword');
        $method->setAccessible(true);
        $error = $method->invoke(new FeeController(), 1, '');
        $this->assertSame('敏感操作需要输入密码确认', $error);
    }
}
