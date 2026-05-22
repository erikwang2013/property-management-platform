/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';

/// 统计卡片组件
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = const Color(0xFF1677FF),
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
