/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'parking_controller.dart';
import '../../config/api_config.dart';

class ParkingSpaceListPage extends GetView<ParkingSpaceController> {
  const ParkingSpaceListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ParkingSpaceController>()) Get.put(ParkingSpaceController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('车位管理', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        ElevatedButton.icon(onPressed: () => _showForm(context, c), icon: const Icon(Icons.add), label: const Text('新增车位')),
      ]),
      const SizedBox(height: 12),
      Expanded(child: Obx(() {
        if (c.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (c.spaces.isEmpty) return const Center(child: Text('暂无数据'));
        return DataTable(columns: const [
          DataColumn(label: Text('车位编号')), DataColumn(label: Text('类型')),
          DataColumn(label: Text('面积')), DataColumn(label: Text('状态')), DataColumn(label: Text('操作')),
        ], rows: c.spaces.map((s) {
          final id = s['id'].toString();
          return DataRow(cells: [
            DataCell(Text(s['space_number'] ?? '')), DataCell(Text(s['type'] ?? '-')),
            DataCell(Text('${s['area'] ?? '-'}')),
            DataCell(StatusChip(status: s['status'] as int?, labels: const {0:'空闲',1:'已租',2:'已售'})),
            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showForm(context, c, data: s)),
              IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () async {
                final pwd = await ConfirmDeleteDialog.show(context, itemName: s['space_number'] ?? '');
                if (pwd != null) c.deleteItem(id, pwd);
              }),
            ])),
          ]);
        }).toList());
      })),
      Obx(() => PaginationRow(page: c.page.value, total: c.total.value, pageSize: c.limit.value, onPrev: c.prevPage, onNext: c.nextPage)),
    ]);
  }

  void _showForm(BuildContext ctx, ParkingSpaceController c, {Map<String, dynamic>? data}) {
    final num = TextEditingController(text: data?['space_number'] ?? '');
    final area = TextEditingController(text: data?['area']?.toString() ?? '');
    String type = data?['type'] ?? 'standard';
    final isEdit = data != null;
    showDialog(context: ctx, builder: (_) => StatefulBuilder(builder: (_, st) => AlertDialog(
      title: Text(isEdit ? '编辑车位' : '新增车位'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: num, decoration: const InputDecoration(labelText: '车位编号', isDense: true)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(initialValue: type, decoration: const InputDecoration(labelText: '类型', isDense: true),
          items: const [DropdownMenuItem(value: 'standard', child: Text('标准')), DropdownMenuItem(value: 'large', child: Text('大型')), DropdownMenuItem(value: 'handicap', child: Text('无障碍'))],
          onChanged: (v) => st(() => type = v ?? 'standard')),
        const SizedBox(height: 12),
        TextField(controller: area, decoration: const InputDecoration(labelText: '面积(m²)', isDense: true)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(onPressed: () async {
          if (num.text.trim().isEmpty) return;
          try {
            final d = {'space_number': num.text.trim(), 'type': type, 'area': double.tryParse(area.text)};
            if (isEdit) { await c.updateItem(data['id'], d); } else { await c.api.post(ApiConfig.parkingSpace, data: d); c.loadItems(reset: true); }
            if (ctx.mounted) Navigator.pop(ctx);
          } catch (e) { if (ctx.mounted) Get.snackbar('错误', '操作失败: $e'); }
        }, child: Text(isEdit ? '保存' : '创建')),
      ],
    )));
  }
}
