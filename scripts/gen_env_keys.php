#!/usr/bin/env php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 *
 * 生成/补齐 .env 密钥（密钥运行时随机生成，不写入代码）
 *
 * 用法:
 *   php gen_env_keys.php                # 输出全部密钥 KEY=VALUE 到 stdout
 *   php gen_env_keys.php --file=.env    # 补齐缺失键（旧密钥一律保留）
 *   php gen_env_keys.php --file=.env --replace-placeholders
 *                                       # 额外将 change-me* 占位符替换为随机密钥
 *                                       # （scripts/deploy.sh 仅在 .env 刚由模板生成时使用）
 *
 * 取值语义（「旧密钥保留」）:
 *   键缺失           → 追加生成
 *   值为 change-me*  → 默认仅告警不动；带 --replace-placeholders 时替换为随机值
 *   值为空           → 不动（可能是有意留空，如 Redis 无密码），仅告警
 *   其他（真实密钥） → 保留，绝不覆盖
 *
 * 依赖同步: ELASTIC_PASSWORD 被 SCOUT_HOSTS / OPENSEARCH_PASSWORD 内嵌引用，
 *   该密钥被替换时会同步改写这两处（仅当其中仍引用旧值/旧占位符）。
 *
 * 生成规则:
 *   ENCRYPTION_KEY         32 位 hex — API 传输加密（AES-256-CBC 需 32 字节 key）
 *   ENCRYPTABLE_KEY        32 位 hex — 数据库字段加密（与 ENCRYPTION_KEY 独立，不可共用）
 *   JWT_SECRET_KEY         96 位 hex — JWT 签名（64 位以上）
 *   HASHIDS_SALT           32 位 hex — ID 加解密
 *   HASHIDS_ALT_SALT       32 位 hex — ID 加解密备用
 *   DB_PASSWORD            32 位 hex — 数据库应用用户密码（compose 的 MYSQL_PASSWORD 默认派生自此）
 *   REDIS_PASSWORD         32 位 hex — Redis 密码（compose 内 redis-server --requirepass）
 *   ELASTIC_PASSWORD       32 位 hex — Elasticsearch elastic 用户密码
 *   MYSQL_ROOT_PASSWORD    32 位 hex — MySQL root 密码（compose 必填插值）
 *   GRAFANA_ADMIN_PASSWORD 24 位 hex — Grafana 管理员密码（compose 必填插值）
 */

$spec = [
    'ENCRYPTION_KEY'         => 16,
    'ENCRYPTABLE_KEY'        => 16,
    'JWT_SECRET_KEY'         => 48,
    'HASHIDS_SALT'           => 16,
    'HASHIDS_ALT_SALT'       => 16,
    'DB_PASSWORD'            => 16,
    'REDIS_PASSWORD'         => 16,
    'ELASTIC_PASSWORD'       => 16,
    'MYSQL_ROOT_PASSWORD'    => 16,
    'GRAFANA_ADMIN_PASSWORD' => 12,
];

/** ELASTIC_PASSWORD 的依赖键（值为内嵌了 ES 密码的整行内容） */
$esDependents = ['SCOUT_HOSTS', 'OPENSEARCH_PASSWORD'];

$file = null;
$replacePlaceholders = false;
for ($i = 1; $i < count($argv); $i++) {
    if (str_starts_with($argv[$i], '--file=')) {
        $file = substr($argv[$i], 7);
    } elseif ($argv[$i] === '--replace-placeholders') {
        $replacePlaceholders = true;
    } else {
        fwrite(STDERR, "未知参数: {$argv[$i]}（用法: php gen_env_keys.php [--file=.env] [--replace-placeholders]）\n");
        exit(1);
    }
}

/** 掩码显示：只露前 8 位 */
$mask = static fn(string $v): string => $v === '' ? '（空）' : substr($v, 0, 8) . '…';

// ── 无 --file：只输出随机密钥到 stdout ──
if ($file === null) {
    $out = [];
    foreach ($spec as $name => $bytes) {
        $out[] = "$name=" . bin2hex(random_bytes($bytes));
    }
    echo implode("\n", $out) . "\n";
    exit(0);
}

if (!is_file($file)) {
    fwrite(STDERR, "错误: 文件不存在 — $file\n");
    exit(1);
}

$lines = file($file, FILE_IGNORE_NEW_LINES);
if ($lines === false) {
    fwrite(STDERR, "错误: 无法读取 $file\n");
    exit(1);
}

/** 键 → 行号列表（同名键可能重复出现，逐行处理） */
$index = [];
foreach ($lines as $i => $line) {
    if (preg_match('/^([A-Z0-9_]+)=/', $line, $m)) {
        $index[$m[1]][] = $i;
    }
}

$valueOf = static function (string $key) use ($lines, $index): ?string {
    if (!isset($index[$key])) {
        return null;
    }
    return substr($lines[$index[$key][0]], strlen($key) + 1);
};

$changed = 0;
$kept = 0;
$warned = [];

// 记录 ES 密码变化前后的值，供依赖同步使用
$esOld = $valueOf('ELASTIC_PASSWORD');
$esNew = null;

// ── 主密钥处理 ──
foreach ($spec as $name => $bytes) {
    $current = $valueOf($name);

    if ($current !== null && !str_starts_with($current, 'change-me')) {
        if ($current === '') {
            $warned[] = "$name 为空值，未生成（如系有意留空可忽略；compose 插值要求非空）";
        } else {
            $kept++;
        }
        continue;
    }

    if ($current !== null && !$replacePlaceholders) {
        $kept++;
        $warned[] = "$name 仍是占位符（change-me），未替换；如在全新环境部署，请删除该行后重跑，或使用 --replace-placeholders";
        continue;
    }

    $new = bin2hex(random_bytes($bytes));
    if ($current === null) {
        $lines[] = "$name=$new";
        $index[$name] = [count($lines) - 1];
        echo "生成 $name=" . $mask($new) . "（追加）\n";
    } else {
        foreach ($index[$name] as $i) {
            $lines[$i] = "$name=$new";
        }
        echo "生成 $name=" . $mask($new) . "（替换占位符）\n";
    }
    $changed++;
    if ($name === 'ELASTIC_PASSWORD') {
        $esNew = $new;
    }
}

// ── ELASTIC_PASSWORD 依赖同步 ──
if ($esNew !== null) {
    foreach ($esDependents as $dep) {
        if (!isset($index[$dep])) {
            continue;
        }
        foreach ($index[$dep] as $i) {
            $line = $lines[$i];
            if ($esOld !== null && $esOld !== '' && str_contains($line, $esOld)) {
                $lines[$i] = "$dep=" . str_replace($esOld, $esNew, substr($line, strlen($dep) + 1));
                echo "同步 $dep → 引用新 ELASTIC_PASSWORD\n";
                $changed++;
            } elseif (str_contains($line, 'change-me-es-password')) {
                $lines[$i] = "$dep=" . str_replace('change-me-es-password', $esNew, substr($line, strlen($dep) + 1));
                echo "同步 $dep → 替换 ES 占位符\n";
                $changed++;
            } else {
                $warned[] = "$dep 未引用旧 ES 密码，未自动同步；确认其凭证是否仍有效";
            }
        }
    }
}

// ── 落盘（临时文件 + rename，避免部分写入） ──
if ($changed > 0) {
    $perm = fileperms($file) & 0777;
    $tmp = $file . '.tmp.' . bin2hex(random_bytes(4));
    if (@file_put_contents($tmp, implode("\n", $lines) . "\n") === false) {
        fwrite(STDERR, "错误: 无法写入 $tmp\n");
        exit(1);
    }
    @chmod($tmp, $perm ?: 0644);
    if (!@rename($tmp, $file)) {
        @unlink($tmp);
        fwrite(STDERR, "错误: 无法替换 $file\n");
        exit(1);
    }
}

echo "\n$file: 生成/替换 $changed 项，保留已有 $kept 项\n";
foreach ($warned as $w) {
    echo "  警告: $w\n";
}
exit(0);
