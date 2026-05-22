<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class Approval extends BaseModel
{
    protected $table = 'erik_approval';

    protected $fillable = [
        'approval_type_id', 'title', 'applicant_id', 'applicant_type',
        'ref_type', 'ref_id', 'current_step', 'status', 'remark', 'completed_at',
    ];

    protected $casts = [
        'approval_type_id' => 'integer',
        'applicant_id'     => 'integer',
        'applicant_type'   => 'integer',
        'ref_id'           => 'integer',
        'current_step'     => 'integer',
        'status'           => 'integer',
        'completed_at'     => 'datetime',
        'created_at'       => 'datetime',
        'updated_at'       => 'datetime',
    ];
}
