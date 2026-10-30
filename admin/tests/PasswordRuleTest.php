<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\admin\validate\PasswordRule;
use PHPUnit\Framework\TestCase;

/**
 * 密码规则唯一源测试。
 * 背景：登录口对提交密码强校验本规则，任入口放宽会造出「能建号、永远登不上」的账号
 * （2026-10 修复）；本文件兼做防漂移源码扫描。
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

    public function test_rule_string_covers_length_and_complexity(): void
    {
        $rule = PasswordRule::ruleString();
        $this->assertStringContainsString('min:8', $rule);
        $this->assertStringContainsString('max:32', $rule);
        $this->assertStringContainsString(PasswordRule::REGEX, $rule);
    }

    /**
     * 防漂移：全部密码入口一律引用 PasswordRule，任何人不得再内联正则副本
     * （登录强校验规则内联在别处放宽 = 重现「能建号、登不上」缺陷）。
     */
    public function test_password_entrypoints_use_shared_rule_only(): void
    {
        $files = [
            __DIR__ . '/../app/api/v1/controller/AuthController.php',
            __DIR__ . '/../app/admin/controller/UserController.php',
            __DIR__ . '/../app/admin/controller/ProfileController.php',
            __DIR__ . '/../app/admin/controller/ImportController.php',
            __DIR__ . '/../app/admin/validate/InstallValidator.php',
        ];
        foreach ($files as $file) {
            $src = file_get_contents($file);
            $this->assertStringContainsString('PasswordRule', $src, basename($file) . ' 应引用 PasswordRule');
            $this->assertStringNotContainsString('(?=.*[a-z])', $src, basename($file) . ' 不应内联密码正则');
        }
    }
}
