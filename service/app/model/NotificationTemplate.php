<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class NotificationTemplate extends BaseModel
{
    protected $table = 'erik_notification_template';

    protected $fillable = [
        'code', 'name', 'title_template', 'content_template', 'channels', 'status',
    ];

    protected $casts = [
        'channels'   => 'json',
        'status'     => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];
}
