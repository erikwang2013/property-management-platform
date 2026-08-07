<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;
use hg\apidoc\annotation as Apidoc;

use app\common\BaseController;
use app\model\Owner;
use support\Request;
use support\Response;
use support\Redis;
use Erikwang2013\Jwt\JWT;
use Erikwang2013\Jwt\JWTFactory;

/**
 * 个人中心
 * @Apidoc\Group("profile")
 * @Apidoc\Sort(1)
 */
class ProfileController extends BaseController
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

    /**
     * 获取个人信息
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/service/profile")
     */
    public function index(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);
        $owner   = Owner::find($ownerId);

        if (!$owner) {
            return $this->fail('用户不存在', 404);
        }

        $data = [
            'id'         => $this->encodeId($owner->id),
            'name'       => $owner->name,
            'phone'      => $owner->phone,
            'email'      => $owner->email,
            'gender'     => $owner->gender,
            'birthday'   => $owner->birthday ? $owner->birthday->format('Y-m-d') : '',
            'remark'     => $owner->remark,
            'created_at' => $owner->created_at ? $owner->created_at->format('Y-m-d H:i') : '',
        ];

        return $this->success($data);
    }

    /**
     * 更新个人信息
     * @Apidoc\Method("PUT")
     * @Apidoc\Url("/service/profile")
     */
    public function update(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);
        $owner   = Owner::find($ownerId);

        if (!$owner) {
            return $this->fail('用户不存在', 404);
        }

        if ($request->input('name') !== null) {
            $owner->name = $request->input('name');
        }
        if ($request->input('email') !== null) {
            $owner->email = $request->input('email', '');
        }
        if ($request->input('gender') !== null) {
            $owner->gender = (int) $request->input('gender');
        }
        if ($request->input('birthday') !== null) {
            $owner->birthday = $request->input('birthday', '') ?: null;
        }

        $owner->save();

        $data = $owner->toArray();
        unset($data['password'], $data['id_card']);
        $data['id'] = $this->encodeId($data['id']);

        return $this->success($data, '更新成功');
    }

    /**
     * 修改密码
     * @Apidoc\Method("PUT")
     * @Apidoc\Url("/service/profile/password")
     */
    public function updatePassword(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);
        $owner   = Owner::find($ownerId);

        if (!$owner) {
            return $this->fail('用户不存在', 404);
        }

        $oldPassword = $request->input('old_password', '');
        $newPassword = $request->input('new_password', '');

        if (empty($oldPassword) || empty($newPassword)) {
            return $this->fail('请填写旧密码和新密码', 422);
        }

        if (!password_verify($oldPassword, $owner->password)) {
            return $this->fail('旧密码错误', 422);
        }

        if (strlen($newPassword) < 6) {
            return $this->fail('新密码至少6位', 422);
        }

        $owner->password = password_hash($newPassword, PASSWORD_BCRYPT);
        $owner->save();

        return $this->success([], '密码修改成功');
    }

    /**
     * 退出登录
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/service/profile/logout")
     */
    public function logout(Request $request): Response
    {
        $token = $request->header('Authorization', '');
        $token = str_replace('Bearer ', '', $token);

        if (empty($token)) {
            return $this->fail('未登录', 401);
        }

        try {
            $payload = self::getJWT()->decode($token);
            $ttl     = max((int) ($payload['exp'] ?? 0) - time(), 0);
            Redis::setex('jwt_blacklist:' . md5($token), $ttl, '1');
        } catch (\Throwable) {
            // token 无效也视为登出成功
        }

        // 清除用户会话
        try {
            $ownerId = $this->getOwnerId($request);
            Redis::del('session:' . $ownerId);
        } catch (\Throwable) {
            // ignore
        }

        return $this->success([], '已登出');
    }
}
