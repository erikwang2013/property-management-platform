<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\validate;

/**
 * 管理员密码唯一规则源 —— 登录 / 注册 / 建号 / 改密 / 导入 / 安装向导共用同一正则与长度区间。
 *
 * 背景：登录校验（AuthController::login）对提交密码强校验本规则，任何入口放宽
 * （如 min:6、零校验）都会造出「能建号、永远登不上」的账号（2026-10 修复）。
 * 新增密码入口一律引用本类；PasswordRuleTest 会扫描源码，内联副本会被判红。
 */
final class PasswordRule
{
    public const MIN_LENGTH = 8;
    public const MAX_LENGTH = 32;

    /** 8-32 位 + 至少一个大写、一个小写、一个数字、一个特殊字符(@$!%*?&)，字符集受限 */
    public const REGEX = '/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$/';

    /** validator() 用规则串（必填 + 长度 + 复杂度，与登录接口历史口径一致） */
    public static function ruleString(): string
    {
        return 'required|string|min:' . self::MIN_LENGTH . '|max:' . self::MAX_LENGTH . '|regex:' . self::REGEX;
    }

    /** 非 validator 路径（导入/安装向导）用：通过返回 null，否则返回中文错误 */
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
