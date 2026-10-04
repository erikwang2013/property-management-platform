<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

/**
 * 把 webman-scout 的 helpers.php 挪到自动加载文件列表的末尾。
 *
 * 背景：scout 的 helpers.php 给「无框架宿主」（Yii2 等）提供 config()/base_path()/app() 等
 * polyfill，webman 框架的 helpers.php 也定义同名函数，两边都是 `function_exists` 保护 —— 谁先
 * 加载谁赢。Composer 生成的顺序里 scout 排在 workerman/webman-framework 之前，config() 被 scout
 * 的版本遮蔽而返回 null：框架 bootstrap、插件 bootstrap（DB 连接等）全部拿不到配置，
 * 服务起不来、DB 相关测试整片跳过。scout 自身的 polyfill 就是按「宿主框架优先」写的，
 * 把它排到最后即恢复该优先级。
 *
 * 由 composer.json 的 post-autoload-dump 触发（dump-autoload / install / update 后都会跑），
 * 因此新 clone + composer install 后顺序即为正确，不再依赖手工改 vendor。
 *
 * 两个文件都要改：运行时（autoload_real.php）读的是 autoload_static.php 的 $files，
 * autoload_files.php 只是兼容副本（部分工具会读），两者必须同序。
 *
 * 幂等：顺序已正确时不重写文件。`composer install --no-scripts` 会跳过本脚本，顺序即回坏。
 */
const SCOUT_NEEDLE = 'webman-scout/helpers.php';

/**
 * 在 $file 的 $marker 开头的数组块内，把 scout 条目移到该数组末尾。
 *
 * @return bool|null true=有改动 false=本来就对 null=结构不识别
 */
function reorderScoutEntry(string $file, string $marker): ?bool
{
    if (!is_file($file)) {
        return null;
    }

    $lines = file($file, FILE_IGNORE_NEW_LINES);
    if ($lines === false) {
        return null;
    }

    $start = null;
    $end = null;
    foreach ($lines as $i => $line) {
        if ($start === null) {
            if (str_contains($line, $marker)) {
                $start = $i;
            }
            continue;
        }
        if (trim($line) === ');') {
            $end = $i;
            break;
        }
    }
    if ($start === null || $end === null) {
        return null;
    }

    $scout = null;
    $block = [];
    for ($i = $start + 1; $i < $end; $i++) {
        if (str_contains($lines[$i], SCOUT_NEEDLE)) {
            $scout ??= $lines[$i];
            continue;
        }
        $block[] = $lines[$i];
    }
    if ($scout === null) {
        return false; // scout 未安装 / 已换结构，无遮蔽风险
    }

    // 已在末尾 ⇒ 无改动
    if ($lines[$end - 1] === $scout) {
        return false;
    }

    array_splice($lines, $start + 1, $end - $start - 1, [...$block, $scout]);
    if (file_put_contents($file, implode("\n", $lines) . "\n") === false) {
        fwrite(STDERR, "[fix-autoload-order] 写入失败：$file\n");
        exit(1);
    }

    return true;
}

$composerDir = __DIR__ . '/../vendor/composer';
$targets = [
    $composerDir . '/autoload_static.php' => 'public static $files = array',
    $composerDir . '/autoload_files.php' => 'return array(',
];

$changed = [];
foreach ($targets as $file => $marker) {
    $result = reorderScoutEntry($file, $marker);
    if ($result === null) {
        // autoload_files.php 缺失说明 dump 尚未跑（本脚本由 post-autoload-dump 触发，不应发生）；
        // 结构不识别则说明 Composer 改了生成格式，此时顺序无法保证，必须显式失败
        if (is_file($file)) {
            fwrite(STDERR, "[fix-autoload-order] 无法识别的生成格式，顺序未修复：$file\n");
            exit(1);
        }
        continue;
    }
    if ($result) {
        $changed[] = basename($file);
    }
}

// 复验：运行时真正读取的 autoload_static.php 里，scout 必须是 $files 的最后一条
$staticFile = $composerDir . '/autoload_static.php';
if (is_file($staticFile)) {
    $lines = file($staticFile, FILE_IGNORE_NEW_LINES) ?: [];
    $lastEntry = null;
    $inBlock = false;
    foreach ($lines as $line) {
        if (!$inBlock) {
            $inBlock = str_contains($line, 'public static $files = array');
            continue;
        }
        if (trim($line) === ');') {
            break;
        }
        if (trim($line) !== '') {
            $lastEntry = $line;
        }
    }
    if ($lastEntry === null || !str_contains($lastEntry, SCOUT_NEEDLE)) {
        fwrite(STDERR, "[fix-autoload-order] 复验失败：scout 不在加载末尾，config() 仍会被遮蔽\n");
        exit(1);
    }
}

if ($changed !== []) {
    fwrite(STDOUT, '[fix-autoload-order] 已把 webman-scout/helpers.php 移到末尾：' . implode('、', $changed) . "\n");
}
