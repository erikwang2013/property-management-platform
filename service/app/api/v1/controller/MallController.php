<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;
use hg\apidoc\annotation as Apidoc;

use app\common\BaseController;
use app\common\LockService;
use app\model\MallOrder;
use app\model\MallProduct;
use InvalidArgumentException;
use support\Db;
use support\Request;
use support\Response;

/**
 * 社区商城
 * @Apidoc\Group("extensions")
 * @Apidoc\Sort(3)
 */
class MallController extends BaseController
{
    /**
     * 商品列表
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/service/mall/products")
     */
    public function products(Request $request): Response
    {
        $categoryId = $request->input('category_id');
        $keyword    = $request->input('keyword', '');

        $query = MallProduct::where('status', 1)
            ->with('category');

        if (!empty($categoryId)) {
            $query->where('category_id', (int) $categoryId);
        }
        if (!empty($keyword)) {
            $query->where('name', 'like', "%{$keyword}%");
        }

        $list = $query->orderBy('is_recommend', 'desc')
            ->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'             => $this->encodeId($item->id),
                    'category_id'    => $item->category_id,
                    'category_name'  => $item->category->name ?? '',
                    'name'           => $item->name,
                    'description'    => $item->description,
                    'images'         => $item->images,
                    'price'          => $item->price,
                    'original_price' => $item->original_price,
                    'stock'          => $item->stock,
                    'sales'          => $item->sales,
                    'is_recommend'   => $item->is_recommend,
                    'created_at'     => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 商品详情
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/service/mall/product/{hashid}")
     */
    public function productDetail(Request $request, string $hashid): Response
    {
        try {
            $id = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的商品ID', 404);
        }

        $item = MallProduct::with('category')->find($id);
        if (!$item || $item->status !== 1) {
            return $this->fail('商品不存在或已下架', 404);
        }

        return $this->success([
            'id'             => $this->encodeId($item->id),
            'category_id'    => $item->category_id,
            'category_name'  => $item->category->name ?? '',
            'community_id'   => $item->community_id,
            'name'           => $item->name,
            'description'    => $item->description,
            'images'         => $item->images,
            'price'          => $item->price,
            'original_price' => $item->original_price,
            'stock'          => $item->stock,
            'sales'          => $item->sales,
            'is_recommend'   => $item->is_recommend,
            'created_at'     => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
        ]);
    }

    /**
     * 创建订单
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/service/mall/order")
     */
    public function createOrder(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);

        $productHashid = $request->input('product_id', '');
        $quantity      = (int) $request->input('quantity', 1);
        $address       = $request->input('address', '');
        $contactPhone  = $request->input('contact_phone', '');

        if (empty($productHashid)) {
            return $this->fail('请选择商品', 422);
        }

        if ($quantity <= 0) {
            return $this->fail('数量必须大于0', 422);
        }

        if (empty($address)) {
            return $this->fail('请填写收货地址', 422);
        }

        try {
            $productId = $this->decodeId($productHashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的商品ID', 404);
        }

        $product = MallProduct::find($productId);
        if (!$product || $product->status !== 1) {
            return $this->fail('商品不存在或已下架', 404);
        }

        $orderId      = $this->generateId();
        $orderNumber  = 'MALL' . date('YmdHis') . str_pad((string) mt_rand(0, 999), 3, '0', STR_PAD_LEFT);
        $amount       = round((float) $product->price * $quantity, 2);

        // 用户级防重复提交锁（事务外，不干扰原子扣库存语义）
        $lockKey = "lock:mall_order:{$ownerId}";
        $token   = LockService::acquire($lockKey, 5);
        if ($token === null) {
            return $this->fail('正在处理中', 429);
        }

        try {
            // 原子扣库存防超卖：条件满足才扣减，0 影响行说明库存不足
            try {
            Db::transaction(function () use ($orderId, $orderNumber, $ownerId, $productId, $quantity, $amount, $address, $contactPhone) {
                $affected = MallProduct::where('id', $productId)
                    ->where('status', 1)
                    ->where('stock', '>=', $quantity)
                    ->decrement('stock', $quantity);
                if (!$affected) {
                    throw new \RuntimeException('库存不足');
                }
                MallProduct::where('id', $productId)->increment('sales', $quantity);

                MallOrder::create([
                    'id'            => $orderId,
                    'order_number'  => $orderNumber,
                    'owner_id'      => $ownerId,
                    'product_id'    => $productId,
                    'quantity'      => $quantity,
                    'amount'        => $amount,
                    'status'        => 0,
                    'address'       => $address,
                    'contact_phone' => $contactPhone,
                ]);
            });
            } catch (\RuntimeException $e) {
                return $this->fail($e->getMessage(), 422);
            } catch (\Throwable) {
                return $this->fail('下单失败，请稍后重试', 500);
            }

            return $this->success([
                'id'           => $this->encodeId($orderId),
                'order_number' => $orderNumber,
                'amount'       => $amount,
            ], '下单成功');
        } finally {
            LockService::release($lockKey, $token);
        }
    }

    /**
     * 我的订单
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/service/mall/orders")
     */
    public function myOrders(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);
        $status  = $request->input('status');

        $query = MallOrder::where('owner_id', $ownerId)
            ->with('product');

        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'              => $this->encodeId($item->id),
                    'order_number'    => $item->order_number,
                    'product_id'      => $item->product_id ? $this->encodeId($item->product_id) : '',
                    'product_name'    => $item->product->name ?? '',
                    'product_images'  => $item->product->images ?? [],
                    'quantity'        => $item->quantity,
                    'amount'          => $item->amount,
                    'status'          => $item->status,
                    'address'         => $item->address,
                    'express_company' => $item->express_company,
                    'express_number'  => $item->express_number,
                    'paid_at'         => $item->paid_at ? $item->paid_at->format('Y-m-d H:i') : '',
                    'shipped_at'      => $item->shipped_at ? $item->shipped_at->format('Y-m-d H:i') : '',
                    'completed_at'    => $item->completed_at ? $item->completed_at->format('Y-m-d H:i') : '',
                    'created_at'      => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }
}
