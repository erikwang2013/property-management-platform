<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
declare(strict_types=1);
namespace app\model;

class FinanceExpense extends BaseModel
{
    protected $table = 'erik_finance_expense';
    protected $fillable = ['community_id', 'category', 'amount', 'pay_method', 'payee', 'transaction_date', 'remark', 'status', 'approval_status'];
    protected $casts = [
        'amount' => 'decimal:2', 'category' => 'integer', 'pay_method' => 'integer',
        'status' => 'integer', 'approval_status' => 'integer',
        'transaction_date' => 'date', 'created_at' => 'datetime', 'updated_at' => 'datetime',
    ];
}
