<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

/**
 * 业主手机号盲索引回填（幂等，可重复执行）
 *
 * 用法: cd admin && php ../scripts/backfill_owner_phone_hash.php
 * 前置: admin/.env 已配置数据库连接，且已执行 docs/migrations/2026-10-30-audit-fix-schema.sql
 *
 * 说明: phone 由 Encryptable 以随机 IV 加密，等值查询走 phone_hash = SHA-256(明文)。
 * 逐行解密读出手机号，仅回填 phone_hash 为空或不一致的行；空手机号跳过。
 */

declare(strict_types=1);

use app\model\Owner;

$baseDir = getenv('APP_BASE_PATH') ?: dirname(__DIR__) . '/admin';

require_once $baseDir . '/vendor/autoload.php';

if (class_exists('Dotenv\Dotenv') && file_exists($baseDir . '/.env')) {
    \Dotenv\Dotenv::createUnsafeMutable($baseDir)->load();
}

\Webman\Config::clear();
support\App::loadAllConfig(['route']);
support\bootstrap\Db::start(null);

$hash = static function (string $phone): string {
    return method_exists(Owner::class, 'phoneHash')
        ? Owner::phoneHash($phone)
        : hash('sha256', $phone);
};

$scanned = 0;
$updated = 0;
$skipped = 0;
$batch   = [];

// 分批静默保存，避免逐行触发模型事件
$flush = static function (array &$batch) use (&$updated): void {
    foreach ($batch as $owner) {
        $owner->saveQuietly();
        $updated++;
    }
    $batch = [];
};

try {
    foreach (Owner::query()->select(['id', 'phone', 'phone_hash'])->cursor() as $owner) {
        $scanned++;
        try {
            $phone = (string) ($owner->phone ?? '');
        } catch (\Throwable $e) {
            // 单行密文损坏不应中断整库回填，记录后跳过
            $skipped++;
            fwrite(STDERR, "owner_id={$owner->id} 手机号解密失败: {$e->getMessage()}\n");
            continue;
        }
        if ($phone === '') {
            $skipped++;
            continue;
        }

        $expected = $hash($phone);
        if ((string) ($owner->phone_hash ?? '') === $expected) {
            $skipped++;
            continue;
        }

        $owner->phone_hash = $expected;
        $batch[] = $owner;
        if (count($batch) >= 500) {
            $flush($batch);
        }
    }
    $flush($batch);
} catch (\Throwable $e) {
    fwrite(STDERR, "回填失败（是否已执行 docs/migrations/2026-10-30-audit-fix-schema.sql？）: {$e->getMessage()}\n");
    exit(1);
}

echo "scanned={$scanned} updated={$updated} skipped={$skipped}\n";
