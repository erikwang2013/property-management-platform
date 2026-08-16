<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

use Illuminate\Database\Eloquent\SoftDeletes;

class Room extends BaseModel
{
    use SoftDeletes;

    protected $table = 'erik_room';

    protected $fillable = [
        'community_id', 'building_id', 'unit_id', 'room_number',
        'floor', 'room_type_id', 'area_indoor', 'area_shared',
        'area_total', 'orientation', 'decoration', 'usage_type',
        'status', 'remark',
    ];

    protected $casts = [
        'community_id'  => 'integer',
        'building_id'   => 'integer',
        'unit_id'       => 'integer',
        'floor'         => 'integer',
        'room_type_id'  => 'integer',
        'area_indoor'   => 'decimal:2',
        'area_shared'   => 'decimal:2',
        'area_total'    => 'decimal:2',
        'status'        => 'integer',
        'created_at'    => 'datetime',
        'updated_at'    => 'datetime',
        'deleted_at'    => 'datetime',
    ];

    public function community()
    {
        return $this->belongsTo(Community::class);
    }

    public function owners()
    {
        return $this->belongsToMany(Owner::class, 'erik_room_owner', 'room_id', 'owner_id');
    }
}
