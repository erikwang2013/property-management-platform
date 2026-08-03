<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

use Webman\Route;
use support\Request;

/**
 * API 路由配置
 *
 * 路由分组说明:
 * - /admin/*  管理端接口，需要 JWT 认证 + 权限校验
 * - /api/*    客户端接口（部分白名单，部分需认证）
 * - /health   健康检查（无需认证）
 *
 * API 版本策略:
 * - 版本号通过请求头 API-Version 携带（如 "v1"、"v2"），不在 URL 中体现
 * - 缺失时默认使用 v1
 * - 由 ApiVersion 中间件校验，路由闭包按版本解析对应控制器
 */

/**
 * 创建版本化 API 路由闭包
 */
function v(string $controller, string $action): \Closure
{
    return function (Request $request) use ($controller, $action) {
        $version = $request->apiVersion ?? 'v1';
        $class = "\\app\\api\\{$version}\\controller\\{$controller}";
        return (new $class)->{$action}($request);
    };
}

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

// API 文档（全局，无需认证）
Route::get('/api/docs', [app\admin\controller\DocsController::class, 'index']);

// ============================================================
// 管理端路由
// ============================================================
Route::group('/admin', function () {
    // 仪表盘
    Route::get('/dashboard', [app\admin\controller\DashboardController::class, 'index']);
    Route::get('/dashboard/property', [app\admin\controller\DashboardController::class, 'propertyStats']);

    // 用户管理
    Route::resource('/user', app\admin\controller\UserController::class);
    Route::post('/user/batch/destroy', [app\admin\controller\UserController::class, 'batchDestroy']);
    Route::post('/user/batch/status', [app\admin\controller\UserController::class, 'batchStatus']);

    // 角色管理
    Route::resource('/role', app\admin\controller\RoleController::class);

    // 权限管理
    Route::resource('/permission', app\admin\controller\PermissionController::class);

    // 系统配置
    Route::get('/config', [app\admin\controller\ConfigController::class, 'index']);
    Route::post('/config', [app\admin\controller\ConfigController::class, 'store']);
    Route::put('/config/{id}', [app\admin\controller\ConfigController::class, 'update']);
    Route::delete('/config/{id}', [app\admin\controller\ConfigController::class, 'destroy']);

    // 操作日志
    Route::get('/log', [app\admin\controller\LogController::class, 'index']);

    // 个人中心
    Route::put('/profile', [app\admin\controller\ProfileController::class, 'updateProfile']);
    Route::put('/profile/password', [app\admin\controller\ProfileController::class, 'updatePassword']);
    Route::post('/profile/logout', [app\admin\controller\ProfileController::class, 'logout']);

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
    Route::resource('/community', app\admin\controller\CommunityController::class);
    // 楼栋管理
    Route::resource('/building', app\admin\controller\BuildingController::class);
    // 单元管理
    Route::resource('/unit', app\admin\controller\UnitController::class);
    // 户型管理
    Route::resource('/room-type', app\admin\controller\RoomTypeController::class);
    // 房产管理
    Route::resource('/room', app\admin\controller\RoomController::class);
    Route::get('/room/tree', [app\admin\controller\RoomController::class, 'tree']);
    // 业主管理
    Route::resource('/owner', app\admin\controller\OwnerController::class);
    Route::post('/owner/batch/import', [app\admin\controller\OwnerController::class, 'batchImport']);
    Route::post('/owner/batch/destroy', [app\admin\controller\OwnerController::class, 'batchDestroy']);
    // 租户管理
    Route::resource('/tenant', app\admin\controller\TenantController::class);
    // 费用类型
    Route::resource('/fee-type', app\admin\controller\FeeTypeController::class);
    // 账单管理
    Route::resource('/fee-bill', app\admin\controller\FeeBillController::class);
    Route::post('/fee-bill/batch/generate', [app\admin\controller\FeeBillController::class, 'batchGenerate']);
    // 缴费记录
    Route::get('/fee-payment', [app\admin\controller\FeePaymentController::class, 'index']);
    Route::post('/fee-payment/offline', [app\admin\controller\FeePaymentController::class, 'offlinePay']);
    // 报修管理
    Route::resource('/repair', app\admin\controller\RepairController::class);
    Route::put('/repair/{id}/assign', [app\admin\controller\RepairController::class, 'assign']);
    Route::post('/repair/{id}/progress', [app\admin\controller\RepairController::class, 'progress']);
    // 公告管理
    Route::resource('/announcement', app\admin\controller\AnnouncementController::class);

    // ============================================================
    // 物业管理 — 第2批辅助业务
    // ============================================================
    // 停车管理
    Route::resource('/parking-space', app\admin\controller\ParkingSpaceController::class);
    Route::resource('/parking-vehicle', app\admin\controller\ParkingVehicleController::class);
    Route::get('/parking-record', [app\admin\controller\ParkingRecordController::class, 'index']);
    // 设备管理
    Route::resource('/equipment', app\admin\controller\EquipmentController::class);
    Route::resource('/equipment-maintenance', app\admin\controller\EquipmentMaintenanceController::class);
    // 投诉管理
    Route::get('/complaint', [app\admin\controller\ComplaintController::class, 'index']);
    Route::get('/complaint/{id}', [app\admin\controller\ComplaintController::class, 'show']);
    Route::put('/complaint/{id}/handle', [app\admin\controller\ComplaintController::class, 'handle']);
    Route::post('/complaint/{id}/visit', [app\admin\controller\ComplaintController::class, 'visit']);
    // 访客管理
    Route::get('/visitor', [app\admin\controller\VisitorController::class, 'index']);
    Route::put('/visitor/{id}/approve', [app\admin\controller\VisitorController::class, 'approve']);
    // 合同管理
    Route::resource('/contract', app\admin\controller\ContractController::class);
    // 财务管理
    Route::get('/finance/statistics', [app\admin\controller\FinanceController::class, 'statistics']);
    Route::resource('/finance-income', app\admin\controller\FinanceController::class, ['names' => 'finance.income']);
    Route::resource('/finance-expense', app\admin\controller\FinanceController::class, ['names' => 'finance.expense']);

    // ============================================================
    // 物业管理 — 第3批高级功能
    // ============================================================
    Route::resource('/security-patrol', app\admin\controller\SecurityPatrolController::class);
    Route::get('/patrol-record', [app\admin\controller\PatrolRecordController::class, 'index']);
    Route::post('/patrol-record', [app\admin\controller\PatrolRecordController::class, 'store']);
    Route::resource('/cleaning-area', app\admin\controller\CleaningAreaController::class);
    Route::get('/cleaning-record', [app\admin\controller\CleaningRecordController::class, 'index']);
    Route::post('/cleaning-record', [app\admin\controller\CleaningRecordController::class, 'store']);
    Route::resource('/green-area', app\admin\controller\GreenAreaController::class);
    Route::get('/green-maintenance', [app\admin\controller\GreenMaintenanceController::class, 'index']);
    Route::post('/green-maintenance', [app\admin\controller\GreenMaintenanceController::class, 'store']);
    Route::resource('/activity', app\admin\controller\ActivityController::class);
    Route::get('/activity-signup', [app\admin\controller\ActivitySignupController::class, 'index']);
    Route::put('/activity-signup/{id}/checkin', [app\admin\controller\ActivitySignupController::class, 'checkin']);
    Route::resource('/energy-meter', app\admin\controller\EnergyMeterController::class);
    Route::get('/energy-record', [app\admin\controller\EnergyRecordController::class, 'index']);
    Route::post('/energy-record', [app\admin\controller\EnergyRecordController::class, 'store']);
    Route::resource('/staff', app\admin\controller\StaffController::class);
    Route::post('/staff/batch/status', [app\admin\controller\StaffController::class, 'batchStatus']);

    // ============================================================
    // 物业管理 — 第4批扩展功能
    // ============================================================
    // SLA管理
    Route::get('/sla-rule', [app\admin\controller\SlaController::class, 'rules']);
    Route::post('/sla-rule', [app\admin\controller\SlaController::class, 'ruleStore']);
    Route::put('/sla-rule/{hashid}', [app\admin\controller\SlaController::class, 'ruleUpdate']);
    Route::delete('/sla-rule/{hashid}', [app\admin\controller\SlaController::class, 'ruleDestroy']);
    Route::get('/sla-record', [app\admin\controller\SlaController::class, 'records']);
    // 智能催缴
    Route::get('/collection-strategy', [app\admin\controller\CollectionController::class, 'strategies']);
    Route::post('/collection-strategy', [app\admin\controller\CollectionController::class, 'strategyStore']);
    Route::put('/collection-strategy/{hashid}', [app\admin\controller\CollectionController::class, 'strategyUpdate']);
    Route::delete('/collection-strategy/{hashid}', [app\admin\controller\CollectionController::class, 'strategyDestroy']);
    Route::get('/collection-record', [app\admin\controller\CollectionController::class, 'records']);
    Route::post('/collection/run', [app\admin\controller\CollectionController::class, 'run']);
    // 巡检管理
    Route::resource('/inspection-task', app\admin\controller\InspectionController::class);
    Route::get('/inspection-task/{hashid}/checkpoints', [app\admin\controller\InspectionController::class, 'checkpoints']);
    Route::put('/inspection-task/{hashid}/start', [app\admin\controller\InspectionController::class, 'startTask']);
    Route::put('/inspection-task/{hashid}/complete', [app\admin\controller\InspectionController::class, 'completeTask']);
    Route::put('/inspection-checkpoint/{hashid}/checkin', [app\admin\controller\InspectionController::class, 'checkin']);
    // 社区商城
    Route::resource('/mall-category', app\admin\controller\MallController::class, ['names'=>'mall.category']);
    Route::resource('/mall-product', app\admin\controller\MallController::class, ['names'=>'mall.product']);
    Route::get('/mall-order', [app\admin\controller\MallController::class, 'orders']);
    Route::get('/mall-order/{hashid}', [app\admin\controller\MallController::class, 'orderShow']);
    Route::put('/mall-order/{hashid}/ship', [app\admin\controller\MallController::class, 'ship']);
    Route::post('/mall-order/{hashid}/refund', [app\admin\controller\MallController::class, 'refundOrder']);
    // 人脸管理
    Route::get('/face', [app\admin\controller\FaceController::class, 'index']);
    Route::put('/face/{hashid}/verify', [app\admin\controller\FaceController::class, 'verify']);
    Route::put('/face/{hashid}/reject', [app\admin\controller\FaceController::class, 'reject']);
    // 集团管理
    Route::resource('/group', app\admin\controller\GroupController::class);
    Route::get('/group/{hashid}/communities', [app\admin\controller\GroupController::class, 'communities']);
    Route::post('/group/{hashid}/community', [app\admin\controller\GroupController::class, 'addCommunity']);
    Route::delete('/group/{hashid}/community/{communityHashid}', [app\admin\controller\GroupController::class, 'removeCommunity']);
    Route::get('/group/{hashid}/summary', [app\admin\controller\GroupController::class, 'summary']);
    // 智能问答
    Route::get('/knowledge-category', [app\admin\controller\KnowledgeController::class, 'categories']);
    Route::post('/knowledge-category', [app\admin\controller\KnowledgeController::class, 'categoryStore']);
    Route::put('/knowledge-category/{hashid}', [app\admin\controller\KnowledgeController::class, 'categoryUpdate']);
    Route::delete('/knowledge-category/{hashid}', [app\admin\controller\KnowledgeController::class, 'categoryDestroy']);
    Route::get('/knowledge', [app\admin\controller\KnowledgeController::class, 'articles']);
    Route::post('/knowledge', [app\admin\controller\KnowledgeController::class, 'articleStore']);
    Route::put('/knowledge/{hashid}', [app\admin\controller\KnowledgeController::class, 'articleUpdate']);
    Route::delete('/knowledge/{hashid}', [app\admin\controller\KnowledgeController::class, 'articleDestroy']);
    Route::get('/chat-record', [app\admin\controller\KnowledgeController::class, 'chatRecords']);
    Route::get('/chat-stats', [app\admin\controller\KnowledgeController::class, 'chatStats']);
})->middleware([
    app\middleware\AdminAuth::class,
    app\middleware\AdminPermission::class,
    app\middleware\OperationLog::class,
]);

// ============================================================
// 公开接口（通过 API-Version 头路由到版本化控制器）
// ============================================================
Route::group('/api', function () {
    // 点击验证码
    Route::post('/captcha/generate', v('CaptchaController', 'generate'));
    Route::post('/captcha/verify', v('CaptchaController', 'verify'));

    // 认证
    Route::post('/auth/login', v('AuthController', 'login'));
    Route::post('/auth/register', v('AuthController', 'register'));
    Route::post('/auth/refresh', v('AuthController', 'refresh'));
})->middleware([
    app\middleware\ApiVersion::class,
]);

// 安装向导（.installed 锁定前可访问）
Route::get('/install', [app\admin\controller\InstallController::class, 'index']);
Route::post('/install', [app\admin\controller\InstallController::class, 'store']);

// 关闭默认路由
Route::disableDefaultRoute();
