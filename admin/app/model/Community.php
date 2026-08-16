<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

use app\common\Tenant;
use Illuminate\Database\Eloquent\SoftDeletes;

class Community extends BaseModel
{
    use SoftDeletes;

    protected $table = 'erik_community';

    // tenant_id 不入 fillable：禁止批量赋值伪造租户归属
    protected $fillable = [
        'name', 'address', 'province', 'city', 'district',
        'area_total', 'building_count', 'room_count',
        'developer', 'property_company', 'contact_phone',
        'description', 'status',
    ];

    protected $casts = [
        'area_total'     => 'decimal',
        'building_count' => 'integer',
        'room_count'     => 'integer',
        'status'         => 'integer',
        'tenant_id'      => 'integer',
        'created_at'     => 'datetime',
        'updated_at'     => 'datetime',
        'deleted_at'     => 'datetime',
    ];

    protected static function booted(): void
    {
        static::addGlobalScope(new TenantScope());
        // 新建时自动归属当前租户，避免漏挂 tenant_id 成为平台级数据
        static::creating(function (self $model) {
            if (Tenant::current() !== null) {
                $model->tenant_id = Tenant::current();
            }
        });
    }
}
