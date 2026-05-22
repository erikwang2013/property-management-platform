<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
declare(strict_types=1);
namespace app\model;
use Erikwang2013\Encryptable\Encryptable;

class CommunityActivity extends BaseModel
{
    protected $table = 'erik_community_activity';
    protected $fillable = ['community_id', 'title', 'content', 'category', 'cover_image', 'location', 'max_participants', 'start_time', 'end_time', 'signup_start', 'signup_end', 'is_free', 'cost', 'organizer', 'contact_phone', 'status'];
    protected $casts = [
        'category' => 'integer', 'max_participants' => 'integer', 'is_free' => 'integer',
        'cost' => 'decimal:2', 'status' => 'integer',
        'start_time' => 'datetime', 'end_time' => 'datetime',
        'signup_start' => 'datetime', 'signup_end' => 'datetime',
        'created_at' => 'datetime', 'updated_at' => 'datetime',
        'contact_phone' => Encryptable::class,
    ];
    public function signups() { return $this->hasMany(ActivitySignup::class, 'activity_id'); }
}
