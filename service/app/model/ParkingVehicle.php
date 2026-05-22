<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
declare(strict_types=1);
namespace app\model;
use Erikwang2013\Encryptable\Encryptable;

class ParkingVehicle extends BaseModel
{
    protected $table = 'erik_parking_vehicle';
    protected $fillable = ['owner_id', 'space_id', 'plate_number', 'vehicle_brand', 'vehicle_color', 'vehicle_type', 'start_date', 'end_date', 'status'];
    protected $casts = [
        'vehicle_type' => 'integer', 'status' => 'integer',
        'start_date' => 'date', 'end_date' => 'date',
        'created_at' => 'datetime', 'updated_at' => 'datetime',
        'plate_number' => Encryptable::class,
    ];
    public function space() { return $this->belongsTo(ParkingSpace::class, 'space_id'); }
}
