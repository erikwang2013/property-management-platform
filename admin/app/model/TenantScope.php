<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

use app\common\Tenant;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Scope;
use RuntimeException;

/**
 * 租户全局作用域：按 Tenant::current() 自动过滤；
 * 无上下文时抛异常（fail-closed），0 = 平台不过滤。
 */
class TenantScope implements Scope
{
    /** fail-closed：无租户上下文拒绝查询 */
    public static function tenantIdOrThrow(): int
    {
        $tenantId = Tenant::current();
        if ($tenantId === null) {
            throw new RuntimeException('缺少租户上下文（fail-closed）：请使用 Tenant::for() 或经 TenantContext 中间件');
        }
        return $tenantId;
    }

    public function apply(Builder $builder, Model $model): void
    {
        $tenantId = self::tenantIdOrThrow();
        if ($tenantId !== 0) {
            $builder->where($model->getTable() . '.tenant_id', $tenantId);
        }
    }
}
