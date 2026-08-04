/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import 'parking_controller.dart';

class ParkingRecordListPage extends GetView<ParkingRecordController> {
  const ParkingRecordListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ParkingRecordController>()) Get.put(ParkingRecordController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('出入记录', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Expanded(child: Obx(() {
        if (c.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (c.records.isEmpty) return const Center(child: Text('暂无数据'));
        return DataTable(columns: const [
          DataColumn(label: Text('车牌号')), DataColumn(label: Text('进入时间')), DataColumn(label: Text('离开时间')), DataColumn(label: Text('类型')),
        ], rows: c.records.map((r) => DataRow(cells: [
          DataCell(Text(r['plate_number'] ?? '-')), DataCell(Text(r['enter_time'] ?? '-')),
          DataCell(Text(r['leave_time'] ?? '-')), DataCell(Text(r['type'] ?? '-')),
        ])).toList());
      })),
      Obx(() => PaginationRow(page: c.page.value, total: c.total.value, pageSize: c.limit.value, onPrev: c.prevPage, onNext: c.nextPage)),
    ]);
  }
}
