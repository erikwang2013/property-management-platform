<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;
use hg\apidoc\annotation as Apidoc;

use app\model\AdminUser;
use app\common\SnowflakeService;
use support\Container;
use support\Log;
use support\Redis;
use support\Request;
use support\Response;
use Erikwang2013\Jwt\JWT;
use Erikwang2013\Jwt\JWTFactory;
use Throwable;

/**
 * 通用接口
 * @Apidoc\Group("common")
 * @Apidoc\Sort(1)
 */
class AuthController
{
    private static ?JWT $jwt = null;

    private static function getJWT(): JWT
    {
        if (self::$jwt === null) {
            $config = config('plugin.erikwang2013.jwt.jwt', []);
            self::$jwt = JWTFactory::createFromConfig($config);
        }
        return self::$jwt;
    }

    /** 归一化点击坐标为数字索引 [[x,y],...]（验证码包契约要求） */
    private function normalizeClicks(mixed $clicks): array
    {
        if (!is_array($clicks)) {
            return [];
        }
        return array_map(function ($c) {
            if (is_array($c) && isset($c[0], $c[1]) && !isset($c['x'])) {
                return [(int)$c[0], (int)$c[1]];
            }
            return [(int)($c['x'] ?? 0), (int)($c['y'] ?? 0)];
        }, $clicks);
    }

    /**
     * 登录（需先通过点击验证码）
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/api/auth/login")
     */
    public function login(Request $request): Response
    {
        $validator = validator($request->all(), [
            'username'    => 'required|string|min:3|max:50',
            'password'    => 'required|string|min:8|max:32|regex:/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$/',
            'captcha_key' => 'required|string',
            'clicks'      => 'required|array|min:2',
        ]);

        if ($validator->fails()) {
            return json(['code' => 422, 'message' => $validator->errors()->first(), 'data' => []]);
        }

        // 验证点击验证码
        if (!captcha_verify($request->input('captcha_key'), 'click', $this->normalizeClicks($request->input('clicks')))) {
            return json(['code' => 422, 'message' => '验证码错误，请重试', 'data' => []]);
        }

        // 校验用户凭证
        $username = $request->input('username');
        $user = AdminUser::where('username', $username)->first();

        // 账号锁定检查（5次失败/15分钟）
        $lockKey = "account_lock:{$username}";
        try {
            if (Redis::get($lockKey)) {
                return json(['code' => 429, 'message' => '账号已被临时锁定，请15分钟后再试', 'data' => []]);
            }
        } catch (\Throwable $e) {
            Log::error('auth_lock_check_failed', ['username' => $username, 'error' => $e->getMessage()]);
        }

        if (!$user || !password_verify($request->input('password'), $user->password)) {
            // 登录失败：计数 + 锁定
            try {
                $failKey = "login_fail:{$username}";
                $fails = Redis::incr($failKey);
                if ($fails === 1) Redis::expire($failKey, 900);
                if ($fails >= 5) {
                    Redis::setex($lockKey, 900, '1');
                    Redis::del($failKey);
                    return json(['code' => 429, 'message' => '账号已被临时锁定，请15分钟后再试', 'data' => []]);
                }
            } catch (\Throwable $e) {
                Log::error('auth_fail_count_failed', ['username' => $username, 'error' => $e->getMessage()]);
            }
            return json(['code' => 401, 'message' => '用户名或密码错误', 'data' => []]);
        }

        // 登录成功：清除失败计数
        try {
            Redis::del("login_fail:{$username}");
            Redis::del($lockKey);
        } catch (\Throwable $e) {
            Log::error('auth_fail_count_reset_failed', ['username' => $username, 'error' => $e->getMessage()]);
        }

        if ($user->status === 0) {
            return json(['code' => 403, 'message' => '账号已被禁用', 'data' => []]);
        }

        // 签发 JWT（携带租户声明，TenantContext 依此隔离）
        $jwt = self::getJWT();
        $tokenExpire = (int)(config('plugin.erikwang2013.jwt.jwt.default_expire') ?: 7200);
        $claims = ['sub' => $user->id, 'username' => $user->username, 'tenant_id' => (int) ($user->tenant_id ?? 0)];
        $token = $jwt->encode($claims);
        $refreshToken = $jwt->encode(['sub' => $user->id, 'token_type' => 'refresh', 'tenant_id' => (int) ($user->tenant_id ?? 0)],
            (int)(config('plugin.erikwang2013.jwt.jwt.refresh_expire') ?: 1209600)
        );

        // 并发会话限制
        $this->trackSession($user->id, $token, $tokenExpire);

        // 更新登录信息
        $user->last_login_at = date('Y-m-d H:i:s');
        $user->last_login_ip = $request->getRealIp();
        $user->save();

        return json([
            'code'    => 0,
            'message' => '登录成功',
            'data'    => [
                'access_token'  => $token,
                'refresh_token' => $refreshToken,
                'expires_in'    => (int)(config('plugin.erikwang2013.jwt.jwt.default_expire') ?: 7200),
                'user'          => [
                    'id'        => Container::get('hashids')->encode($user->id),
                    'username'  => $user->username,
                    'real_name' => $user->real_name,
                ],
            ],
        ]);
    }

    /**
     * 注册（需先通过点击验证码）
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/api/auth/register")
     */
    public function register(Request $request): Response
    {
        $validator = validator($request->all(), [
            'username'    => 'required|string|min:3|max:50',
            'password'    => 'required|string|min:8|max:32|regex:/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$/',
            'real_name'   => 'required|string|max:50',
            'captcha_key' => 'required|string',
            'clicks'      => 'required|array|min:2',
        ]);

        if ($validator->fails()) {
            return json(['code' => 422, 'message' => $validator->errors()->first(), 'data' => []]);
        }

        if (!captcha_verify($request->input('captcha_key'), 'click', $this->normalizeClicks($request->input('clicks')))) {
            return json(['code' => 422, 'message' => '验证码错误，请重试', 'data' => []]);
        }

        $username = $request->input('username');
        if (AdminUser::where('username', $username)->exists()) {
            return json(['code' => 422, 'message' => '用户名已存在', 'data' => []]);
        }

        $user = new AdminUser();
        $user->id = SnowflakeService::generate();
        $user->username = $username;
        $user->password = password_hash($request->input('password'), PASSWORD_BCRYPT);
        $user->real_name = $request->input('real_name');
        $user->phone = $request->input('phone', '');
        $user->email = $request->input('email', '');
        $user->status = 1;
        $user->save();

        $jwt = self::getJWT();
        $tokenExpire = (int)(config('plugin.erikwang2013.jwt.jwt.default_expire') ?: 7200);
        $token = $jwt->encode(['sub' => $user->id, 'username' => $user->username]);
        $refreshToken = $jwt->encode(['sub' => $user->id, 'token_type' => 'refresh'],
            (int)(config('plugin.erikwang2013.jwt.jwt.refresh_expire') ?: 1209600)
        );

        $this->trackSession($user->id, $token, $tokenExpire);

        return json([
            'code'    => 0,
            'message' => '注册成功',
            'data'    => [
                'access_token'  => $token,
                'refresh_token' => $refreshToken,
                'expires_in'    => (int)(config('plugin.erikwang2013.jwt.jwt.default_expire') ?: 7200),
                'user'          => [
                    'id'        => Container::get('hashids')->encode($user->id),
                    'username'  => $user->username,
                    'real_name' => $user->real_name,
                ],
            ],
        ]);
    }

    /**
     * 刷新令牌
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/api/auth/refresh")
     */
    public function refresh(Request $request): Response
    {
        $refreshToken = $request->input('refresh_token', '');

        if (empty($refreshToken)) {
            return json(['code' => 422, 'message' => '缺少刷新令牌', 'data' => []]);
        }

        try {
            $jwt = self::getJWT();
            $payload = $jwt->decode($refreshToken);

            // 刷新时更新最后登录时间和IP
            $userId = $payload['sub'] ?? 0;
            if ($userId) {
                $user = AdminUser::find($userId);
                if ($user) {
                    $user->last_login_at = date('Y-m-d H:i:s');
                    $user->last_login_ip = $request->getRealIp();
                    $user->save();
                }
            }

            $tokenExpire = (int)(config('plugin.erikwang2013.jwt.jwt.default_expire') ?: 7200);
            // 租户声明随刷新延续，防止刷新后降级为平台(0)越权
            $tenantId = (int) ($payload['tenant_id'] ?? 0);
            $token = $jwt->encode(['sub' => $payload['sub'], 'username' => $payload['username'] ?? '', 'tenant_id' => $tenantId]);
            $newRefresh = $jwt->encode(['sub' => $payload['sub'], 'token_type' => 'refresh', 'tenant_id' => $tenantId],
                (int)(config('plugin.erikwang2013.jwt.jwt.refresh_expire') ?: 1209600)
            );

            // 并发会话限制：注册新 token，移除旧 refresh token 的活跃状态
            $this->trackSession($userId, $token, $tokenExpire);
            try {
                Redis::zrem("user_tokens:{$userId}", md5($refreshToken));
            } catch (\Throwable $e) {
                Log::error('auth_session_cleanup_failed', ['user_id' => $userId, 'error' => $e->getMessage()]);
            }

            return json([
                'code'    => 0,
                'message' => 'success',
                'data'    => [
                    'access_token'  => $token,
                    'refresh_token' => $newRefresh,
                    'expires_in'    => (int)(config('plugin.erikwang2013.jwt.jwt.default_expire') ?: 7200),
                ],
            ]);
        } catch (Throwable $e) {
            return json(['code' => 401, 'message' => '刷新令牌无效或已过期', 'data' => []]);
        }
    }

    /**
     * 并发会话限制 — 同一用户最多 3 个有效 token
     * @param int $userId 用户 ID
     * @param string $token JWT access_token
     * @param int $expiresIn token 有效期（秒）
     */
    private function trackSession(int $userId, string $token, int $expiresIn): void
    {
        try {
            $key = "user_tokens:{$userId}";
            $exp = time() + $expiresIn;
            $member = md5($token);

            // 清理已过期的 token
            Redis::zremrangebyscore($key, 0, time());
            // 添加新 token
            Redis::zadd($key, $exp, $member);
            // 超过 3 个 → 踢出最旧的
            $count = Redis::zcard($key);
            if ($count > 3) {
                $oldest = Redis::zrange($key, 0, 0, true);
                if ($oldest) {
                    $oldMember = array_key_first($oldest);
                    $oldExp = (int) $oldest[$oldMember];
                    $ttl = max($oldExp - time(), 0);
                    Redis::zrem($key, $oldMember);
                    if ($ttl > 0) {
                        Redis::setex("jwt_blacklist:{$oldMember}", $ttl, '1');
                    }
                }
            }
            Redis::expire($key, $expiresIn + 3600);
        } catch (\Throwable) {
            // Redis 故障不影响登录
        }
    }
}
