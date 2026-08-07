/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'unit_controller.dart';

class UnitListPage extends GetView<UnitController> {
  const UnitListPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<UnitController>()) Get.put(UnitController(), permanent: false);
    final ctrl = controller;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildHeader(context, ctrl),
      Expanded(child: Obx(() {
        if (ctrl.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (ctrl.units.isEmpty) return const Center(child: Text('暂无数据'));
        return DataTable(columns: const [
          DataColumn(label: Text('单元号')), DataColumn(label: Text('楼层数')),
          DataColumn(label: Text('状态')), DataColumn(label: Text('创建时间')), DataColumn(label: Text('操作')),
        ], rows: ctrl.units.map((u) {
          final id = u['id'].toString();
          return DataRow(cells: [
            DataCell(Text(u['name'] ?? '')), DataCell(Text('${u['floor_count'] ?? '-'}')),
            DataCell(StatusChip(status: u['status'] as int?)), DataCell(Text(u['created_at'] ?? '-')),
            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showForm(context, ctrl, data: u)),
              IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () async {
                final pwd = await ConfirmDeleteDialog.show(context, itemName: u['name'] ?? '');
                if (pwd != null) ctrl.deleteItem(id, pwd);
              }),
            ])),
          ]);
        }).toList());
      })),
      Obx(() => PaginationRow(page: ctrl.page.value, total: ctrl.total.value, pageSize: ctrl.limit.value, onPrev: ctrl.prevPage, onNext: ctrl.nextPage)),
    ]);
  }

  Widget _buildHeader(BuildContext ctx, UnitController ctrl) {
    return Row(children: [
      const Text('单元管理', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const Spacer(),
      ElevatedButton.icon(onPressed: () => _showForm(ctx, ctrl), icon: const Icon(Icons.add), label: const Text('新增单元')),
    ]);
  }

  void _showForm(BuildContext ctx, UnitController ctrl, {Map<String, dynamic>? data}) {
    final name = TextEditingController(text: data?['name'] ?? '');
    final floors = TextEditingController(text: data?['floor_count']?.toString() ?? '');
    int status = data?['status'] as int? ?? 1;
    final isEdit = data != null;
    showDialog(context: ctx, builder: (_) => StatefulBuilder(builder: (_, st) => AlertDialog(
      title: Text(isEdit ? '编辑单元' : '新增单元'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: '单元号', isDense: true)),
        const SizedBox(height: 12),
        TextField(controller: floors, decoration: const InputDecoration(labelText: '楼层数', isDense: true), keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(initialValue: status, decoration: const InputDecoration(labelText: '状态', isDense: true),
          items: const [DropdownMenuItem(value: 1, child: Text('启用')), DropdownMenuItem(value: 0, child: Text('禁用'))],
          onChanged: (v) => st(() => status = v ?? 1)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(onPressed: () async {
          if (name.text.trim().isEmpty) return;
          try {
            final d = {'name': name.text.trim(), 'floor_count': int.tryParse(floors.text) ?? 0, 'status': status};
            if (isEdit) { await ctrl.updateItem(data['id'], d); } else { await ctrl.create(d); }
            if (ctx.mounted) Navigator.pop(ctx);
          } catch (e) { if (ctx.mounted) Get.snackbar('错误', '操作失败: $e'); }
        }, child: Text(isEdit ? '保存' : '创建')),
      ],
    )));
  }
}
