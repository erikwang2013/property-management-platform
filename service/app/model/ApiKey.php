<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class ApiKey extends BaseModel
{
    protected $table = 'erik_api_key';

    protected $fillable = [
        'name', 'api_key_hash', 'status',
    ];

    protected $casts = [
        'status'     => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];
}
