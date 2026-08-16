<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class FeePayment extends BaseModel
{
    protected $table = 'erik_fee_payment';

    protected $fillable = [
        'bill_id', 'owner_id', 'payment_number', 'amount',
        'payment_method', 'payment_channel', 'paid_at',
        'operator_id', 'receipt_url', 'remark',
    ];

    protected $casts = [
        'bill_id'     => 'integer',
        'owner_id'    => 'integer',
        'amount'      => 'decimal:2',
        'paid_at'     => 'datetime',
        'operator_id' => 'integer',
        'created_at'  => 'datetime',
        'updated_at'  => 'datetime',
    ];

    public function bill()
    {
        return $this->belongsTo(FeeBill::class, 'bill_id');
    }
}
