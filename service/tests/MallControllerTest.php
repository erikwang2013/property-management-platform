<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\api\v1\controller\MallController;
use PHPUnit\Framework\TestCase;
use support\Request;

class MallControllerTest extends TestCase
{
    private static function makeRequest(array $inputs = [], int $ownerId = 1): Request
    {
        return new class($inputs, $ownerId) extends Request {
            public $ownerId;

            public function __construct(private array $inputs = [], int $ownerId = 1)
            {
                $this->ownerId = $ownerId;
            }

            public function input(string $name, mixed $default = null)
            {
                return $this->inputs[$name] ?? $default;
            }
        };
    }

    private static function call(string $method, array $inputs): array
    {
        $response = (new MallController())->{$method}(self::makeRequest($inputs));
        return json_decode($response->rawBody(), true);
    }

    public function test_create_order_missing_product(): void
    {
        $body = self::call('createOrder', ['quantity' => 1, 'address' => '某小区1栋']);
        $this->assertSame(422, $body['code']);
        $this->assertSame('请选择商品', $body['message']);
    }

    public function test_create_order_zero_quantity_rejected(): void
    {
        $body = self::call('createOrder', ['product_id' => 'abc', 'quantity' => 0, 'address' => '某小区1栋']);
        $this->assertSame(422, $body['code']);
        $this->assertSame('数量必须大于0', $body['message']);
    }

    public function test_create_order_negative_quantity_rejected(): void
    {
        $body = self::call('createOrder', ['product_id' => 'abc', 'quantity' => -3, 'address' => '某小区1栋']);
        $this->assertSame(422, $body['code']);
        $this->assertSame('数量必须大于0', $body['message']);
    }

    public function test_create_order_missing_address(): void
    {
        $body = self::call('createOrder', ['product_id' => 'abc', 'quantity' => 1]);
        $this->assertSame(422, $body['code']);
        $this->assertSame('请填写收货地址', $body['message']);
    }

    public function test_create_order_invalid_product_hashid(): void
    {
        $body = self::call('createOrder', ['product_id' => 'not-a-hashid', 'quantity' => 1, 'address' => '某小区1栋']);
        $this->assertSame(404, $body['code']);
        $this->assertSame('无效的商品ID', $body['message']);
    }

    public function test_product_detail_invalid_hashid(): void
    {
        $request = self::makeRequest();
        $response = (new MallController())->productDetail($request, 'not-a-hashid');
        $body = json_decode($response->rawBody(), true);
        $this->assertSame(404, $body['code']);
        $this->assertSame('无效的商品ID', $body['message']);
    }
}
