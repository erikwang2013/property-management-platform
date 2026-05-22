<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class PaymentOrder extends BaseModel
{
    protected $table = 'erik_payment_order';

    protected $fillable = [
        'order_number', 'bill_id', 'user_id', 'user_type', 'amount',
        'channel', 'trade_no', 'status', 'paid_at', 'refund_at',
        'refund_amount', 'notify_data', 'expire_at',
    ];

    protected $casts = [
        'bill_id'       => 'integer',
        'user_id'       => 'integer',
        'user_type'     => 'integer',
        'amount'        => 'decimal:2',
        'status'        => 'integer',
        'refund_amount' => 'decimal:2',
        'notify_data'   => 'json',
        'paid_at'       => 'datetime',
        'refund_at'     => 'datetime',
        'expire_at'     => 'datetime',
        'created_at'    => 'datetime',
        'updated_at'    => 'datetime',
    ];
}
