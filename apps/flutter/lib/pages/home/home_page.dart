/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/stat_card.dart';
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
  _FunctionEntry('报修管理', Icons.build_circle_outlined, AppTheme.warning, '/repairs'),
  _FunctionEntry('我的车辆', Icons.directions_car, Color(0xFF5470C6), '/parking-vehicles'),
  _FunctionEntry('车位查询', Icons.local_parking, Color(0xFF13A8A8), '/parking-spaces'),
  _FunctionEntry('停车记录', Icons.history, Color(0xFF2F54EB), '/parking-records'),
  _FunctionEntry('访客通行', Icons.person_pin, AppTheme.success, '/visitors'),
  _FunctionEntry('社区活动', Icons.celebration, Color(0xFF722ED1), '/activities'),
  _FunctionEntry('消息通知', Icons.notifications, Color(0xFFFA8C16), '/notifications'),
  _FunctionEntry('社区投票', Icons.how_to_vote, Color(0xFFD4380D), '/votes'),
  _FunctionEntry('社区商城', Icons.storefront, Color(0xFF8C6D1F), '/mall-products'),
  _FunctionEntry('智能问答', Icons.chat_bubble_outline, Color(0xFF1677FF), '/chat'),
  _FunctionEntry('人脸识别', Icons.face, Color(0xFF531DAB), '/face-register'),
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
                      GestureDetector(
                        onTap: () => Get.toNamed('/repairs'),
                        child: StatCard(
                          title: 'repairing'.tr,
                          value: '$repairingCount 件',
                          icon: Icons.build,
                          color: AppTheme.danger,
                          subtitle: '查看',
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.toNamed('/notifications'),
                        child: StatCard(
                          title: 'latest_announcements'.tr,
                          value: '${_announcements.length} 条',
                          icon: Icons.campaign,
                          color: AppTheme.success,
                          subtitle: '查看全部',
                        ),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('latest_announcements'.tr, style: Theme.of(context).textTheme.titleMedium),
                              TextButton(onPressed: () => Get.toNamed('/notifications'), child: Text('查看全部')),
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
                                  onTap: () => Get.toNamed('/notifications'),
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
