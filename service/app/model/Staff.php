<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
declare(strict_types=1);
namespace app\model;
use Erikwang2013\Encryptable\Encryptable;

class Staff extends BaseModel
{
    protected $table = 'erik_staff';
    protected $fillable = ['community_id', 'name', 'phone', 'id_card', 'job_title', 'department', 'hire_date', 'salary', 'status'];
    protected $casts = [
        'department' => 'integer', 'status' => 'integer',
        'hire_date' => 'date',
        'created_at' => 'datetime', 'updated_at' => 'datetime',
        'phone' => Encryptable::class, 'id_card' => Encryptable::class, 'salary' => Encryptable::class,
    ];
}
