<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

use Illuminate\Database\Eloquent\Model;

class BaseModel extends Model
{
    public $incrementing = false;
    protected $keyType = 'int';
}
