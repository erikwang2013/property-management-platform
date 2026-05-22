<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class FeeBill extends BaseModel
{
    protected $table = 'erik_fee_bill';

    protected $fillable = [
        'room_id', 'owner_id', 'fee_type_id', 'bill_number',
        'amount', 'paid_amount', 'late_fee',
        'start_date', 'end_date', 'due_date',
        'status', 'paid_at', 'remark',
    ];

    protected $casts = [
        'room_id'     => 'integer',
        'owner_id'    => 'integer',
        'fee_type_id' => 'integer',
        'amount'      => 'decimal',
        'paid_amount' => 'decimal',
        'late_fee'    => 'decimal',
        'status'      => 'integer',
        'start_date'  => 'date',
        'end_date'    => 'date',
        'due_date'    => 'date',
        'paid_at'     => 'datetime',
        'created_at'  => 'datetime',
        'updated_at'  => 'datetime',
    ];

    public function feeType()
    {
        return $this->belongsTo(FeeType::class);
    }

    public function room()
    {
        return $this->belongsTo(Room::class);
    }

    public function payments()
    {
        return $this->hasMany(FeePayment::class, 'bill_id');
    }
}
