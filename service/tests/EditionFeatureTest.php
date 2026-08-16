<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);
namespace tests;
use PHPUnit\Framework\TestCase;

class EditionFeatureTest extends TestCase
{
    private const LEVELS = ['lite' => 1, 'standard' => 2, 'full' => 3];

    public function test_edition_supports_ladder(): void
    {
        // 测试 bootstrap 不加载 route.php（webman 约定：路由由 Route::load 加载），此处按需加载
        if (!function_exists('edition_supports')) {
            \Webman\Route::load([config_path()]);
        }
        $this->assertTrue(function_exists('edition_supports'));

        foreach (self::LEVELS as $current => $level) {
            $this->setEdition($current);
            foreach (self::LEVELS as $min => $minLevel) {
                $expect = $minLevel <= $level;
                $this->assertSame(
                    $expect,
                    edition_supports($min),
                    "edition {$current} should " . ($expect ? '' : 'not ') . "support {$min}"
                );
            }
        }
    }

    public function test_edition_config_fail_fast(): void
    {
        $source = file_get_contents(__DIR__ . '/../config/edition.php');
        $this->assertStringContainsString('RuntimeException', $source);
        $this->assertStringContainsString('EDITIONS', $source);
    }

    public function test_edition_route_gates_registered(): void
    {
        $source = file_get_contents(__DIR__ . '/../config/route.php');
        $this->assertStringContainsString("edition_supports('standard')", $source);
        $this->assertStringContainsString("edition_supports('full')", $source);
    }

    /** webman config 只读，测试通过反射临时替换 config 值并清除缓存 */
    private function setEdition(string $default): void
    {
        $ref = new \ReflectionProperty(\Webman\Config::class, 'config');
        $config = $ref->getValue();
        $config['edition'] = ['default' => $default, 'levels' => self::LEVELS];
        $ref->setValue(null, $config);
        (new \ReflectionProperty(\Webman\Config::class, 'flatCache'))->setValue(null, []);
    }
}
