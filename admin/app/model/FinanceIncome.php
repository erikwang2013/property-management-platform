<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class FinanceIncome extends BaseModel
{
    protected $table = 'erik_finance_income';

    protected $fillable = [
        'income_number', 'income_type', 'amount',
        'payer_type', 'payer_id', 'payment_method',
        'income_date', 'operator_id', 'remark',
    ];

    protected $casts = [
        'income_type'    => 'integer',
        'amount'         => 'decimal:2',
        'payer_type'     => 'integer',
        'payer_id'       => 'integer',
        'payment_method' => 'integer',
        'operator_id'    => 'integer',
        'income_date'    => 'date',
        'created_at'     => 'datetime',
        'updated_at'     => 'datetime',
    ];
}
