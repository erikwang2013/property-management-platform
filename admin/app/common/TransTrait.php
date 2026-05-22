<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\common;

/**
 * 国际化翻译 trait
 * 控制器 use 此 trait 后可使用 $this->__() 获取翻译文本
 */
trait TransTrait
{
    /**
     * 获取翻译文本
     * @param string $key 翻译键
     * @param array $replace 替换参数
     * @return string
     */
    protected function __(string $key, array $replace = []): string
    {
        $message = trans($key, $replace);
        // 如果翻译结果与 key 相同说明没有对应翻译，返回 key 本身（中文原生消息或降级）
        return $message !== $key ? $message : $key;
    }
}
