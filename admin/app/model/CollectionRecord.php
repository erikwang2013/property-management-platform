<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class CollectionRecord extends BaseModel
{
    protected $table = 'erik_collection_record';

    protected $fillable = [
        'bill_id', 'strategy_id', 'action', 'executed_by', 'remark', 'executed_at',
    ];

    protected $casts = [
        'bill_id'     => 'integer',
        'strategy_id' => 'integer',
        'action'      => 'integer',
        'executed_by' => 'integer',
        'executed_at' => 'datetime',
        'created_at'  => 'datetime',
    ];

    public function strategy()
    {
        return $this->belongsTo(CollectionStrategy::class, 'strategy_id');
    }
}
