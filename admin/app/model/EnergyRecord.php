<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
declare(strict_types=1);
namespace app\model;

class EnergyRecord extends BaseModel
{
    protected $table = 'erik_energy_record';
    protected $fillable = ['meter_id', 'room_id', 'reading', 'previous_reading', 'usage_amount', 'unit_price', 'amount', 'record_date', 'reader_id', 'bill_id'];
    protected $casts = [
        'reading' => 'decimal:2', 'previous_reading' => 'decimal:2',
        'usage_amount' => 'decimal:2', 'unit_price' => 'decimal:2', 'amount' => 'decimal:2',
        'record_date' => 'date', 'created_at' => 'datetime',
    ];
    public function meter() { return $this->belongsTo(EnergyMeter::class, 'meter_id'); }
}
