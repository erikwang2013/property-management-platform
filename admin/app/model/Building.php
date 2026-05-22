<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class Building extends BaseModel
{
    protected $table = 'erik_building';
    protected $fillable = [
        'community_id', 'name', 'building_type',
        'floor_count', 'unit_count', 'elevator_count',
        'build_year', 'structure_type', 'sort',
    ];
    protected $casts = [
        'building_type' => 'integer', 'floor_count' => 'integer',
        'unit_count' => 'integer', 'elevator_count' => 'integer',
        'sort' => 'integer',
        'created_at' => 'datetime', 'updated_at' => 'datetime',
    ];
    public function community() { return $this->belongsTo(Community::class, 'community_id'); }
    public function units() { return $this->hasMany(Unit::class, 'building_id'); }
}
