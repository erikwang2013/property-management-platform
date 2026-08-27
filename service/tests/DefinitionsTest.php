<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\common\Definitions;
use PHPUnit\Framework\TestCase;

class DefinitionsTest extends TestCase
{
    public function test_class_and_doc_methods_exist(): void
    {
        $this->assertTrue(class_exists(Definitions::class));
        foreach (['pagination', 'searchParams', 'dateRange', 'passwordConfirm'] as $method) {
            $this->assertTrue(method_exists(Definitions::class, $method), "方法 {$method} 应存在");
        }
    }

    public function test_methods_carry_apidoc_annotations(): void
    {
        $doc = (new \ReflectionMethod(Definitions::class, 'passwordConfirm'))->getDocComment();
        $this->assertIsString($doc);
        $this->assertStringContainsString('@Apidoc\Param', $doc);
    }
}
