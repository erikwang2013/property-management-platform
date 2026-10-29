/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/pet_mark.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

/// 首页功能入口定义
class _FunctionEntry {
  const _FunctionEntry(this.label, this.icon, this.color, this.route);
  final String label;
  final IconData icon;
  final Color color;
  final String route;
}

const List<_FunctionEntry> _entries = [
  _FunctionEntry('费用账单', Icons.receipt_long, AppTheme.primary, '/fee-bills'),
  _FunctionEntry('我的车辆', Icons.directions_car, Color(0xFF5470C6), '/parking-vehicles'),
  _FunctionEntry('车位查询', Icons.local_parking, Color(0xFF13A8A8), '/parking-spaces'),
  _FunctionEntry('停车记录', Icons.history, Color(0xFF2F54EB), '/parking-records'),
  _FunctionEntry('个人中心', Icons.person, AppTheme.danger, '/profile'),
];

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
        _announcements = List<Map<String, dynamic>>.from(annoResponse.data['data']?['data'] ?? []);
      });
    } catch (e) {
      // Use default values on error
      debugPrint('[home_page] $e');
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

    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          const PetMark(size: 24),
          const SizedBox(width: 8),
          Text('home'.tr),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () => Get.toNamed('/profile')),
        ],
      ),
      body: _loading
          ? PetLoading()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 统计卡片行
                  GridView.count(
                    crossAxisCount: 3,
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
                        subtitle: '我的房产',
                      ),
                      GestureDetector(
                        onTap: () => Get.toNamed('/fee-bills'),
                        child: StatCard(
                          title: 'pending_payment'.tr,
                          value: _formatCurrency(pendingAmount),
                          icon: Icons.payment,
                          color: AppTheme.warning,
                          subtitle: '去缴费',
                        ),
                      ),
                      StatCard(
                        title: 'latest_announcements'.tr,
                        value: '${_announcements.length} 条',
                        icon: Icons.campaign,
                        color: AppTheme.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 功能入口网格
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('功能服务', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final columns = (constraints.maxWidth / 130).floor().clamp(3, 8);
                              return GridView.count(
                                crossAxisCount: columns,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.5,
                                children: [for (final e in _entries) _EntryTile(entry: e)],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 底部: 最新公告
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('latest_announcements'.tr, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          if (_announcements.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: PetEmpty(),
                            )
                          else
                            ..._announcements.map((a) => ListTile(
                                  leading: const Icon(Icons.circle, size: 8, color: AppTheme.primary),
                                  title: Text(a['title'] ?? ''),
                                  subtitle: Text(a['published_at'] ?? ''),
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

/// 单个功能入口卡片
class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});
  final _FunctionEntry entry;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Get.toNamed(entry.route),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: entry.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(entry.icon, color: entry.color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(entry.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
