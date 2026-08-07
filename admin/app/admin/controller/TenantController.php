<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;
use hg\apidoc\annotation as Apidoc;

use app\common\SnowflakeService;
use app\model\Room;
use app\model\Tenant;
use support\Request;

/**
 * 租户管理
 * @Apidoc\Group("property-core")
 * @Apidoc\Sort(7)
 */
class TenantController extends BaseController
{
    /**
     * 租户列表（手机号已脱敏）
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/tenant")
     * @Apidoc\Param("keyword", type="string", require=false, desc="搜索关键词（姓名）")
     * @Apidoc\Param("room_id", type="string", require=false, desc="房产hashid")
     * @Apidoc\Param("status", type="int", require=false, desc="状态: 0=到期 1=在租")
     * @Apidoc\Param(ref="pagination")
     * @Apidoc\Returned("id", type="string", desc="租户hashid")
     * @Apidoc\Returned("name", type="string", desc="姓名")
     * @Apidoc\Returned("phone", type="string", desc="脱敏手机号")
     * @Apidoc\Returned("lease_end", type="string", desc="租约截止")
     * @Apidoc\Returned("status", type="int", desc="状态")
     */
    public function index(Request $request)
    {
        $keyword = $request->input('keyword', '');
        $roomId  = $request->input('room_id');
        $status  = $request->input('status');

        $query = Tenant::query();
        if (!empty($keyword)) {
            $query->where('name', 'like', "%{$keyword}%");
        }
        if (!empty($roomId)) {
            $query->where('room_id', $this->decodeId($roomId));
        }
        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'          => $this->encodeId($item->id),
                    'room_id'     => $this->encodeId($item->room_id),
                    'owner_id'    => $item->owner_id ? $this->encodeId($item->owner_id) : '',
                    'name'        => $item->name,
                    'phone'       => $this->maskPhone($item->phone),
                    'lease_start' => $item->lease_start ? $item->lease_start->format('Y-m-d') : '',
                    'lease_end'   => $item->lease_end ? $item->lease_end->format('Y-m-d') : '',
                    'rent_amount' => $item->rent_amount,
                    'status'      => $item->status,
                    'created_at'  => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 租户详情
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/tenant/{hashid}")
     * @Apidoc\Param("hashid", type="string", require=true, desc="租户hashid", from="path")
     * @Apidoc\Returned("id", type="string", desc="租户hashid")
     * @Apidoc\Returned("name", type="string", desc="姓名")
     */
    public function show(Request $request, string $hashid)
    {
        $id = $this->decodeId($hashid);
        $item = Tenant::find($id);
        if (!$item) {
            return $this->fail('租户不存在', 404);
        }

        return $this->success([
            'id'          => $this->encodeId($item->id),
            'room_id'     => $this->encodeId($item->room_id),
            'owner_id'    => $item->owner_id ? $this->encodeId($item->owner_id) : '',
            'name'        => $item->name,
            'phone'       => $item->phone,
            'lease_start' => $item->lease_start ? $item->lease_start->format('Y-m-d') : '',
            'lease_end'   => $item->lease_end ? $item->lease_end->format('Y-m-d') : '',
            'rent_amount' => $item->rent_amount,
            'status'      => $item->status,
        ]);
    }

    /**
     * 创建租户
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/tenant")
     * @Apidoc\Param("room_id", type="string", require=true, desc="房产hashid")
     * @Apidoc\Param("owner_id", type="string", require=false, desc="房东(业主)hashid")
     * @Apidoc\Param("name", type="string", require=true, desc="姓名")
     * @Apidoc\Param("phone", type="string", require=true, desc="手机号")
     * @Apidoc\Param("id_card", type="string", require=false, desc="身份证号")
     * @Apidoc\Param("lease_start", type="string", require=false, desc="租约起始")
     * @Apidoc\Param("lease_end", type="string", require=false, desc="租约截止")
     * @Apidoc\Param("rent_amount", type="float", require=false, desc="月租金")
     * @Apidoc\Param("status", type="int", require=false, desc="状态: 0=到期 1=在租")
     * @Apidoc\Returned("id", type="string", desc="新建租户的hashid")
     */
    public function store(Request $request)
    {
        $data = $request->only([
            'room_id', 'owner_id', 'name', 'phone', 'id_card',
            'lease_start', 'lease_end', 'rent_amount', 'status',
        ]);

        if (empty($data['room_id'])) {
            return $this->fail('请选择租赁房产', 422);
        }
        $roomId = $this->decodeId($data['room_id']);
        if (!Room::find($roomId)) {
            return $this->fail('房产不存在', 422);
        }
        if (empty($data['name'])) {
            return $this->fail('租户姓名不能为空', 422);
        }
        if (empty($data['phone'])) {
            return $this->fail('手机号不能为空', 422);
        }

        $data['room_id'] = $roomId;
        if (!empty($data['owner_id'])) {
            $data['owner_id'] = $this->decodeId($data['owner_id']);
        }
        $data['id'] = SnowflakeService::generate();

        Tenant::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /**
     * @Apidoc\Method("PUT")
     * @Apidoc\Url("/admin/tenant/{hashid}")
     */
    public function update(Request $request, string $hashid)
    {
        $id = $this->decodeId($hashid);
        $item = Tenant::find($id);
        if (!$item) {
            return $this->fail('租户不存在', 404);
        }

        $data = $request->only([
            'name', 'phone', 'lease_start', 'lease_end',
            'rent_amount', 'status',
        ]);
        if ($request->input('owner_id')) {
            $data['owner_id'] = $this->decodeId($request->input('owner_id'));
        }
        $item->fill($data);
        $item->save();

        return $this->success([], '更新成功');
    }

    /**
     * @Apidoc\Method("DELETE")
     * @Apidoc\Url("/admin/tenant/{hashid}")
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
        $item = Tenant::find($id);
        if (!$item) {
            return $this->fail('租户不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }

    /** 手机号脱敏：138****8000 */
    private function maskPhone(string $phone): string
    {
        if (empty($phone)) {
            return '';
        }
        return preg_replace('/^(\d{3})\d+(\d{4})$/', '$1****$2', $phone);
    }
}
