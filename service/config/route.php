<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

use Webman\Route;

/**
 * 物业管理系统-业务端 API 路由配置
 *
 * 路由分组说明:
 * - /service/v1/*  业主端接口 v1，需要 JWT 认证
 * - /api/v1/*      公开接口 v1（验证码、登录注册）
 * - /open/v1/*     开放 API v1（X-API-Key 鉴权）
 * - /health        健康检查
 *
 * API 版本策略: 版本号体现在接口路由中（/api/v1/*、/service/v1/*、/open/v1/*），
 * 不使用请求头；新增版本注册新的 /{namespace}/v{version} 路由组即可，
 * 不存在的版本路径由 FastRoute 直接返回 404。
 */

// 健康检查
Route::get('/health', function () {
    return json(['code' => 0, 'message' => 'ok', 'data' => ['service' => 'property-service']]);
});

// Prometheus 指标
Route::get('/metrics', [app\api\v1\controller\MetricsController::class, 'index']);

// 公开接口 v1
Route::group('/api/v1', function () {
    Route::post('/captcha/generate', [app\api\v1\controller\CaptchaController::class, 'generate']);
    Route::post('/captcha/verify', [app\api\v1\controller\CaptchaController::class, 'verify']);
    Route::post('/auth/login', [app\api\v1\controller\AuthController::class, 'login']);
    Route::post('/auth/register', [app\api\v1\controller\AuthController::class, 'register']);
    Route::post('/auth/refresh', [app\api\v1\controller\AuthController::class, 'refresh']);
});

// 业主端接口 v1
Route::group('/service/v1', function () {
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

    // 公告
    Route::get('/announcements', [app\api\v1\controller\AnnouncementController::class, 'index']);
    Route::get('/announcement/{hashid}', [app\api\v1\controller\AnnouncementController::class, 'show']);

    // 个人信息
    Route::get('/profile', [app\api\v1\controller\ProfileController::class, 'index']);
    Route::put('/profile', [app\api\v1\controller\ProfileController::class, 'update']);
    Route::put('/profile/password', [app\api\v1\controller\ProfileController::class, 'updatePassword']);
    Route::post('/profile/logout', [app\api\v1\controller\ProfileController::class, 'logout']);

    // ============================================================
    // 停车
    // ============================================================
    Route::get('/parking/vehicles', [app\api\v1\controller\ParkingController::class, 'vehicles']);
    Route::get('/parking/spaces', [app\api\v1\controller\ParkingController::class, 'spaces']);
    Route::get('/parking/records', [app\api\v1\controller\ParkingController::class, 'records']);
})->middleware([
    app\middleware\ServiceAuth::class,
    app\middleware\OperationLog::class,
]);

// 开放 API v1（入站对外只读接口，X-API-Key 鉴权）
Route::group('/open/v1', function () {
    Route::get('/announcements', [app\api\v1\controller\OpenApiController::class, 'announcements']);
    Route::get('/bills', [app\api\v1\controller\OpenApiController::class, 'bills']);
})->middleware([
    app\middleware\ApiKeyAuth::class,
]);

Route::disableDefaultRoute();
