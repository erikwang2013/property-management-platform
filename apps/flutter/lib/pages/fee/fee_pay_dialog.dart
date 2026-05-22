/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class FeePayDialog extends StatefulWidget {
  final Map<String, dynamic> bill;
  const FeePayDialog({super.key, required this.bill});
  @override
  State<FeePayDialog> createState() => _FeePayDialogState();
}

class _FeePayDialogState extends State<FeePayDialog> {
  String _method = 'wechat';
  final _passwordController = TextEditingController();
  final _amountController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final amount = double.tryParse(widget.bill['amount']?.toString() ?? '0') ?? 0;
    final paid = double.tryParse(widget.bill['paid_amount']?.toString() ?? '0') ?? 0;
    _amountController.text = (amount - paid).toStringAsFixed(2);
  }

  Future<void> _confirmPay() async {
    if (_passwordController.text.isEmpty) {
      Get.snackbar('提示', 'password_confirm'.tr, backgroundColor: Colors.orange.shade50);
      return;
    }
    setState(() => _loading = true);
    try {
      final api = Get.find<ApiService>();
      await api.dio.post(ApiConfig.feePay, data: {
        'bill_id': widget.bill['hashid'] ?? widget.bill['id'],
        'amount': double.tryParse(_amountController.text),
        'payment_method': _method,
        'password': _passwordController.text,
      });
      Get.snackbar('成功', 'payment_success'.tr, backgroundColor: Colors.green.shade50);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      Get.snackbar('支付失败', e.toString(), backgroundColor: Colors.red.shade50);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(widget.bill['amount']?.toString() ?? '0') ?? 0;
    final paid = double.tryParse(widget.bill['paid_amount']?.toString() ?? '0') ?? 0;
    final remaining = amount - paid;

    return AlertDialog(
      title: Text('fee_pay'.tr),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 金额展示区
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text('${'bill_number'.tr}: ${widget.bill['bill_number'] ?? '-'}'),
                  const SizedBox(height: 12),
                  Text(
                    '¥${remaining.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 支付方式选择
            Text('payment_method'.tr, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildMethodRadio('wechat_pay'.tr, 'wechat', Icons.wechat),
                const SizedBox(width: 16),
                _buildMethodRadio('alipay'.tr, 'alipay', Icons.account_balance_wallet),
              ],
            ),
            const SizedBox(height: 16),

            // 支付金额
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: '支付金额'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),

            // 密码
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'password_confirm'.tr, prefixIcon: const Icon(Icons.lock_outline)),
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: Text('cancel'.tr),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _confirmPay,
          child: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text('confirm_pay'.tr),
        ),
      ],
    );
  }

  Widget _buildMethodRadio(String label, String value, IconData icon) {
    final selected = _method == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _method = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: selected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05) : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? Theme.of(context).colorScheme.primary : Colors.grey),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(
                color: selected ? Theme.of(context).colorScheme.primary : Colors.grey,
                fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
              )),
            ],
          ),
        ),
      ),
    );
  }
}
