<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
declare(strict_types=1);
namespace app\model;
use Erikwang2013\Encryptable\Encryptable;

class Contract extends BaseModel
{
    protected $table = 'erik_contract';
    protected $fillable = ['community_id', 'owner_id', 'room_id', 'contract_number', 'contract_type', 'title', 'content', 'start_date', 'end_date', 'amount', 'status', 'signed_at', 'remark'];
    protected $casts = [
        'contract_type' => 'integer', 'amount' => 'decimal:2', 'status' => 'integer',
        'start_date' => 'date', 'end_date' => 'date', 'signed_at' => 'datetime',
        'created_at' => 'datetime', 'updated_at' => 'datetime',
        'content' => Encryptable::class,
    ];
}
