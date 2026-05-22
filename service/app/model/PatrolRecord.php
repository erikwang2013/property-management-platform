<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
declare(strict_types=1);
namespace app\model;

class PatrolRecord extends BaseModel
{
    protected $table = 'erik_patrol_record';
    protected $fillable = ['patrol_id', 'staff_id', 'started_at', 'ended_at', 'duration', 'checkpoints_done', 'abnormal_note'];
    protected $casts = [
        'duration' => 'integer',
        'started_at' => 'datetime', 'ended_at' => 'datetime',
        'created_at' => 'datetime',
    ];
    public function patrol() { return $this->belongsTo(SecurityPatrol::class, 'patrol_id'); }
}
