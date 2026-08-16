/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'helpers/mock_api.dart';

void main() {
  setUp(() {
    resetMockRoutes();
    mockRoutes['/service/fees/bills'] = (options) {
      final status = options.queryParameters['status'];
      if (status == 'paid') {
        return {
          'data': [
            {
              'bill_number': 'B2026002',
              'fee_type': '物业费',
              'amount': '200.00',
              'paid_amount': '200.00',
              'status': 'paid',
            },
          ],
        };
      }
      return {
        'data': [
          {
            'bill_number': 'B2026001',
            'fee_type': '物业费',
            'amount': '100.00',
            'paid_amount': '0',
            'status': 'unpaid',
          },
        ],
      };
    };
  });

  Future<void> openBills(WidgetTester tester) async {
    await setupServices();
    await pumpApp(tester);
    Get.toNamed('/fee-bills');
    await tester.pumpAndSettle();
  }

  testWidgets('账单列表渲染账单卡片', (tester) async {
    await openBills(tester);

    expect(find.textContaining('B2026001'), findsOneWidget);
    expect(find.text('¥100.00'), findsOneWidget);
    expect(find.text('未缴'), findsWidgets);
  });

  testWidgets('状态筛选切换后重新加载', (tester) async {
    await openBills(tester);
    expect(find.textContaining('B2026001'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '已缴'));
    await tester.pumpAndSettle();

    expect(find.textContaining('B2026002'), findsOneWidget);
    expect(find.textContaining('B2026001'), findsNothing);
  });

  testWidgets('无账单时展示空状态', (tester) async {
    mockRoutes['/service/fees/bills'] = (_) => {'data': []};
    await openBills(tester);

    expect(find.text('暂无数据'), findsOneWidget);
  });
}
