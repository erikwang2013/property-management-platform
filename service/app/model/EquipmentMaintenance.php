<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
declare(strict_types=1);
namespace app\model;

class EquipmentMaintenance extends BaseModel
{
    protected $table = 'erik_equipment_maintenance';
    protected $fillable = ['equipment_id', 'maintenance_type', 'description', 'staff_id', 'cost', 'company', 'started_at', 'completed_at', 'result', 'next_at'];
    protected $casts = [
        'maintenance_type' => 'integer', 'cost' => 'decimal:2',
        'started_at' => 'datetime', 'completed_at' => 'datetime', 'next_at' => 'date',
        'created_at' => 'datetime', 'updated_at' => 'datetime',
    ];
    public function equipment() { return $this->belongsTo(Equipment::class, 'equipment_id'); }
}
