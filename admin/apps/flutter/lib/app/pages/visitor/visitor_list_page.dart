/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/status_chip.dart';
import 'visitor_controller.dart';

class VisitorListPage extends GetView<VisitorController> {
  const VisitorListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<VisitorController>()) Get.put(VisitorController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('访客管理', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Expanded(child: Obx(() {
        if (c.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (c.visitors.isEmpty) return const Center(child: Text('暂无数据'));
        return DataTable(columns: const [
          DataColumn(label: Text('访客姓名')), DataColumn(label: Text('手机号')), DataColumn(label: Text('被访人')),
          DataColumn(label: Text('访问时间')), DataColumn(label: Text('状态')), DataColumn(label: Text('操作')),
        ], rows: c.visitors.map((v) {
          final id = v['id'].toString();
          return DataRow(cells: [
            DataCell(Text(v['visitor_name'] ?? '')), DataCell(Text(v['visitor_phone'] ?? '-')),
            DataCell(Text(v['host_name'] ?? '-')), DataCell(Text(v['visit_time'] ?? '-')),
            DataCell(StatusChip(status: v['status'] as int?, labels: const {0:'待审批',1:'已通过',2:'已拒绝'})),
            DataCell((v['status'] as int? ?? 0) == 0
              ? ElevatedButton(onPressed: () => c.approve(id), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)), child: const Text('通过'))
              : const Text('-')),
          ]);
        }).toList());
      })),
      Obx(() => PaginationRow(page: c.page.value, total: c.total.value, pageSize: c.limit.value, onPrev: c.prevPage, onNext: c.nextPage)),
    ]);
  }
}
