/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'fee_type_controller.dart';

class FeeTypeListPage extends GetView<FeeTypeController> {
  const FeeTypeListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<FeeTypeController>()) Get.put(FeeTypeController(), permanent: false);
    final ctrl = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('费用类型', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        ElevatedButton.icon(onPressed: () => _showForm(context, ctrl), icon: const Icon(Icons.add), label: const Text('新增费用类型')),
      ]),
      const SizedBox(height: 12),
      Expanded(child: Obx(() {
        if (ctrl.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (ctrl.feeTypes.isEmpty) return const Center(child: Text('暂无数据'));
        return DataTable(columns: const [
          DataColumn(label: Text('费项名称')), DataColumn(label: Text('单价')), DataColumn(label: Text('计费周期')), DataColumn(label: Text('科目')), DataColumn(label: Text('操作')),
        ], rows: ctrl.feeTypes.map((f) {
          final id = f['id'].toString();
          return DataRow(cells: [
            DataCell(Text(f['name'] ?? '')), DataCell(Text('${f['unit_price'] ?? '-'}')),
            DataCell(Text(f['billing_cycle'] ?? '-')), DataCell(Text(f['category'] ?? '-')),
            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showForm(context, ctrl, data: f)),
              IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () async {
                final pwd = await ConfirmDeleteDialog.show(context, itemName: f['name'] ?? '');
                if (pwd != null) ctrl.deleteItem(id, pwd);
              }),
            ])),
          ]);
        }).toList());
      })),
      Obx(() => PaginationRow(page: ctrl.page.value, total: ctrl.total.value, pageSize: ctrl.limit.value, onPrev: ctrl.prevPage, onNext: ctrl.nextPage)),
    ]);
  }

  void _showForm(BuildContext ctx, FeeTypeController ctrl, {Map<String, dynamic>? data}) {
    final name = TextEditingController(text: data?['name'] ?? '');
    final price = TextEditingController(text: data?['unit_price']?.toString() ?? '');
    final cycle = TextEditingController(text: data?['billing_cycle'] ?? '');
    final cat = TextEditingController(text: data?['category'] ?? '');
    final isEdit = data != null;
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: Text(isEdit ? '编辑费用类型' : '新增费用类型'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: '费项名称', isDense: true)),
        const SizedBox(height: 12),
        TextField(controller: price, decoration: const InputDecoration(labelText: '单价', isDense: true), keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        TextField(controller: cycle, decoration: const InputDecoration(labelText: '计费周期', isDense: true)),
        const SizedBox(height: 12),
        TextField(controller: cat, decoration: const InputDecoration(labelText: '科目', isDense: true)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(onPressed: () async {
          if (name.text.trim().isEmpty) return;
          try {
            final d = {'name': name.text.trim(), 'unit_price': double.tryParse(price.text), 'billing_cycle': cycle.text.trim(), 'category': cat.text.trim()};
            if (isEdit) { await ctrl.updateItem(data['id'], d); } else { await ctrl.create(d); }
            if (ctx.mounted) Navigator.pop(ctx);
          } catch (e) { if (ctx.mounted) Get.snackbar('错误', '操作失败: $e'); }
        }, child: Text(isEdit ? '保存' : '创建')),
      ],
    ));
  }
}
