/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'room_type_controller.dart';

class RoomTypeListPage extends GetView<RoomTypeController> {
  const RoomTypeListPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<RoomTypeController>()) Get.put(RoomTypeController(), permanent: false);
    final ctrl = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('户型管理', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        ElevatedButton.icon(onPressed: () => _showForm(context, ctrl), icon: const Icon(Icons.add), label: const Text('新增户型')),
      ]),
      const SizedBox(height: 12),
      Expanded(child: Obx(() {
        if (ctrl.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (ctrl.roomTypes.isEmpty) return const Center(child: Text('暂无数据'));
        return DataTable(columns: const [
          DataColumn(label: Text('户型名称')), DataColumn(label: Text('面积(m²)')),
          DataColumn(label: Text('卧室')), DataColumn(label: Text('客厅')), DataColumn(label: Text('操作')),
        ], rows: ctrl.roomTypes.map((r) {
          final id = r['id'].toString();
          return DataRow(cells: [
            DataCell(Text(r['name'] ?? '')), DataCell(Text('${r['area'] ?? '-'}')),
            DataCell(Text('${r['bedrooms'] ?? '-'}')), DataCell(Text('${r['living_rooms'] ?? '-'}')),
            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showForm(context, ctrl, data: r)),
              IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () async {
                final pwd = await ConfirmDeleteDialog.show(context, itemName: r['name'] ?? '');
                if (pwd != null) ctrl.deleteItem(id, pwd);
              }),
            ])),
          ]);
        }).toList());
      })),
      Obx(() => PaginationRow(page: ctrl.page.value, total: ctrl.total.value, pageSize: ctrl.limit.value, onPrev: ctrl.prevPage, onNext: ctrl.nextPage)),
    ]);
  }

  void _showForm(BuildContext ctx, RoomTypeController ctrl, {Map<String, dynamic>? data}) {
    final name = TextEditingController(text: data?['name'] ?? '');
    final area = TextEditingController(text: data?['area']?.toString() ?? '');
    final bd = TextEditingController(text: data?['bedrooms']?.toString() ?? '');
    final lr = TextEditingController(text: data?['living_rooms']?.toString() ?? '');
    final isEdit = data != null;
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: Text(isEdit ? '编辑户型' : '新增户型'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: '户型名称', isDense: true)),
        const SizedBox(height: 12),
        TextField(controller: area, decoration: const InputDecoration(labelText: '面积(m²)', isDense: true), keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        TextField(controller: bd, decoration: const InputDecoration(labelText: '卧室数', isDense: true), keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        TextField(controller: lr, decoration: const InputDecoration(labelText: '客厅数', isDense: true), keyboardType: TextInputType.number),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(onPressed: () async {
          if (name.text.trim().isEmpty) return;
          try {
            final d = {'name': name.text.trim(), 'area': double.tryParse(area.text), 'bedrooms': int.tryParse(bd.text), 'living_rooms': int.tryParse(lr.text)};
            if (isEdit) await ctrl.updateItem(data!['id'], d); else await ctrl.create(d);
            if (ctx.mounted) Navigator.pop(ctx);
          } catch (e) { if (ctx.mounted) Get.snackbar('错误', '操作失败: $e'); }
        }, child: Text(isEdit ? '保存' : '创建')),
      ],
    ));
  }
}
