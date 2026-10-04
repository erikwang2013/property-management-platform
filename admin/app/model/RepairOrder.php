<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

use Erikwang2013\Encryptable\Encryptable;

class RepairOrder extends BaseModel
{
    protected $table = 'management_repair_order';

    protected $fillable = [
        'id', 'order_number', 'room_id', 'owner_id', 'contact_phone',
        'category', 'urgency', 'description', 'images',
        'scheduled_at', 'status', 'staff_id',
        'completed_at', 'rating', 'feedback',
    ];

    protected $casts = [
        'contact_phone' => Encryptable::class,
        'room_id'       => 'integer',
        'owner_id'      => 'integer',
        'category'      => 'integer',
        'urgency'       => 'integer',
        'status'        => 'integer',
        'staff_id'      => 'integer',
        'rating'        => 'integer',
        'images'        => 'json',
        'scheduled_at'  => 'datetime',
        'completed_at'  => 'datetime',
        'created_at'    => 'datetime',
        'updated_at'    => 'datetime',
    ];

    public function room()
    {
        return $this->belongsTo(Room::class);
    }

    public function progress()
    {
        return $this->hasMany(RepairProgress::class);
    }

    /**
     * 维修人员（派单对象）
     *
     * 注意：`staff_id` 列存的是**原始数字 ID**（`assign` 收 hashid 后解码存入），
     * 对外输出时由控制器编码为 hashid（见 RepairController::index/show）。
     */
    public function staff()
    {
        return $this->belongsTo(Staff::class);
    }
}
