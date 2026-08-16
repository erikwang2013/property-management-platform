<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

/**
 * 数据库敏感字段加解密配置
 * 用于数据持久层的字段加解密，与接口传输层加密（encryption）是独立的密钥体系
 * @link https://github.com/erikwang2013/encryptable
 */
$key = getenv('ENCRYPTABLE_KEY') ?: '';
if ($key === '' || str_starts_with($key, 'change-me')) {
    throw new RuntimeException('ENCRYPTABLE_KEY 未配置或仍为占位符，请在 .env 中配置 32 字节随机密钥（勿与 ENCRYPTION_KEY 共用）');
}

return [
    // 数据库加密密钥，生产环境请使用 32 字节随机字符串并通过环境变量注入
    'key' => $key,

    // 加密算法，推荐 AES-256-CBC
    'cipher' => getenv('ENCRYPTABLE_CIPHER') ?: 'AES-256-CBC',
];
