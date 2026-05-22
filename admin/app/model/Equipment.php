<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
declare(strict_types=1);
namespace app\model;

class Equipment extends BaseModel
{
    protected $table = 'erik_equipment';
    protected $fillable = ['community_id', 'name', 'equipment_number', 'category', 'brand', 'model', 'location', 'install_date', 'warranty_end', 'service_life', 'status'];
    protected $casts = [
        'category' => 'integer', 'service_life' => 'integer', 'status' => 'integer',
        'install_date' => 'date', 'warranty_end' => 'date',
        'created_at' => 'datetime', 'updated_at' => 'datetime',
    ];
    public function maintenances() { return $this->hasMany(EquipmentMaintenance::class, 'equipment_id'); }
}
