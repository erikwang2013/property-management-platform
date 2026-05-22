<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class FeeType extends BaseModel
{
    protected $table = 'erik_fee_type';

    protected $fillable = [
        'name', 'category', 'unit_price', 'unit_type',
        'cycle_type', 'is_required', 'sort',
    ];

    protected $casts = [
        'unit_price' => 'decimal',
        'sort'       => 'integer',
        'is_required' => 'boolean',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function bills()
    {
        return $this->hasMany(FeeBill::class);
    }
}
