<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

use Erikwang2013\Encryptable\Encryptable;
use Illuminate\Database\Eloquent\SoftDeletes;

class Owner extends BaseModel
{
    use SoftDeletes;

    protected $table = 'erik_owner';

    protected $fillable = [
        'name', 'phone', 'email', 'id_card', 'password',
        'gender', 'birthday', 'emergency_contact', 'emergency_phone',
        'check_in_date', 'remark', 'status',
        'last_login_at', 'last_login_ip', 'login_failures', 'locked_until',
    ];

    protected $hidden = ['password', 'id_card'];

    protected $casts = [
        'phone'              => Encryptable::class,
        'email'              => Encryptable::class,
        'id_card'            => Encryptable::class,
        'emergency_contact'  => Encryptable::class,
        'emergency_phone'    => Encryptable::class,
        'gender'             => 'integer',
        'status'             => 'integer',
        'login_failures'     => 'integer',
        'birthday'           => 'date',
        'check_in_date'      => 'date',
        'last_login_at'      => 'datetime',
        'locked_until'       => 'datetime',
        'created_at'         => 'datetime',
        'updated_at'         => 'datetime',
        'deleted_at'         => 'datetime',
    ];

    public function rooms()
    {
        return $this->belongsToMany(Room::class, 'erik_room_owner', 'owner_id', 'room_id');
    }
}
