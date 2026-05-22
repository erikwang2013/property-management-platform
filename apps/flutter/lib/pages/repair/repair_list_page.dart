/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../config/theme.dart';

class RepairListPage extends StatefulWidget {
  const RepairListPage({super.key});
  @override
  State<RepairListPage> createState() => _RepairListPageState();
}

class _RepairListPageState extends State<RepairListPage> {
  List<Map<String, dynamic>> _repairs = [];
  bool _loading = true;
  String _statusFilter = '';

  @override
  void initState() {
    super.initState();
    _loadRepairs();
  }

  Future<void> _loadRepairs() async {
    setState(() => _loading = true);
    try {
      final api = Get.find<ApiService>();
      final queryParams = <String, dynamic>{'page': 1, 'per_page': 50};
      if (_statusFilter.isNotEmpty) {
        queryParams['status'] = _statusFilter;
      }
      final response = await api.dio.get(ApiConfig.repairs, queryParameters: queryParams);
      setState(() {
        _repairs = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      });
    } catch (e) {
      Get.snackbar('错误', '加载报修列表失败: $e', backgroundColor: Colors.red.shade50);
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'repairing':
        return AppTheme.warning;
      case 'completed':
        return AppTheme.success;
      case 'rated':
        return Colors.purple;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'pending':
        return 'status_pending'.tr;
      case 'assigned':
        return 'status_assigned'.tr;
      case 'repairing':
        return 'status_repairing'.tr;
      case 'completed':
        return 'status_completed'.tr;
      case 'rated':
        return 'status_rated'.tr;
      case 'cancelled':
        return 'status_cancelled'.tr;
      default:
        return status ?? '';
    }
  }

  Color _urgencyColor(String? urgency) {
    switch (urgency) {
      case 'critical':
        return AppTheme.danger;
      case 'urgent':
        return AppTheme.warning;
      default:
        return AppTheme.success;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('repair_list'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'repair_submit'.tr,
            onPressed: () async {
              final result = await Get.toNamed('/repair-submit');
              if (result == true) _loadRepairs();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 筛选栏
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('全部', ''),
                  const SizedBox(width: 8),
                  _buildFilterChip('status_pending'.tr, 'pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('status_assigned'.tr, 'assigned'),
                  const SizedBox(width: 8),
                  _buildFilterChip('status_repairing'.tr, 'repairing'),
                  const SizedBox(width: 8),
                  _buildFilterChip('status_completed'.tr, 'completed'),
                ],
              ),
            ),
          ),
          // 列表
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _repairs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.build_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('no_data'.tr, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRepairs,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _repairs.length,
                          itemBuilder: (context, index) {
                            final repair = _repairs[index];
                            return _buildRepairCard(repair);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final selected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _statusFilter = value);
        _loadRepairs();
      },
    );
  }

  Widget _buildRepairCard(Map<String, dynamic> repair) {
    final status = repair['status'] as String?;
    final urgency = repair['urgency'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Get.toNamed('/repair-detail', arguments: repair),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      repair['category'] ?? 'repair_category'.tr,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  // 紧急程度 badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _urgencyColor(urgency).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _urgencyLabel(urgency),
                      style: TextStyle(color: _urgencyColor(urgency), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 状态 badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(color: _statusColor(status), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (repair['description'] != null)
                Text(
                  repair['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (repair['room_number'] != null) ...[
                    Icon(Icons.meeting_room, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(repair['room_number'], style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(width: 16),
                  ],
                  Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(repair['created_at'] ?? '', style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
