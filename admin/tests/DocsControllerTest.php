<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\admin\controller\DocsController;
use PHPUnit\Framework\TestCase;
use ReflectionMethod;
use support\Request;

/**
 * OpenAPI 文档端点测试
 * DOCS_ENABLED 控制开关：关闭时 404（含 HTTP 状态码），开启时输出完整 OpenAPI 3.0 规范
 */
class DocsControllerTest extends TestCase
{
    protected function tearDown(): void
    {
        // 恢复环境变量，避免污染其他测试
        putenv('DOCS_ENABLED');
    }

    private static function buildSpec(): array
    {
        $ref = new ReflectionMethod(DocsController::class, 'buildSpec');
        $ref->setAccessible(true);
        return $ref->invoke(new DocsController());
    }

    public function test_disabled_returns_http_404(): void
    {
        putenv('DOCS_ENABLED=0');
        $resp = (new DocsController())->index(new Request('', 'GET'));
        $this->assertSame(404, $resp->getStatusCode());
        $body = json_decode($resp->rawBody(), true);
        $this->assertSame(404, $body['code']);
    }

    public function test_enabled_returns_openapi_spec(): void
    {
        putenv('DOCS_ENABLED=1');
        $resp = (new DocsController())->index(new Request('', 'GET'));
        $this->assertSame(200, $resp->getStatusCode());
        $spec = json_decode($resp->rawBody(), true);
        $this->assertSame('3.0.3', $spec['openapi']);
        $this->assertSame('开放管理后台 API', $spec['info']['title']);
        $this->assertSame('erik@erik.xyz', $spec['info']['contact']['email']);
        $this->assertNotEmpty($spec['paths']);
    }

    public function test_spec_security_schemes_only_bearer(): void
    {
        $spec = self::buildSpec();
        $schemes = $spec['components']['securitySchemes'] ?? [];
        $this->assertSame('http', $schemes['bearerAuth']['type']);
        $this->assertSame('bearer', $schemes['bearerAuth']['scheme']);
        // 版本在路由中体现，不应再有 API-Version 头安全方案
        $this->assertArrayNotHasKey('apiVersion', $schemes);
        $this->assertSame([['bearerAuth' => []]], $spec['security']);
    }

    public function test_spec_paths_carry_url_version(): void
    {
        $spec = self::buildSpec();
        $paths = array_keys($spec['paths'] ?? []);
        $this->assertContains('/api/v1/auth/login', $paths);
        $this->assertContains('/api/v1/captcha/generate', $paths);
        $this->assertNotContains('/api/auth/login', $paths);
    }

    public function test_spec_servers_use_configured_base_url(): void
    {
        $spec = self::buildSpec();
        $this->assertSame('http://localhost:8787', $spec['servers'][0]['url']);
    }

    public function test_spec_contains_core_schemas(): void
    {
        $spec = self::buildSpec();
        $schemas = $spec['components']['schemas'] ?? [];
        foreach (['ApiResponse', 'User', 'Role'] as $name) {
            $this->assertArrayHasKey($name, $schemas, "缺少 schema {$name}");
        }
        $this->assertSame('integer', $schemas['ApiResponse']['properties']['code']['type']);
    }
}
