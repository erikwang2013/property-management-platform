/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/mock_api.dart';

void main() {
  setUp(resetMockRoutes);

  testWidgets('登录页渲染验证码与表单', (tester) async {
    await setupServices();
    await pumpApp(tester);

    expect(find.text('业主登录'), findsOneWidget);
    expect(find.text('请按顺序点击图中文字: "云"'), findsOneWidget);
    expect(find.text('登 录'), findsOneWidget);
  });

  testWidgets('空表单点登录触发校验提示', (tester) async {
    await setupServices();
    await pumpApp(tester);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // 校验文案与输入框 label 文本相同（label + 错误提示各一个）
    expect(find.text('请输入手机号'), findsNWidgets(2));
    expect(find.text('请输入密码'), findsNWidgets(2));
  });

  testWidgets('点击验证码后登录成功跳转首页', (tester) async {
    await setupServices();
    await pumpApp(tester);

    await tester.enterText(find.byType(TextFormField).at(0), '13800000000');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.byType(Image));
    await tester.pumpAndSettle();
    expect(find.text('已点击 1/1'), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.text('首页'), findsOneWidget);
    expect(find.text('费用账单'), findsOneWidget);
  });
}
