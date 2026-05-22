<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class InspectionTask extends BaseModel
{
    protected $table = 'erik_inspection_task';

    protected $fillable = [
        'community_id', 'title', 'task_type', 'route_points', 'checkpoints',
        'assigned_to', 'scheduled_date', 'status', 'started_at', 'completed_at',
    ];

    protected $casts = [
        'community_id'   => 'integer',
        'task_type'      => 'integer',
        'route_points'   => 'json',
        'checkpoints'    => 'json',
        'assigned_to'    => 'integer',
        'scheduled_date' => 'date',
        'status'         => 'integer',
        'started_at'     => 'datetime',
        'completed_at'   => 'datetime',
        'created_at'     => 'datetime',
        'updated_at'     => 'datetime',
    ];
}
