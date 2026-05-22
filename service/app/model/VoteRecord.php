<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class VoteRecord extends BaseModel
{
    protected $table = 'erik_vote_record';

    protected $fillable = [
        'vote_id', 'option_id', 'owner_id', 'room_id', 'area_ratio', 'voted_at',
    ];

    protected $casts = [
        'vote_id'    => 'integer',
        'option_id'  => 'integer',
        'owner_id'   => 'integer',
        'room_id'    => 'integer',
        'area_ratio' => 'decimal:2',
        'voted_at'   => 'datetime',
        'created_at' => 'datetime',
    ];
}
