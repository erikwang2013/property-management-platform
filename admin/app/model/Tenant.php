<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

use Erikwang2013\Encryptable\Encryptable;

class Tenant extends BaseModel
{
    protected $table = 'erik_tenant';

    protected $fillable = [
        'room_id', 'owner_id', 'name', 'phone', 'id_card',
        'lease_start', 'lease_end', 'rent_amount', 'status',
    ];

    protected $casts = [
        'phone'       => Encryptable::class,
        'id_card'     => Encryptable::class,
        'room_id'     => 'integer',
        'owner_id'    => 'integer',
        'rent_amount' => 'decimal',
        'status'      => 'integer',
        'lease_start' => 'date',
        'lease_end'   => 'date',
        'created_at'  => 'datetime',
        'updated_at'  => 'datetime',
    ];
}
