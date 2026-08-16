<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
declare(strict_types=1);
namespace tests;
use PHPUnit\Framework\TestCase;
use app\admin\validate\InstallValidator;

class InstallValidatorTest extends TestCase
{
    public function test_db_valid_passes(): void
    {
        $db = ['host' => '127.0.0.1', 'port' => '3306', 'database' => 'pm', 'username' => 'root'];
        $this->assertSame([], InstallValidator::validateDbConfig($db));
    }

    public function test_db_missing_host(): void
    {
        $db = ['host' => '', 'port' => '3306', 'database' => 'pm', 'username' => 'root'];
        $this->assertContains('请输入数据库主机地址', InstallValidator::validateDbConfig($db));
    }

    public function test_db_invalid_port(): void
    {
        $db = ['host' => '127.0.0.1', 'port' => 'abc', 'database' => 'pm', 'username' => 'root'];
        $this->assertContains('请输入有效的端口号', InstallValidator::validateDbConfig($db));
    }

    public function test_db_empty_port(): void
    {
        $db = ['host' => '127.0.0.1', 'port' => '', 'database' => 'pm', 'username' => 'root'];
        $this->assertContains('请输入有效的端口号', InstallValidator::validateDbConfig($db));
    }

    public function test_db_missing_database(): void
    {
        $db = ['host' => '127.0.0.1', 'port' => '3306', 'database' => '', 'username' => 'root'];
        $this->assertContains('请输入数据库名', InstallValidator::validateDbConfig($db));
    }

    public function test_db_missing_username(): void
    {
        $db = ['host' => '127.0.0.1', 'port' => '3306', 'database' => 'pm', 'username' => ''];
        $this->assertContains('请输入数据库用户名', InstallValidator::validateDbConfig($db));
    }

    public function test_db_all_missing_collects_every_error(): void
    {
        $db = ['host' => '', 'port' => '', 'database' => '', 'username' => ''];
        $errors = InstallValidator::validateDbConfig($db);
        $this->assertCount(4, $errors);
    }

    public function test_admin_valid_passes(): void
    {
        $admin = ['admin_username' => 'admin', 'admin_password' => 'Abcdefg1@'];
        $this->assertSame([], InstallValidator::validateAdminConfig($admin, 'Abcdefg1@'));
    }

    public function test_admin_username_too_short(): void
    {
        $admin = ['admin_username' => 'ab', 'admin_password' => 'Abcdefg1@'];
        $this->assertContains('管理员用户名至少3个字符', InstallValidator::validateAdminConfig($admin, 'Abcdefg1@'));
    }

    public function test_admin_password_too_short(): void
    {
        $admin = ['admin_username' => 'admin', 'admin_password' => 'Ab1@'];
        $this->assertContains('管理员密码长度需 8-32 位', InstallValidator::validateAdminConfig($admin, 'Ab1@'));
    }

    public function test_admin_password_too_long(): void
    {
        $admin = ['admin_username' => 'admin', 'admin_password' => str_repeat('Ab1@', 9)];
        $this->assertContains('管理员密码长度需 8-32 位', InstallValidator::validateAdminConfig($admin, str_repeat('Ab1@', 9)));
    }

    public function test_admin_password_missing_uppercase(): void
    {
        $admin = ['admin_username' => 'admin', 'admin_password' => 'abcdefg1@'];
        $this->assertContains('管理员密码需包含大小写字母、数字和特殊字符(@$!%*?&)', InstallValidator::validateAdminConfig($admin, 'abcdefg1@'));
    }

    public function test_admin_password_missing_lowercase(): void
    {
        $admin = ['admin_username' => 'admin', 'admin_password' => 'ABCDEFG1@'];
        $this->assertContains('管理员密码需包含大小写字母、数字和特殊字符(@$!%*?&)', InstallValidator::validateAdminConfig($admin, 'ABCDEFG1@'));
    }

    public function test_admin_password_missing_digit(): void
    {
        $admin = ['admin_username' => 'admin', 'admin_password' => 'Abcdefg@'];
        $this->assertContains('管理员密码需包含大小写字母、数字和特殊字符(@$!%*?&)', InstallValidator::validateAdminConfig($admin, 'Abcdefg@'));
    }

    public function test_admin_password_missing_special(): void
    {
        $admin = ['admin_username' => 'admin', 'admin_password' => 'Abcdefg1'];
        $this->assertContains('管理员密码需包含大小写字母、数字和特殊字符(@$!%*?&)', InstallValidator::validateAdminConfig($admin, 'Abcdefg1'));
    }

    public function test_admin_password_with_invalid_character(): void
    {
        $admin = ['admin_username' => 'admin', 'admin_password' => 'Abcdefg1@ '];
        $this->assertContains('管理员密码需包含大小写字母、数字和特殊字符(@$!%*?&)', InstallValidator::validateAdminConfig($admin, 'Abcdefg1@ '));
    }

    public function test_admin_confirm_mismatch(): void
    {
        $admin = ['admin_username' => 'admin', 'admin_password' => 'Abcdefg1@'];
        $this->assertContains('两次输入的密码不一致', InstallValidator::validateAdminConfig($admin, 'Abcdefg1#'));
    }
}
