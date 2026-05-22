/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// API 服务 — Dio 单例 + JWT 拦截器
class ApiService extends GetxService {
  late final Dio dio;

  @override
  void onInit() {
    super.onInit();
    dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json', 'X-Client-Platform': 'web'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final prefs = await SharedPreferences.getInstance();
          final refreshToken = prefs.getString('refresh_token');
          if (refreshToken != null) {
            try {
              final response = await Dio(BaseOptions(
                baseUrl: ApiConfig.baseUrl,
              )).post(ApiConfig.authRefresh, data: {
                'refresh_token': refreshToken,
              });
              final newToken = response.data['data']['access_token'];
              await prefs.setString('access_token', newToken);
              error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              final retryResponse = await dio.fetch(error.requestOptions);
              return handler.resolve(retryResponse);
            } catch (e) {
              await prefs.clear();
              Get.offAllNamed('/login');
              return handler.reject(error);
            }
          } else {
            Get.offAllNamed('/login');
          }
        }
        handler.next(error);
      },
    ));
  }
}
