<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
declare(strict_types=1);
namespace app\model;

class Complaint extends BaseModel
{
    protected $table = 'erik_complaint';
    protected $fillable = ['owner_id', 'room_id', 'type', 'category', 'title', 'content', 'images', 'is_anonymous', 'status', 'handler_id', 'handler_remark', 'handled_at', 'visitor_id', 'visitor_remark', 'visitor_at', 'satisfaction'];
    protected $casts = [
        'type' => 'integer', 'category' => 'integer', 'is_anonymous' => 'integer',
        'status' => 'integer', 'satisfaction' => 'integer',
        'handled_at' => 'datetime', 'visitor_at' => 'datetime',
        'created_at' => 'datetime', 'updated_at' => 'datetime',
    ];
}
