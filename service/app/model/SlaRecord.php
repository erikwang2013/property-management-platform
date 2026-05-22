<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class SlaRecord extends BaseModel
{
    protected $table = 'erik_sla_record';

    protected $fillable = [
        'repair_order_id', 'rule_id', 'response_deadline', 'resolve_deadline',
        'escalated_at', 'escalate_level', 'is_response_overtime',
        'is_resolve_overtime', 'penalty_amount',
    ];

    protected $casts = [
        'repair_order_id'     => 'integer',
        'rule_id'             => 'integer',
        'escalate_level'      => 'integer',
        'is_response_overtime' => 'integer',
        'is_resolve_overtime' => 'integer',
        'penalty_amount'      => 'decimal:2',
        'response_deadline'   => 'datetime',
        'resolve_deadline'    => 'datetime',
        'escalated_at'        => 'datetime',
        'created_at'          => 'datetime',
        'updated_at'          => 'datetime',
    ];
}
