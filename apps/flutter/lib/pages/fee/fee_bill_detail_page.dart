/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../config/theme.dart';
import 'fee_pay_dialog.dart';

class FeeBillDetailPage extends StatefulWidget {
  const FeeBillDetailPage({super.key});
  @override
  State<FeeBillDetailPage> createState() => _FeeBillDetailPageState();
}

class _FeeBillDetailPageState extends State<FeeBillDetailPage> {
  Map<String, dynamic>? _bill;
  List<Map<String, dynamic>> _payments = [];
  bool _loading = true;

  Map<String, dynamic>? get billData {
    if (_bill != null) return _bill;
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
    setState(() => _loading = true);
    try {
      final bd = billData;
      final hashid = bd?['hashid'] ?? bd?['id'];
      if (hashid == null) return;

      final api = Get.find<ApiService>();
      final response = await api.dio.get(ApiConfig.feeBillDetail(hashid.toString()));
      setState(() {
        _bill = response.data['data'];
      });

      // Load payment history
      final payResponse = await api.dio.get(ApiConfig.feePayments, queryParameters: {
        'bill_id': hashid,
        'page': 1,
        'per_page': 20,
      });
      setState(() {
        _payments = List<Map<String, dynamic>>.from(payResponse.data['data'] ?? []);
      });
    } catch (e) {
      Get.snackbar('错误', '加载详情失败: $e', backgroundColor: Colors.red.shade50);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pay() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => FeePayDialog(bill: billData ?? {}),
    );
    if (result == true) {
      _loadDetail();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bd = _bill ?? billData;
    if (bd == null) return Scaffold(appBar: AppBar(title: Text('fee_bills'.tr)), body: const SizedBox());

    final amount = double.tryParse(bd['amount']?.toString() ?? '0') ?? 0;
    final paidAmount = double.tryParse(bd['paid_amount']?.toString() ?? '0') ?? 0;
    final status = bd['status'] as String? ?? '';
    final canPay = status == 'unpaid' || status == 'overdue' || status == 'partial';

    return Scaffold(
      appBar: AppBar(title: Text('bill_detail'.tr)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // 账单信息卡片
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('bill_detail'.tr, style: Theme.of(context).textTheme.titleMedium),
                              _buildStatusBadge(status),
                            ],
                          ),
                          const Divider(height: 32),
                          _buildInfoRow('bill_number'.tr, bd['bill_number'] ?? '-'),
                          _buildInfoRow('fee_type'.tr, bd['fee_type'] ?? '-'),
                          _buildInfoRow('bill_amount'.tr, '¥${amount.toStringAsFixed(2)}'),
                          _buildInfoRow('已缴金额', '¥${paidAmount.toStringAsFixed(2)}'),
                          _buildInfoRow('bill_due_date'.tr, bd['due_date'] ?? '-'),
                          if (bd['room_number'] != null)
                            _buildInfoRow('room_number'.tr, bd['room_number']),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 缴费记录
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('fee_payment'.tr, style: Theme.of(context).textTheme.titleMedium),
                          const Divider(height: 24),
                          if (_payments.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: Text('no_data'.tr, style: TextStyle(color: Colors.grey))),
                            )
                          else
                            ..._payments.map((p) => ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppTheme.success.withValues(alpha: 0.1),
                                    child: const Icon(Icons.check, color: AppTheme.success, size: 20),
                                  ),
                                  title: Text('¥${(double.tryParse(p['amount']?.toString() ?? '0') ?? 0).toStringAsFixed(2)}'),
                                  subtitle: Text(p['payment_method'] ?? ''),
                                  trailing: Text(p['paid_at'] ?? '', style: Theme.of(context).textTheme.bodySmall),
                                )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: canPay
          ? FloatingActionButton.extended(
              onPressed: _pay,
              icon: const Icon(Icons.payment),
              label: Text('fee_pay'.tr),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'unpaid':
        color = AppTheme.warning;
        label = 'bill_unpaid'.tr;
        break;
      case 'paid':
        color = AppTheme.success;
        label = 'bill_paid'.tr;
        break;
      case 'overdue':
        color = AppTheme.danger;
        label = 'bill_overdue'.tr;
        break;
      case 'partial':
        color = Colors.blue;
        label = 'bill_partial'.tr;
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
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
