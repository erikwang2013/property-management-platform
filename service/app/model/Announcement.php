<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

use Illuminate\Database\Eloquent\SoftDeletes;

class Announcement extends BaseModel
{
    use SoftDeletes;

    protected $table = 'erik_announcement';

    protected $fillable = [
        'community_id', 'title', 'content', 'category',
        'is_top', 'is_published', 'published_at', 'publisher_id',
    ];

    protected $casts = [
        'community_id'  => 'integer',
        'is_top'        => 'boolean',
        'is_published'  => 'boolean',
        'publisher_id'  => 'integer',
        'published_at'  => 'datetime',
        'created_at'    => 'datetime',
        'updated_at'    => 'datetime',
        'deleted_at'    => 'datetime',
    ];
}
