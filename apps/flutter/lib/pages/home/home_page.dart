/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/stat_card.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _homeData;
  List<Map<String, dynamic>> _announcements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final api = Get.find<ApiService>();
      final homeResponse = await api.dio.get(ApiConfig.home);
      setState(() {
        _homeData = homeResponse.data['data'];
      });

      final annoResponse = await api.dio.get(ApiConfig.announcements, queryParameters: {'page': 1, 'per_page': 5});
      setState(() {
        _announcements = List<Map<String, dynamic>>.from(annoResponse.data['data'] ?? []);
      });
    } catch (_) {
      // Use default values on error
    } finally {
      setState(() => _loading = false);
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '¥0.00';
    final numValue = amount is double ? amount : double.tryParse(amount.toString()) ?? 0;
    return '¥${numValue.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final roomCount = _homeData?['room_count'] ?? 0;
    final pendingAmount = _homeData?['pending_amount'] ?? 0;
    final repairingCount = _homeData?['repairing_count'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('home'.tr),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () => Get.toNamed('/profile')),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 统计卡片行
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2.2,
                    children: [
                      StatCard(
                        title: 'my_rooms'.tr,
                        value: '$roomCount 套',
                        icon: Icons.home,
                        color: AppTheme.primary,
                        subtitle: '查看详情',
                      ),
                      StatCard(
                        title: 'pending_payment'.tr,
                        value: _formatCurrency(pendingAmount),
                        icon: Icons.payment,
                        color: AppTheme.warning,
                        subtitle: '去缴费',
                      ),
                      StatCard(
                        title: 'repairing'.tr,
                        value: '$repairingCount 件',
                        icon: Icons.build,
                        color: AppTheme.danger,
                        subtitle: '查看',
                      ),
                      StatCard(
                        title: 'latest_announcements'.tr,
                        value: '${_announcements.length} 条',
                        icon: Icons.campaign,
                        color: AppTheme.success,
                        subtitle: '查看全部',
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 中段: 费用走势 + 分类饼图
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('费用走势', style: Theme.of(context).textTheme.titleMedium),
                                    TextButton.icon(
                                      icon: const Icon(Icons.trending_up, size: 18),
                                      label: Text('fee_statistics'.tr),
                                      onPressed: () => Get.toNamed('/fee-bills'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  height: 220,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.show_chart, size: 48, color: Colors.grey.shade300),
                                        const SizedBox(height: 8),
                                        Text('费用走势图表（待接入数据）',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 340,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('费用分类', style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 24),
                                SizedBox(
                                  height: 220,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey.shade300),
                                        const SizedBox(height: 8),
                                        Text('费用分类图表（待接入数据）',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 底部: 最新公告
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('latest_announcements'.tr, style: Theme.of(context).textTheme.titleMedium),
                              TextButton(onPressed: () {}, child: Text('查看全部')),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_announcements.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(child: Text('no_data'.tr, style: TextStyle(color: Colors.grey))),
                            )
                          else
                            ..._announcements.map((a) => ListTile(
                                  leading: const Icon(Icons.circle, size: 8, color: AppTheme.primary),
                                  title: Text(a['title'] ?? ''),
                                  subtitle: Text(a['published_at'] ?? ''),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {},
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
