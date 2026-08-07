/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:property_portal/app.dart';
import 'package:property_portal/services/api_service.dart';
import 'package:property_portal/services/auth_service.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App renders login page', (WidgetTester tester) async {
    // GetX 服务初始化（与 main.dart 一致）
    await Get.putAsync(() async => ApiService());
    await Get.putAsync(() async => AuthService());

    await tester.pumpWidget(const PortalApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('物业管理平台'), findsOneWidget);
  });
}
