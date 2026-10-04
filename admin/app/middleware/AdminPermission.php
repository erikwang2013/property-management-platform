<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\middleware;

use app\model\AdminUser;
use support\Redis;
use support\Request;
use Webman\Http\Response;
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

        // 用「注册路由模式」而非运行时 path：种子按不带参数的逻辑路径写
        // （如 put.admin/complaint/handle），模式里才有 {hashid} 占位可剥；
        // 运行时 path 里是真 hashid（/admin/complaint/DLB7n94aMkMe/handle），剥不出参数段。
        // 未匹配到路由对象（理论上不会走到这里）时退回 path，保持旧行为。
        $route = $request->route;
        // 类型即 Webman\Route\Route（vendor Route.php 已有 getPath），直接调用即可
        $pattern = $route ? $route->getPath() : '';

        $requiredPermission = $this->resolvePermission($method, $pattern !== '' ? $pattern : $path, $permissions);

        if (!in_array($requiredPermission, $permissions, true)) {
            return json(['code' => 403, 'message' => '无权限访问', 'data' => []]);
        }

        return $next($request);
    }

    /**
     * 解析请求所需的权限 slug：先剥掉路由参数段（{hashid} 等），再逐级前缀回退。
     * $path 传注册路由模式（如 /admin/complaint/{hashid}/handle）时效果最好。
     * 返回最终候选（命中的 slug 或已耗尽的短前缀），由调用方判断是否在权限列表内。
     */
    private function resolvePermission(string $method, string $path, array $permissions): string
    {
        // 剥参数段的理由：不剥直接回退只会从右往左砍，参数段在中间时砍不到种子
        // （put.admin/complaint/{hashid}/handle → put.admin/complaint/{hashid}
        //  → put.admin/complaint，两级都未种）→ 403。
        $segments = array_filter(
            explode('/', trim($path, '/')),
            static fn (string $segment): bool => $segment !== '' && !str_starts_with($segment, '{')
        );
        $required = strtolower($method) . '.' . implode('/', $segments);

        // 再逐级去掉末尾段做前缀回退，直到命中或只剩方法名（如 get.admin/user/{id} → get.admin/user）
        while (!in_array($required, $permissions, true) && str_contains($required, '/')) {
            $required = substr($required, 0, (int) strrpos($required, '/'));
        }

        return $required;
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
