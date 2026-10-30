<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

/**
 * @property int $id
 * @property string $order_number
 * @property int $bill_id
 * @property string $amount
 * @property string $credited_amount
 * @property string $refund_amount
 * @property string $refund_request_id
 * @property string $channel
 * @property int $status
 */
class PaymentOrder extends BaseModel
{
    protected $table = 'management_payment_order';

    protected $fillable = [
        'order_number', 'bill_id', 'user_id', 'user_type', 'amount', 'credited_amount',
        'channel', 'trade_no', 'status', 'paid_at', 'refund_at',
        'refund_amount', 'refund_request_id', 'notify_data', 'expire_at',
    ];

    protected $casts = [
        'bill_id'         => 'integer',
        'user_id'         => 'integer',
        'user_type'       => 'integer',
        'amount'          => 'decimal:2',
        'credited_amount' => 'decimal:2',
        'status'          => 'integer',
        'refund_amount'   => 'decimal:2',
        'notify_data'     => 'json',
        'paid_at'         => 'datetime',
        'refund_at'       => 'datetime',
        'expire_at'       => 'datetime',
        'created_at'      => 'datetime',
        'updated_at'      => 'datetime',
    ];
}
