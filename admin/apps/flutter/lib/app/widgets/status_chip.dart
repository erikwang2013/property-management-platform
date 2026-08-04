/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final int? status;
  final Map<int, String> labels;
  final Map<int, Color>? colors;

  const StatusChip({
    super.key,
    required this.status,
    this.labels = const {0: '禁用', 1: '启用'},
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final s = status ?? 0;
    final c = colors ?? const {0: Color(0xFFFFF1F0), 1: Color(0xFFF6FFED)};
    return Chip(
      label: Text(labels[s] ?? '未知', style: const TextStyle(fontSize: 12)),
      color: WidgetStatePropertyAll(c[s] ?? Colors.grey.shade100),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
