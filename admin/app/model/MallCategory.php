<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class MallCategory extends BaseModel
{
    protected $table = 'erik_mall_category';

    protected $fillable = [
        'name', 'icon', 'sort', 'status',
    ];

    protected $casts = [
        'sort'       => 'integer',
        'status'     => 'integer',
        'created_at' => 'datetime',
    ];
}
