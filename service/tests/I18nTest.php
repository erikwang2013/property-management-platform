<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use PHPUnit\Framework\TestCase;

class I18nTest extends TestCase
{
    /**
     * RED: 验证中文翻译文件存在且包含必要键
     */
    public function testChineseTranslationFileExists(): void
    {
        $path = __DIR__ . '/../resource/translations/zh_CN/messages.php';
        $this->assertFileExists($path, '中文翻译文件应存在');

        $messages = require $path;
        $this->assertIsArray($messages, '翻译文件应返回数组');

        $requiredKeys = ['success', 'fail', 'not_found', 'unauthorized',
            'auth.login_success', 'auth.credentials_wrong', 'auth.captcha_wrong',
            'community.name_required', 'fee.pay_success', 'repair.submit_success'];

        foreach ($requiredKeys as $key) {
            $this->assertArrayHasKey($key, $messages, "翻译文件应包含键: {$key}");
        }
    }

    /**
     * RED: 验证英文翻译文件存在且包含必要键
     */
    public function testEnglishTranslationFileExists(): void
    {
        $path = __DIR__ . '/../resource/translations/en/messages.php';
        $this->assertFileExists($path, '英文翻译文件应存在');

        $messages = require $path;
        $this->assertIsArray($messages, '翻译文件应返回数组');

        $requiredKeys = ['success', 'fail', 'not_found', 'unauthorized',
            'auth.login_success', 'auth.credentials_wrong',
            'community.name_required', 'fee.pay_success', 'repair.submit_success'];

        foreach ($requiredKeys as $key) {
            $this->assertArrayHasKey($key, $messages, "翻译文件应包含键: {$key}");
        }
    }

    /**
     * RED: 验证中英文翻译键一致
     */
    public function testAllLocaleFilesHaveSameKeys(): void
    {
        $zh = require __DIR__ . '/../resource/translations/zh_CN/messages.php';
        $en = require __DIR__ . '/../resource/translations/en/messages.php';

        $zhKeys = array_keys($zh);
        $enKeys = array_keys($en);

        $missingInEn = array_diff($zhKeys, $enKeys);
        $missingInZh = array_diff($enKeys, $zhKeys);

        $this->assertEmpty($missingInEn, '中文键在英文中缺失: ' . implode(', ', $missingInEn));
        $this->assertEmpty($missingInZh, '英文键在中文中缺失: ' . implode(', ', $missingInZh));
    }
}
