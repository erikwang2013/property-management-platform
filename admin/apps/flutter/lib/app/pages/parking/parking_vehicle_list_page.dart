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

class ParkingVehicleListPage extends GetView<ParkingVehicleController> {
  const ParkingVehicleListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ParkingVehicleController>()) Get.put(ParkingVehicleController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('车辆管理', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        ElevatedButton.icon(onPressed: () => _showForm(context, c), icon: const Icon(Icons.add), label: const Text('新增车辆')),
      ]),
      const SizedBox(height: 12),
      Expanded(child: Obx(() {
        if (c.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (c.vehicles.isEmpty) return const Center(child: Text('暂无数据'));
        return DataTable(columns: const [
          DataColumn(label: Text('车牌号')), DataColumn(label: Text('车主')), DataColumn(label: Text('车位')),
          DataColumn(label: Text('状态')), DataColumn(label: Text('操作')),
        ], rows: c.vehicles.map((v) {
          final id = v['id'].toString();
          return DataRow(cells: [
            DataCell(Text(v['plate_number'] ?? '')), DataCell(Text(v['owner_name'] ?? '-')),
            DataCell(Text(v['space_number'] ?? '-')),
            DataCell(StatusChip(status: v['status'] as int?)),
            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showForm(context, c, data: v)),
              IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () async {
                final pwd = await ConfirmDeleteDialog.show(context, itemName: v['plate_number'] ?? '');
                if (pwd != null) c.deleteItem(id, pwd);
              }),
            ])),
          ]);
        }).toList());
      })),
      Obx(() => PaginationRow(page: c.page.value, total: c.total.value, pageSize: c.limit.value, onPrev: c.prevPage, onNext: c.nextPage)),
    ]);
  }
  void _showForm(BuildContext ctx, ParkingVehicleController c, {Map<String, dynamic>? data}) {
    final plate = TextEditingController(text: data?['plate_number'] ?? '');
    final owner = TextEditingController(text: data?['owner_name'] ?? '');
    final isEdit = data != null;
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: Text(isEdit ? '编辑车辆' : '新增车辆'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: plate, decoration: const InputDecoration(labelText: '车牌号', isDense: true)),
        const SizedBox(height: 12),
        TextField(controller: owner, decoration: const InputDecoration(labelText: '车主', isDense: true)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(onPressed: () async {
          if (plate.text.trim().isEmpty) return;
          try {
            final d = {'plate_number': plate.text.trim(), 'owner_name': owner.text.trim()};
            if (isEdit) { await c.updateItem(data['id'], d); } else { await c.api.post(ApiConfig.parkingVehicle, data: d); c.loadItems(reset: true); }
            if (ctx.mounted) Navigator.pop(ctx);
          } catch (e) { if (ctx.mounted) Get.snackbar('错误', '操作失败: $e'); }
        }, child: Text(isEdit ? '保存' : '创建')),
      ],
    ));
  }
}
