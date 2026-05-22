<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class RoomOwner extends BaseModel
{
    protected $table = 'erik_room_owner';

    protected $fillable = [
        'room_id', 'owner_id', 'relation_type',
        'ownership_ratio', 'cert_number', 'start_date', 'end_date',
    ];

    protected $casts = [
        'room_id'          => 'integer',
        'owner_id'         => 'integer',
        'ownership_ratio'  => 'decimal',
        'start_date'       => 'date',
        'end_date'         => 'date',
        'created_at'       => 'datetime',
        'updated_at'       => 'datetime',
    ];
}
