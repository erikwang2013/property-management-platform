/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'building_controller.dart';

class BuildingListPage extends GetView<BuildingController> {
  const BuildingListPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<BuildingController>()) Get.put(BuildingController(), permanent: false);
    final ctrl = controller;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('楼栋管理', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => _showForm(context, ctrl),
          icon: const Icon(Icons.add), label: const Text('新增楼栋')),
        if (ctrl.selectedIds.isNotEmpty) ...[
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final pwd = await ConfirmDeleteDialog.show(context, itemName: '楼栋', count: ctrl.selectedIds.length);
              if (pwd != null) ctrl.batchDelete(pwd);
            },
            icon: const Icon(Icons.delete, color: Colors.red),
            label: Text('删除(${ctrl.selectedIds.length})'),
            style: ElevatedButton.styleFrom(foregroundColor: Colors.red)),
        ],
      ]),
      const SizedBox(height: 12),
      Row(children: [
        SizedBox(width: 250, child: TextField(
          decoration: const InputDecoration(hintText: '搜索楼栋名称', prefixIcon: Icon(Icons.search), isDense: true),
          onSubmitted: (v) => ctrl.search(v))),
        const SizedBox(width: 12),
        ChoiceChip(label: const Text('全部'), selected: ctrl.statusFilter.value == null, onSelected: (_) => ctrl.filterByStatus(null)),
        ChoiceChip(label: const Text('启用'), selected: ctrl.statusFilter.value == 1, onSelected: (_) => ctrl.filterByStatus(1)),
        ChoiceChip(label: const Text('禁用'), selected: ctrl.statusFilter.value == 0, onSelected: (_) => ctrl.filterByStatus(0)),
      ]),
      const SizedBox(height: 12),
      Expanded(child: Obx(() {
        if (ctrl.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (ctrl.buildings.isEmpty) return const Center(child: Text('暂无数据'));
        return DataTable(columns: const [
          DataColumn(label: Text('楼栋名称')), DataColumn(label: Text('编号')),
          DataColumn(label: Text('状态')), DataColumn(label: Text('创建时间')), DataColumn(label: Text('操作')),
        ], rows: ctrl.buildings.map((b) {
          final id = b['id'].toString();
          return DataRow(cells: [
            DataCell(Text(b['name'] ?? '')), DataCell(Text(b['code'] ?? '-')),
            DataCell(StatusChip(status: b['status'] as int?)),
            DataCell(Text(b['created_at'] ?? '-')),
            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showForm(context, ctrl, data: b)),
              IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () async {
                final pwd = await ConfirmDeleteDialog.show(context, itemName: b['name'] ?? '');
                if (pwd != null) ctrl.deleteItem(id, pwd);
              }),
            ])),
          ]);
        }).toList());
      })),
      Obx(() => PaginationRow(page: ctrl.page.value, total: ctrl.total.value, pageSize: ctrl.limit.value, onPrev: ctrl.prevPage, onNext: ctrl.nextPage)),
    ]);
  }

  void _showForm(BuildContext ctx, BuildingController ctrl, {Map<String, dynamic>? data}) {
    final name = TextEditingController(text: data?['name'] ?? '');
    final code = TextEditingController(text: data?['code'] ?? '');
    int status = data?['status'] as int? ?? 1;
    final isEdit = data != null;

    showDialog(
      context: ctx,
      builder: (_) => StatefulBuilder(builder: (_, setSt) => AlertDialog(
        title: Text(isEdit ? '编辑楼栋' : '新增楼栋'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: '楼栋名称', isDense: true)),
          const SizedBox(height: 12),
          TextField(controller: code, decoration: const InputDecoration(labelText: '编号', isDense: true)),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: status, decoration: const InputDecoration(labelText: '状态', isDense: true),
            items: const [DropdownMenuItem(value: 1, child: Text('启用')), DropdownMenuItem(value: 0, child: Text('禁用'))],
            onChanged: (v) => setSt(() => status = v ?? 1)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(onPressed: () async {
            if (name.text.trim().isEmpty) return;
            final d = {'name': name.text.trim(), 'code': code.text.trim(), 'status': status};
            try {
              if (isEdit) await ctrl.updateItem(data!['id'], d);
              else await ctrl.create(d);
              if (ctx.mounted) Navigator.pop(ctx);
            } catch (e) { if (ctx.mounted) Get.snackbar('错误', '操作失败: $e'); }
          }, child: Text(isEdit ? '保存' : '创建')),
        ],
      )),
    );
  }
}
