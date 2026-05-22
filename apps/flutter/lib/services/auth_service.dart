/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'api_service.dart';

/// 认证服务
class AuthService extends GetxService {
  final _isLoggedIn = false.obs;
  bool get isLoggedIn => _isLoggedIn.value;
  set isLoggedIn(bool value) => _isLoggedIn.value = value;

  late final ApiService _api;

  @override
  void onInit() {
    super.onInit();
    _api = Get.find<ApiService>();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    isLoggedIn = token != null && token.isNotEmpty;
  }

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
    required String captchaKey,
    required List<Map<String, int>> clicks,
  }) async {
    final response = await _api.dio.post(ApiConfig.authLogin, data: {
      'phone': phone,
      'password': password,
      'captcha_key': captchaKey,
      'clicks': clicks,
    });

    final data = response.data['data'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', data['access_token']);
    await prefs.setString('refresh_token', data['refresh_token']);
    await prefs.setString('owner_name', data['owner']['name'] ?? '');

    isLoggedIn = true;
    return data;
  }

  Future<void> logout() async {
    try {
      await _api.dio.post(ApiConfig.profileLogout);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    isLoggedIn = false;
    Get.offAllNamed('/login');
  }
}
