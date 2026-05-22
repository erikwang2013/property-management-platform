<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class Unit extends BaseModel
{
    protected $table = 'erik_unit';
    protected $fillable = ['building_id', 'name', 'room_count_per_floor', 'sort'];
    protected $casts = [
        'room_count_per_floor' => 'integer', 'sort' => 'integer',
        'created_at' => 'datetime', 'updated_at' => 'datetime',
    ];
    public function building() { return $this->belongsTo(Building::class, 'building_id'); }
}
