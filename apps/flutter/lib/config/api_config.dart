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
  static const String announcements = '/service/announcements';
  static String announcementDetail(String hashid) => '/service/announcement/$hashid';
  static const String profile = '/service/profile';
  static const String profilePassword = '/service/profile/password';
  static const String profileLogout = '/service/profile/logout';

  // 停车
  static const String parkingVehicles = '/service/parking/vehicles';
  static const String parkingSpaces = '/service/parking/spaces';
  static const String parkingRecords = '/service/parking/records';
}
