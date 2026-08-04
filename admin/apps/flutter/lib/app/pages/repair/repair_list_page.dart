/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/status_chip.dart';
import 'repair_controller.dart';

class RepairListPage extends GetView<RepairController> {
  const RepairListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<RepairController>()) Get.put(RepairController(), permanent: false);
    final ctrl = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('报修管理', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Row(children: [
        ChoiceChip(label: const Text('全部'), selected: ctrl.statusFilter.value == null, onSelected: (_) => ctrl.filterByStatus(null)),
        const SizedBox(width: 4),
        ChoiceChip(label: const Text('待处理'), selected: ctrl.statusFilter.value == 0, onSelected: (_) => ctrl.filterByStatus(0)),
        const SizedBox(width: 4),
        ChoiceChip(label: const Text('处理中'), selected: ctrl.statusFilter.value == 1, onSelected: (_) => ctrl.filterByStatus(1)),
        const SizedBox(width: 4),
        ChoiceChip(label: const Text('已完成'), selected: ctrl.statusFilter.value == 2, onSelected: (_) => ctrl.filterByStatus(2)),
      ]),
      const SizedBox(height: 12),
      Expanded(child: Obx(() {
        if (ctrl.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (ctrl.repairs.isEmpty) return const Center(child: Text('暂无数据'));
        return DataTable(columns: const [
          DataColumn(label: Text('报修编号')), DataColumn(label: Text('类型')), DataColumn(label: Text('紧急度')),
          DataColumn(label: Text('状态')), DataColumn(label: Text('时间')), DataColumn(label: Text('操作')),
        ], rows: ctrl.repairs.map((r) {
          final id = r['id'].toString();
          return DataRow(cells: [
            DataCell(Text(r['order_no'] ?? id)),
            DataCell(Text(r['category'] ?? '-')),
            DataCell(Text(r['urgency'] ?? '-')),
            DataCell(StatusChip(status: r['status'] as int?, labels: const {0: '待处理', 1: '已分配', 2: '维修中', 3: '已完成', 4: '已评价', 5: '已取消'})),
            DataCell(Text(r['created_at'] ?? '-')),
            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
              if ((r['status'] as int? ?? 0) <= 1)
                IconButton(icon: const Icon(Icons.person_add, size: 18), tooltip: '分配', onPressed: () => _assignDialog(context, ctrl, id)),
              IconButton(icon: const Icon(Icons.timeline, size: 18), tooltip: '进度', onPressed: () => _progressDialog(context, ctrl, id)),
            ])),
          ]);
        }).toList());
      })),
      Obx(() => PaginationRow(page: ctrl.page.value, total: ctrl.total.value, pageSize: ctrl.limit.value, onPrev: ctrl.prevPage, onNext: ctrl.nextPage)),
    ]);
  }

  void _assignDialog(BuildContext ctx, RepairController ctrl, String hid) {
    final staff = TextEditingController();
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: const Text('分配维修人员'),
      content: TextField(controller: staff, decoration: const InputDecoration(labelText: '员工ID(hashid)', isDense: true)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(onPressed: () async {
          if (staff.text.isEmpty) return;
          await ctrl.assign(hid, staff.text.trim());
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('分配')),
      ],
    ));
  }

  void _progressDialog(BuildContext ctx, RepairController ctrl, String hid) {
    final content = TextEditingController();
    int status = 2;
    showDialog(context: ctx, builder: (_) => StatefulBuilder(builder: (_, st) => AlertDialog(
      title: const Text('更新进度'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: content, decoration: const InputDecoration(labelText: '进度说明', isDense: true)),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(value: status, decoration: const InputDecoration(labelText: '状态', isDense: true),
          items: const [
            DropdownMenuItem(value: 2, child: Text('维修中')), DropdownMenuItem(value: 3, child: Text('已完成')),
          ], onChanged: (v) => st(() => status = v ?? 2)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(onPressed: () async {
          await ctrl.addProgress(hid, content.text.trim(), status);
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('更新')),
      ],
    )));
  }
}
