<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class RoomType extends BaseModel
{
    protected $table = 'erik_room_type';
    protected $fillable = ['name', 'bedrooms', 'halls', 'bathrooms', 'image'];
    protected $casts = [
        'bedrooms' => 'integer', 'halls' => 'integer', 'bathrooms' => 'integer',
        'created_at' => 'datetime', 'updated_at' => 'datetime',
    ];
}
