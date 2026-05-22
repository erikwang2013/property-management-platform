<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
declare(strict_types=1);
namespace app\model;

class GreenMaintenance extends BaseModel
{
    protected $table = 'erik_green_maintenance';
    protected $fillable = ['area_id', 'maintenance_type', 'staff_id', 'description', 'cost', 'maintained_at'];
    protected $casts = [
        'maintenance_type' => 'integer', 'cost' => 'decimal:2',
        'maintained_at' => 'datetime', 'created_at' => 'datetime',
    ];
    public function area() { return $this->belongsTo(GreenArea::class, 'area_id'); }
}
