<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class ChatRecord extends BaseModel
{
    protected $table = 'erik_chat_record';

    protected $fillable = [
        'user_id', 'user_type', 'question', 'answer',
        'match_type', 'matched_kb_id', 'is_helpful',
    ];

    protected $casts = [
        'user_id'       => 'integer',
        'user_type'     => 'integer',
        'match_type'    => 'integer',
        'matched_kb_id' => 'integer',
        'is_helpful'    => 'integer',
        'created_at'    => 'datetime',
    ];
}
