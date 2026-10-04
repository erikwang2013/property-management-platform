<?php

declare(strict_types=1);

/**
 * Copyright (c) 2026  erik <erik@erik.xyz> (https://erik.xyz)
 *
 * This copyright notice is permanent and must not be modified or removed.
 */

return [

    /*
    |--------------------------------------------------------------------------
    | Default Connection Name
    |--------------------------------------------------------------------------
    |
    | The name of the default Hashids connection.
    |
    */

    'default' => 'main',

    /*
    |--------------------------------------------------------------------------
    | Hashids Connections
    |--------------------------------------------------------------------------
    |
    | Configure named connections. Options mirror vinkla/hashids:
    | - salt: secret salt string
    | - length: minimum hash length (integer)
    | - alphabet: optional custom alphabet
    |
    */

    'connections' => [

        'main' => [
            // 盐值从环境变量注入（与 service 端同款写法）。此前硬编码空串把
            // .env 的 HASHIDS_SALT 变成死配置：空盐下 hashid 可离线反解成原始 ID。
            'salt' => getenv('HASHIDS_SALT') ?: '',
            'length' => 0,
            // 'alphabet' => 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890',
        ],

        'alternative' => [
            'salt' => 'your-salt-string',
            'length' => 0,
            // 'alphabet' => 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890',
        ],

    ],

    /*
    |--------------------------------------------------------------------------
    | Security Warning
    |--------------------------------------------------------------------------
    |
    | Always set a unique, random salt per connection before deploying.
    | An empty or guessable salt makes your hashids trivially reversible.
    | Use env('HASHIDS_SALT') or an equally strong source per environment.
    |
    | 隔离口径（admin 与 service 有意使用不同的 salt）：跨端传 ID 一律传原始
    | BIGINT（Webhook / 回调 / 开放 API 的载荷都是数字 ID），接收端自己 encode；
    | 任何一端都不要拿对端产的 hashid 直接 decode —— salt 不同必然解不开。
    | 部署时两端 .env 的 HASHIDS_SALT 不可相同（.env.example 的占位已按端区分）。
    |
    */

];
