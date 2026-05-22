<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class FinanceExpense extends BaseModel
{
    protected $table = 'erik_finance_expense';

    protected $fillable = [
        'expense_number', 'expense_type', 'amount',
        'payee', 'expense_date', 'operator_id',
        'receipt_url', 'remark',
    ];

    protected $casts = [
        'expense_type' => 'integer',
        'amount'       => 'decimal:2',
        'operator_id'  => 'integer',
        'expense_date' => 'date',
        'created_at'   => 'datetime',
        'updated_at'   => 'datetime',
    ];
}
