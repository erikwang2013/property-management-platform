<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\middleware\SecurityFilter;
use PHPUnit\Framework\TestCase;
use ReflectionMethod;

class SecurityFilterTest extends TestCase
{
    private static function scanValue(string $value): ?string
    {
        $method = new ReflectionMethod(SecurityFilter::class, 'scan');
        $method->setAccessible(true);
        return $method->invoke(new SecurityFilter(), $value);
    }

    public function test_scan_detects_xss(): void
    {
        $this->assertSame('XSS', self::scanValue('<script>alert(1)</script>'));
        $this->assertSame('XSS', self::scanValue('{{template injection}}'));
    }

    public function test_scan_detects_sql_injection(): void
    {
        $this->assertSame('SQL注入', self::scanValue("' OR 1=1 --"));
        $this->assertSame('SQL注入', self::scanValue('UNION ALL SELECT id FROM users'));
        $this->assertSame('SQL注入', self::scanValue('DROP TABLE erik_fee_bill'));
    }

    public function test_scan_detects_path_traversal(): void
    {
        $this->assertSame('路径遍历', self::scanValue('/etc/passwd'));
        $this->assertSame('路径遍历', self::scanValue('/boot.ini'));
        $this->assertSame('路径遍历', self::scanValue('a%00b'));
    }

    public function test_scan_detects_command_injection(): void
    {
        $this->assertSame('命令注入', self::scanValue('; ls -la'));
        $this->assertSame('命令注入', self::scanValue('`id`'));
        $this->assertSame('命令注入', self::scanValue('$(whoami)'));
    }

    public function test_scan_detects_malicious_upload(): void
    {
        $this->assertSame('恶意文件上传', self::scanValue('shell.php.png'));
        $this->assertSame('恶意文件上传', self::scanValue('evil.php'));
    }

    public function test_scan_clean_input_returns_null(): void
    {
        $this->assertNull(self::scanValue('正常的业主姓名与描述 123'));
        $this->assertNull(self::scanValue('hello world'));
        $this->assertNull(self::scanValue(''));
    }
}
