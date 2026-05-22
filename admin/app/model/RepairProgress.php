<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class RepairProgress extends BaseModel
{
    protected $table = 'erik_repair_progress';

    protected $fillable = [
        'repair_order_id', 'staff_id', 'status_from',
        'status_to', 'remark', 'images',
    ];

    protected $casts = [
        'repair_order_id' => 'integer',
        'staff_id'        => 'integer',
        'images'          => 'json',
        'created_at'      => 'datetime',
        'updated_at'      => 'datetime',
    ];
}
