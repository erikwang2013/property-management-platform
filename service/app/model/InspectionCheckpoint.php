<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class InspectionCheckpoint extends BaseModel
{
    protected $table = 'erik_inspection_checkpoint';

    protected $fillable = [
        'task_id', 'checkpoint_index', 'checkpoint_name', 'latitude',
        'longitude', 'photo_url', 'status', 'remark', 'checked_at',
    ];

    protected $casts = [
        'task_id'          => 'integer',
        'checkpoint_index' => 'integer',
        'status'           => 'integer',
        'latitude'         => 'decimal:7',
        'longitude'        => 'decimal:7',
        'checked_at'       => 'datetime',
        'created_at'       => 'datetime',
    ];
}
