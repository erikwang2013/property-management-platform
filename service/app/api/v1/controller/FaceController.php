<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;
use hg\apidoc\annotation as Apidoc;

use app\common\BaseController;
use app\model\FaceInfo;
use support\Request;
use support\Response;

/**
 * 人脸识别
 * @Apidoc\Group("extensions")
 * @Apidoc\Sort(5)
 */
class FaceController extends BaseController
{
    /**
     * 人脸注册
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/service/face/register")
     */
    public function register(Request $request): Response
    {
        $ownerId   = $this->getOwnerId($request);
        $faceImage = $request->input('face_image', '');

        if (empty($faceImage)) {
            return $this->fail('请上传人脸照片', 422);
        }

        // 查找是否已有记录
        $faceInfo = FaceInfo::where('owner_id', $ownerId)->first();

        if ($faceInfo) {
            // 更新已有记录，重新进入审核
            $faceInfo->face_image    = $faceImage;
            $faceInfo->verify_status = 1;
            $faceInfo->verified_at   = null;
            $faceInfo->save();

            return $this->success([
                'id'            => $this->encodeId($faceInfo->id),
                'verify_status' => 1,
            ], '人脸信息已更新，请等待审核');
        }

        // 创建新记录
        $id = $this->generateId();

        FaceInfo::create([
            'id'            => $id,
            'owner_id'      => $ownerId,
            'face_image'    => $faceImage,
            'verify_status' => 1,
        ]);

        return $this->success([
            'id'            => $this->encodeId($id),
            'verify_status' => 1,
        ], '人脸信息已提交，请等待审核');
    }

    /**
     * 查询人脸审核状态
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/service/face/status")
     */
    public function status(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);

        $faceInfo = FaceInfo::where('owner_id', $ownerId)->first();

        if (!$faceInfo) {
            return $this->success([
                'has_record'    => false,
                'verify_status' => 0,
            ]);
        }

        return $this->success([
            'has_record'    => true,
            'id'            => $this->encodeId($faceInfo->id),
            'face_image'    => $faceInfo->face_image,
            'verify_status' => $faceInfo->verify_status,
            'verified_at'   => $faceInfo->verified_at ? $faceInfo->verified_at->format('Y-m-d H:i') : '',
            'created_at'    => $faceInfo->created_at ? $faceInfo->created_at->format('Y-m-d H:i') : '',
        ]);
    }
}
