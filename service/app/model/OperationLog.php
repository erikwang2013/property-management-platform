<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

use Illuminate\Database\Eloquent\Model;

class OperationLog extends Model
{
    protected $table = 'erik_operation_log';
    protected $primaryKey = 'id';
    public $incrementing = false;
    public $timestamps = false;
    protected $keyType = 'int';

    protected $fillable = ['user_id', 'action', 'method', 'path', 'ip', 'source', 'input'];
    protected $casts = ['user_id' => 'integer'];
}
