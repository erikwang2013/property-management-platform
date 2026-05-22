<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class ApprovalRecord extends BaseModel
{
    protected $table = 'erik_approval_record';

    protected $fillable = [
        'approval_id', 'step', 'approver_id', 'action', 'remark', 'acted_at',
    ];

    protected $casts = [
        'approval_id' => 'integer',
        'step'        => 'integer',
        'approver_id' => 'integer',
        'action'      => 'integer',
        'acted_at'    => 'datetime',
        'created_at'  => 'datetime',
    ];
}
