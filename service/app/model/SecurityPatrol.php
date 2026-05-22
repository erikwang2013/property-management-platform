<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
declare(strict_types=1);
namespace app\model;

class SecurityPatrol extends BaseModel
{
    protected $table = 'erik_security_patrol';
    protected $fillable = ['community_id', 'name', 'route_points', 'checkpoints', 'sort', 'status'];
    protected $casts = [
        'sort' => 'integer', 'status' => 'integer',
        'created_at' => 'datetime', 'updated_at' => 'datetime',
    ];
    public function records() { return $this->hasMany(PatrolRecord::class, 'patrol_id'); }
}
