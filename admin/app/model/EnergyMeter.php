<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
declare(strict_types=1);
namespace app\model;

class EnergyMeter extends BaseModel
{
    protected $table = 'erik_energy_meter';
    protected $fillable = ['room_id', 'meter_type', 'meter_number', 'install_reading', 'install_date', 'status'];
    protected $casts = [
        'meter_type' => 'integer', 'install_reading' => 'decimal:2', 'status' => 'integer',
        'install_date' => 'date',
        'created_at' => 'datetime', 'updated_at' => 'datetime',
    ];
    public function records() { return $this->hasMany(EnergyRecord::class, 'meter_id'); }
}
