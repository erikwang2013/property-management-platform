<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;

use app\model\FaceInfo;
use InvalidArgumentException;
use support\Request;

class FaceController extends BaseController
{
    /**
     * 人脸记录列表
     * GET /admin/face?verify_status=&page=1
     */
    public function index(Request $request)
    {
        $verifyStatus = $request->input('verify_status');
        $keyword      = $request->input('keyword', '');

        $query = FaceInfo::query();
        if ($verifyStatus !== null && $verifyStatus !== '') {
            $query->where('verify_status', (int) $verifyStatus);
        }
        if (!empty($keyword)) {
            $query->whereHas('owner', function ($q) use ($keyword) {
                $q->where('name', 'like', "%{$keyword}%")
                  ->orWhere('phone', 'like', "%{$keyword}%");
            });
        }

        $list = $query->with('owner')
            ->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'            => $this->encodeId($item->id),
                    'owner_id'      => $item->owner_id,
                    'owner_name'    => $item->owner->name ?? '',
                    'face_image'    => $item->face_image,
                    'verify_status' => $item->verify_status,
                    'verified_at'   => $item->verified_at ? $item->verified_at->format('Y-m-d H:i') : '',
                    'created_at'    => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 审核通过
     * PUT /admin/face/{hashid}/verify
     */
    public function verify(Request $request, string $hashid)
    {
        try {
            $id = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的人脸记录ID', 404);
        }

        $item = FaceInfo::find($id);
        if (!$item) {
            return $this->fail('人脸记录不存在', 404);
        }

        $item->verify_status = 2;
        $item->verified_at   = date('Y-m-d H:i:s');
        $item->save();

        return $this->success([], '审核通过');
    }

    /**
     * 审核拒绝
     * PUT /admin/face/{hashid}/reject
     */
    public function reject(Request $request, string $hashid)
    {
        try {
            $id = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的人脸记录ID', 404);
        }

        $item = FaceInfo::find($id);
        if (!$item) {
            return $this->fail('人脸记录不存在', 404);
        }

        $item->verify_status = 3;
        $item->save();

        return $this->success([], '已拒绝');
    }
}
