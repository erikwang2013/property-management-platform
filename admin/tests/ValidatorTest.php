<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
declare(strict_types=1);
namespace tests;
use PHPUnit\Framework\TestCase;
use app\common\Validator;

class ValidatorTest extends TestCase
{
    public function test_required_passes_with_value(): void
    {
        $v = new Validator(['name' => 'test']);
        $v->required('name', '名称');
        $this->assertTrue($v->passes());
    }

    public function test_required_fails_with_empty(): void
    {
        $v = new Validator(['name' => '']);
        $v->required('name', '名称');
        $this->assertTrue($v->fails());
        $this->assertStringContainsString('名称', $v->firstError());
    }

    public function test_required_fails_with_missing(): void
    {
        $v = new Validator([]);
        $v->required('name', '名称');
        $this->assertTrue($v->fails());
    }

    public function test_max_exceeds_limit(): void
    {
        $v = new Validator(['title' => str_repeat('a', 101)]);
        $v->max('title', 100, '标题');
        $this->assertTrue($v->fails());
    }

    public function test_max_within_limit(): void
    {
        $v = new Validator(['title' => 'short']);
        $v->max('title', 100);
        $this->assertTrue($v->passes());
    }

    public function test_email_valid(): void
    {
        $v = new Validator(['email' => 'test@example.com']);
        $v->email('email');
        $this->assertTrue($v->passes());
    }

    public function test_email_invalid(): void
    {
        $v = new Validator(['email' => 'not-an-email']);
        $v->email('email');
        $this->assertTrue($v->fails());
    }

    public function test_mobile_valid(): void
    {
        $v = new Validator(['phone' => '13800138000']);
        $v->mobile('phone');
        $this->assertTrue($v->passes());
    }

    public function test_mobile_invalid(): void
    {
        $v = new Validator(['phone' => '12345']);
        $v->mobile('phone');
        $this->assertTrue($v->fails());
    }

    public function test_numeric_valid(): void
    {
        $v = new Validator(['amount' => '99.99']);
        $v->numeric('amount');
        $this->assertTrue($v->passes());
    }

    public function test_min_value_fails(): void
    {
        $v = new Validator(['amount' => '5']);
        $v->minValue('amount', 10, '金额');
        $this->assertTrue($v->fails());
    }

    public function test_in_range(): void
    {
        $v = new Validator(['status' => 1]);
        $v->in('status', [0, 1, 2]);
        $this->assertTrue($v->passes());
    }

    public function test_in_out_of_range(): void
    {
        $v = new Validator(['status' => 99]);
        $v->in('status', [0, 1, 2]);
        $this->assertTrue($v->fails());
    }

    public function test_multiple_rules_returns_first_error(): void
    {
        $v = new Validator(['name' => '']);
        $v->required('name', '名称')->max('name', 50);
        $this->assertStringContainsString('不能为空', $v->firstError());
    }

    public function test_errors_returns_all(): void
    {
        $v = new Validator(['name' => '', 'email' => 'bad']);
        $v->required('name', '名称')->email('email', '邮箱');
        $this->assertCount(2, $v->errors());
    }
}
