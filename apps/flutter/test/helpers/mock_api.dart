/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'dart:ui' show Size;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:property_portal/app.dart';
import 'package:property_portal/services/api_service.dart';
import 'package:property_portal/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 1x1 PNG（base64），用作验证码图片 mock
const kCaptchaPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

/// 按请求路径返回 mock 响应的路由表；未注册的路径直接 reject（等价于网络失败）
final Map<String, Map<String, dynamic> Function(RequestOptions)> mockRoutes = {};

void resetMockRoutes() {
  mockRoutes
    ..clear()
    ..addAll({
      '/api/captcha/generate': (_) => {
            'data': {
              'key': 'test-key',
              'image': kCaptchaPng,
              'extra': {
                'texts': [
                  {'order': 1, 'text': '云'},
                ],
              },
            },
          },
      '/api/auth/login': (_) => {
            'data': {
              'access_token': 'test-token',
              'refresh_token': 'test-refresh',
              'owner': {'name': '测试业主', 'phone': '13800000000'},
            },
          },
    });
}

class MockApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final data = mockRoutes[options.path]?.call(options);
    if (data == null) {
      handler.reject(DioException(requestOptions: options, type: DioExceptionType.badResponse));
      return;
    }
    handler.resolve(Response(requestOptions: options, data: data, statusCode: 200));
  }
}

/// 与 main.dart 一致的服务初始化；ApiService 的 dio 挂上 mock 拦截器短路网络
Future<void> setupServices() async {
  Get.reset();
  SharedPreferences.setMockInitialValues({});
  final api = await Get.putAsync(() async => ApiService());
  api.dio.interceptors.add(MockApiInterceptor());
  await Get.putAsync(() async => AuthService());
}

/// 注册全部路由的应用实例（初始路由 /login）
/// 默认测试视口 800x600 放不下登录页（含 300px 验证码图）与首页 4 列统计卡，调大避免溢出
Future<void> pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1600, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const PortalApp());
  await tester.pumpAndSettle();
}
