<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class VoteOption extends BaseModel
{
    protected $table = 'erik_vote_option';

    protected $fillable = [
        'vote_id', 'content', 'sort', 'vote_count', 'area_weighted_count',
    ];

    protected $casts = [
        'vote_id'            => 'integer',
        'sort'               => 'integer',
        'vote_count'         => 'integer',
        'area_weighted_count' => 'decimal:2',
        'created_at'         => 'datetime',
    ];
}
