/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

/// API 配置 — 业主端
class ApiConfig {
  static const String baseUrl = 'http://localhost:8788';
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
}
