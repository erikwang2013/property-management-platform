<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class Vote extends BaseModel
{
    protected $table = 'erik_vote';

    protected $fillable = [
        'community_id', 'title', 'description', 'vote_type',
        'start_time', 'end_time', 'is_anonymous', 'min_participation_rate',
        'status', 'publisher_id',
    ];

    protected $casts = [
        'community_id'          => 'integer',
        'vote_type'             => 'integer',
        'is_anonymous'          => 'integer',
        'min_participation_rate' => 'decimal:2',
        'status'                => 'integer',
        'publisher_id'          => 'integer',
        'start_time'            => 'datetime',
        'end_time'              => 'datetime',
        'created_at'            => 'datetime',
        'updated_at'            => 'datetime',
    ];
}
