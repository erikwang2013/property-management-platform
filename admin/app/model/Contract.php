<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class Contract extends BaseModel
{
    protected $table = 'erik_contract';

    protected $fillable = [
        'contract_number', 'contract_type',
        'party_a_type', 'party_a_id',
        'party_b_type', 'party_b_id',
        'title', 'amount',
        'start_date', 'end_date', 'sign_date',
        'content', 'attachments', 'status',
    ];

    protected $casts = [
        'contract_type' => 'integer',
        'party_a_type'  => 'integer',
        'party_a_id'    => 'integer',
        'party_b_type'  => 'integer',
        'party_b_id'    => 'integer',
        'amount'        => 'decimal:2',
        'status'        => 'integer',
        'start_date'    => 'date',
        'end_date'      => 'date',
        'sign_date'     => 'date',
        'created_at'    => 'datetime',
        'updated_at'    => 'datetime',
    ];
}
