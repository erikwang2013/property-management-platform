<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\common\Definitions;
use PHPUnit\Framework\TestCase;
use ReflectionClass;

class DefinitionsTest extends TestCase
{
    public function test_apidoc_definition_methods_exist(): void
    {
        $ref = new ReflectionClass(Definitions::class);
        foreach (['pagination', 'searchParams', 'dateRange', 'passwordConfirm', 'deletedResponse'] as $method) {
            $this->assertTrue($ref->hasMethod($method), "缺少 Apidoc 定义方法 {$method}");
        }
    }

    public function test_pagination_annotations_describe_page_params(): void
    {
        $doc = (string) (new ReflectionClass(Definitions::class))->getMethod('pagination')->getDocComment();
        $this->assertStringContainsString('Apidoc\Param("page"', $doc);
        $this->assertStringContainsString('Apidoc\Param("page_size"', $doc);
    }

    public function test_annotation_methods_are_empty_noop(): void
    {
        $definitions = new Definitions();
        $this->assertNull($definitions->pagination());
        $this->assertNull($definitions->searchParams());
        $this->assertNull($definitions->dateRange());
        $this->assertNull($definitions->passwordConfirm());
        $this->assertNull($definitions->deletedResponse());
    }
}
