<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
declare(strict_types=1);
namespace app\model;

class ParkingRecord extends BaseModel
{
    protected $table = 'erik_parking_record';
    protected $fillable = ['vehicle_id', 'space_id', 'entry_time', 'exit_time', 'duration', 'fee'];
    protected $casts = ['duration' => 'integer', 'fee' => 'decimal:2', 'entry_time' => 'datetime', 'exit_time' => 'datetime', 'created_at' => 'datetime'];
    public function vehicle() { return $this->belongsTo(ParkingVehicle::class, 'vehicle_id'); }
}
