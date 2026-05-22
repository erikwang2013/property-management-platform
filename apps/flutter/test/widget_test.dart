/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:property_portal/app.dart';

void main() {
  testWidgets('App renders login page', (WidgetTester tester) async {
    await tester.pumpWidget(const PortalApp());
    await tester.pumpAndSettle();

    expect(find.text('物业管理系统 - 登录'), findsOneWidget);
  });
}
