<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;

use app\common\BaseController;
use app\common\SnowflakeService;
use app\model\Owner;
use app\model\Room;
use app\model\RoomOwner;
use support\Request;
use support\Response;
use support\Redis;
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
     * @Apidoc\Url("/api/auth/login")
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

        $owner = Owner::where('phone', $phone)->first();

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
        $accessToken = $jwt->create(['sub' => $owner->id, 'phone' => $owner->phone]);
        $refreshToken = $jwt->createRefresh(['sub' => $owner->id, 'phone' => $owner->phone]);

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

        if (strlen($password) < 8 || strlen($password) > 32) {
            return $this->fail('密码长度 8-32 位', 422);
        }

        if (!preg_match('/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$/', $password)) {
            return $this->fail('密码需包含大小写字母、数字和特殊字符(@$!%*?&)', 422);
        }

        if (!captcha_verify($captchaKey, 'click', $clicks)) {
            return $this->fail('验证码错误', 422);
        }

        if (Owner::where('phone', $phone)->exists()) {
            return $this->fail('该手机号已注册', 422);
        }

        $ownerId = SnowflakeService::generate();
        Owner::create([
            'id' => $ownerId,
            'name' => $name,
            'phone' => $phone,
            'password' => password_hash($password, PASSWORD_BCRYPT),
            'status' => 1,
        ]);

        return $this->success([], '注册成功');
    }

    public function refresh(Request $request): Response
    {
        $refreshToken = $request->input('refresh_token', '');
        if (empty($refreshToken)) {
            return $this->fail('缺少 refresh_token', 422);
        }

        try {
            $jwt = JWTFactory::createFromConfig(config('plugin.erikwang2013.jwt.jwt', []));
            $payload = $jwt->decode($refreshToken);
            $accessToken = $jwt->create(['sub' => $payload['sub'], 'phone' => $payload['phone']]);
            return $this->success(['access_token' => $accessToken]);
        } catch (\Exception $e) {
            return $this->fail('Token已过期，请重新登录', 401);
        }
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
