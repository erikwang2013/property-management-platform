/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'tenant_controller.dart';

class TenantListPage extends GetView<TenantController> {
  const TenantListPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<TenantController>()) Get.put(TenantController(), permanent: false);
    final ctrl = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('租户管理', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        ElevatedButton.icon(onPressed: () => _showForm(context, ctrl), icon: const Icon(Icons.add), label: const Text('新增租户')),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        SizedBox(width: 250, child: TextField(decoration: const InputDecoration(hintText: '搜索租户姓名', prefixIcon: Icon(Icons.search), isDense: true), onSubmitted: (v) => ctrl.search(v))),
        const SizedBox(width: 12),
        ChoiceChip(label: const Text('全部'), selected: ctrl.statusFilter.value == null, onSelected: (_) => ctrl.filterByStatus(null)),
        ChoiceChip(label: const Text('有效'), selected: ctrl.statusFilter.value == 1, onSelected: (_) => ctrl.filterByStatus(1)),
        ChoiceChip(label: const Text('已退租'), selected: ctrl.statusFilter.value == 0, onSelected: (_) => ctrl.filterByStatus(0)),
      ]),
      const SizedBox(height: 12),
      Expanded(child: Obx(() {
        if (ctrl.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (ctrl.tenants.isEmpty) return const Center(child: Text('暂无数据'));
        return DataTable(columns: const [
          DataColumn(label: Text('姓名')), DataColumn(label: Text('手机号')),
          DataColumn(label: Text('租期开始')), DataColumn(label: Text('租期结束')), DataColumn(label: Text('状态')), DataColumn(label: Text('操作')),
        ], rows: ctrl.tenants.map((t) {
          final id = t['id'].toString();
          return DataRow(cells: [
            DataCell(Text(t['name'] ?? '')), DataCell(Text(t['phone'] ?? '-')),
            DataCell(Text(t['start_date'] ?? '-')), DataCell(Text(t['end_date'] ?? '-')),
            DataCell(StatusChip(status: t['status'] as int?, labels: const {0: '已退租', 1: '有效'})),
            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showForm(context, ctrl, data: t)),
              IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () async {
                final pwd = await ConfirmDeleteDialog.show(context, itemName: t['name'] ?? '');
                if (pwd != null) ctrl.deleteItem(id, pwd);
              }),
            ])),
          ]);
        }).toList());
      })),
      Obx(() => PaginationRow(page: ctrl.page.value, total: ctrl.total.value, pageSize: ctrl.limit.value, onPrev: ctrl.prevPage, onNext: ctrl.nextPage)),
    ]);
  }

  void _showForm(BuildContext ctx, TenantController ctrl, {Map<String, dynamic>? data}) {
    final name = TextEditingController(text: data?['name'] ?? '');
    final phone = TextEditingController(text: data?['phone'] ?? '');
    final idCard = TextEditingController(text: data?['id_card'] ?? '');
    final start = TextEditingController(text: data?['start_date'] ?? '');
    final end = TextEditingController(text: data?['end_date'] ?? '');
    int status = data?['status'] as int? ?? 1;
    final isEdit = data != null;
    showDialog(context: ctx, builder: (_) => StatefulBuilder(builder: (_, st) => AlertDialog(
      title: Text(isEdit ? '编辑租户' : '新增租户'),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: '姓名', isDense: true)),
        const SizedBox(height: 12),
        TextField(controller: phone, decoration: const InputDecoration(labelText: '手机号', isDense: true)),
        const SizedBox(height: 12),
        TextField(controller: idCard, decoration: const InputDecoration(labelText: '身份证号', isDense: true)),
        const SizedBox(height: 12),
        TextField(controller: start, decoration: const InputDecoration(labelText: '租期开始(YYYY-MM-DD)', isDense: true)),
        const SizedBox(height: 12),
        TextField(controller: end, decoration: const InputDecoration(labelText: '租期结束(YYYY-MM-DD)', isDense: true)),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(value: status, decoration: const InputDecoration(labelText: '状态', isDense: true),
          items: const [DropdownMenuItem(value: 1, child: Text('有效')), DropdownMenuItem(value: 0, child: Text('已退租'))],
          onChanged: (v) => st(() => status = v ?? 1)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(onPressed: () async {
          if (name.text.trim().isEmpty) return;
          try {
            final d = {'name': name.text.trim(), 'phone': phone.text.trim(), 'id_card': idCard.text.trim(), 'start_date': start.text.trim(), 'end_date': end.text.trim(), 'status': status};
            if (isEdit) await ctrl.updateItem(data!['id'], d); else await ctrl.create(d);
            if (ctx.mounted) Navigator.pop(ctx);
          } catch (e) { if (ctx.mounted) Get.snackbar('错误', '操作失败: $e'); }
        }, child: Text(isEdit ? '保存' : '创建')),
      ],
    )));
  }
}
