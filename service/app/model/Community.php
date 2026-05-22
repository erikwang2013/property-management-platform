<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

use Illuminate\Database\Eloquent\SoftDeletes;

class Community extends BaseModel
{
    use SoftDeletes;

    protected $table = 'erik_community';

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
        'created_at'     => 'datetime',
        'updated_at'     => 'datetime',
        'deleted_at'     => 'datetime',
    ];
}
