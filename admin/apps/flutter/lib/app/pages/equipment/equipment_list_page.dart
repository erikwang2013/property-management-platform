/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'equipment_controller.dart';
import '../../config/api_config.dart';

class EquipmentListPage extends GetView<EquipmentController> {
  const EquipmentListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<EquipmentController>()) Get.put(EquipmentController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('设备台账', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        ElevatedButton.icon(onPressed: () => _showForm(context, c), icon: const Icon(Icons.add), label: const Text('新增设备')),
      ]),
      const SizedBox(height: 12),
      Expanded(child: Obx(() {
        if (c.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (c.equipment.isEmpty) return const Center(child: Text('暂无数据'));
        return DataTable(columns: const [
          DataColumn(label: Text('设备名称')), DataColumn(label: Text('编号')), DataColumn(label: Text('位置')),
          DataColumn(label: Text('状态')), DataColumn(label: Text('操作')),
        ], rows: c.equipment.map((e) {
          final id = e['id'].toString();
          return DataRow(cells: [
            DataCell(Text(e['name'] ?? '')), DataCell(Text(e['code'] ?? '-')), DataCell(Text(e['location'] ?? '-')),
            DataCell(StatusChip(status: e['status'] as int?, labels: const {0:'停用',1:'正常',2:'维修中'})),
            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showForm(context, c, data: e)),
              IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () async {
                final pwd = await ConfirmDeleteDialog.show(context, itemName: e['name'] ?? '');
                if (pwd != null) c.deleteItem(id, pwd);
              }),
            ])),
          ]);
        }).toList());
      })),
      Obx(() => PaginationRow(page: c.page.value, total: c.total.value, pageSize: c.limit.value, onPrev: c.prevPage, onNext: c.nextPage)),
    ]);
  }
  void _showForm(BuildContext ctx, EquipmentController c, {Map<String, dynamic>? data}) {
    final name = TextEditingController(text: data?['name'] ?? '');
    final code = TextEditingController(text: data?['code'] ?? '');
    final loc = TextEditingController(text: data?['location'] ?? '');
    int status = data?['status'] as int? ?? 1;
    final isEdit = data != null;
    showDialog(context: ctx, builder: (_) => StatefulBuilder(builder: (_, st) => AlertDialog(
      title: Text(isEdit ? '编辑设备' : '新增设备'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: '设备名称', isDense: true)),
        const SizedBox(height: 12), TextField(controller: code, decoration: const InputDecoration(labelText: '编号', isDense: true)),
        const SizedBox(height: 12), TextField(controller: loc, decoration: const InputDecoration(labelText: '位置', isDense: true)),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(initialValue: status, decoration: const InputDecoration(labelText: '状态', isDense: true),
          items: const [DropdownMenuItem(value:1,child:Text('正常')),DropdownMenuItem(value:0,child:Text('停用')),DropdownMenuItem(value:2,child:Text('维修中'))],
          onChanged: (v) => st(() => status = v ?? 1)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(onPressed: () async {
          if (name.text.trim().isEmpty) return;
          try {
            final d = {'name': name.text.trim(), 'code': code.text.trim(), 'location': loc.text.trim(), 'status': status};
            if (isEdit) { await c.updateItem(data['id'], d); } else { await c.api.post(ApiConfig.equipment, data: d); c.loadItems(reset: true); }
            if (ctx.mounted) Navigator.pop(ctx);
          } catch (e) { if (ctx.mounted) Get.snackbar('错误', '操作失败: $e'); }
        }, child: Text(isEdit ? '保存' : '创建')),
      ],
    )));
  }
}
