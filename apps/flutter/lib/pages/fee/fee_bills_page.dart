/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../config/theme.dart';

class FeeBillsPage extends StatefulWidget {
  const FeeBillsPage({super.key});
  @override
  State<FeeBillsPage> createState() => _FeeBillsPageState();
}

class _FeeBillsPageState extends State<FeeBillsPage> {
  List<Map<String, dynamic>> _bills = [];
  bool _loading = true;
  String _statusFilter = ''; // '' = 全部

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    setState(() => _loading = true);
    try {
      final api = Get.find<ApiService>();
      final queryParams = <String, dynamic>{'page': 1, 'per_page': 50};
      if (_statusFilter.isNotEmpty) {
        queryParams['status'] = _statusFilter;
      }
      final response = await api.dio.get(ApiConfig.feeBills, queryParameters: queryParams);
      setState(() {
        _bills = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      });
    } catch (e) {
      Get.snackbar('错误', '加载账单失败: $e', backgroundColor: Colors.red.shade50);
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'unpaid':
        return AppTheme.warning;
      case 'paid':
        return AppTheme.success;
      case 'overdue':
        return AppTheme.danger;
      case 'partial':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'unpaid':
        return 'bill_unpaid'.tr;
      case 'paid':
        return 'bill_paid'.tr;
      case 'overdue':
        return 'bill_overdue'.tr;
      case 'partial':
        return 'bill_partial'.tr;
      default:
        return status ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('fee_bills'.tr),
        actions: [
          IconButton(icon: const Icon(Icons.payment), tooltip: 'fee_pay'.tr, onPressed: () {}),
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
                  _buildFilterChip('bill_unpaid'.tr, 'unpaid'),
                  const SizedBox(width: 8),
                  _buildFilterChip('bill_paid'.tr, 'paid'),
                  const SizedBox(width: 8),
                  _buildFilterChip('bill_overdue'.tr, 'overdue'),
                ],
              ),
            ),
          ),
          // 账单列表
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _bills.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('no_data'.tr, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBills,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _bills.length,
                          itemBuilder: (context, index) {
                            final bill = _bills[index];
                            return _buildBillCard(bill);
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
        _loadBills();
      },
    );
  }

  Widget _buildBillCard(Map<String, dynamic> bill) {
    final status = bill['status'] as String?;
    final amount = double.tryParse(bill['amount']?.toString() ?? '0') ?? 0;
    final paidAmount = double.tryParse(bill['paid_amount']?.toString() ?? '0') ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Get.toNamed('/fee-bill-detail', arguments: bill),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.receipt_long, color: _statusColor(status), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${'bill_number'.tr}: ${bill['bill_number'] ?? '-'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bill['fee_type'] ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '¥${amount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _statusColor(status),
                        ),
                  ),
                  if (paidAmount > 0)
                    Text(
                      '已缴 ¥${paidAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(color: _statusColor(status), fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
