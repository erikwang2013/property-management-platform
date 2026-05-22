<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
declare(strict_types=1);
namespace app\model;

class FinanceIncome extends BaseModel
{
    protected $table = 'erik_finance_income';
    protected $fillable = ['community_id', 'room_id', 'owner_id', 'fee_type_id', 'amount', 'pay_method', 'transaction_date', 'remark', 'status'];
    protected $casts = [
        'amount' => 'decimal:2', 'pay_method' => 'integer', 'status' => 'integer',
        'transaction_date' => 'date', 'created_at' => 'datetime', 'updated_at' => 'datetime',
    ];
}
