/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import 'fee_payment_controller.dart';

class FeePaymentListPage extends GetView<FeePaymentController> {
  const FeePaymentListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<FeePaymentController>()) Get.put(FeePaymentController(), permanent: false);
    final ctrl = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('缴费记录', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        ElevatedButton.icon(onPressed: () => _offlinePayDialog(context, ctrl), icon: const Icon(Icons.attach_money), label: const Text('线下收款')),
      ]),
      const SizedBox(height: 12),
      Expanded(child: Obx(() {
        if (ctrl.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (ctrl.payments.isEmpty) return const Center(child: Text('暂无数据'));
        return DataTable(columns: const [
          DataColumn(label: Text('支付编号')), DataColumn(label: Text('金额')), DataColumn(label: Text('支付方式')),
          DataColumn(label: Text('时间')), DataColumn(label: Text('状态')),
        ], rows: ctrl.payments.map((p) {
          return DataRow(cells: [
            DataCell(Text(p['payment_no'] ?? '-')), DataCell(Text('${p['amount'] ?? '-'}')),
            DataCell(Text(p['pay_method'] ?? '-')), DataCell(Text(p['paid_at'] ?? p['created_at'] ?? '-')),
            DataCell(Chip(label: Text(p['status'] == 1 ? '成功' : '失败', style: const TextStyle(fontSize: 12)), color: WidgetStatePropertyAll(p['status'] == 1 ? Colors.green.shade50 : Colors.red.shade50))),
          ]);
        }).toList());
      })),
      Obx(() => PaginationRow(page: ctrl.page.value, total: ctrl.total.value, pageSize: ctrl.limit.value, onPrev: ctrl.prevPage, onNext: ctrl.nextPage)),
    ]);
  }

  void _offlinePayDialog(BuildContext ctx, FeePaymentController ctrl) {
    final billId = TextEditingController();
    final amount = TextEditingController();
    final method = TextEditingController(text: '现金');
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: const Text('线下收款'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: billId, decoration: const InputDecoration(labelText: '账单ID(hashid)', isDense: true)),
        const SizedBox(height: 12),
        TextField(controller: amount, decoration: const InputDecoration(labelText: '金额', isDense: true), keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        TextField(controller: method, decoration: const InputDecoration(labelText: '支付方式', isDense: true)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(onPressed: () async {
          if (billId.text.isEmpty || amount.text.isEmpty) return;
          try {
            await ctrl.offlinePay({'bill_id': billId.text.trim(), 'amount': double.parse(amount.text), 'pay_method': method.text.trim()});
            if (ctx.mounted) Navigator.pop(ctx);
            Get.snackbar('成功', '线下收款已记录');
          } catch (e) { if (ctx.mounted) Get.snackbar('错误', '收款失败: $e'); }
        }, child: const Text('确认收款')),
      ],
    ));
  }
}
