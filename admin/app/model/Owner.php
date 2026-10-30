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

    protected $table = 'management_owner';

    protected $fillable = [
        'id', 'name', 'phone', 'phone_hash', 'email', 'id_card', 'password',
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

    /** 手机号盲索引：供等值查询，不是加密（SHA-256 摘要） */
    public static function phoneHash(string $phone): string
    {
        return hash('sha256', $phone);
    }

    public function rooms()
    {
        return $this->belongsToMany(Room::class, 'management_room_owner', 'owner_id', 'room_id');
    }
}
