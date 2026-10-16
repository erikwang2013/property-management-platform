<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\common;

/**
 * 业主密码唯一规则源 —— 注册 / 改密共用同一正则与长度区间（与 admin 端 PasswordRule 同口径）。
 *
 * 背景：改密口曾只查「至少6位」，比注册口（8-32 + 复杂度）宽松，能把自己降级成弱密码
 * （2026-10 修复）。新增密码入口一律引用本类；PasswordRuleTest 会扫描源码防内联副本。
 */
final class PasswordRule
{
    public const MIN_LENGTH = 8;
    public const MAX_LENGTH = 32;

    /** 8-32 位 + 至少一个大写、一个小写、一个数字、一个特殊字符(@$!%*?&)，字符集受限 */
    public const REGEX = '/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$/';

    /** 通过返回 null，否则返回中文错误（与注册接口历史文案一致） */
    public static function check(string $password): ?string
    {
        if (strlen($password) < self::MIN_LENGTH || strlen($password) > self::MAX_LENGTH) {
            return '密码长度 8-32 位';
        }
        if (!preg_match(self::REGEX, $password)) {
            return '密码需包含大小写字母、数字和特殊字符(@$!%*?&)';
        }
        return null;
    }
}
