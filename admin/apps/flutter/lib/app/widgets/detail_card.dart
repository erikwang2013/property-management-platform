/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';

class DetailCard extends StatelessWidget {
  final String title;
  final List<DetailRow> rows;

  const DetailCard({super.key, required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const Divider(height: 24),
            ...rows,
          ],
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const DetailRow({super.key, required this.label, this.value = '', this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label：', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                ],
                Flexible(child: Text(value, style: const TextStyle(fontSize: 13))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
