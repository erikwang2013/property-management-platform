<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;

use app\common\SnowflakeService;
use app\model\Contract;
use support\Request;

class ContractController extends BaseController
{
    /**
     * 合同列表
     * ?contract_type=xxx&status=xxx&keyword=搜索词&page_size=20
     */
    public function index(Request $request)
    {
        $contractType = $request->input('contract_type');
        $status       = $request->input('status');
        $keyword      = $request->input('keyword', '');

        $query = Contract::query();

        if ($contractType !== null && $contractType !== '') {
            $query->where('contract_type', (int) $contractType);
        }
        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        }
        if (!empty($keyword)) {
            $query->where(function ($q) use ($keyword) {
                $q->where('title', 'like', "%{$keyword}%")
                  ->orWhere('contract_number', 'like', "%{$keyword}%");
            });
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'              => $this->encodeId($item->id),
                    'contract_number' => $item->contract_number,
                    'contract_type'   => $item->contract_type,
                    'party_a_type'    => $item->party_a_type,
                    'party_a_id'      => $item->party_a_id ? $this->encodeId($item->party_a_id) : '',
                    'party_b_type'    => $item->party_b_type,
                    'party_b_id'      => $item->party_b_id ? $this->encodeId($item->party_b_id) : '',
                    'title'           => $item->title,
                    'amount'          => $item->amount,
                    'start_date'      => $item->start_date ? $item->start_date->format('Y-m-d') : '',
                    'end_date'        => $item->end_date ? $item->end_date->format('Y-m-d') : '',
                    'sign_date'       => $item->sign_date ? $item->sign_date->format('Y-m-d') : '',
                    'status'          => $item->status,
                    'created_at'      => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /** 合同详情 */
    public function show(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = Contract::find($id);
        if (!$item) {
            return $this->fail('合同不存在', 404);
        }

        return $this->success([
            'id'              => $this->encodeId($item->id),
            'contract_number' => $item->contract_number,
            'contract_type'   => $item->contract_type,
            'party_a_type'    => $item->party_a_type,
            'party_a_id'      => $item->party_a_id ? $this->encodeId($item->party_a_id) : '',
            'party_b_type'    => $item->party_b_type,
            'party_b_id'      => $item->party_b_id ? $this->encodeId($item->party_b_id) : '',
            'title'           => $item->title,
            'amount'          => $item->amount,
            'start_date'      => $item->start_date ? $item->start_date->format('Y-m-d') : '',
            'end_date'        => $item->end_date ? $item->end_date->format('Y-m-d') : '',
            'sign_date'       => $item->sign_date ? $item->sign_date->format('Y-m-d') : '',
            'content'         => $item->content,
            'attachments'     => $item->attachments,
            'status'          => $item->status,
            'created_at'      => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
            'updated_at'      => $item->updated_at ? $item->updated_at->format('Y-m-d H:i') : '',
        ]);
    }

    /** 创建合同 */
    public function store(Request $request)
    {
        $data = $request->only([
            'contract_number', 'contract_type',
            'party_a_type', 'party_a_id',
            'party_b_type', 'party_b_id',
            'title', 'amount',
            'start_date', 'end_date', 'sign_date',
            'content', 'attachments',
        ]);

        if (empty($data['contract_number'])) {
            return $this->fail('合同编号不能为空', 422);
        }
        if (empty($data['title'])) {
            return $this->fail('合同标题不能为空', 422);
        }

        $data['id']     = SnowflakeService::generate();
        $data['status'] = $request->input('status', 0);

        Contract::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /** 更新合同 */
    public function update(Request $request, string $hashid)
    {
        $id   = $this->decodeId($hashid);
        $item = Contract::find($id);
        if (!$item) {
            return $this->fail('合同不存在', 404);
        }

        $item->fill($request->only([
            'contract_number', 'contract_type',
            'party_a_type', 'party_a_id',
            'party_b_type', 'party_b_id',
            'title', 'amount',
            'start_date', 'end_date', 'sign_date',
            'content', 'attachments', 'status',
        ]));
        $item->save();

        return $this->success([], '更新成功');
    }

    /** 删除合同（需密码确认） */
    public function destroy(Request $request, string $hashid)
    {
        $adminId  = $request->adminId;
        $password = $request->input('password', '');

        $error = $this->confirmPassword($adminId, $password, $request);
        if ($error !== null) {
            return $this->fail($error, 422);
        }

        $id   = $this->decodeId($hashid);
        $item = Contract::find($id);
        if (!$item) {
            return $this->fail('合同不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }
}
