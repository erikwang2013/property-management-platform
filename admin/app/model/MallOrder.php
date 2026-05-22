<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

use Erikwang2013\Encryptable\Encryptable;

class MallOrder extends BaseModel
{
    protected $table = 'erik_mall_order';

    protected $fillable = [
        'order_number', 'owner_id', 'product_id', 'quantity', 'amount',
        'status', 'address', 'contact_phone', 'express_company',
        'express_number', 'paid_at', 'shipped_at', 'completed_at', 'remark',
    ];

    protected $casts = [
        'owner_id'       => 'integer',
        'product_id'     => 'integer',
        'quantity'       => 'integer',
        'amount'         => 'decimal:2',
        'status'         => 'integer',
        'contact_phone'  => Encryptable::class,
        'paid_at'        => 'datetime',
        'shipped_at'     => 'datetime',
        'completed_at'   => 'datetime',
        'created_at'     => 'datetime',
        'updated_at'     => 'datetime',
    ];

    public function product()
    {
        return $this->belongsTo(MallProduct::class, 'product_id');
    }
}
