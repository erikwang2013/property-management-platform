<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

use Erikwang2013\Encryptable\Encryptable;

class FaceInfo extends BaseModel
{
    protected $table = 'erik_face_info';

    protected $fillable = [
        'owner_id', 'face_image', 'face_token', 'feature_data',
        'verify_status', 'verified_at',
    ];

    protected $casts = [
        'owner_id'      => 'integer',
        'verify_status' => 'integer',
        'feature_data'  => Encryptable::class,
        'verified_at'   => 'datetime',
        'created_at'    => 'datetime',
        'updated_at'    => 'datetime',
    ];
}
