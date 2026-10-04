/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'helpers/mock_api.dart';

void main() {
  setUp(() {
    resetMockRoutes();
    // 真实分页器形状：{code,message,data:{current_page,per_page,total,data:[...]}}
    // 列表在 data.data（service VisitorController::index -> paginate）
    mockRoutes['/service/visitors'] = (_) => {
          'code': 0,
          'message': 'success',
          'data': {
            'current_page': 1,
            'per_page': 20,
            'total': 2,
            'data': [
              {
                'visitor_name': '张三',
                'status': 0,
                'expected_start': '2026-08-01 10:00',
                'expected_end': '2026-08-01 12:00',
              },
              {
                'visitor_name': '李四',
                'status': 1,
                'expected_start': '2026-08-02 09:30',
                'expected_end': '2026-08-02 11:00',
              },
            ],
          },
        };
  });

  testWidgets('访客列表按 data.data 解析并渲染非空列表', (tester) async {
    await setupServices();
    await pumpApp(tester);
    Get.toNamed('/visitors');
    await tester.pumpAndSettle();

    expect(find.text('张三'), findsOneWidget);
    expect(find.text('李四'), findsOneWidget);
    // expected_start 为后端实际返回键（原 visit_time 不存在于响应）
    expect(find.text('访问时间: 2026-08-01 10:00'), findsOneWidget);
    // 状态枚举: 0=已预约 1=已到访（原实现为 已通过/已拒绝/待审批，与 DB 不符）
    expect(find.text('已预约'), findsOneWidget);
    expect(find.text('已到访'), findsOneWidget);
  });
}
