<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class MallProduct extends BaseModel
{
    protected $table = 'erik_mall_product';

    protected $fillable = [
        'category_id', 'community_id', 'name', 'description', 'images',
        'price', 'original_price', 'stock', 'sales', 'is_recommend', 'status',
    ];

    protected $casts = [
        'category_id'    => 'integer',
        'community_id'   => 'integer',
        'images'         => 'json',
        'price'          => 'decimal:2',
        'original_price' => 'decimal:2',
        'stock'          => 'integer',
        'sales'          => 'integer',
        'is_recommend'   => 'integer',
        'status'         => 'integer',
        'created_at'     => 'datetime',
        'updated_at'     => 'datetime',
    ];
}
