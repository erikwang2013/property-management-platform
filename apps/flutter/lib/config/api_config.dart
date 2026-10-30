/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

/// API 配置 — 业主端
class ApiConfig {
  /// 可通过 --dart-define=API_BASE_URL=... 覆盖
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8788');
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String captchaGenerate = '/api/v1/captcha/generate';
  static const String authLogin = '/api/v1/auth/login';
  static const String authRegister = '/api/v1/auth/register';
  static const String authRefresh = '/api/v1/auth/refresh';

  static const String home = '/service/v1/home';
  static const String rooms = '/service/v1/rooms';
  static String roomDetail(String hashid) => '/service/v1/room/$hashid';
  static const String feeBills = '/service/v1/fees/bills';
  static String feeBillDetail(String hashid) => '/service/v1/fees/bill/$hashid';
  static const String feePayments = '/service/v1/fees/payments';
  static const String feeStatistics = '/service/v1/fees/statistics';
  static const String announcements = '/service/v1/announcements';
  static String announcementDetail(String hashid) => '/service/v1/announcement/$hashid';
  static const String profile = '/service/v1/profile';
  static const String profilePassword = '/service/v1/profile/password';
  static const String profileLogout = '/service/v1/profile/logout';

  // 停车
  static const String parkingVehicles = '/service/v1/parking/vehicles';
  static const String parkingSpaces = '/service/v1/parking/spaces';
  static const String parkingRecords = '/service/v1/parking/records';
}
