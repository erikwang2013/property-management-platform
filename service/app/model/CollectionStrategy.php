<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class CollectionStrategy extends BaseModel
{
    protected $table = 'erik_collection_strategy';

    protected $fillable = [
        'name', 'overdue_days', 'action', 'template_id',
        'late_fee_rate', 'sort', 'status',
    ];

    protected $casts = [
        'overdue_days'  => 'integer',
        'action'        => 'integer',
        'template_id'   => 'integer',
        'late_fee_rate' => 'decimal:3',
        'sort'          => 'integer',
        'status'        => 'integer',
        'created_at'    => 'datetime',
    ];
}
