<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

use Erikwang2013\Encryptable\Encryptable;

class Group extends BaseModel
{
    protected $table = 'erik_group';

    protected $fillable = [
        'name', 'contact_person', 'contact_phone', 'description', 'status',
    ];

    protected $casts = [
        'status'        => 'integer',
        'contact_phone' => Encryptable::class,
        'created_at'    => 'datetime',
        'updated_at'    => 'datetime',
    ];
}
