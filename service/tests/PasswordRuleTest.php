<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\common\PasswordRule;
use PHPUnit\Framework\TestCase;

/**
 * 业主密码规则唯一源测试（注册/改密同口径，2026-10 修复「改密至少6位」的降级漏洞）。
 */
class PasswordRuleTest extends TestCase
{
    public function test_rule_accepts_complex_password(): void
    {
        $this->assertNull(PasswordRule::check('Abcdef1@'));
    }

    public function test_rule_rejects_short_or_long(): void
    {
        $this->assertSame('密码长度 8-32 位', PasswordRule::check('Ab1@'));
        $this->assertSame('密码长度 8-32 位', PasswordRule::check(str_repeat('Ab1@', 9)));
    }

    public function test_rule_rejects_missing_classes(): void
    {
        $complexError = '密码需包含大小写字母、数字和特殊字符(@$!%*?&)';
        $this->assertSame($complexError, PasswordRule::check('abcdefg1@')); // 无大写
        $this->assertSame($complexError, PasswordRule::check('ABCDEFG1@')); // 无小写
        $this->assertSame($complexError, PasswordRule::check('Abcdefg@'));  // 无数字
        $this->assertSame($complexError, PasswordRule::check('Abcdefg1'));  // 无特殊字符
    }

    /** 防漂移：注册/改密口一律引用 PasswordRule，禁用内联正则副本 */
    public function test_password_entrypoints_use_shared_rule_only(): void
    {
        $files = [
            __DIR__ . '/../app/api/v1/controller/AuthController.php',
            __DIR__ . '/../app/api/v1/controller/ProfileController.php',
        ];
        foreach ($files as $file) {
            $src = file_get_contents($file);
            $this->assertStringContainsString('PasswordRule', $src, basename($file) . ' 应引用 PasswordRule');
            $this->assertStringNotContainsString('(?=.*[a-z])', $src, basename($file) . ' 不应内联密码正则');
        }
    }
}
