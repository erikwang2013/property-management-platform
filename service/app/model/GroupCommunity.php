<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class GroupCommunity extends BaseModel
{
    protected $table = 'erik_group_community';

    protected $fillable = [
        'group_id', 'community_id',
    ];

    protected $casts = [
        'group_id'     => 'integer',
        'community_id' => 'integer',
        'created_at'   => 'datetime',
    ];
}
