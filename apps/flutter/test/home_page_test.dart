/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'helpers/mock_api.dart';

void main() {
  setUp(() {
    resetMockRoutes();
    mockRoutes['/service/home'] = (_) => {
          'data': {'room_count': 2, 'pending_amount': 123.45, 'repairing_count': 1},
        };
    mockRoutes['/service/announcements'] = (_) => {
          'data': [
            {'title': '停水通知', 'published_at': '2026-08-01 10:00'},
          ],
        };
  });

  Future<void> openHome(WidgetTester tester) async {
    await setupServices();
    await pumpApp(tester);
    Get.toNamed('/home');
    await tester.pumpAndSettle();
  }

  testWidgets('首页渲染统计卡片、功能入口与公告', (tester) async {
    await openHome(tester);

    expect(find.text('2 套'), findsOneWidget);
    expect(find.text('¥123.45'), findsOneWidget);
    expect(find.text('1 件'), findsOneWidget);
    expect(find.text('1 条'), findsOneWidget);
    expect(find.text('停水通知'), findsOneWidget);
    expect(find.text('费用账单'), findsOneWidget);
    expect(find.text('个人中心'), findsOneWidget);
  });

  testWidgets('接口失败时首页回退默认值', (tester) async {
    mockRoutes
      ..remove('/service/home')
      ..remove('/service/announcements');
    await openHome(tester);

    expect(find.text('0 套'), findsOneWidget);
    expect(find.text('¥0.00'), findsOneWidget);
    expect(find.text('暂无数据'), findsOneWidget);
  });
}
