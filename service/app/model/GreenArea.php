<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
declare(strict_types=1);
namespace app\model;

class GreenArea extends BaseModel
{
    protected $table = 'erik_green_area';
    protected $fillable = ['community_id', 'name', 'location', 'area', 'plant_types', 'responsible_staff', 'sort', 'status'];
    protected $casts = [
        'area' => 'decimal:2', 'sort' => 'integer', 'status' => 'integer',
        'created_at' => 'datetime', 'updated_at' => 'datetime',
    ];
    public function maintenances() { return $this->hasMany(GreenMaintenance::class, 'area_id'); }
}
