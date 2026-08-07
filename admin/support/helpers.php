<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

use Webman\Validation\Validator;

if (!function_exists('validator')) {
    /**
     * webman v2 移除了全局 validator() 辅助函数，此函数恢复 v1 调用约定，
     * 委托给 webman/validation 插件的静态工厂。
     */
    function validator(array $data, ?array $rules = null, ?array $messages = null, ?array $attributes = null): Validator
    {
        return Validator::make($data, $rules, $messages, $attributes);
    }
}
