/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'owner_controller.dart';

class OwnerListPage extends GetView<OwnerController> {
  const OwnerListPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<OwnerController>()) Get.put(OwnerController(), permanent: false);
    final ctrl = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('业主管理', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        ElevatedButton.icon(onPressed: () => _showForm(context, ctrl), icon: const Icon(Icons.add), label: const Text('新增业主')),
        if (ctrl.selectedIds.isNotEmpty) ...[
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final pwd = await ConfirmDeleteDialog.show(context, itemName: '业主', count: ctrl.selectedIds.length);
              if (pwd != null) ctrl.batchDelete(pwd);
            },
            icon: const Icon(Icons.delete, color: Colors.red),
            label: Text('删除(${ctrl.selectedIds.length})'),
            style: ElevatedButton.styleFrom(foregroundColor: Colors.red)),
        ],
      ]),
      const SizedBox(height: 12),
      Row(children: [
        SizedBox(width: 250, child: TextField(decoration: const InputDecoration(hintText: '搜索姓名/手机号', prefixIcon: Icon(Icons.search), isDense: true), onSubmitted: (v) => ctrl.search(v))),
      ]),
      const SizedBox(height: 12),
      Expanded(child: Obx(() {
        if (ctrl.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (ctrl.owners.isEmpty) return const Center(child: Text('暂无数据'));
        return DataTable(columns: [
          DataColumn(label: Checkbox(value: ctrl.selectedIds.length == ctrl.owners.length && ctrl.owners.isNotEmpty, onChanged: (_) => ctrl.toggleSelectAll())),
          const DataColumn(label: Text('姓名')), const DataColumn(label: Text('手机号')),
          const DataColumn(label: Text('身份证号')), const DataColumn(label: Text('状态')), const DataColumn(label: Text('操作')),
        ], rows: ctrl.owners.map((o) {
          final id = o['id'].toString();
          return DataRow(selected: ctrl.selectedIds.contains(id), onSelectChanged: (_) => ctrl.toggleSelect(id), cells: [
            DataCell(Checkbox(value: ctrl.selectedIds.contains(id), onChanged: (_) => ctrl.toggleSelect(id))),
            DataCell(Text(o['name'] ?? '')), DataCell(Text(o['phone'] ?? '-')),
            DataCell(Text(o['id_card'] ?? '-')), DataCell(StatusChip(status: o['status'] as int?)),
            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showForm(context, ctrl, data: o)),
              IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () async {
                final pwd = await ConfirmDeleteDialog.show(context, itemName: o['name'] ?? '');
                if (pwd != null) ctrl.deleteItem(id, pwd);
              }),
            ])),
          ]);
        }).toList());
      })),
      Obx(() => PaginationRow(page: ctrl.page.value, total: ctrl.total.value, pageSize: ctrl.limit.value, onPrev: ctrl.prevPage, onNext: ctrl.nextPage)),
    ]);
  }

  void _showForm(BuildContext ctx, OwnerController ctrl, {Map<String, dynamic>? data}) {
    final name = TextEditingController(text: data?['name'] ?? '');
    final phone = TextEditingController(text: data?['phone'] ?? '');
    final idCard = TextEditingController(text: data?['id_card'] ?? '');
    int status = data?['status'] as int? ?? 1;
    final isEdit = data != null;
    showDialog(context: ctx, builder: (_) => StatefulBuilder(builder: (_, st) => AlertDialog(
      title: Text(isEdit ? '编辑业主' : '新增业主'),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: '姓名', isDense: true)),
        const SizedBox(height: 12),
        TextField(controller: phone, decoration: const InputDecoration(labelText: '手机号', isDense: true)),
        const SizedBox(height: 12),
        TextField(controller: idCard, decoration: const InputDecoration(labelText: '身份证号', isDense: true)),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(initialValue: status, decoration: const InputDecoration(labelText: '状态', isDense: true),
          items: const [DropdownMenuItem(value: 1, child: Text('启用')), DropdownMenuItem(value: 0, child: Text('禁用'))],
          onChanged: (v) => st(() => status = v ?? 1)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(onPressed: () async {
          if (name.text.trim().isEmpty) return;
          try {
            final d = {'name': name.text.trim(), 'phone': phone.text.trim(), 'id_card': idCard.text.trim(), 'status': status};
            if (isEdit) { await ctrl.updateItem(data['id'], d); } else { await ctrl.create(d); }
            if (ctx.mounted) Navigator.pop(ctx);
          } catch (e) { if (ctx.mounted) Get.snackbar('错误', '操作失败: $e'); }
        }, child: Text(isEdit ? '保存' : '创建')),
      ],
    )));
  }
}
