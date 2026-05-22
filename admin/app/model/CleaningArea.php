<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
declare(strict_types=1);
namespace app\model;

class CleaningArea extends BaseModel
{
    protected $table = 'erik_cleaning_area';
    protected $fillable = ['community_id', 'name', 'location', 'area', 'frequency', 'responsible_staff', 'sort', 'status'];
    protected $casts = [
        'area' => 'decimal:2', 'frequency' => 'integer', 'sort' => 'integer', 'status' => 'integer',
        'created_at' => 'datetime', 'updated_at' => 'datetime',
    ];
    public function records() { return $this->hasMany(CleaningRecord::class, 'area_id'); }
}
