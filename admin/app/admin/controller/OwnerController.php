<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;
use hg\apidoc\annotation as Apidoc;

use app\common\SnowflakeService;
use app\model\Owner;
use support\Request;

/**
 * 业主管理
 * @Apidoc\Group("property-core")
 * @Apidoc\Sort(6)
 */
class OwnerController extends BaseController
{
    /**
     * 业主列表（手机号/邮箱已脱敏）
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/owner")
     * @Apidoc\Param("keyword", type="string", require=false, desc="搜索关键词（姓名/手机号）")
     * @Apidoc\Param("status", type="int", require=false, desc="状态: 0=迁出 1=入住")
     * @Apidoc\Param(ref="pagination")
     * @Apidoc\Returned("id", type="string", desc="业主hashid")
     * @Apidoc\Returned("name", type="string", desc="姓名")
     * @Apidoc\Returned("phone", type="string", desc="脱敏手机号")
     * @Apidoc\Returned("status", type="int", desc="状态")
     * @Apidoc\Returned("created_at", type="string", desc="创建时间")
     */
    public function index(Request $request)
    {
        $keyword = $request->input('keyword', '');
        $status  = $request->input('status');

        $query = Owner::query();
        if (!empty($keyword)) {
            $query->where(function ($q) use ($keyword) {
                $q->where('name', 'like', "%{$keyword}%")
                  ->orWhere('phone', 'like', "%{$keyword}%");
            });
        }
        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'           => $this->encodeId($item->id),
                    'name'         => $item->name,
                    'phone'        => $this->maskPhone($item->phone),
                    'email'        => $this->maskEmail($item->email),
                    'gender'       => $item->gender,
                    'status'       => $item->status,
                    'check_in_date' => $item->check_in_date ? $item->check_in_date->format('Y-m-d') : '',
                    'created_at'   => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 业主详情（手机号/邮箱为解密明文）
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/owner/{hashid}")
     * @Apidoc\Param("hashid", type="string", require=true, desc="业主hashid", from="path")
     * @Apidoc\Returned("id", type="string", desc="业主hashid")
     * @Apidoc\Returned("name", type="string", desc="姓名")
     */
    public function show(Request $request, string $hashid)
    {
        $id = $this->decodeId($hashid);
        $item = Owner::find($id);
        if (!$item) {
            return $this->fail('业主不存在', 404);
        }

        return $this->success([
            'id'                => $this->encodeId($item->id),
            'name'              => $item->name,
            'phone'             => $item->phone,
            'email'             => $item->email,
            'gender'            => $item->gender,
            'birthday'          => $item->birthday ? $item->birthday->format('Y-m-d') : '',
            'emergency_contact' => $item->emergency_contact,
            'emergency_phone'   => $item->emergency_phone,
            'check_in_date'     => $item->check_in_date ? $item->check_in_date->format('Y-m-d') : '',
            'remark'            => $item->remark,
            'status'            => $item->status,
        ]);
    }

    /**
     * 创建业主
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/owner")
     * @Apidoc\Param("name", type="string", require=true, desc="姓名")
     * @Apidoc\Param("phone", type="string", require=true, desc="手机号")
     * @Apidoc\Param("email", type="string", require=false, desc="邮箱")
     * @Apidoc\Param("id_card", type="string", require=false, desc="身份证号")
     * @Apidoc\Param("gender", type="int", require=false, desc="性别: 0=未知 1=男 2=女")
     * @Apidoc\Param("birthday", type="string", require=false, desc="生日")
     * @Apidoc\Param("emergency_contact", type="string", require=false, desc="紧急联系人")
     * @Apidoc\Param("emergency_phone", type="string", require=false, desc="紧急联系电话")
     * @Apidoc\Param("check_in_date", type="string", require=false, desc="入住日期")
     * @Apidoc\Param("remark", type="string", require=false, desc="备注")
     * @Apidoc\Returned("id", type="string", desc="新建业主的hashid")
     */
    public function store(Request $request)
    {
        $data = $request->only([
            'name', 'phone', 'email', 'id_card', 'gender',
            'birthday', 'emergency_contact', 'emergency_phone',
            'check_in_date', 'remark',
        ]);

        if (empty($data['name'])) {
            return $this->fail('业主姓名不能为空', 422);
        }
        if (empty($data['phone'])) {
            return $this->fail('手机号不能为空', 422);
        }

        $data['id']     = SnowflakeService::generate();
        $data['status'] = (int) $request->input('status', 1);

        Owner::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /**
     * @Apidoc\Method("PUT")
     * @Apidoc\Url("/admin/owner/{hashid}")
     */
    public function update(Request $request, string $hashid)
    {
        $id = $this->decodeId($hashid);
        $item = Owner::find($id);
        if (!$item) {
            return $this->fail('业主不存在', 404);
        }

        $item->fill($request->only([
            'name', 'phone', 'email', 'gender', 'birthday',
            'emergency_contact', 'emergency_phone',
            'check_in_date', 'remark', 'status',
        ]));
        $item->save();

        return $this->success([], '更新成功');
    }

    /**
     * @Apidoc\Method("DELETE")
     * @Apidoc\Url("/admin/owner/{hashid}")
     */
    public function destroy(Request $request, string $hashid)
    {
        $adminId = $request->adminId;
        $password = $request->input('password', '');

        $error = $this->confirmPassword($adminId, $password, $request);
        if ($error !== null) {
            return $this->fail($error, 422);
        }

        $id = $this->decodeId($hashid);
        $item = Owner::find($id);
        if (!$item) {
            return $this->fail('业主不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }

    /**
     * 业主批量导入
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/owner/batch/import")
     * @Apidoc\Param("items", type="array", require=true, desc="业主数组，每项含 name/phone 等字段")
     * @Apidoc\Returned("count", type="int", desc="导入成功数量")
     */
    public function batchImport(Request $request)
    {
        $items = $request->input('items', []);
        if (empty($items) || !is_array($items)) {
            return $this->fail('请提供待导入的业主数据', 422);
        }

        $created = 0;
        $failed  = 0;
        foreach ($items as $item) {
            if (empty($item['name']) || empty($item['phone'])) {
                $failed++;
                continue;
            }
            $exists = Owner::where('phone', $item['phone'])->exists();
            if ($exists) {
                $failed++;
                continue;
            }
            Owner::create([
                'id'                => SnowflakeService::generate(),
                'name'              => $item['name'],
                'phone'             => $item['phone'],
                'email'             => $item['email'] ?? '',
                'id_card'           => $item['id_card'] ?? '',
                'gender'            => (int) ($item['gender'] ?? 0),
                'birthday'          => $item['birthday'] ?? null,
                'emergency_contact' => $item['emergency_contact'] ?? '',
                'emergency_phone'   => $item['emergency_phone'] ?? '',
                'check_in_date'     => $item['check_in_date'] ?? null,
                'remark'            => $item['remark'] ?? '',
                'status'            => (int) ($item['status'] ?? 1),
            ]);
            $created++;
        }

        return $this->success(['count' => $created, 'failed' => $failed], '导入完成');
    }

    /**
     * 业主批量删除（需密码确认）
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/owner/batch/destroy")
     * @Apidoc\Param("ids", type="array", require=true, desc="业主hashid数组")
     * @Apidoc\Param("password", type="string", require=true, desc="登录密码确认")
     * @Apidoc\Returned("count", type="int", desc="删除数量")
     */
    public function batchDestroy(Request $request)
    {
        $ids      = $request->input('ids', []);
        $password = $request->input('password', '');

        if (empty($ids) || !is_array($ids)) {
            return $this->fail('请选择要删除的业主', 422);
        }

        $adminId = $request->adminId ?? 0;
        $error   = $this->confirmPassword($adminId, $password, $request);
        if ($error !== null) {
            return $this->fail($error, 422);
        }

        $decodedIds = [];
        foreach ($ids as $hashid) {
            $decodedIds[] = $this->decodeId($hashid);
        }

        Owner::whereIn('id', $decodedIds)->delete();

        return $this->success(['count' => count($decodedIds)], '删除成功');
    }

    /** 手机号脱敏：138****8000 */
    private function maskPhone(string $phone): string
    {
        if (empty($phone)) {
            return '';
        }
        return preg_replace('/^(\d{3})\d+(\d{4})$/', '$1****$2', $phone);
    }

    /** 邮箱脱敏：a***@xx.com */
    private function maskEmail(string $email): string
    {
        if (empty($email)) {
            return '';
        }
        $parts = explode('@', $email);
        return mb_substr($parts[0], 0, 1) . '***@' . ($parts[1] ?? '');
    }
}
