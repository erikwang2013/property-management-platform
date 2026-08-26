<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\common\TransTrait;
use PHPUnit\Framework\TestCase;

class TransTraitTest extends TestCase
{
    private function makeController(): object
    {
        return new class {
            use TransTrait;

            public function t(string $key, array $replace = []): string
            {
                return $this->__($key, $replace);
            }
        };
    }

    public function test_translated_key_returns_translation(): void
    {
        $this->assertSame('操作成功', $this->makeController()->t('success'));
    }

    public function test_missing_key_returns_key_itself(): void
    {
        $this->assertSame('non.existent.key.xyz', $this->makeController()->t('non.existent.key.xyz'));
    }

    public function test_replace_params_are_substituted(): void
    {
        $this->assertSame('操作成功', $this->makeController()->t('success', ['x' => 1]));
        $this->assertSame('non.existent.key.xyz', $this->makeController()->t('non.existent.key.xyz', ['a' => 'b']));
    }
}
