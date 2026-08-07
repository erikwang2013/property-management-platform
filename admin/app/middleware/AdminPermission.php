<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\middleware;

use app\model\AdminUser;
use support\Redis;
use support\Request;
use support\Response;
use support\Log;

class AdminPermission
{
    private const CACHE_TTL = 60; // 权限缓存 60 秒

    public function process(Request $request, callable $next): Response
    {
        $adminId = $request->adminId ?? 0;
        if (!$adminId) {
            return $next($request);
        }

        $path = $request->path();
        $method = $request->method();

        $permissions = $this->getUserPermissions($adminId);

        if (in_array('*', $permissions)) {
            return $next($request);
        }

        // 带参数的路径（如 /admin/user/{id}）无法与 seed 中的资源级 slug 精确匹配，
        // 逐级去掉末尾段做前缀回退，直到命中或只剩方法名（如 get.admin/user/{id} → get.admin/user）
        $requiredPermission = strtolower($method) . '.' . trim($path, '/');
        while (!in_array($requiredPermission, $permissions, true) && str_contains($requiredPermission, '/')) {
            $requiredPermission = substr($requiredPermission, 0, (int) strrpos($requiredPermission, '/'));
        }

        if (!in_array($requiredPermission, $permissions, true)) {
            return json(['code' => 403, 'message' => '无权限访问', 'data' => []]);
        }

        return $next($request);
    }

    private function getUserPermissions(int $adminId): array
    {
        // Redis 缓存，避免每请求 N+1 查询
        $cacheKey = "perm:{$adminId}";
        try {
            $cached = Redis::get($cacheKey);
            if ($cached) {
                return json_decode($cached, true);
            }
        } catch (\Throwable $e) {
            Log::error('Redis unavailable, skip permission cache read: ' . $e->getMessage());
        }

        $user = AdminUser::find($adminId);
        if (!$user) return [];

        $permissions = [];
        foreach ($user->roles as $role) {
            if ($role->status === 0) continue;
            foreach ($role->permissions as $perm) {
                $permissions[] = $perm->slug;
            }
        }
        $permissions = array_unique($permissions);

        try {
            Redis::setex($cacheKey, self::CACHE_TTL, json_encode($permissions));
        } catch (\Throwable $e) {
            Log::error('Redis unavailable, skip permission cache write: ' . $e->getMessage());
        }

        return $permissions;
    }
}
