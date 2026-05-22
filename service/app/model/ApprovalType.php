<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class ApprovalType extends BaseModel
{
    protected $table = 'erik_approval_type';

    protected $fillable = [
        'code', 'name', 'steps', 'status',
    ];

    protected $casts = [
        'steps'      => 'json',
        'status'     => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];
}
