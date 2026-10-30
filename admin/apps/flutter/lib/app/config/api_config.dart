// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

class ApiConfig {
  ApiConfig._();

  // 认证
  static const String authLogin = '/api/v1/auth/login';
  static const String authRefresh = '/api/v1/auth/refresh';

  // 验证码
  static const String captchaGenerate = '/api/v1/captcha/generate';
  static const String captchaVerify = '/api/v1/captcha/verify';

  // 仪表盘
  static const String dashboard = '/admin/dashboard';
  static const String dashboardProperty = '/admin/dashboard/property';

  // 报表中心
  static const String report = '/admin/report';

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

  // 缴费
  static const String feePayment = '/admin/fee-payment';
  static const String feePaymentOffline = '/admin/fee-payment/offline';

  // 公告
  static const String announcement = '/admin/announcement';

  // 停车
  static const String parkingSpace = '/admin/parking-space';
  static const String parkingVehicle = '/admin/parking-vehicle';
  static const String parkingRecord = '/admin/parking-record';

  // 设备
  static const String equipment = '/admin/equipment';
  static const String equipmentMaintenance = '/admin/equipment-maintenance';

  // 安防巡逻
  static const String securityPatrol = '/admin/security-patrol';
  static const String patrolRecord = '/admin/patrol-record';

  // 保洁
  static const String cleaningArea = '/admin/cleaning-area';
  static const String cleaningRecord = '/admin/cleaning-record';

  // 绿化
  static const String greenArea = '/admin/green-area';
  static const String greenMaintenance = '/admin/green-maintenance';

  // 员工
  static const String staff = '/admin/staff';
  static const String staffBatchStatus = '/admin/staff/batch/status';

  // 支付
  static const String payment = '/admin/payment-order';
}
