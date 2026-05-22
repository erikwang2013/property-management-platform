<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
declare(strict_types=1);
namespace app\model;
use Erikwang2013\Encryptable\Encryptable;

class Visitor extends BaseModel
{
    protected $table = 'erik_visitor';
    protected $fillable = ['room_id', 'owner_id', 'visitor_name', 'visitor_phone', 'visitor_id_card', 'plate_number', 'visitor_count', 'purpose', 'expected_start', 'expected_end', 'actual_start', 'actual_end', 'pass_code', 'status'];
    protected $casts = [
        'visitor_count' => 'integer', 'status' => 'integer',
        'expected_start' => 'datetime', 'expected_end' => 'datetime',
        'actual_start' => 'datetime', 'actual_end' => 'datetime',
        'created_at' => 'datetime', 'updated_at' => 'datetime',
        'visitor_phone' => Encryptable::class, 'visitor_id_card' => Encryptable::class, 'plate_number' => Encryptable::class,
    ];
}
