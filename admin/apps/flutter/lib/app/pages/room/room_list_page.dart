/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/confirm_delete_dialog.dart';
import '../../widgets/detail_card.dart';
import 'room_controller.dart';

class RoomListPage extends GetView<RoomController> {
  const RoomListPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<RoomController>()) Get.put(RoomController(), permanent: false);
    final ctrl = controller;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('房产管理', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        ElevatedButton.icon(onPressed: () => _showForm(context, ctrl), icon: const Icon(Icons.add), label: const Text('新增房产')),
      ]),
      const SizedBox(height: 12),
      Expanded(child: Obx(() {
        if (ctrl.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (ctrl.rooms.isEmpty) return const Center(child: Text('暂无数据'));
        return DataTable(columns: const [
          DataColumn(label: Text('房号')), DataColumn(label: Text('面积(m²)')),
          DataColumn(label: Text('户型')), DataColumn(label: Text('状态')), DataColumn(label: Text('操作')),
        ], rows: ctrl.rooms.map((r) {
          final id = r['id'].toString();
          return DataRow(cells: [
            DataCell(Text(r['room_number'] ?? '')), DataCell(Text('${r['area'] ?? '-'}')),
            DataCell(Text(r['room_type_name'] ?? r['room_type_id']?.toString() ?? '-')),
            DataCell(StatusChip(status: r['status'] as int?, labels: const {0: '空置', 1: '已售', 2: '出租', 3: '自住'})),
            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showForm(context, ctrl, data: r)),
              IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () async {
                final pwd = await ConfirmDeleteDialog.show(context, itemName: r['room_number'] ?? '');
                if (pwd != null) ctrl.deleteItem(id, pwd);
              }),
            ])),
          ]);
        }).toList());
      })),
      Obx(() => PaginationRow(page: ctrl.page.value, total: ctrl.total.value, pageSize: ctrl.limit.value, onPrev: ctrl.prevPage, onNext: ctrl.nextPage)),
    ]);
  }

  void _showForm(BuildContext ctx, RoomController ctrl, {Map<String, dynamic>? data}) {
    final number = TextEditingController(text: data?['room_number'] ?? '');
    final area = TextEditingController(text: data?['area']?.toString() ?? '');
    String? communityId = data?['community_id']?.toString();
    String? buildingId = data?['building_id']?.toString();
    String? unitId = data?['unit_id']?.toString();
    String? roomTypeId = data?['room_type_id']?.toString();
    int status = data?['status'] as int? ?? 0;
    final isEdit = data != null;

    showDialog(context: ctx, builder: (_) => StatefulBuilder(builder: (_, st) => AlertDialog(
      title: Text(isEdit ? '编辑房产' : '新增房产'),
      content: SizedBox(width: 480, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: number, decoration: const InputDecoration(labelText: '房号', isDense: true)),
        const SizedBox(height: 12),
        TextField(controller: area, decoration: const InputDecoration(labelText: '面积(m²)', isDense: true), keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        Obx(() => DropdownButtonFormField<String>(
          value: communityId, decoration: const InputDecoration(labelText: '小区', isDense: true),
          items: ctrl.communities.map((c) => DropdownMenuItem(value: c['id']?.toString(), child: Text(c['name'] ?? ''))).toList(),
          onChanged: (v) { st(() { communityId = v; buildingId = null; unitId = null; }); if (v != null) ctrl.loadBuildings(v); },
        )),
        const SizedBox(height: 12),
        Obx(() => DropdownButtonFormField<String>(
          value: buildingId, decoration: const InputDecoration(labelText: '楼栋', isDense: true),
          items: ctrl.buildings.map((b) => DropdownMenuItem(value: b['id']?.toString(), child: Text(b['name'] ?? ''))).toList(),
          onChanged: (v) { st(() { buildingId = v; unitId = null; }); if (v != null) ctrl.loadUnits(v); },
        )),
        const SizedBox(height: 12),
        Obx(() => DropdownButtonFormField<String>(
          value: unitId, decoration: const InputDecoration(labelText: '单元', isDense: true),
          items: ctrl.units.map((u) => DropdownMenuItem(value: u['id']?.toString(), child: Text(u['name'] ?? ''))).toList(),
          onChanged: (v) => st(() => unitId = v),
        )),
        const SizedBox(height: 12),
        Obx(() => DropdownButtonFormField<String>(
          value: roomTypeId, decoration: const InputDecoration(labelText: '户型', isDense: true),
          items: ctrl.roomTypes.map((rt) => DropdownMenuItem(value: rt['id']?.toString(), child: Text(rt['name'] ?? ''))).toList(),
          onChanged: (v) => st(() => roomTypeId = v),
        )),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(value: status, decoration: const InputDecoration(labelText: '状态', isDense: true),
          items: const [
            DropdownMenuItem(value: 0, child: Text('空置')), DropdownMenuItem(value: 1, child: Text('已售')),
            DropdownMenuItem(value: 2, child: Text('出租')), DropdownMenuItem(value: 3, child: Text('自住')),
          ], onChanged: (v) => st(() => status = v ?? 0)),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(onPressed: () async {
          if (number.text.trim().isEmpty) return;
          try {
            final d = {'room_number': number.text.trim(), 'area': double.tryParse(area.text), 'community_id': communityId, 'building_id': buildingId, 'unit_id': unitId, 'room_type_id': roomTypeId, 'status': status};
            if (isEdit) await ctrl.updateItem(data!['id'], d); else await ctrl.create(d);
            if (ctx.mounted) Navigator.pop(ctx);
          } catch (e) { if (ctx.mounted) Get.snackbar('错误', '操作失败: $e'); }
        }, child: Text(isEdit ? '保存' : '创建')),
      ],
    )));
  }
}
