<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;
use hg\apidoc\annotation as Apidoc;

use app\common\BaseController;
use app\model\Room;
use support\Request;
use support\Response;
use InvalidArgumentException;

/**
 * @Apidoc\Group("home")
 */
class RoomController extends BaseController
{
    /**
     * 我的房间列表
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/service/rooms")
     */
    public function index(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);
        $page    = (int) $request->input('page', 1);

        $rooms = Room::whereHas('owners', function ($q) use ($ownerId) {
            $q->where('owner_id', $ownerId);
        })
            ->with('community')
            ->orderBy('created_at', 'desc')
            ->paginate(20, ['*'], 'page', $page)
            ->through(function ($room) {
                return [
                    'id'             => $this->encodeId($room->id),
                    'room_number'    => $room->room_number,
                    'floor'          => $room->floor,
                    'area_total'     => $room->area_total,
                    'usage_type'     => $room->usage_type,
                    'status'         => $room->status,
                    'community_name' => $room->community->name ?? '',
                ];
            });

        return $this->success($rooms);
    }

    /**
     * 房间详情
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/service/room/{hashid}")
     */
    public function show(Request $request, string $hashid): Response
    {
        try {
            $roomId = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的房间ID', 404);
        }

        $ownerId = $this->getOwnerId($request);

        $room = Room::with(['community', 'owners'])
            ->whereHas('owners', function ($q) use ($ownerId) {
                $q->where('owner_id', $ownerId);
            })
            ->find($roomId);

        if (!$room) {
            return $this->fail('房间不存在或无权访问', 404);
        }

        $data = [
            'id'          => $this->encodeId($room->id),
            'room_number' => $room->room_number,
            'floor'       => $room->floor,
            'area_indoor' => $room->area_indoor,
            'area_shared' => $room->area_shared,
            'area_total'  => $room->area_total,
            'orientation' => $room->orientation,
            'decoration'  => $room->decoration,
            'usage_type'  => $room->usage_type,
            'status'      => $room->status,
            'remark'      => $room->remark,
            'community'   => $room->community ? [
                'id'   => $this->encodeId($room->community->id),
                'name' => $room->community->name,
                'address' => $room->community->address,
            ] : null,
            'owners'      => $room->owners->map(function ($owner) {
                return [
                    'id'              => $this->encodeId($owner->id),
                    'name'            => $owner->name,
                    'relation_type'   => $owner->pivot->relation_type ?? '',
                    'ownership_ratio' => $owner->pivot->ownership_ratio ?? 0,
                    'start_date'      => $owner->pivot->start_date ?? '',
                    'end_date'        => $owner->pivot->end_date ?? '',
                ];
            })->values(),
        ];

        return $this->success($data);
    }
}
