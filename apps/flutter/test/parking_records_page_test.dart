/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'helpers/mock_api.dart';

void main() {
  setUp(() {
    resetMockRoutes();
    // 真实分页器形状（service ParkingController::records -> paginate）
    mockRoutes['/service/parking/records'] = (_) => {
          'code': 0,
          'message': 'success',
          'data': {
            'current_page': 1,
            'per_page': 20,
            'total': 1,
            'data': [
              {
                'plate_number': '京A12345',
                'enter_time': '2026-08-01 08:00',
                'leave_time': '2026-08-01 18:00',
              },
            ],
          },
        };
  });

  testWidgets('停车记录按 data.data 解析并渲染非空列表', (tester) async {
    await setupServices();
    await pumpApp(tester);
    Get.toNamed('/parking-records');
    await tester.pumpAndSettle();

    expect(find.text('京A12345'), findsOneWidget);
    expect(find.text('进入: 2026-08-01 08:00 | 离开: 2026-08-01 18:00'), findsOneWidget);
  });
}
