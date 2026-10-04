<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;

use app\common\HashidsService;
use app\common\SnowflakeService;
use app\exception\InvalidResourceIdException;
use app\model\AdminUser;
use InvalidArgumentException;
use support\Request;
use support\Response;

/**
 * 管理端基础控制器
 * 提供统一响应格式、ID编解码、snowflake ID 生成
 */
class BaseController
{
    /**
     * 成功响应
     */
    protected function success($data = [], string $message = 'success', int $code = 0): Response
    {
        return json(['code' => $code, 'message' => $message, 'data' => $data]);
    }

    /**
     * 失败响应
     */
    protected function fail(string $message = 'fail', int $code = 500, $data = []): Response
    {
        return json(['code' => $code, 'message' => $message, 'data' => $data]);
    }

    /**
     * 将模型 ID 编码为 hashid 字符串
     */
    protected function encodeId(int $id): string
    {
        return HashidsService::encode($id);
    }

    /**
     * 将 hashid 字符串解码为原始 ID
     *
     * 非法/旧盐字符串转 InvalidResourceIdException（自带 render() → 干净 422），
     * 不再以 500 暴露异常类名与栈路径。
     */
    protected function decodeId(string $hashid): int
    {
        try {
            return HashidsService::decode($hashid);
        } catch (InvalidArgumentException) {
            throw new InvalidResourceIdException('无效的资源 ID');
        }
    }

    /**
     * 批量编码数组中的 ID 字段
     */
    protected function encodeIds(array $data, array $idFields = ['id']): array
    {
        return HashidsService::encodeIds($data, $idFields);
    }

    /**
     * 批量把请求里的外键 hashid 解码为原始 ID（与 encodeIds 对称）。
     * 契约：读响应里 encodeId 出去的外键，写路径必须在本处解码——
     * 客户端送回的就是 hashid，直写 BIGINT 列会 1366 / 落垃圾值。
     * 只处理数组里实际存在的键（更新时未传的字段不能凭空补 null）。
     */
    protected function decodeIds(array $data, array $idFields = []): array
    {
        foreach ($idFields as $field) {
            if (!array_key_exists($field, $data) || $data[$field] === '' || $data[$field] === null) {
                continue;
            }
            $data[$field] = $this->decodeId((string) $data[$field]);
        }
        return $data;
    }

    /**
     * 生成新的 snowflake ID
     */
    protected function generateId(): int
    {
        return SnowflakeService::generate();
    }

    /**
     * 二次确认 — 验证当前登录用户密码
     * 敏感操作（删除、导出等）调用此方法确认身份
     *
     * @param int $adminId 当前登录用户 ID
     * @param string $password 用户输入的密码
     * @return string|null 错误消息，null 表示验证通过
     */
    protected function confirmPassword(int $adminId, string $password, Request $request): ?string
    {
        if (empty($password)) {
            return '敏感操作需要输入密码确认';
        }

        $admin = AdminUser::find($adminId);
        if (!$admin || !password_verify($password, $admin->password)) {
            return '密码验证失败';
        }

        return null; // 验证通过
    }
}
