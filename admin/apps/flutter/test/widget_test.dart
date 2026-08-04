/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admin_app/main.dart';

void main() {
  testWidgets('AdminApp renders login page', (tester) async {
    await tester.pumpWidget(const AdminApp());
    await tester.pump();
    expect(find.text('开放管理后台'), findsOneWidget);
  });
}
