/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';

class PaginationRow extends StatelessWidget {
  final int page;
  final int total;
  final int pageSize;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const PaginationRow({
    super.key,
    required this.page,
    required this.total,
    required this.pageSize,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = (total / pageSize).ceil();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: page > 1 ? onPrev : null,
          icon: const Icon(Icons.chevron_left, size: 20),
        ),
        Text(
          '第 $page 页 / 共 $totalPages 页 ($total 条)',
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        IconButton(
          onPressed: page * pageSize < total ? onNext : null,
          icon: const Icon(Icons.chevron_right, size: 20),
        ),
      ],
    );
  }
}
