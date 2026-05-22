<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
declare(strict_types=1);
namespace app\model;
use Erikwang2013\Encryptable\Encryptable;

class ActivitySignup extends BaseModel
{
    protected $table = 'erik_activity_signup';
    protected $fillable = ['activity_id', 'owner_id', 'participant_count', 'contact_phone', 'remark', 'signup_status', 'signup_at', 'checkin_at'];
    protected $casts = [
        'participant_count' => 'integer', 'signup_status' => 'integer',
        'signup_at' => 'datetime', 'checkin_at' => 'datetime',
        'created_at' => 'datetime',
        'contact_phone' => Encryptable::class,
    ];
    public function activity() { return $this->belongsTo(CommunityActivity::class, 'activity_id'); }
}
