#!/usr/bin/env php
<?php

/**
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 *
 * 签发压测用 JWT（绕过验证码登录直接签发），供 k6 脚本使用
 *
 * 用法:
 *   php mint-token.php                      # 输出到 stdout
 *   php mint-token.php --uid=21000000000000100 --username=erik --file=/tmp/pmp-token
 */

$uid = 21000000000000100;      // erik（压测管理员账号，按环境调整）
$username = 'erik';
$file = null;
for ($i = 1; $i < count($argv); $i++) {
    if (str_starts_with($argv[$i], '--uid=')) {
        $uid = (int) substr($argv[$i], 6);
    } elseif (str_starts_with($argv[$i], '--username=')) {
        $username = substr($argv[$i], 11);
    } elseif (str_starts_with($argv[$i], '--file=')) {
        $file = substr($argv[$i], 7);
    } else {
        fwrite(STDERR, "未知参数: {$argv[$i]}\n");
        exit(1);
    }
}

require __DIR__ . '/../../admin/vendor/autoload.php';

// 加载 admin/.env 到环境变量（JWT 配置依赖 getenv）
foreach (file(__DIR__ . '/../../admin/.env', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
    if (preg_match('/^([A-Z0-9_]+)=(.*)$/', $line, $m)) {
        putenv($m[1] . '=' . $m[2]);
    }
}

$config = require __DIR__ . '/../../admin/config/plugin/erikwang2013/jwt/jwt.php';
$token = \Erikwang2013\Jwt\JWTFactory::createFromConfig($config)
    ->encode(['sub' => $uid, 'username' => $username]);

if ($file !== null) {
    file_put_contents($file, $token);
    echo "已写入 $file\n";
} else {
    echo $token . "\n";
}
