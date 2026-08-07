/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

/// API 配置 — 业主端
class ApiConfig {
  /// 可通过 --dart-define=API_BASE_URL=... 覆盖
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8788');
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String captchaGenerate = '/api/captcha/generate';
  static const String authLogin = '/api/auth/login';
  static const String authRegister = '/api/auth/register';
  static const String authRefresh = '/api/auth/refresh';

  static const String home = '/service/home';
  static const String rooms = '/service/rooms';
  static String roomDetail(String hashid) => '/service/room/$hashid';
  static const String feeBills = '/service/fees/bills';
  static String feeBillDetail(String hashid) => '/service/fees/bill/$hashid';
  static const String feePayments = '/service/fees/payments';
  static const String feePay = '/service/fees/pay';
  static const String feeStatistics = '/service/fees/statistics';
  static const String repairs = '/service/repairs';
  static String repairDetail(String hashid) => '/service/repair/$hashid';
  static const String repairStore = '/service/repair';
  static String repairDelete(String hashid) => '/service/repair/$hashid';
  static String repairRate(String hashid) => '/service/repair/$hashid/rate';
  static const String complaints = '/service/complaints';
  static String complaintDetail(String hashid) => '/service/complaint/$hashid';
  static const String complaintStore = '/service/complaint';
  static const String announcements = '/service/announcements';
  static String announcementDetail(String hashid) => '/service/announcement/$hashid';
  static const String profile = '/service/profile';
  static const String profilePassword = '/service/profile/password';
  static const String profileLogout = '/service/profile/logout';

  // 停车
  static const String parkingVehicles = '/service/parking/vehicles';
  static const String parkingSpaces = '/service/parking/spaces';
  static const String parkingRecords = '/service/parking/records';

  // 访客
  static const String visitors = '/service/visitors';
  static const String visitorStore = '/service/visitor';

  // 活动
  static const String activities = '/service/activities';
  static String activityDetail(String hid) => '/service/activity/$hid';
  static const String activitySignup = '/service/activity/signup';

  // 通知
  static const String notifications = '/service/notifications';
  static String notificationRead(String hid) => '/service/notification/$hid/read';
  static const String notificationReadAll = '/service/notifications/read-all';

  // 投票
  static const String votes = '/service/votes';
  static String voteDetail(String hid) => '/service/vote/$hid';
  static const String voteCast = '/service/vote/cast';

  // 商城
  static const String mallProducts = '/service/mall/products';
  static String mallProductDetail(String hid) => '/service/mall/product/$hid';
  static const String mallOrder = '/service/mall/order';
  static const String mallOrders = '/service/mall/orders';

  // 智能问答
  static const String chatAsk = '/service/chat/ask';

  // 人脸
  static const String faceRegister = '/service/face/register';
  static const String faceStatus = '/service/face/status';
}
