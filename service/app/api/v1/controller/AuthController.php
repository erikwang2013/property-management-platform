<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;
use hg\apidoc\annotation as Apidoc;

use app\common\BaseController;
use app\common\LockService;
use app\common\PasswordRule;
use app\common\SnowflakeService;
use app\model\Owner;
use app\model\Room;
use support\Log;
use support\Redis;
use support\Request;
use support\Response;
use Erikwang2013\Jwt\JWTFactory;

/**
 * 业主认证
 * @Apidoc\Group("public")
 * @Apidoc\Sort(1)
 */
class AuthController extends BaseController
{
    /**
     * 业主登录
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/api/v1/auth/login")
     * @Apidoc\Desc("业主手机号+密码+验证码登录，返回JWT令牌")
     * @Apidoc\Param("phone", type="string", require=true, desc="手机号")
     * @Apidoc\Param("password", type="string", require=true, desc="密码")
     * @Apidoc\Param("captcha_key", type="string", require=true, desc="验证码key")
     * @Apidoc\Param("clicks", type="array", require=true, desc="点击坐标[{x,y},...]")
     * @Apidoc\Returned("access_token", type="string", desc="访问令牌(2h)")
     * @Apidoc\Returned("refresh_token", type="string", desc="刷新令牌(14d)")
     * @Apidoc\Returned("owner.id", type="string", desc="业主hashid")
     * @Apidoc\Returned("owner.name", type="string", desc="业主姓名")
     * @Apidoc\Returned("owner.phone", type="string", desc="手机号(掩码)")
     */
    public function login(Request $request): Response
    {
        $phone = $request->input('phone', '');
        $password = $request->input('password', '');
        $captchaKey = $request->input('captcha_key', '');
        $clicks = $this->normalizeClicks($request->input('clicks', []));

        if (empty($phone) || empty($password)) {
            return $this->fail('手机号和密码不能为空', 422);
        }

        if (!captcha_verify($captchaKey, 'click', $clicks)) {
            return $this->fail('验证码错误', 422);
        }

        $owner = $this->findOwnerByPhone($phone);

        // 锁定检查必须在密码验证之前，否则锁定期间仍可无限尝试密码
        if ($owner && $owner->locked_until && strtotime($owner->locked_until) > time()) {
            return $this->fail('账号已被锁定，请稍后再试', 429);
        }

        // 锁定到期自动复位失败计数
        if ($owner && $owner->locked_until && strtotime($owner->locked_until) <= time()) {
            $owner->login_failures = 0;
            $owner->locked_until = null;
            $owner->save();
        }

        // 对不存在的手机号执行一次假哈希比对，避免通过响应耗时枚举账号
        if (!$owner) {
            password_verify($password, '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi');
            return $this->fail('手机号或密码错误', 401);
        }

        if (!password_verify($password, $owner->password)) {
            $this->recordLoginFailure($owner);
            return $this->fail('手机号或密码错误', 401);
        }

        if ($owner->status !== 1) {
            return $this->fail('账号已被禁用', 403);
        }

        $owner->last_login_at = date('Y-m-d H:i:s');
        $owner->last_login_ip = $request->getRealIp();
        $owner->login_failures = 0;
        $owner->save();

        $jwt = JWTFactory::createFromConfig(config('plugin.erikwang2013.jwt.jwt', []));
        $claims = ['sub' => $owner->id, 'phone' => $owner->phone];
        // encode() 的 expire 传 0 时按 token_type 取配置：access 走 default_expire、refresh 走 refresh_expire
        $accessToken = $jwt->encode($claims);
        $refreshToken = $jwt->encode($claims + ['token_type' => 'refresh']);

        return $this->success([
            'access_token' => $accessToken,
            'refresh_token' => $refreshToken,
            'owner' => [
                'id' => $this->encodeId($owner->id),
                'name' => $owner->name,
                'phone' => $this->maskPhone($owner->phone),
                'gender' => $owner->gender,
            ],
        ], '登录成功');
    }

    /**
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/api/v1/auth/register")
     */
    public function register(Request $request): Response
    {
        $phone = $request->input('phone', '');
        $password = $request->input('password', '');
        $name = $request->input('name', '');
        $captchaKey = $request->input('captcha_key', '');
        $clicks = $this->normalizeClicks($request->input('clicks', []));

        if (empty($phone) || empty($password) || empty($name)) {
            return $this->fail('手机号、密码、姓名不能为空', 422);
        }

        // 与改密口共用同一规则源（app\common\PasswordRule），防止两处口径漂移
        $passwordError = PasswordRule::check($password);
        if ($passwordError !== null) {
            return $this->fail($passwordError, 422);
        }

        if (!captcha_verify($captchaKey, 'click', $clicks)) {
            return $this->fail('验证码错误', 422);
        }

        // 手机号盲索引没有唯一约束，注册用 Redis 锁串行化查重+插入，避免并发重复注册
        $phoneHash = Owner::phoneHash($phone);
        $lock = LockService::acquire('owner_phone:' . $phoneHash, 10);
        if ($lock === null) {
            return $this->fail('该手机号正在处理，请稍后再试', 429);
        }
        try {
            if ($this->findOwnerByPhone($phone) !== null) {
                return $this->fail('该手机号已注册', 422);
            }
            Owner::create([
                'id' => SnowflakeService::generate(),
                'name' => $name,
                'phone' => $phone,
                'phone_hash' => $phoneHash,
                'password' => password_hash($password, PASSWORD_BCRYPT),
                'status' => 1,
            ]);
        } finally {
            LockService::release('owner_phone:' . $phoneHash, $lock);
        }

        return $this->success([], '注册成功');
    }

    /**
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/api/v1/auth/refresh")
     */
    public function refresh(Request $request): Response
    {
        $refreshToken = $request->input('refresh_token', '');
        if (empty($refreshToken)) {
            return $this->fail('缺少 refresh_token', 422);
        }

        try {
            $jwt = JWTFactory::createFromConfig(config('plugin.erikwang2013.jwt.jwt', []));
            // 登出时拉黑的 refresh_token 不得再换发；Redis 故障沿用 ServiceAuth 的 fail-open
            try {
                if (Redis::get('jwt_blacklist:' . md5($refreshToken))) {
                    return $this->fail('刷新令牌已失效', 401);
                }
            } catch (\Throwable $e) {
                Log::error('auth_refresh_blacklist_failed', ['error' => $e->getMessage()]);
            }

            // 刷新令牌默认被 decode() 拒绝，显式放行；轮换后客户端必须用新 refresh_token 覆盖本地旧值
            $payload = $jwt->decode($refreshToken, true);

            // 只接受 refresh 类型：access token 无 token_type，不能用来换发新令牌
            if (($payload['token_type'] ?? '') !== 'refresh') {
                return $this->fail('刷新令牌无效或已过期', 401);
            }

            // 业主被删/禁用后旧刷新令牌立即失效
            $owner = Owner::find((int) ($payload['sub'] ?? 0));
            if (!$owner || (int) $owner->status !== 1) {
                return $this->fail('账号不存在或已被禁用', 401);
            }

            // 原子占用旧刷新令牌：并发刷新只有一个请求能成功，另一个 401
            $oldTtl = max((int) ($payload['exp'] ?? 0) - time(), 0);
            if ($oldTtl > 0) {
                try {
                    if (!Redis::set('jwt_blacklist:' . md5($refreshToken), '1', ['NX', 'EX' => $oldTtl])) {
                        return $this->fail('刷新令牌已使用', 401);
                    }
                } catch (\Throwable $e) {
                    Log::error('auth_refresh_blacklist_failed', ['error' => $e->getMessage()]);
                }
            }

            $claims = ['sub' => $payload['sub'], 'phone' => $payload['phone']];
            // encode() 的 expire 传 0 时按 token_type 取配置：access 走 default_expire、refresh 走 refresh_expire
            $accessToken = $jwt->encode($claims);
            $newRefresh = $jwt->encode($claims + ['token_type' => 'refresh']);

            return $this->success(['access_token' => $accessToken, 'refresh_token' => $newRefresh]);
        } catch (\Exception $e) {
            return $this->fail('Token已过期，请重新登录', 401);
        }
    }

    /**
     * 按手机号查业主。
     *
     * phone 是随机 IV 加密列，密文等值查询永远匹配不到，走盲索引 phone_hash（SHA-256，非加密）等值查询。
     */
    private function findOwnerByPhone(string $phone): ?Owner
    {
        return Owner::query()->where('phone_hash', Owner::phoneHash($phone))->first();
    }

    /** 记录登录失败：连续 5 次失败锁定账号 15 分钟 */
    private function recordLoginFailure(Owner $owner): void
    {
        $owner->login_failures = (int) $owner->login_failures + 1;
        if ($owner->login_failures >= 5) {
            $owner->locked_until = date('Y-m-d H:i:s', time() + 900);
            $owner->login_failures = 0;
        }
        $owner->save();
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

    private function maskPhone(string $phone): string
    {
        if (strlen($phone) >= 7) {
            return substr($phone, 0, 3) . '****' . substr($phone, -4);
        }
        return $phone;
    }
}
