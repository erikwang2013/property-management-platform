<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\common;

use support\Container;
use InvalidArgumentException;
use Erikwang2013\Hashids\HashidsFactory;
use Erikwang2013\Hashids\HashidsManager;

/**
 * Hashids 编解码服务
 * 用于 API 层 ID 加解密，对外暴露 hash 字符串，隐藏真实数据库 BIGINT ID
 */
class HashidsService
{
    private static ?HashidsManager $instance = null;

    private static function manager(): HashidsManager
    {
        if (self::$instance !== null) {
            return self::$instance;
        }

        try {
            $manager = Container::get('hashids');
            if ($manager instanceof HashidsManager) {
                self::$instance = $manager;
                return self::$instance;
            }
        } catch (\Throwable) {
        }

        $config = config('hashids') ?: [
            'default' => 'main',
            'connections' => [
                'main' => [
                    'salt' => getenv('HASHIDS_SALT') ?: 'open-admin-hashids-salt-2026',
                    'length' => 16,
                    'alphabet' => 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890',
                ],
            ],
        ];
        $factory = new HashidsFactory();
        self::$instance = new HashidsManager($config, $factory);
        return self::$instance;
    }

    public static function encode(int $id): string
    {
        return self::manager()->encode($id);
    }

    public static function decode(string $hashid): int
    {
        $ids = self::manager()->decode($hashid);
        if (empty($ids)) {
            throw new InvalidArgumentException('无效的加密ID');
        }
        return (int) $ids[0];
    }

    /**
     * 批量编码数组中的 ID 字段
     */
    public static function encodeIds(array $data, array $fields = ['id']): array
    {
        foreach ($fields as $field) {
            if (isset($data[$field]) && is_numeric($data[$field])) {
                $data[$field] = self::encode((int) $data[$field]);
            }
        }
        return $data;
    }
}
