<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

use Webman\Route;

// 商业版本开关（config/edition.php，env EDITIONS: lite/standard/full，逐级累进）
function edition_supports(string $minEdition): bool
{
    $config = config('edition', []);
    $current = $config['levels'][strtolower($config['default'] ?? 'full')] ?? 3;
    return $current >= ($config['levels'][strtolower($minEdition)] ?? 9);
}

/**
 * 物业管理系统-业务端 API 路由配置
 *
 * 路由分组说明:
 * - /service/*  业主端接口，需要 JWT 认证
 * - /api/*      公开接口（验证码、登录注册）
 * - /health     健康检查
 */

// 健康检查
Route::get('/health', function () {
    return json(['code' => 0, 'message' => 'ok', 'data' => ['service' => 'property-service']]);
});

// 公开接口
Route::group('/api', function () {
    Route::post('/captcha/generate', [app\api\v1\controller\CaptchaController::class, 'generate']);
    Route::post('/captcha/verify', [app\api\v1\controller\CaptchaController::class, 'verify']);
    Route::post('/auth/login', [app\api\v1\controller\AuthController::class, 'login']);
    Route::post('/auth/register', [app\api\v1\controller\AuthController::class, 'register']);
    Route::post('/auth/refresh', [app\api\v1\controller\AuthController::class, 'refresh']);
})->middleware([
    app\middleware\ApiVersion::class,
]);

// 业主端认证接口
Route::group('/service', function () {
    // 首页
    Route::get('/home', [app\api\v1\controller\HomeController::class, 'index']);

    // 我的房产
    Route::get('/rooms', [app\api\v1\controller\RoomController::class, 'index']);
    Route::get('/room/{hashid}', [app\api\v1\controller\RoomController::class, 'show']);

    // 费用管理
    Route::get('/fees/bills', [app\api\v1\controller\FeeController::class, 'bills']);
    Route::get('/fees/bill/{hashid}', [app\api\v1\controller\FeeController::class, 'billDetail']);
    Route::get('/fees/payments', [app\api\v1\controller\FeeController::class, 'payments']);
    Route::post('/fees/pay', [app\api\v1\controller\FeeController::class, 'pay']);
    Route::get('/fees/statistics', [app\api\v1\controller\FeeController::class, 'statistics']);

    // 报修
    Route::get('/repairs', [app\api\v1\controller\RepairController::class, 'index']);
    Route::get('/repair/{hashid}', [app\api\v1\controller\RepairController::class, 'show']);
    Route::post('/repair', [app\api\v1\controller\RepairController::class, 'store']);
    Route::delete('/repair/{hashid}', [app\api\v1\controller\RepairController::class, 'destroy']);
    Route::post('/repair/{hashid}/rate', [app\api\v1\controller\RepairController::class, 'rate']);

    // 投诉建议
    Route::get('/complaints', [app\api\v1\controller\ComplaintController::class, 'index']);
    Route::get('/complaint/{hashid}', [app\api\v1\controller\ComplaintController::class, 'show']);
    Route::post('/complaint', [app\api\v1\controller\ComplaintController::class, 'store']);
    Route::post('/complaint/{hashid}/satisfaction', [app\api\v1\controller\ComplaintController::class, 'satisfaction']);

    // 公告
    Route::get('/announcements', [app\api\v1\controller\AnnouncementController::class, 'index']);
    Route::get('/announcement/{hashid}', [app\api\v1\controller\AnnouncementController::class, 'show']);

    // 个人信息
    Route::get('/profile', [app\api\v1\controller\ProfileController::class, 'index']);
    Route::put('/profile', [app\api\v1\controller\ProfileController::class, 'update']);
    Route::put('/profile/password', [app\api\v1\controller\ProfileController::class, 'updatePassword']);
    Route::post('/profile/logout', [app\api\v1\controller\ProfileController::class, 'logout']);

    // ============================================================
    // 标准版(Standard) 及以上：停车/访客
    // ============================================================
if (edition_supports('standard')) {
        // 停车管理
        Route::get('/parking/vehicles', [app\api\v1\controller\ParkingController::class, 'vehicles']);
        Route::get('/parking/spaces', [app\api\v1\controller\ParkingController::class, 'spaces']);
        Route::get('/parking/records', [app\api\v1\controller\ParkingController::class, 'records']);
        // 访客管理
        Route::get('/visitors', [app\api\v1\controller\VisitorController::class, 'index']);
        Route::post('/visitor', [app\api\v1\controller\VisitorController::class, 'store']);
        Route::put('/visitor/{hashid}', [app\api\v1\controller\VisitorController::class, 'update']);
        Route::delete('/visitor/{hashid}', [app\api\v1\controller\VisitorController::class, 'destroy']);
    }

    // ============================================================
    // 完整版(Full) 及以上：活动/通知/投票/商城/问答/人脸
    // ============================================================
if (edition_supports('full')) {
        // 社区活动
        Route::get('/activities', [app\api\v1\controller\ActivityController::class, 'index']);
        Route::get('/activity/{hashid}', [app\api\v1\controller\ActivityController::class, 'show']);
        Route::post('/activity/{hashid}/signup', [app\api\v1\controller\ActivityController::class, 'signup']);
        Route::post('/activity/{hashid}/cancel', [app\api\v1\controller\ActivityController::class, 'cancel']);

        // 消息通知
        Route::get('/notifications', [app\api\v1\controller\NotificationController::class, 'index']);
        Route::put('/notification/{hashid}/read', [app\api\v1\controller\NotificationController::class, 'markRead']);
        Route::put('/notifications/read-all', [app\api\v1\controller\NotificationController::class, 'markAllRead']);
        // 投票
        Route::get('/votes', [app\api\v1\controller\VoteController::class, 'index']);
        Route::get('/vote/{hashid}', [app\api\v1\controller\VoteController::class, 'show']);
        Route::post('/vote/{hashid}/cast', [app\api\v1\controller\VoteController::class, 'cast']);
        // 商城
        Route::get('/mall/products', [app\api\v1\controller\MallController::class, 'products']);
        Route::get('/mall/product/{hashid}', [app\api\v1\controller\MallController::class, 'productDetail']);
        Route::post('/mall/order', [app\api\v1\controller\MallController::class, 'createOrder']);
        Route::get('/mall/orders', [app\api\v1\controller\MallController::class, 'myOrders']);
        // 智能问答
        Route::post('/chat/ask', [app\api\v1\controller\KnowledgeController::class, 'ask']);
        // 人脸
        Route::post('/face/register', [app\api\v1\controller\FaceController::class, 'register']);
        Route::get('/face/status', [app\api\v1\controller\FaceController::class, 'status']);
    }
})->middleware([
    app\middleware\ServiceAuth::class,
    app\middleware\ApiVersion::class,
    app\middleware\OperationLog::class,
]);

Route::disableDefaultRoute();
