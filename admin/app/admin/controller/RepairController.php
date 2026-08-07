<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;
use hg\apidoc\annotation as Apidoc;

use app\common\SnowflakeService;
use app\model\RepairOrder;
use app\model\RepairProgress;
use app\model\Staff;
use support\Request;

/**
 * 报修管理
 * @Apidoc\Group("property-core")
 * @Apidoc\Sort(11)
 */
class RepairController extends BaseController
{
    /**
     * 报修单列表
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/repair")
     * @Apidoc\Param("keyword", type="string", require=false, desc="搜索关键词（报修编号）")
     * @Apidoc\Param("status", type="int", require=false, desc="状态: 0=待派单 1=已派单 2=维修中 3=已完成 4=已评价 5=已取消")
     * @Apidoc\Param("category", type="int", require=false, desc="分类: 1=水电 2=门窗 3=墙面地面 4=管道 5=家电 6=电梯 7=公共设施 8=其他")
     * @Apidoc\Param(ref="pagination")
     * @Apidoc\Returned("id", type="string", desc="报修单hashid")
     * @Apidoc\Returned("order_number", type="string", desc="报修编号")
     * @Apidoc\Returned("status", type="int", desc="状态")
     * @Apidoc\Returned("created_at", type="string", desc="创建时间")
     */
    public function index(Request $request)
    {
        $keyword = $request->input('keyword', '');
        $status  = $request->input('status');
        $category = $request->input('category');

        $query = RepairOrder::query();
        if (!empty($keyword)) {
            $query->where('order_number', 'like', "%{$keyword}%");
        }
        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        }
        if ($category !== null && $category !== '') {
            $query->where('category', (int) $category);
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'           => $this->encodeId($item->id),
                    'order_number' => $item->order_number,
                    'room_id'      => $this->encodeId($item->room_id),
                    'owner_id'     => $item->owner_id ? $this->encodeId($item->owner_id) : '',
                    'contact_phone' => $this->maskPhone($item->contact_phone),
                    'category'     => $item->category,
                    'urgency'      => $item->urgency,
                    'description'  => $item->description,
                    'status'       => $item->status,
                    'staff_id'     => $item->staff_id,
                    'completed_at' => $item->completed_at ? $item->completed_at->format('Y-m-d H:i') : '',
                    'created_at'   => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 报修单详情（含进度记录）
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/repair/{hashid}")
     * @Apidoc\Param("hashid", type="string", require=true, desc="报修单hashid", from="path")
     * @Apidoc\Returned("id", type="string", desc="报修单hashid")
     * @Apidoc\Returned("order_number", type="string", desc="报修编号")
     * @Apidoc\Returned("progress", type="array", desc="进度记录数组")
     */
    public function show(Request $request, string $hashid)
    {
        $id = $this->decodeId($hashid);
        $item = RepairOrder::find($id);
        if (!$item) {
            return $this->fail('报修单不存在', 404);
        }

        $progress = [];
        foreach ($item->progress()->orderBy('created_at', 'asc')->get() as $p) {
            $progress[] = [
                'id'           => $this->encodeId($p->id),
                'staff_id'     => $p->staff_id,
                'status_from'  => $p->status_from,
                'status_to'    => $p->status_to,
                'remark'       => $p->remark,
                'images'       => $p->images,
                'created_at'   => $p->created_at ? $p->created_at->format('Y-m-d H:i') : '',
            ];
        }

        return $this->success([
            'id'            => $this->encodeId($item->id),
            'order_number'  => $item->order_number,
            'room_id'       => $this->encodeId($item->room_id),
            'owner_id'      => $item->owner_id ? $this->encodeId($item->owner_id) : '',
            'contact_phone' => $item->contact_phone,
            'category'      => $item->category,
            'urgency'       => $item->urgency,
            'description'   => $item->description,
            'images'        => $item->images,
            'scheduled_at'  => $item->scheduled_at ? $item->scheduled_at->format('Y-m-d H:i') : '',
            'status'        => $item->status,
            'staff_id'      => $item->staff_id,
            'completed_at'  => $item->completed_at ? $item->completed_at->format('Y-m-d H:i') : '',
            'rating'        => $item->rating,
            'feedback'      => $item->feedback,
            'progress'      => $progress,
        ]);
    }

    /**
     * 创建报修单
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/repair")
     * @Apidoc\Param("room_id", type="string", require=true, desc="房产hashid")
     * @Apidoc\Param("owner_id", type="string", require=false, desc="报修人hashid")
     * @Apidoc\Param("contact_phone", type="string", require=true, desc="联系电话")
     * @Apidoc\Param("category", type="int", require=false, desc="分类: 1=水电 2=门窗 3=墙面地面 4=管道 5=家电 6=电梯 7=公共设施 8=其他")
     * @Apidoc\Param("urgency", type="int", require=false, desc="紧急程度: 1=普通 2=紧急 3=非常紧急")
     * @Apidoc\Param("description", type="string", require=false, desc="问题描述")
     * @Apidoc\Param("images", type="array", require=false, desc="图片URL数组")
     * @Apidoc\Param("scheduled_at", type="string", require=false, desc="预约维修时间")
     * @Apidoc\Returned("id", type="string", desc="新建报修单的hashid")
     */
    public function store(Request $request)
    {
        $data = $request->only([
            'room_id', 'owner_id', 'contact_phone', 'category',
            'urgency', 'description', 'images', 'scheduled_at',
        ]);

        if (empty($data['room_id'])) {
            return $this->fail('请选择报修房产', 422);
        }
        if (empty($data['contact_phone'])) {
            return $this->fail('联系电话不能为空', 422);
        }

        $data['room_id']  = $this->decodeId($data['room_id']);
        if (!empty($data['owner_id'])) {
            $data['owner_id'] = $this->decodeId($data['owner_id']);
        }
        $data['id']          = SnowflakeService::generate();
        $data['order_number'] = 'RO' . date('YmdHis') . rand(1000, 9999);
        $data['status']      = 0; // 待派单
        $data['staff_id']    = 0;
        $data['images']      = $data['images'] ?? [];

        RepairOrder::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /**
     * @Apidoc\Method("PUT")
     * @Apidoc\Url("/admin/repair/{hashid}")
     */
    public function update(Request $request, string $hashid)
    {
        $id = $this->decodeId($hashid);
        $item = RepairOrder::find($id);
        if (!$item) {
            return $this->fail('报修单不存在', 404);
        }

        $data = $request->only([
            'contact_phone', 'category', 'urgency', 'description',
            'images', 'scheduled_at', 'status', 'staff_id',
        ]);
        if ($request->input('room_id')) {
            $data['room_id'] = $this->decodeId($request->input('room_id'));
        }
        if ($request->input('owner_id')) {
            $data['owner_id'] = $this->decodeId($request->input('owner_id'));
        }
        $item->fill($data);
        $item->save();

        return $this->success([], '更新成功');
    }

    /**
     * @Apidoc\Method("DELETE")
     * @Apidoc\Url("/admin/repair/{hashid}")
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
        $item = RepairOrder::find($id);
        if (!$item) {
            return $this->fail('报修单不存在', 404);
        }

        RepairProgress::where('repair_order_id', $item->id)->delete();
        $item->delete();

        return $this->success([], '删除成功');
    }

    /**
     * 派单（指派维修人员）
     * @Apidoc\Method("PUT")
     * @Apidoc\Url("/admin/repair/{id}/assign")
     * @Apidoc\Param("hashid", type="string", require=true, desc="报修单hashid", from="path")
     * @Apidoc\Param("staff_id", type="int", require=true, desc="维修人员ID")
     * @Apidoc\Param("remark", type="string", require=false, desc="派单说明")
     */
    public function assign(Request $request, string $hashid)
    {
        $id = $this->decodeId($hashid);
        $order = RepairOrder::find($id);
        if (!$order) {
            return $this->fail('报修单不存在', 404);
        }

        $staffId = (int) $request->input('staff_id', 0);
        if ($staffId <= 0 || !Staff::find($staffId)) {
            return $this->fail('请选择有效的维修人员', 422);
        }
        if ($order->status == 5) {
            return $this->fail('已取消的报修单不能派单', 422);
        }

        $from = $order->status;
        $order->staff_id = $staffId;
        if ($order->status == 0) {
            $order->status = 1; // 待派单 → 已派单
        }
        $order->save();

        $this->addProgress($order->id, $from, $order->status, (int) ($request->adminId ?? $staffId), (string) $request->input('remark', '已派单'), $request->input('images', []));

        return $this->success([], '派单成功');
    }

    /**
     * 更新维修进度
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/repair/{id}/progress")
     * @Apidoc\Param("hashid", type="string", require=true, desc="报修单hashid", from="path")
     * @Apidoc\Param("status", type="int", require=true, desc="变更后状态: 0=待派单 1=已派单 2=维修中 3=已完成 4=已评价 5=已取消")
     * @Apidoc\Param("remark", type="string", require=false, desc="进度说明")
     * @Apidoc\Param("images", type="array", require=false, desc="现场图片URL数组")
     */
    public function progress(Request $request, string $hashid)
    {
        $id = $this->decodeId($hashid);
        $order = RepairOrder::find($id);
        if (!$order) {
            return $this->fail('报修单不存在', 404);
        }

        $status = (int) $request->input('status', -1);
        if ($status < 0 || $status > 5) {
            return $this->fail('状态值无效', 422);
        }
        if ($status == 5 && $order->status == 3) {
            return $this->fail('已完成的报修单不能取消', 422);
        }

        $from = $order->status;
        $order->status = $status;
        if ($status == 3) {
            $order->completed_at = date('Y-m-d H:i:s');
        }
        $order->save();

        $this->addProgress($order->id, $from, $status, (int) ($request->adminId ?? $order->staff_id), (string) $request->input('remark', ''), $request->input('images', []));

        return $this->success([], '进度更新成功');
    }

    /** 写入进度记录 */
    private function addProgress(int $repairOrderId, int $from, int $to, int $staffId, string $remark, $images): void
    {
        $progress = new RepairProgress();
        $progress->id              = SnowflakeService::generate();
        $progress->repair_order_id = $repairOrderId;
        $progress->staff_id        = $staffId;
        $progress->status_from     = $from;
        $progress->status_to       = $to;
        $progress->remark          = $remark;
        $progress->images          = $images ?: [];
        $progress->save();
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
