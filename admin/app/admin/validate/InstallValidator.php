<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\validate;

class InstallValidator
{
    /**
     * 校验数据库连接配置，返回错误消息列表（空数组表示通过）。
     */
    public static function validateDbConfig(array $db): array
    {
        $errors = [];
        if ($db['host'] === '') $errors[] = '请输入数据库主机地址';
        if ($db['port'] === '' || !ctype_digit($db['port'])) $errors[] = '请输入有效的端口号';
        if ($db['database'] === '') $errors[] = '请输入数据库名';
        if ($db['username'] === '') $errors[] = '请输入数据库用户名';
        return $errors;
    }

    /**
     * 校验管理员账户配置，返回错误消息列表（空数组表示通过）。
     */
    public static function validateAdminConfig(array $admin, string $confirm): array
    {
        $errors = [];
        if (mb_strlen($admin['admin_username']) < 3) $errors[] = '管理员用户名至少3个字符';
        // 密码强度与登录校验保持一致：8-32 位 + 大小写字母 + 数字 + 特殊字符
        if (strlen($admin['admin_password']) < 8 || strlen($admin['admin_password']) > 32) {
            $errors[] = '管理员密码长度需 8-32 位';
        }
        if (!preg_match('/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$/', $admin['admin_password'])) {
            $errors[] = '管理员密码需包含大小写字母、数字和特殊字符(@$!%*?&)';
        }
        if ($admin['admin_password'] !== $confirm) $errors[] = '两次输入的密码不一致';
        return $errors;
    }
}
