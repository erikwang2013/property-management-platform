<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;
use hg\apidoc\annotation as Apidoc;

use app\common\SnowflakeService;
use app\model\Building;
use app\model\FeeBill;
use app\model\FeeType;
use app\model\Room;
use app\model\RoomOwner;
use support\Request;

/**
 * 账单管理
 * @Apidoc\Group("property-core")
 * @Apidoc\Sort(9)
 */
class FeeBillController extends BaseController
{
    /**
     * 账单列表
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/fee-bill")
     * @Apidoc\Param("keyword", type="string", require=false, desc="搜索关键词（账单编号）")
     * @Apidoc\Param("room_id", type="string", require=false, desc="房产hashid")
     * @Apidoc\Param("fee_type_id", type="string", require=false, desc="费用类型hashid")
     * @Apidoc\Param("status", type="int", require=false, desc="状态: 0=未缴 1=部分缴 2=已缴 3=逾期 4=豁免")
     * @Apidoc\Param(ref="pagination")
     * @Apidoc\Returned("id", type="string", desc="账单hashid")
     * @Apidoc\Returned("bill_number", type="string", desc="账单编号")
     * @Apidoc\Returned("amount", type="float", desc="账单金额")
     * @Apidoc\Returned("status", type="int", desc="状态")
     * @Apidoc\Returned("created_at", type="string", desc="创建时间")
     */
    public function index(Request $request)
    {
        $keyword   = $request->input('keyword', '');
        $roomId    = $request->input('room_id');
        $feeTypeId = $request->input('fee_type_id');
        $status    = $request->input('status');

        $query = FeeBill::query();
        if (!empty($keyword)) {
            $query->where('bill_number', 'like', "%{$keyword}%");
        }
        if (!empty($roomId)) {
            $query->where('room_id', $this->decodeId($roomId));
        }
        if (!empty($feeTypeId)) {
            $query->where('fee_type_id', $this->decodeId($feeTypeId));
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
                    'fee_type_id' => $this->encodeId($item->fee_type_id),
                    'bill_number' => $item->bill_number,
                    'amount'      => $item->amount,
                    'paid_amount' => $item->paid_amount,
                    'late_fee'    => $item->late_fee,
                    'start_date'  => $item->start_date ? $item->start_date->format('Y-m-d') : '',
                    'end_date'    => $item->end_date ? $item->end_date->format('Y-m-d') : '',
                    'due_date'    => $item->due_date ? $item->due_date->format('Y-m-d') : '',
                    'status'      => $item->status,
                    'paid_at'     => $item->paid_at ? $item->paid_at->format('Y-m-d H:i') : '',
                    'created_at'  => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 账单详情
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/fee-bill/{hashid}")
     * @Apidoc\Param("hashid", type="string", require=true, desc="账单hashid", from="path")
     * @Apidoc\Returned("id", type="string", desc="账单hashid")
     * @Apidoc\Returned("bill_number", type="string", desc="账单编号")
     */
    public function show(Request $request, string $hashid)
    {
        $id = $this->decodeId($hashid);
        $item = FeeBill::find($id);
        if (!$item) {
            return $this->fail('账单不存在', 404);
        }

        return $this->success([
            'id'          => $this->encodeId($item->id),
            'room_id'     => $this->encodeId($item->room_id),
            'owner_id'    => $item->owner_id ? $this->encodeId($item->owner_id) : '',
            'fee_type_id' => $this->encodeId($item->fee_type_id),
            'bill_number' => $item->bill_number,
            'amount'      => $item->amount,
            'paid_amount' => $item->paid_amount,
            'late_fee'    => $item->late_fee,
            'start_date'  => $item->start_date ? $item->start_date->format('Y-m-d') : '',
            'end_date'    => $item->end_date ? $item->end_date->format('Y-m-d') : '',
            'due_date'    => $item->due_date ? $item->due_date->format('Y-m-d') : '',
            'status'      => $item->status,
            'paid_at'     => $item->paid_at ? $item->paid_at->format('Y-m-d H:i') : '',
            'remark'      => $item->remark,
        ]);
    }

    /**
     * 创建账单
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/fee-bill")
     * @Apidoc\Param("room_id", type="string", require=true, desc="房产hashid")
     * @Apidoc\Param("fee_type_id", type="string", require=true, desc="费用类型hashid")
     * @Apidoc\Param("amount", type="float", require=true, desc="账单金额")
     * @Apidoc\Param("owner_id", type="string", require=false, desc="业主hashid")
     * @Apidoc\Param("start_date", type="string", require=false, desc="费用周期起始")
     * @Apidoc\Param("end_date", type="string", require=false, desc="费用周期截止")
     * @Apidoc\Param("due_date", type="string", require=false, desc="截止日期")
     * @Apidoc\Param("remark", type="string", require=false, desc="备注")
     * @Apidoc\Returned("id", type="string", desc="新建账单的hashid")
     */
    public function store(Request $request)
    {
        $data = $request->only([
            'room_id', 'owner_id', 'fee_type_id', 'amount',
            'start_date', 'end_date', 'due_date', 'remark',
        ]);

        if (empty($data['room_id'])) {
            return $this->fail('请选择房产', 422);
        }
        if (empty($data['fee_type_id'])) {
            return $this->fail('请选择费用类型', 422);
        }
        if ((float) ($data['amount'] ?? 0) <= 0) {
            return $this->fail('账单金额必须大于0', 422);
        }

        $data['room_id']     = $this->decodeId($data['room_id']);
        $data['fee_type_id'] = $this->decodeId($data['fee_type_id']);
        if (!empty($data['owner_id'])) {
            $data['owner_id'] = $this->decodeId($data['owner_id']);
        }
        $data['id']          = SnowflakeService::generate();
        $data['bill_number'] = 'FB' . date('YmdHis') . rand(1000, 9999);
        $data['status']      = 0;

        FeeBill::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /**
     * @Apidoc\Method("PUT")
     * @Apidoc\Url("/admin/fee-bill/{hashid}")
     */
    public function update(Request $request, string $hashid)
    {
        $id = $this->decodeId($hashid);
        $item = FeeBill::find($id);
        if (!$item) {
            return $this->fail('账单不存在', 404);
        }

        $data = $request->only([
            'amount', 'late_fee', 'start_date', 'end_date',
            'due_date', 'remark',
        ]);
        if ($request->input('status') !== null) {
            $data['status'] = (int) $request->input('status');
        }
        $item->fill($data);
        $item->save();

        return $this->success([], '更新成功');
    }

    /**
     * @Apidoc\Method("DELETE")
     * @Apidoc\Url("/admin/fee-bill/{hashid}")
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
        $item = FeeBill::find($id);
        if (!$item) {
            return $this->fail('账单不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }

    /**
     * 批量生成账单（按楼栋/户型）
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/fee-bill/batch/generate")
     * @Apidoc\Param("building_id", type="string", require=true, desc="楼栋hashid")
     * @Apidoc\Param("fee_type_id", type="string", require=true, desc="费用类型hashid")
     * @Apidoc\Param("room_type_id", type="string", require=false, desc="户型hashid，缺省为楼栋全部房产")
     * @Apidoc\Param("start_date", type="string", require=true, desc="费用周期起始")
     * @Apidoc\Param("end_date", type="string", require=true, desc="费用周期截止")
     * @Apidoc\Param("due_date", type="string", require=false, desc="截止日期")
     * @Apidoc\Param("amount", type="float", require=false, desc="固定金额（缺省按费用类型单价×面积计算）")
     * @Apidoc\Returned("created", type="int", desc="生成数量")
     * @Apidoc\Returned("skipped", type="int", desc="跳过数量（已存在账单）")
     */
    public function batchGenerate(Request $request)
    {
        $buildingId = $request->input('building_id', '');
        $feeTypeId  = $request->input('fee_type_id', '');
        $startDate  = (string) $request->input('start_date', '');
        $endDate    = (string) $request->input('end_date', '');

        if (empty($buildingId)) {
            return $this->fail('请选择楼栋', 422);
        }
        $buildingId = $this->decodeId($buildingId);
        if (!Building::find($buildingId)) {
            return $this->fail('楼栋不存在', 422);
        }
        if (empty($feeTypeId)) {
            return $this->fail('请选择费用类型', 422);
        }
        $feeTypeId = $this->decodeId($feeTypeId);
        $feeType = FeeType::find($feeTypeId);
        if (!$feeType) {
            return $this->fail('费用类型不存在', 422);
        }
        if (empty($startDate) || empty($endDate)) {
            return $this->fail('请填写费用周期', 422);
        }

        $roomTypeId = 0;
        if ($request->input('room_type_id')) {
            $roomTypeId = $this->decodeId($request->input('room_type_id'));
        }
        $overrideAmount = (float) $request->input('amount', 0);
        $dueDate        = (string) $request->input('due_date', $endDate);

        $query = Room::where('building_id', $buildingId);
        if ($roomTypeId > 0) {
            $query->where('room_type_id', $roomTypeId);
        }

        $created = 0;
        $skipped = 0;
        foreach ($query->get() as $room) {
            $exists = FeeBill::where('room_id', $room->id)
                ->where('fee_type_id', $feeTypeId)
                ->where('start_date', $startDate)
                ->exists();
            if ($exists) {
                $skipped++;
                continue;
            }

            $amount = $overrideAmount > 0
                ? $overrideAmount
                : $this->calcBillAmount($feeType, $room);

            FeeBill::create([
                'id'          => SnowflakeService::generate(),
                'room_id'     => $room->id,
                'owner_id'    => (int) (RoomOwner::where('room_id', $room->id)->value('owner_id') ?? 0),
                'fee_type_id' => $feeTypeId,
                'bill_number' => 'FB' . date('YmdHis') . str_pad((string) ($created + 1), 3, '0', STR_PAD_LEFT) . rand(10, 99),
                'amount'      => $amount,
                'paid_amount' => 0,
                'late_fee'    => 0,
                'start_date'  => $startDate,
                'end_date'    => $endDate,
                'due_date'    => $dueDate,
                'status'      => 0,
            ]);
            $created++;
        }

        return $this->success(['created' => $created, 'skipped' => $skipped], '批量生成完成');
    }

    /**
     * 计算账单金额：按面积计费(unit_type=1)时 = 单价 × 总面积，否则取单价
     */
    private function calcBillAmount(FeeType $feeType, Room $room): float
    {
        if ((int) $feeType->unit_type === 1) {
            return round((float) $feeType->unit_price * (float) $room->area_total, 2);
        }
        return (float) $feeType->unit_price;
    }
}
