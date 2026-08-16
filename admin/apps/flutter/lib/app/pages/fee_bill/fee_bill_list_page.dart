/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/status_chip.dart';
import 'fee_bill_controller.dart';

class FeeBillListPage extends GetView<FeeBillController> {
  const FeeBillListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<FeeBillController>()) Get.put(FeeBillController(), permanent: false);
    final ctrl = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('账单管理', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        ElevatedButton.icon(onPressed: () => ctrl.batchGenerate(), icon: const Icon(Icons.auto_awesome), label: const Text('批量生成')),
        const SizedBox(width: 8),
        ElevatedButton.icon(onPressed: () => _showForm(context, ctrl), icon: const Icon(Icons.add), label: const Text('新增账单')),
      ]),
      const SizedBox(height: 12),
      Expanded(child: Obx(() {
        if (ctrl.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (ctrl.bills.isEmpty) return const Center(child: Text('暂无数据'));
        return DataTable(columns: const [
          DataColumn(label: Text('费项')), DataColumn(label: Text('金额')), DataColumn(label: Text('已缴')),
          DataColumn(label: Text('状态')), DataColumn(label: Text('截止日期')), DataColumn(label: Text('操作')),
        ], rows: ctrl.bills.map((b) {
          return DataRow(cells: [
            DataCell(Text(b['fee_type_name'] ?? b['fee_type_id']?.toString() ?? '-')),
            DataCell(Text('${b['amount'] ?? '-'}')), DataCell(Text('${b['paid_amount'] ?? '0'}')),
            DataCell(StatusChip(status: b['status'] as int?, labels: const {0: '待缴', 1: '已缴', 2: '逾期', 3: '部分缴纳'})),
            DataCell(Text(b['due_date'] ?? '-')),
            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showForm(context, ctrl, data: b)),
            ])),
          ]);
        }).toList());
      })),
      Obx(() => PaginationRow(page: ctrl.page.value, total: ctrl.total.value, pageSize: ctrl.limit.value, onPrev: ctrl.prevPage, onNext: ctrl.nextPage)),
    ]);
  }

  void _showForm(BuildContext ctx, FeeBillController ctrl, {Map<String, dynamic>? data}) {
    final amount = TextEditingController(text: data?['amount']?.toString() ?? '');
    final dueDate = TextEditingController(text: data?['due_date'] ?? '');
    final isEdit = data != null;
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: Text(isEdit ? '编辑账单' : '新增账单'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: amount, decoration: const InputDecoration(labelText: '金额', isDense: true), keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        TextField(controller: dueDate, decoration: const InputDecoration(labelText: '截止日期(YYYY-MM-DD)', isDense: true)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(onPressed: () => _saveForm(ctx, ctrl, data: data, amount: amount, dueDate: dueDate), child: const Text('保存')),
      ],
    ));
  }

  Future<void> _saveForm(BuildContext ctx, FeeBillController ctrl,
      {Map<String, dynamic>? data, required TextEditingController amount, required TextEditingController dueDate}) async {
    final isEdit = data != null;
    if (amount.text.trim().isEmpty) {
      Get.snackbar('提示', '请输入金额');
      return;
    }
    final payload = {'amount': amount.text.trim(), 'due_date': dueDate.text.trim()};
    try {
      if (isEdit) {
        await ctrl.updateItem(data['id'].toString(), payload);
      } else {
        await ctrl.api.post(ctrl.basePath, data: payload);
        await ctrl.loadItems(reset: true);
      }
      if (ctx.mounted) Navigator.pop(ctx);
      Get.snackbar('成功', isEdit ? '账单更新成功' : '账单创建成功');
    } catch (e) {
      Get.snackbar('错误', '保存失败: $e');
    }
  }
}
