<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
declare(strict_types=1);
namespace app\model;

class Activity extends BaseModel
{
    protected $table = 'erik_activity';
    protected $fillable = ['community_id', 'title', 'description', 'cover_image', 'location', 'start_time', 'end_time', 'max_signup', 'signup_count', 'status'];
    protected $casts = [
        'community_id' => 'integer', 'max_signup' => 'integer', 'signup_count' => 'integer', 'status' => 'integer',
        'start_time' => 'datetime', 'end_time' => 'datetime',
        'created_at' => 'datetime', 'updated_at' => 'datetime',
    ];
    public function community() { return $this->belongsTo(Community::class); }
    public function signups() { return $this->hasMany(ActivitySignup::class, 'activity_id'); }
}
