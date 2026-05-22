/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../config/theme.dart';

class RepairDetailPage extends StatefulWidget {
  const RepairDetailPage({super.key});
  @override
  State<RepairDetailPage> createState() => _RepairDetailPageState();
}

class _RepairDetailPageState extends State<RepairDetailPage> {
  Map<String, dynamic>? _repair;
  bool _loading = true;

  Map<String, dynamic>? get repairData {
    if (_repair != null) return _repair;
    final args = Get.arguments;
    if (args is Map<String, dynamic>) return args;
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final rd = repairData;
      final hashid = rd?['hashid'] ?? rd?['id'];
      if (hashid == null) return;

      final api = Get.find<ApiService>();
      final response = await api.dio.get(ApiConfig.repairDetail(hashid.toString()));
      setState(() {
        _repair = response.data['data'];
      });
    } catch (e) {
      Get.snackbar('错误', '加载详情失败: $e', backgroundColor: Colors.red.shade50);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rd = _repair ?? repairData;
    if (rd == null) return Scaffold(appBar: AppBar(title: Text('repair_detail'.tr)), body: const SizedBox());

    final status = rd['status'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(title: Text('repair_detail'.tr)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 报修信息卡片
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('repair_detail'.tr, style: Theme.of(context).textTheme.titleMedium),
                              _buildStatusBadge(status),
                            ],
                          ),
                          const Divider(height: 32),
                          _buildInfoRow('repair_category'.tr, rd['category'] ?? '-'),
                          _buildInfoRow('repair_urgency'.tr, _urgencyLabel(rd['urgency'])),
                          _buildInfoRow('room_number'.tr, rd['room_number'] ?? '-'),
                          _buildInfoRow('repair_schedule'.tr, rd['scheduled_date'] ?? '-'),
                          const SizedBox(height: 12),
                          Text('repair_description'.tr, style: TextStyle(color: Colors.grey.shade600)),
                          const SizedBox(height: 4),
                          Text(rd['description'] ?? '', style: Theme.of(context).textTheme.bodyMedium),
                          if (rd['images'] != null && (rd['images'] as List).isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text('repair_images'.tr, style: TextStyle(color: Colors.grey.shade600)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (rd['images'] as List).map((img) => Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.image, color: Colors.grey),
                                  )).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 进度时间线
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('repair_progress'.tr, style: Theme.of(context).textTheme.titleMedium),
                          const Divider(height: 24),
                          _buildProgressTimeline(status),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 评价部分 (仅已完成状态)
                  if (status == 'completed') _buildRateSection(rd),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'status_pending'.tr;
        break;
      case 'assigned':
        color = Colors.blue;
        label = 'status_assigned'.tr;
        break;
      case 'repairing':
        color = AppTheme.warning;
        label = 'status_repairing'.tr;
        break;
      case 'completed':
        color = AppTheme.success;
        label = 'status_completed'.tr;
        break;
      case 'rated':
        color = Colors.purple;
        label = 'status_rated'.tr;
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey.shade600))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  String _urgencyLabel(String? urgency) {
    switch (urgency) {
      case 'critical':
        return 'urgency_critical'.tr;
      case 'urgent':
        return 'urgency_urgent'.tr;
      default:
        return 'urgency_normal'.tr;
    }
  }

  Widget _buildProgressTimeline(String status) {
    final steps = ['status_pending'.tr, 'status_assigned'.tr, 'status_repairing'.tr, 'status_completed'.tr];
    int currentStep;
    switch (status) {
      case 'pending':
        currentStep = 0;
        break;
      case 'assigned':
        currentStep = 1;
        break;
      case 'repairing':
        currentStep = 2;
        break;
      case 'completed':
      case 'rated':
        currentStep = 3;
        break;
      case 'cancelled':
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text('status_cancelled'.tr, style: TextStyle(color: Colors.grey.shade500)),
          ),
        );
      default:
        currentStep = 0;
    }

    return Column(
      children: List.generate(steps.length, (index) {
        final isActive = index <= currentStep;
        final isLast = index == steps.length - 1;
        return Row(
          children: [
            // 左边时间线指示器
            SizedBox(
              width: 32,
              height: isLast ? 32 : 48,
              child: Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? AppTheme.primary : Colors.grey.shade300,
                    ),
                    child: Icon(
                      isActive ? Icons.check : Icons.remove,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isActive && index < currentStep ? AppTheme.primary : Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
            ),
            // 步骤文本
            Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Text(
                steps[index],
                style: TextStyle(
                  color: isActive ? Colors.black87 : Colors.grey,
                  fontWeight: isActive && index == currentStep ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildRateSection(Map<String, dynamic> rd) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('repair_rate'.tr, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('repair_rate_hint'.tr, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            // Star rating placeholder
            Row(
              children: List.generate(5, (i) => IconButton(
                    onPressed: () async {
                      final hashid = rd['hashid'] ?? rd['id'];
                      if (hashid == null) return;
                      try {
                        final api = Get.find<ApiService>();
                        await api.dio.post(ApiConfig.repairRate(hashid.toString()), data: {
                          'rating': i + 1,
                        });
                        Get.snackbar('成功', '感谢您的评价', backgroundColor: Colors.green.shade50);
                        _loadDetail();
                      } catch (e) {
                        Get.snackbar('错误', e.toString(), backgroundColor: Colors.red.shade50);
                      }
                    },
                    icon: const Icon(Icons.star_border),
                    iconSize: 32,
                    color: AppTheme.warning,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
