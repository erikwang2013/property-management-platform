<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;
use hg\apidoc\annotation as Apidoc;

use app\model\AdminRole;
use support\Request;
use support\Response;

/**
 * 系统管理
 * @Apidoc\Group("system")
 */
class RoleController extends BaseController
{
    /**
     * 角色列表
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/role")
     */
    public function index(Request $request): Response
    {
        $page = (int) $request->input('page', 1);
        $limit = $this->pageSize($request, 'limit', 15);

        $query = AdminRole::withCount('users')->with('permissions');
        $total = $query->count();
        $list = $query->offset(($page - 1) * $limit)
                      ->limit($limit)
                      ->orderBy('id', 'asc')
                      ->get()
                      ->map(function ($role) {
                          $data = $this->encodeIds($role->toArray());
                          // 权限树节点 ID 是 hashid，角色也按同一格式返回，前端才能与树节点对齐勾选
                          $data['permissions'] = array_map(fn ($perm) => [
                              'id'   => $this->encodeId((int) $perm['id']),
                              'name' => $perm['name'] ?? '',
                              'slug' => $perm['slug'] ?? '',
                          ], $data['permissions'] ?? []);

                          return $data;
                      });

        return $this->success([
            'list' => $list,
            'total' => $total,
            'page' => $page,
            'limit' => $limit,
        ]);
    }

    /**
     * 创建角色
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/role")
     */
    public function store(Request $request): Response
    {
        $validator = validator($request->all(), [
            'name' => 'required|string|max:50',
            'slug' => 'required|string|max:50',
        ]);

        if ($validator->fails()) {
            return $this->fail($validator->errors()->first(), 422);
        }

        $role = new AdminRole();
        $role->id = $this->generateId();
        $role->name = $request->input('name');
        $role->slug = $request->input('slug');
        $role->description = $request->input('description', '');
        $role->status = (int) $request->input('status', 1);
        $role->save();

        // 同步权限：客户端送权限树 hashid，中间表存原始 BIGINT；非法 ID 由 decodeId 抛 422
        if ($request->input('permission_ids') !== null) {
            $permissionIds = array_map(
                fn ($id) => $this->decodeId((string) $id),
                (array) $request->input('permission_ids', [])
            );
            $role->permissions()->sync($permissionIds);
        }

        return $this->success($this->encodeIds($role->toArray()), '创建成功');
    }

    /**
     * 更新角色
     * @Apidoc\Method("PUT")
     * @Apidoc\Url("/admin/role/{hashid}")
     */
    public function update(Request $request, string $hashid): Response
    {
        $id = $this->decodeId($hashid);
        $role = AdminRole::find($id);
        if (!$role) {
            return $this->fail('角色不存在', 404);
        }

        $role->name = $request->input('name', $role->name);
        $role->description = $request->input('description', $role->description);
        $role->status = (int) $request->input('status', $role->status);
        $role->save();

        if ($request->input('permission_ids') !== null) {
            // 客户端送权限树 hashid，中间表存原始 BIGINT；非法 ID 由 decodeId 抛 422
            $permissionIds = array_map(
                fn ($id) => $this->decodeId((string) $id),
                (array) $request->input('permission_ids', [])
            );
            $role->permissions()->sync($permissionIds);
        }

        return $this->success($this->encodeIds($role->toArray()), '更新成功');
    }

    /**
     * 删除角色（需密码二次确认）
     * @Apidoc\Method("DELETE")
     * @Apidoc\Url("/admin/role/{hashid}")
     */
    public function destroy(Request $request, string $hashid): Response
    {
        $id = $this->decodeId($hashid);
        $role = AdminRole::find($id);
        if (!$role) {
            return $this->fail('角色不存在', 404);
        }

        $adminId = $request->adminId ?? 0;
        $error = $this->confirmPassword($adminId, $request->input('password', ''), $request);
        if ($error !== null) {
            return $this->fail($error, 422);
        }

        $role->permissions()->detach();
        $role->users()->detach();
        $role->delete();

        return $this->success([], '删除成功');
    }
}
