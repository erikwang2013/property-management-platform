<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

use Webman\Route;

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
})->middleware([
    app\middleware\ServiceAuth::class,
]);

Route::disableDefaultRoute();
