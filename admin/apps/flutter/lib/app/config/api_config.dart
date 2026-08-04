// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

class ApiConfig {
  ApiConfig._();

  // 认证
  static const String authLogin = '/api/auth/login';
  static const String authRegister = '/api/auth/register';
  static const String authRefresh = '/api/auth/refresh';

  // 验证码
  static const String captchaGenerate = '/api/captcha/generate';
  static const String captchaVerify = '/api/captcha/verify';

  // 仪表盘
  static const String dashboard = '/admin/dashboard';
  static const String dashboardProperty = '/admin/dashboard/property';

  // 用户管理
  static const String user = '/admin/user';
  static String userItem(String hashid) => '/admin/user/$hashid';
  static const String userBatchDestroy = '/admin/user/batch/destroy';
  static const String userBatchStatus = '/admin/user/batch/status';

  // 角色/权限
  static const String role = '/admin/role';
  static const String permission = '/admin/permission';

  // 系统配置
  static const String config = '/admin/config';

  // 操作日志
  static const String log = '/admin/log';

  // 个人中心
  static const String profile = '/admin/profile';
  static const String profilePassword = '/admin/profile/password';
  static const String profileLogout = '/admin/profile/logout';

  // 导出
  static const String exportExcel = '/admin/export/excel';
  static const String exportPdf = '/admin/export/pdf';

  // 导入
  static const String importUsers = '/admin/import/users';

  // 文件上传
  static const String upload = '/admin/upload';

  // 小区
  static const String community = '/admin/community';

  // 楼栋
  static const String building = '/admin/building';

  // 单元
  static const String unit = '/admin/unit';

  // 户型
  static const String roomType = '/admin/room-type';

  // 房产
  static const String room = '/admin/room';
  static const String roomTree = '/admin/room/tree';

  // 业主
  static const String owner = '/admin/owner';
  static const String ownerBatchImport = '/admin/owner/batch/import';
  static const String ownerBatchDestroy = '/admin/owner/batch/destroy';

  // 租户
  static const String tenant = '/admin/tenant';

  // 费用类型
  static const String feeType = '/admin/fee-type';

  // 账单
  static const String feeBill = '/admin/fee-bill';
  static const String feeBillBatchGenerate = '/admin/fee-bill/batch/generate';

  // 缴费
  static const String feePayment = '/admin/fee-payment';
  static const String feePaymentOffline = '/admin/fee-payment/offline';

  // 报修
  static const String repair = '/admin/repair';
  static String repairAssign(String hashid) => '/admin/repair/$hashid/assign';
  static String repairProgress(String hashid) => '/admin/repair/$hashid/progress';

  // 公告
  static const String announcement = '/admin/announcement';

  // 停车
  static const String parkingSpace = '/admin/parking-space';
  static const String parkingVehicle = '/admin/parking-vehicle';
  static const String parkingRecord = '/admin/parking-record';

  // 设备
  static const String equipment = '/admin/equipment';
  static const String equipmentMaintenance = '/admin/equipment-maintenance';

  // 投诉
  static const String complaint = '/admin/complaint';
  static String complaintHandle(String hashid) => '/admin/complaint/$hashid/handle';
  static String complaintVisit(String hashid) => '/admin/complaint/$hashid/visit';

  // 访客
  static const String visitor = '/admin/visitor';
  static String visitorApprove(String hashid) => '/admin/visitor/$hashid/approve';

  // 合同
  static const String contract = '/admin/contract';

  // 财务
  static const String financeStatistics = '/admin/finance/statistics';
  static const String financeIncome = '/admin/finance-income';
  static const String financeExpense = '/admin/finance-expense';

  // 安防巡逻
  static const String securityPatrol = '/admin/security-patrol';
  static const String patrolRecord = '/admin/patrol-record';

  // 保洁
  static const String cleaningArea = '/admin/cleaning-area';
  static const String cleaningRecord = '/admin/cleaning-record';

  // 绿化
  static const String greenArea = '/admin/green-area';
  static const String greenMaintenance = '/admin/green-maintenance';

  // 社区活动
  static const String activity = '/admin/activity';
  static const String activitySignup = '/admin/activity-signup';
  static String activitySignupCheckin(String hashid) => '/admin/activity-signup/$hashid/checkin';

  // 能耗
  static const String energyMeter = '/admin/energy-meter';
  static const String energyRecord = '/admin/energy-record';

  // 员工
  static const String staff = '/admin/staff';
  static const String staffBatchStatus = '/admin/staff/batch/status';

  // 通知
  static const String notification = '/admin/notification';

  // 审批
  static const String approval = '/admin/approval';

  // 支付
  static const String payment = '/admin/payment';

  // 投票
  static const String vote = '/admin/vote';

  // SLA
  static const String slaRule = '/admin/sla-rule';
  static const String slaRecord = '/admin/sla-record';

  // 催缴
  static const String collectionStrategy = '/admin/collection-strategy';
  static const String collectionRecord = '/admin/collection-record';
  static const String collectionRun = '/admin/collection/run';

  // 巡检
  static const String inspectionTask = '/admin/inspection-task';
  static String inspectionCheckpoints(String hashid) => '/admin/inspection-task/$hashid/checkpoints';
  static String inspectionStart(String hashid) => '/admin/inspection-task/$hashid/start';
  static String inspectionComplete(String hashid) => '/admin/inspection-task/$hashid/complete';

  // 商城
  static const String mallCategory = '/admin/mall-category';
  static const String mallProduct = '/admin/mall-product';
  static const String mallOrder = '/admin/mall-order';
  static String mallOrderShip(String hashid) => '/admin/mall-order/$hashid/ship';
  static String mallOrderRefund(String hashid) => '/admin/mall-order/$hashid/refund';

  // 人脸
  static const String face = '/admin/face';

  // 集团
  static const String group = '/admin/group';
  static String groupCommunities(String hashid) => '/admin/group/$hashid/communities';
  static String groupAddCommunity(String hashid) => '/admin/group/$hashid/community';
  static String groupSummary(String hashid) => '/admin/group/$hashid/summary';

  // 智能问答
  static const String knowledgeCategory = '/admin/knowledge-category';
  static const String knowledge = '/admin/knowledge';
  static const String chatRecord = '/admin/chat-record';
  static const String chatStats = '/admin/chat-stats';
}
