<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class Notification extends BaseModel
{
    protected $table = 'erik_notification';

    protected $fillable = [
        'user_id', 'user_type', 'template_id', 'title', 'content',
        'type', 'channel', 'is_read', 'read_at', 'ref_type', 'ref_id',
    ];

    protected $casts = [
        'user_id'     => 'integer',
        'user_type'   => 'integer',
        'template_id' => 'integer',
        'type'        => 'integer',
        'is_read'     => 'integer',
        'ref_id'      => 'integer',
        'read_at'     => 'datetime',
        'created_at'  => 'datetime',
    ];
}
