<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class KnowledgeBase extends BaseModel
{
    protected $table = 'erik_knowledge_base';

    protected $fillable = [
        'category_id', 'question', 'answer', 'keywords',
        'view_count', 'helpful_count', 'sort', 'status',
    ];

    protected $casts = [
        'category_id'   => 'integer',
        'view_count'    => 'integer',
        'helpful_count' => 'integer',
        'sort'          => 'integer',
        'status'        => 'integer',
        'created_at'    => 'datetime',
        'updated_at'    => 'datetime',
    ];
}
