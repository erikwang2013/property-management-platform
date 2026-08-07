<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;
use hg\apidoc\annotation as Apidoc;

use app\common\SnowflakeService;
use app\model\MallCategory;
use app\model\MallOrder;
use app\model\MallProduct;
use InvalidArgumentException;
use support\Request;

/**
 * 扩展功能
 * @Apidoc\Group("extensions")
 */
class MallController extends BaseController
{
    /**
     * 检测当前请求是否为分类（否则为商品）
     */
    private function isCategory(Request $request): bool
    {
        return str_contains($request->path(), 'mall-category');
    }

    // ============================================================
    // 标准资源方法（Route::resource 需要，按 path 分流到分类/商品）
    // ============================================================

    /**
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/mall-category")
     */
    public function index(Request $request)
    {
        return $this->isCategory($request) ? $this->categories($request) : $this->products($request);
    }

    /**
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/mall-category")
     */
    public function store(Request $request)
    {
        return $this->isCategory($request) ? $this->categoryStore($request) : $this->productStore($request);
    }

    /**
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/mall-category/{hashid}")
     */
    public function show(Request $request, string $hashid)
    {
        // 商品仅支持show
        return $this->isCategory($request) ? $this->fail('不支持的操作', 405) : $this->productDetail($request, $hashid);
    }

    /**
     * @Apidoc\Method("PUT")
     * @Apidoc\Url("/admin/mall-category/{hashid}")
     */
    public function update(Request $request, string $hashid)
    {
        return $this->isCategory($request) ? $this->categoryUpdate($request, $hashid) : $this->productUpdate($request, $hashid);
    }

    /**
     * @Apidoc\Method("DELETE")
     * @Apidoc\Url("/admin/mall-category/{hashid}")
     */
    public function destroy(Request $request, string $hashid)
    {
        return $this->isCategory($request) ? $this->categoryDestroy($request, $hashid) : $this->productDestroy($request, $hashid);
    }

    // ============================================================
    // 分类管理
    // ============================================================

    /**
     * 分类列表
     * GET /admin/mall-category
     */
    public function categories(Request $request)
    {
        $list = MallCategory::orderBy('sort', 'asc')
            ->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'         => $this->encodeId($item->id),
                    'name'       => $item->name,
                    'icon'       => $item->icon,
                    'sort'       => $item->sort,
                    'status'     => $item->status,
                    'created_at' => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 创建分类
     * POST /admin/mall-category
     */
    public function categoryStore(Request $request)
    {
        $data = $request->only(['name', 'icon', 'sort']);

        if (empty($data['name'])) {
            return $this->fail('分类名称不能为空', 422);
        }

        $data['id']     = SnowflakeService::generate();
        $data['status'] = 1;

        MallCategory::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /**
     * 更新分类
     * PUT /admin/mall-category/{hashid}
     */
    public function categoryUpdate(Request $request, string $hashid)
    {
        try {
            $id = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的分类ID', 404);
        }

        $item = MallCategory::find($id);
        if (!$item) {
            return $this->fail('分类不存在', 404);
        }

        $item->fill($request->only(['name', 'icon', 'sort', 'status']));
        $item->save();

        return $this->success([], '更新成功');
    }

    /**
     * 删除分类
     * DELETE /admin/mall-category/{hashid}
     */
    public function categoryDestroy(Request $request, string $hashid)
    {
        $adminId  = $request->adminId;
        $password = $request->input('password', '');

        $error = $this->confirmPassword($adminId, $password, $request);
        if ($error !== null) {
            return $this->fail($error, 422);
        }

        try {
            $id = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的分类ID', 404);
        }

        $item = MallCategory::find($id);
        if (!$item) {
            return $this->fail('分类不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }

    // ============================================================
    // 商品管理
    // ============================================================

    /**
     * 商品列表
     * GET /admin/mall-product?category_id=&community_id=&status=
     */
    public function products(Request $request)
    {
        $categoryId  = $request->input('category_id');
        $communityId = $request->input('community_id');
        $status      = $request->input('status');
        $keyword     = $request->input('keyword', '');

        $query = MallProduct::with('category');
        if (!empty($categoryId)) {
            $query->where('category_id', (int) $categoryId);
        }
        if (!empty($communityId)) {
            $query->where('community_id', (int) $communityId);
        }
        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        }
        if (!empty($keyword)) {
            $query->where('name', 'like', "%{$keyword}%");
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
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
                    'status'         => $item->status,
                    'created_at'     => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 商品详情
     * GET /admin/mall-product/{hashid}
     */
    public function productDetail(Request $request, string $hashid)
    {
        try {
            $id = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的商品ID', 404);
        }

        $item = MallProduct::with('category')->find($id);
        if (!$item) {
            return $this->fail('商品不存在', 404);
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
            'status'         => $item->status,
            'created_at'     => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
            'updated_at'     => $item->updated_at ? $item->updated_at->format('Y-m-d H:i') : '',
        ]);
    }

    /**
     * 创建商品
     * POST /admin/mall-product
     */
    public function productStore(Request $request)
    {
        $data = $request->only([
            'category_id', 'community_id', 'name', 'description', 'images',
            'price', 'original_price', 'stock', 'is_recommend',
        ]);

        if (empty($data['name'])) {
            return $this->fail('商品名称不能为空', 422);
        }

        $data['id']     = SnowflakeService::generate();
        $data['status'] = 1;

        MallProduct::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /**
     * 更新商品
     * PUT /admin/mall-product/{hashid}
     */
    public function productUpdate(Request $request, string $hashid)
    {
        try {
            $id = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的商品ID', 404);
        }

        $item = MallProduct::find($id);
        if (!$item) {
            return $this->fail('商品不存在', 404);
        }

        $item->fill($request->only([
            'category_id', 'community_id', 'name', 'description', 'images',
            'price', 'original_price', 'stock', 'is_recommend', 'status',
        ]));
        $item->save();

        return $this->success([], '更新成功');
    }

    /**
     * 删除商品
     * DELETE /admin/mall-product/{hashid}
     */
    public function productDestroy(Request $request, string $hashid)
    {
        $adminId  = $request->adminId;
        $password = $request->input('password', '');

        $error = $this->confirmPassword($adminId, $password, $request);
        if ($error !== null) {
            return $this->fail($error, 422);
        }

        try {
            $id = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的商品ID', 404);
        }

        $item = MallProduct::find($id);
        if (!$item) {
            return $this->fail('商品不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }

    // ============================================================
    // 订单管理
    // ============================================================

    /**
     * 订单列表
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/mall-order")
     */
    public function orders(Request $request)
    {
        $status = $request->input('status');

        $query = MallOrder::with('product');
        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id'              => $this->encodeId($item->id),
                    'order_number'    => $item->order_number,
                    'owner_id'        => $item->owner_id,
                    'product_id'      => $item->product_id ? $this->encodeId($item->product_id) : '',
                    'product_name'    => $item->product->name ?? '',
                    'quantity'        => $item->quantity,
                    'amount'          => $item->amount,
                    'status'          => $item->status,
                    'address'         => $item->address,
                    'contact_phone'   => $item->contact_phone,
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

    /**
     * 订单详情
     * @Apidoc\Method("GET")
     * @Apidoc\Url("/admin/mall-order/{hashid}")
     */
    public function orderShow(Request $request, string $hashid)
    {
        try {
            $id = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的订单ID', 404);
        }

        $item = MallOrder::with('product')->find($id);
        if (!$item) {
            return $this->fail('订单不存在', 404);
        }

        return $this->success([
            'id'              => $this->encodeId($item->id),
            'order_number'    => $item->order_number,
            'owner_id'        => $item->owner_id,
            'product_id'      => $item->product_id ? $this->encodeId($item->product_id) : '',
            'product_name'    => $item->product->name ?? '',
            'quantity'        => $item->quantity,
            'amount'          => $item->amount,
            'status'          => $item->status,
            'address'         => $item->address,
            'contact_phone'   => $item->contact_phone,
            'express_company' => $item->express_company,
            'express_number'  => $item->express_number,
            'paid_at'         => $item->paid_at ? $item->paid_at->format('Y-m-d H:i') : '',
            'shipped_at'      => $item->shipped_at ? $item->shipped_at->format('Y-m-d H:i') : '',
            'completed_at'    => $item->completed_at ? $item->completed_at->format('Y-m-d H:i') : '',
            'remark'          => $item->remark,
            'created_at'      => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
        ]);
    }

    /**
     * 发货
     * @Apidoc\Method("PUT")
     * @Apidoc\Url("/admin/mall-order/{hashid}/ship")
     */
    public function ship(Request $request, string $hashid)
    {
        try {
            $id = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的订单ID', 404);
        }

        $item = MallOrder::find($id);
        if (!$item) {
            return $this->fail('订单不存在', 404);
        }

        if ($item->status !== 1) {
            return $this->fail('仅已支付订单可以发货', 422);
        }

        $item->status          = 2;
        $item->express_company = $request->input('express_company', '');
        $item->express_number  = $request->input('express_number', '');
        $item->shipped_at      = date('Y-m-d H:i:s');
        $item->save();

        return $this->success([], '发货成功');
    }

    /**
     * 退款
     * @Apidoc\Method("POST")
     * @Apidoc\Url("/admin/mall-order/{hashid}/refund")
     */
    public function refundOrder(Request $request, string $hashid)
    {
        try {
            $id = $this->decodeId($hashid);
        } catch (InvalidArgumentException) {
            return $this->fail('无效的订单ID', 404);
        }

        $item = MallOrder::find($id);
        if (!$item) {
            return $this->fail('订单不存在', 404);
        }

        if (!in_array($item->status, [1, 2])) {
            return $this->fail('仅已支付或已发货订单可以退款', 422);
        }

        $remark = $request->input('remark', '');

        $item->status = 4;
        $item->remark = $remark;
        $item->save();

        return $this->success([], '退款成功');
    }
}
