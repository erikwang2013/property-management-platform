<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

use Erikwang2013\Encryptable\Encryptable;
use Erikwang2013\WebmanScout\Searchable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Webman\RedisQueue\Redis as QueueRedis;

class AdminUser extends Model
{
    use SoftDeletes;
    use Searchable;

    protected $table = 'erik_admin_user';
    protected $primaryKey = 'id';
    public $incrementing = false;
    protected $keyType = 'int';

    protected $fillable = [
        'username', 'password', 'real_name', 'avatar',
        'email', 'phone', 'id_card', 'status',
        'last_login_at', 'last_login_ip',
    ];

    protected $hidden = ['password', 'id_card'];
    protected $casts = [
        'status' => 'integer',
        'last_login_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'email' => Encryptable::class,
        'phone' => Encryptable::class,
        'id_card' => Encryptable::class,
    ];

    public function roles()
    {
        return $this->belongsToMany(AdminRole::class, 'erik_admin_user_role', 'user_id', 'role_id');
    }

    public function toSearchableArray(): array
    {
        return [
            'username'  => $this->username,
            'real_name' => $this->real_name,
        ];
    }

    // 覆写 Searchable trait：ES 不可用时同步索引写入/删除失败仅记日志，不阻塞模型保存主流程
    public function queueMakeSearchable($models)
    {
        if ($models->isEmpty()) {
            return;
        }
        try {
            if (!scout_config('queue')) {
                $this->syncMakeSearchable($models);
                return;
            }
            if (class_exists(QueueRedis::class)) {
                QueueRedis::send('scout_make', serialize($models));
            }
        } catch (\Throwable $e) {
            \support\Log::info('search_fallback', ['op' => 'make_searchable', 'error' => $e->getMessage()]);
        }
    }

    public function queueRemoveFromSearch($models)
    {
        if ($models->isEmpty()) {
            return;
        }
        try {
            if (!scout_config('queue')) {
                $this->syncRemoveFromSearch($models);
                return;
            }
            if (class_exists(QueueRedis::class)) {
                QueueRedis::send('scout_remove', serialize($models));
            }
        } catch (\Throwable $e) {
            \support\Log::info('search_fallback', ['op' => 'remove_from_search', 'error' => $e->getMessage()]);
        }
    }
}
