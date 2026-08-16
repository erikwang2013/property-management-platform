<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace tests;

use app\common\Tenant;
use app\middleware\AdminAuth;
use app\middleware\TenantContext;
use app\model\TenantScope;
use Erikwang2013\Jwt\JWTFactory;
use PHPUnit\Framework\TestCase;
use RuntimeException;
use support\Request;

/**
 * 多租户越权防护测试矩阵（DB-free）：
 * 上下文栈 / fail-closed / 中间件注入链 / JWT 租户声明 / 装配结构
 */
class MultiTenantTest extends TestCase
{
    // ============ 1. Tenant 上下文栈 ============

    public function test_tenant_context_roundtrip(): void
    {
        $this->assertNull(Tenant::current());
        $result = Tenant::for(1001, function () {
            $this->assertSame(1001, Tenant::current());
            return 'ok';
        });
        $this->assertSame('ok', $result);
        $this->assertNull(Tenant::current(), '闭包结束必须还原上下文');
    }

    public function test_tenant_context_nested_and_exception_restores(): void
    {
        Tenant::for(1, function () {
            Tenant::for(2, fn() => $this->assertSame(2, Tenant::current()));
            $this->assertSame(1, Tenant::current(), '嵌套内层结束还原到外层');
        });
        try {
            Tenant::for(3, function () {
                throw new RuntimeException('boom');
            });
        } catch (RuntimeException) {
        }
        $this->assertNull(Tenant::current(), '异常路径也必须还原上下文');
    }

    public function test_tenant_without_sets_platform(): void
    {
        Tenant::without(fn() => $this->assertSame(0, Tenant::current()));
        $this->assertNull(Tenant::current());
    }

    // ============ 2. fail-closed：无上下文拒绝查询 ============

    public function test_tenant_scope_fail_closed_without_context(): void
    {
        $this->assertNull(Tenant::current());
        $this->expectException(RuntimeException::class);
        TenantScope::tenantIdOrThrow();
    }

    public function test_tenant_scope_decision_logic(): void
    {
        // 租户管理员 → 返回自身租户 ID（作用域过滤依据）
        Tenant::for(7, fn() => $this->assertSame(7, TenantScope::tenantIdOrThrow()));
        // 平台管理员(0) → 旁路放行
        Tenant::without(fn() => $this->assertSame(0, TenantScope::tenantIdOrThrow()));
    }

    // ============ 3. 中间件注入链 ============

    public function test_tenant_context_middleware_wraps_request(): void
    {
        $request = new Request('GET', '/admin/community');
        $request->tenantId = 5; // AdminAuth 注入的租户声明
        $response = (new TenantContext())->process($request, function () {
            $this->assertSame(5, Tenant::current(), '控制器执行期间应持有租户上下文');
            return response('ok');
        });
        $this->assertSame('ok', $response->rawBody());
        $this->assertNull(Tenant::current(), '请求结束必须还原');
    }

    public function test_tenant_context_middleware_platform_bypass(): void
    {
        $request = new Request('GET', '/admin/community');
        $request->tenantId = 0;
        (new TenantContext())->process($request, function () {
            $this->assertSame(0, Tenant::current());
            return response('ok');
        });
    }

    // ============ 4. JWT 租户声明全链路（登录签发 → AdminAuth 注入） ============

    public function test_admin_auth_injects_tenant_id_from_jwt(): void
    {
        $jwt = JWTFactory::createFromConfig(config('plugin.erikwang2013.jwt.jwt', []));
        $token = $jwt->encode(['sub' => 42, 'username' => 'tester', 'tenant_id' => 8]);

        $request = $this->makeRequest($token);
        (new AdminAuth())->process($request, function (Request $req) {
            $this->assertSame(8, $req->tenantId);
            return response('ok');
        });
    }

    public function test_admin_auth_legacy_token_defaults_to_platform(): void
    {
        // 升级前签发的旧 token 无 tenant_id 声明 → 平台(0)，重新登录后生效
        $jwt = JWTFactory::createFromConfig(config('plugin.erikwang2013.jwt.jwt', []));
        $token = $jwt->encode(['sub' => 42, 'username' => 'legacy']);

        $request = $this->makeRequest($token);
        (new AdminAuth())->process($request, function (Request $req) {
            $this->assertSame(0, $req->tenantId);
            return response('ok');
        });
    }

    /** Workerman Request 构造器只接收原始 HTTP buffer，需拼完整请求头 */
    private function makeRequest(string $token): Request
    {
        $buffer = "GET /admin/community HTTP/1.1\r\nAuthorization: Bearer {$token}\r\nHost: localhost\r\n\r\n";
        return new Request($buffer);
    }

    // ============ 5. 装配结构（与既有测试风格一致，防接线回归） ============

    public function test_tenant_context_middleware_wired_in_admin_group(): void
    {
        $source = file_get_contents(__DIR__ . '/../config/route.php');
        $this->assertStringContainsString('app\middleware\TenantContext::class', $source);
    }

    public function test_community_model_has_tenant_scope_and_auto_assign(): void
    {
        $source = file_get_contents(__DIR__ . '/../app/model/Community.php');
        $this->assertStringContainsString('addGlobalScope(new TenantScope())', $source);
        $this->assertStringContainsString('creating', $source);
        // tenant_id 禁止入 fillable（防批量赋值伪造租户）
        $fillableStart = strpos($source, '$fillable');
        $fillableBlock = substr($source, $fillableStart, strpos($source, '];', $fillableStart) - $fillableStart);
        $this->assertStringNotContainsString("'tenant_id'", $fillableBlock);
    }

    public function test_schema_and_migration_have_tenant_columns(): void
    {
        $sql = (string) file_get_contents(dirname(__DIR__, 2) . '/docs/install.sql');
        $this->assertStringContainsString('CREATE TABLE IF NOT EXISTS `erik_platform_tenant`', $sql);
        $this->assertMatchesRegularExpression('/CREATE TABLE IF NOT EXISTS `erik_community`.*?`tenant_id` BIGINT UNSIGNED NOT NULL DEFAULT 0/s', $sql);
        $this->assertMatchesRegularExpression('/CREATE TABLE IF NOT EXISTS `erik_admin_user`.*?`tenant_id` BIGINT UNSIGNED NOT NULL DEFAULT 0/s', $sql);
        $this->assertStringContainsString('INSERT IGNORE INTO `erik_platform_tenant`', $sql);

        $migration = (string) file_get_contents(__DIR__ . '/../database/migrations/2026_08_16_000006_multi_tenant.sql');
        $this->assertStringContainsString('erik_platform_tenant', $migration);
        $this->assertStringContainsString('UPDATE `erik_community` SET `tenant_id` = 1 WHERE `tenant_id` = 0', $migration);
        $this->assertStringContainsString('UPDATE `erik_admin_user` SET `tenant_id` = 1 WHERE `tenant_id` = 0', $migration);
    }

    public function test_login_and_refresh_carry_tenant_claim(): void
    {
        $source = file_get_contents(__DIR__ . '/../app/api/v1/controller/AuthController.php');
        $this->assertStringContainsString("'tenant_id' => (int) (\$user->tenant_id ?? 0)", $source);
        $this->assertStringContainsString("'tenant_id' => \$tenantId", $source);
    }
}
