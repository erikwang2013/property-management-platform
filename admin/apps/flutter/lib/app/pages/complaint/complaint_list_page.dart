/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/status_chip.dart';
import 'complaint_controller.dart';

class ComplaintListPage extends GetView<ComplaintController> {
  const ComplaintListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ComplaintController>()) Get.put(ComplaintController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('投诉管理', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Row(children: [
        ChoiceChip(label: const Text('全部'), selected: c.statusFilter.value == null, onSelected: (_) { c.statusFilter.value = null; c.loadItems(reset: true); }),
        const SizedBox(width: 4), ChoiceChip(label: const Text('待处理'), selected: c.statusFilter.value == 0, onSelected: (_) { c.statusFilter.value = 0; c.loadItems(reset: true); }),
        const SizedBox(width: 4), ChoiceChip(label: const Text('已处理'), selected: c.statusFilter.value == 1, onSelected: (_) { c.statusFilter.value = 1; c.loadItems(reset: true); }),
        const SizedBox(width: 4), ChoiceChip(label: const Text('已回访'), selected: c.statusFilter.value == 2, onSelected: (_) { c.statusFilter.value = 2; c.loadItems(reset: true); }),
      ]),
      const SizedBox(height: 12),
      Expanded(child: Obx(() {
        if (c.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (c.complaints.isEmpty) return const Center(child: Text('暂无数据'));
        return DataTable(columns: const [
          DataColumn(label: Text('投诉人')), DataColumn(label: Text('类型')), DataColumn(label: Text('内容')),
          DataColumn(label: Text('状态')), DataColumn(label: Text('时间')), DataColumn(label: Text('操作')),
        ], rows: c.complaints.map((x) {
          final id = x['id'].toString();
          return DataRow(cells: [
            DataCell(Text(x['owner_name'] ?? x['owner_id']?.toString() ?? '-')), DataCell(Text(x['type'] ?? '-')),
            DataCell(SizedBox(width: 200, child: Text(x['content'] ?? '', overflow: TextOverflow.ellipsis))),
            DataCell(StatusChip(status: x['status'] as int?, labels: const {0:'待处理',1:'已处理',2:'已回访'})),
            DataCell(Text(x['created_at'] ?? '-')),
            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
              if ((x['status'] as int? ?? 0) == 0)
                IconButton(icon: const Icon(Icons.check, size: 18, color: Colors.green), tooltip: '处理', onPressed: () => _handleDialog(context, c, id)),
              if ((x['status'] as int? ?? 0) == 1)
                IconButton(icon: const Icon(Icons.phone_callback, size: 18, color: Colors.blue), tooltip: '回访', onPressed: () => _visitDialog(context, c, id)),
            ])),
          ]);
        }).toList());
      })),
      Obx(() => PaginationRow(page: c.page.value, total: c.total.value, pageSize: c.limit.value, onPrev: c.prevPage, onNext: c.nextPage)),
    ]);
  }
  void _handleDialog(BuildContext ctx, ComplaintController c, String hid) {
    final result = TextEditingController();
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: const Text('处理投诉'), content: TextField(controller: result, decoration: const InputDecoration(labelText: '处理结果', isDense: true), maxLines: 3),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')), ElevatedButton(onPressed: () async { if (result.text.isNotEmpty) { await c.handle(hid, result.text); if (ctx.mounted) Navigator.pop(ctx); } }, child: const Text('提交'))],
    ));
  }
  void _visitDialog(BuildContext ctx, ComplaintController c, String hid) {
    String sat = '满意';
    showDialog(context: ctx, builder: (_) => StatefulBuilder(builder: (_, st) => AlertDialog(
      title: const Text('回访'), content: DropdownButtonFormField<String>(value: sat, decoration: const InputDecoration(labelText: '满意度', isDense: true),
        items: const [DropdownMenuItem(value:'满意',child:Text('满意')),DropdownMenuItem(value:'一般',child:Text('一般')),DropdownMenuItem(value:'不满意',child:Text('不满意'))],
        onChanged: (v) => st(() => sat = v ?? '满意')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')), ElevatedButton(onPressed: () async { await c.visit(hid, sat); if (ctx.mounted) Navigator.pop(ctx); }, child: const Text('提交'))],
    )));
  }
}
