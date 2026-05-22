/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import '../../widgets/stat_card.dart';
import '../../config/theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('首页')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 统计卡片
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 2.2,
              children: [
                StatCard(title: '我的房产', value: '2 套', icon: Icons.home, color: AppTheme.primary),
                StatCard(title: '待缴费', value: '¥1,250.00', icon: Icons.payment, color: AppTheme.warning),
                StatCard(title: '处理中', value: '1 件', icon: Icons.build, color: AppTheme.danger),
                StatCard(title: '最新公告', value: '3 条', icon: Icons.campaign, color: AppTheme.success),
              ],
            ),
            const SizedBox(height: 32),
            // 内容区占位
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('最近公告', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    ...List.generate(3, (i) => ListTile(
                      leading: const Icon(Icons.circle, size: 8),
                      title: Text(['停水通知', '电梯维护通知', '物业费缴纳提醒'][i]),
                      subtitle: Text(['2026-05-20', '2026-05-18', '2026-05-15'][i]),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
