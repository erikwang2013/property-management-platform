<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class SlaRule extends BaseModel
{
    protected $table = 'erik_sla_rule';

    protected $fillable = [
        'name', 'category', 'urgency', 'response_minutes', 'resolve_minutes',
        'escalate_to_role', 'escalate_minutes', 'penalty_amount', 'status',
    ];

    protected $casts = [
        'category'         => 'integer',
        'urgency'          => 'integer',
        'response_minutes' => 'integer',
        'resolve_minutes'  => 'integer',
        'escalate_minutes' => 'integer',
        'penalty_amount'   => 'decimal:2',
        'status'           => 'integer',
        'created_at'       => 'datetime',
        'updated_at'       => 'datetime',
    ];
}
