#!/usr/bin/env php
<?php

/**
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 *
 * 生成加密密钥，输出可追加到 .env 的 KEY=VALUE 片段（密钥运行时随机生成，不写入代码）
 *
 * 用法:
 *   php gen_env_keys.php                # 输出全部 5 个密钥到 stdout
 *   php gen_env_keys.php --file=.env    # 仅追加缺失的密钥，已存在的不覆盖
 *
 * 生成规则:
 *   ENCRYPTION_KEY    32 位 hex — API 传输加密（AES-256-CBC 需 32 字节 key）
 *   ENCRYPTABLE_KEY   32 位 hex — 数据库字段加密（与 ENCRYPTION_KEY 独立，不可共用）
 *   JWT_SECRET_KEY    96 位 hex — JWT 签名（64 位以上）
 *   HASHIDS_SALT      32 位 hex — ID 加解密
 *   HASHIDS_ALT_SALT  32 位 hex — ID 加解密备用
 */

$spec = [
    'ENCRYPTION_KEY'   => 16,
    'ENCRYPTABLE_KEY'  => 16,
    'JWT_SECRET_KEY'   => 48,
    'HASHIDS_SALT'     => 16,
    'HASHIDS_ALT_SALT' => 16,
];

$file = null;
for ($i = 1; $i < count($argv); $i++) {
    if (str_starts_with($argv[$i], '--file=')) {
        $file = substr($argv[$i], 7);
    } else {
        fwrite(STDERR, "未知参数: {$argv[$i]}（用法: php gen_env_keys.php [--file=.env]）\n");
        exit(1);
    }
}

$existing = [];
if ($file !== null) {
    if (!is_file($file)) {
        fwrite(STDERR, "错误: 文件不存在 — $file\n");
        exit(1);
    }
    foreach (file($file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
        if (preg_match('/^([A-Z0-9_]+)=/', $line, $m)) {
            $existing[$m[1]] = true;
        }
    }
}

$lines = [];
foreach ($spec as $name => $bytes) {
    if (isset($existing[$name])) {
        echo "# $name 已存在，跳过\n";
        continue;
    }
    $lines[] = "$name=" . bin2hex(random_bytes($bytes));
}

if ($file === null) {
    echo implode("\n", $lines) . "\n";
    exit(0);
}

if ($lines === []) {
    echo "所有密钥均已存在，无需写入 $file\n";
    exit(0);
}

if (@file_put_contents($file, "\n" . implode("\n", $lines) . "\n", FILE_APPEND) === false) {
    fwrite(STDERR, "错误: 无法写入 $file\n");
    exit(1);
}
echo "已追加 " . count($lines) . " 个缺失密钥到 $file\n";
