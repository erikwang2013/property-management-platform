<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
declare(strict_types=1);
namespace app\model;

class ParkingSpace extends BaseModel
{
    protected $table = 'erik_parking_space';
    protected $fillable = ['community_id', 'space_number', 'space_type', 'area', 'status', 'fee_monthly'];
    protected $casts = [
        'space_type' => 'integer', 'area' => 'decimal:2', 'status' => 'integer',
        'fee_monthly' => 'decimal:2', 'created_at' => 'datetime', 'updated_at' => 'datetime',
    ];
    public function vehicles() { return $this->hasMany(ParkingVehicle::class, 'space_id'); }
}
