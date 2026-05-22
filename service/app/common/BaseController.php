<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\common;

use app\model\Owner;
use support\Request;
use support\Response;

/**
 * 业务端基础控制器
 * 提供统一响应格式、ID编解码、业主身份验证
 */
class BaseController
{
    /**
     * 成功响应
     *
     * @param array|object $data 响应数据
     * @param string $message 提示消息
     * @param int $code 状态码，0 表示成功
     */
    protected function success($data = [], string $message = 'success', int $code = 0): Response
    {
        return json(['code' => $code, 'message' => $message, 'data' => $data]);
    }

    /**
     * 失败响应
     *
     * @param string $message 错误消息
     * @param int $code HTTP 状态码
     */
    protected function fail(string $message = 'fail', int $code = 500, $data = []): Response
    {
        return json(['code' => $code, 'message' => $message, 'data' => $data]);
    }

    /**
     * 将 BIGINT ID 编码为 hashid 字符串
     */
    protected function encodeId(int $id): string
    {
        return HashidsService::encode($id);
    }

    /**
     * 将 hashid 字符串解码为 BIGINT ID
     */
    protected function decodeId(string $hashid): int
    {
        return HashidsService::decode($hashid);
    }

    /**
     * 批量编码数组中的 ID 字段
     */
    protected function encodeIds(array $data, array $idFields = ['id']): array
    {
        return HashidsService::encodeIds($data, $idFields);
    }

    /**
     * 生成新的 snowflake ID
     */
    protected function generateId(): int
    {
        return SnowflakeService::generate();
    }

    /**
     * 获取当前登录业主 ID
     */
    protected function getOwnerId(Request $request): int
    {
        return $request->ownerId ?? 0;
    }

    /**
     * 获取翻译文本
     * @param string $key 翻译键
     * @param array $replace 替换参数
     * @return string
     */
    protected function __(string $key, array $replace = []): string
    {
        $message = trans($key, $replace);
        return $message !== $key ? $message : $key;
    }

    /**
     * 密码二次确认 — 敏感操作验证
     *
     * @param int $ownerId 业主 ID
     * @param string $password 用户输入的密码
     * @return string|null null 表示验证通过，非 null 为错误消息
     */
    protected function confirmPassword(int $ownerId, string $password): ?string
    {
        if (empty($password)) {
            return '敏感操作需要输入密码确认';
        }

        $owner = Owner::find($ownerId);
        if (!$owner || !password_verify($password, $owner->password)) {
            return '密码验证失败';
        }

        return null;
    }
}
