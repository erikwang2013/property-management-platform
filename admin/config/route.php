<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

use Webman\Route;

/**
 * API 路由配置
 *
 * 路由分组说明:
 * - /admin/*  管理端接口，需要 JWT 认证 + 权限校验
 * - /api/*    客户端接口（部分白名单，部分需认证）
 * - /health   健康检查（无需认证）
 *
 * API 版本策略:
 * - 版本号体现在接口路由中（如 /api/v1/*），不使用请求头
 * - 新增版本只需注册新的 /api/{version} 路由组，控制器按 app/api/{version}/controller/ 目录组织
 * - 不存在的版本路径由 FastRoute 直接返回 404
 */

// ============================================================
// 健康检查（全局，无需认证）
// ============================================================
Route::get('/health', [app\admin\controller\HealthController::class, 'index']);

// Prometheus 指标（无需认证）
Route::get('/metrics', [app\admin\controller\MetricsController::class, 'index']);

// security.txt — RFC 9116 安全漏洞报告联系人
Route::get('/.well-known/security.txt', function () {
    return response(<<<'TXT'
Contact: mailto:erik@erik.xyz
Expires: 2027-12-31T23:59:59Z
Preferred-Languages: zh, en
Canonical: https://erik.xyz/.well-known/security.txt
TXT
    , 200, ['Content-Type' => 'text/plain; charset=utf-8']);
});

// API 文档（DOCS_ENABLED 开关控制，默认关闭）
Route::get('/api/docs', [app\admin\controller\DocsController::class, 'index']);

// ============================================================
// 管理端路由
// ============================================================
Route::group('/admin', function () {
    // 资源路由本地包装：webman v2 的 Route::resource 把详情/更新路径写死成 {id}，
    // 而控制器形参是 $hashid（框架按参数名注入路由变量，见 App::getRouteCallback 的
    // array_merge($request->all(), $args)），对不上就抛 MissingInputException → 500。
    // 这里按同样的注册顺序展开，只把 {id} 换成 {hashid}；控制器无需改动。
    $resource = static function (string $name, string $controller): void {
        $name = trim($name, '/'); // 与 vendor Route::resource 一致：调用方传 '/fee-bill'，需去掉前导斜杠，否则会拼出 /admin//fee-bill
        if (method_exists($controller, 'index')) {
            Route::get("/$name", [$controller, 'index']);
        }
        if (method_exists($controller, 'store')) {
            Route::post("/$name", [$controller, 'store']);
        }
        if (method_exists($controller, 'show')) {
            Route::get("/$name/{hashid}", [$controller, 'show']);
        }
        if (method_exists($controller, 'update')) {
            Route::put("/$name/{hashid}", [$controller, 'update']);
        }
        if (method_exists($controller, 'destroy')) {
            Route::delete("/$name/{hashid}", [$controller, 'destroy']);
        }
    };

    // 仪表盘
    Route::get('/dashboard', [app\admin\controller\DashboardController::class, 'index']);
    Route::get('/dashboard/property', [app\admin\controller\DashboardController::class, 'propertyStats']);

    // 用户管理
    $resource('/user', app\admin\controller\UserController::class);
    Route::post('/user/batch/destroy', [app\admin\controller\UserController::class, 'batchDestroy']);
    Route::post('/user/batch/status', [app\admin\controller\UserController::class, 'batchStatus']);

    // 角色管理
    $resource('/role', app\admin\controller\RoleController::class);

    // 权限管理
    $resource('/permission', app\admin\controller\PermissionController::class);

    // 系统配置
    Route::get('/config', [app\admin\controller\ConfigController::class, 'index']);
    Route::post('/config', [app\admin\controller\ConfigController::class, 'store']);
    Route::put('/config/{hashid}', [app\admin\controller\ConfigController::class, 'update']);
    Route::delete('/config/{hashid}', [app\admin\controller\ConfigController::class, 'destroy']);

    // 操作日志
    Route::get('/log', [app\admin\controller\LogController::class, 'index']);

    // 个人中心
    Route::get('/profile', [app\admin\controller\ProfileController::class, 'show']);
    Route::put('/profile', [app\admin\controller\ProfileController::class, 'updateProfile']);
    Route::put('/profile/password', [app\admin\controller\ProfileController::class, 'updatePassword']);
    Route::post('/profile/logout', [app\admin\controller\ProfileController::class, 'logout']);

    // ============================================================
    // 报表中心 + 数据导出
    // ============================================================
    // 报表中心（Flutter 管理端与业主端共用；此前漏注册路由，导致该模块在真后端恒 404）
    Route::get('/report', [app\admin\controller\ReportController::class, 'index']);

    // 导出
    Route::post('/export/excel', [app\admin\controller\ExportController::class, 'excel']);
    Route::post('/export/pdf', [app\admin\controller\ExportController::class, 'pdf']);
    Route::post('/export/property-excel', [app\admin\controller\ExportController::class, 'propertyExcel']);

    // 导入
    Route::post('/import/users', [app\admin\controller\ImportController::class, 'users']);

    // 文件上传
    Route::post('/upload', [app\admin\controller\UploadController::class, 'upload']);

    // ============================================================
    // 物业管理 — 第1批核心业务
    // ============================================================
    // 小区管理
    $resource('/community', app\admin\controller\CommunityController::class);
    // 楼栋管理
    $resource('/building', app\admin\controller\BuildingController::class);
    // 单元管理
    $resource('/unit', app\admin\controller\UnitController::class);
    // 户型管理
    $resource('/room-type', app\admin\controller\RoomTypeController::class);
    // 房产管理（静态路由必须先于 resource 注册，否则被变量路由遮蔽）
    Route::get('/room/tree', [app\admin\controller\RoomController::class, 'tree']);
    $resource('/room', app\admin\controller\RoomController::class);
    // 业主管理
    $resource('/owner', app\admin\controller\OwnerController::class);
    Route::post('/owner/batch/import', [app\admin\controller\OwnerController::class, 'batchImport']);
    Route::post('/owner/batch/destroy', [app\admin\controller\OwnerController::class, 'batchDestroy']);
    // 租户管理
    $resource('/tenant', app\admin\controller\TenantController::class);
    // 费用类型
    $resource('/fee-type', app\admin\controller\FeeTypeController::class);
    // 账单管理
    $resource('/fee-bill', app\admin\controller\FeeBillController::class);
    Route::post('/fee-bill/batch/generate', [app\admin\controller\FeeBillController::class, 'batchGenerate']);
    // 缴费记录
    Route::get('/fee-payment', [app\admin\controller\FeePaymentController::class, 'index']);
    Route::post('/fee-payment/offline', [app\admin\controller\FeePaymentController::class, 'offlinePay']);
    // 公告管理
    $resource('/announcement', app\admin\controller\AnnouncementController::class);

    // ============================================================
    // 停车/设备
    // ============================================================
    // 停车管理
    $resource('/parking-space', app\admin\controller\ParkingSpaceController::class);
    $resource('/parking-vehicle', app\admin\controller\ParkingVehicleController::class);
    Route::get('/parking-record', [app\admin\controller\ParkingRecordController::class, 'index']);
    // 设备管理
    $resource('/equipment', app\admin\controller\EquipmentController::class);
    $resource('/equipment-maintenance', app\admin\controller\EquipmentMaintenanceController::class);

    // ============================================================
    // 高级模块
    // ============================================================
    $resource('/security-patrol', app\admin\controller\SecurityPatrolController::class);
    Route::get('/patrol-record', [app\admin\controller\PatrolRecordController::class, 'index']);
    Route::post('/patrol-record', [app\admin\controller\PatrolRecordController::class, 'store']);
    $resource('/cleaning-area', app\admin\controller\CleaningAreaController::class);
    Route::get('/cleaning-record', [app\admin\controller\CleaningRecordController::class, 'index']);
    Route::post('/cleaning-record', [app\admin\controller\CleaningRecordController::class, 'store']);
    $resource('/green-area', app\admin\controller\GreenAreaController::class);
    Route::get('/green-maintenance', [app\admin\controller\GreenMaintenanceController::class, 'index']);
    Route::post('/green-maintenance', [app\admin\controller\GreenMaintenanceController::class, 'store']);
    $resource('/staff', app\admin\controller\StaffController::class);
    Route::post('/staff/batch/status', [app\admin\controller\StaffController::class, 'batchStatus']);

    // ============================================================
    // 物业管理 — 支付
    // ============================================================
    // 支付订单（静态路由先于变量路由注册）
    Route::get('/payment-order', [app\admin\controller\PaymentController::class, 'orders']);
    Route::get('/payment-order/statistics', [app\admin\controller\PaymentController::class, 'statistics']);
    Route::get('/payment-order/{hashid}', [app\admin\controller\PaymentController::class, 'orderShow']);
    Route::post('/payment-order/create', [app\admin\controller\PaymentController::class, 'create']);
    Route::post('/payment-order/reconcile', [app\admin\controller\PaymentController::class, 'reconcile']);
    Route::post('/payment-order/{hashid}/refund', [app\admin\controller\PaymentController::class, 'refund']);
})->middleware([
    app\middleware\AdminAuth::class,
    app\middleware\TenantContext::class,
    app\middleware\AdminPermission::class,
    app\middleware\OperationLog::class,
]);

// ============================================================
// 公开接口 v1（版本体现在路由 /api/v1/*）
// ============================================================
Route::group('/api/v1', function () {
    // 点击验证码
    Route::post('/captcha/generate', [app\api\v1\controller\CaptchaController::class, 'generate']);
    Route::post('/captcha/verify', [app\api\v1\controller\CaptchaController::class, 'verify']);

    // 认证
    Route::post('/auth/login', [app\api\v1\controller\AuthController::class, 'login']);
    Route::post('/auth/refresh', [app\api\v1\controller\AuthController::class, 'refresh']);
});

// 安装向导（.installed 锁定前可访问）
Route::get('/install', [app\admin\controller\InstallController::class, 'index']);
Route::post('/install', [app\admin\controller\InstallController::class, 'store']);

// ============================================================
// 支付回调（第三方服务器调用，无需 JWT 认证，
// 签名验证由 PaymentController 回调方法内部自行处理）
// ============================================================
Route::post('/payment/wechat/callback', [app\admin\controller\PaymentController::class, 'callbackWechat']);
Route::post('/payment/alipay/callback', [app\admin\controller\PaymentController::class, 'callbackAlipay']);

// 关闭默认路由
Route::disableDefaultRoute();
