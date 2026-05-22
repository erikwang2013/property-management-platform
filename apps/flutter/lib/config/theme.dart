/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';

/// 物业管理系统 — PC 风格主题
class AppTheme {
  static const Color primary = Color(0xFF1677FF);
  static const Color success = Color(0xFF52C41A);
  static const Color warning = Color(0xFFFA8C16);
  static const Color danger = Color(0xFFFF4D4F);
  static const Color bgGray = Color(0xFFF5F5F5);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: primary,
    brightness: Brightness.light,
    scaffoldBackgroundColor: bgGray,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 1,
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF262626),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dataTableTheme: const DataTableThemeData(
      headingRowHeight: 40,
      dataRowMinHeight: 36,
      dataRowMaxHeight: 44,
      dividerThickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      isDense: true,
    ),
  );
}
