/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'community_controller.dart';
import 'community_form_page.dart';

class CommunityListPage extends GetView<CommunityController> {
  const CommunityListPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CommunityController>()) {
      Get.put(CommunityController(), permanent: false);
    }
    final ctrl = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('小区管理', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => Get.to(() => const CommunityFormPage())?.then((_) => ctrl.loadItems(reset: true)),
              icon: const Icon(Icons.add),
              label: const Text('新增小区'),
            ),
            if (ctrl.selectedIds.isNotEmpty) ...[
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final pwd = await ConfirmDeleteDialog.show(context, itemName: '小区', count: ctrl.selectedIds.length);
                  if (pwd != null) ctrl.batchDelete(pwd);
                },
                icon: const Icon(Icons.delete, color: Colors.red),
                label: Text('删除(${ctrl.selectedIds.length})'),
                style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              width: 250,
              child: TextField(
                decoration: const InputDecoration(hintText: '搜索小区名称', prefixIcon: Icon(Icons.search), isDense: true),
                onSubmitted: (v) => ctrl.search(v),
              ),
            ),
            const SizedBox(width: 12),
            ChoiceChip(label: const Text('全部'), selected: ctrl.statusFilter.value == null, onSelected: (_) => ctrl.filterByStatus(null)),
            ChoiceChip(label: const Text('启用'), selected: ctrl.statusFilter.value == 1, onSelected: (_) => ctrl.filterByStatus(1)),
            ChoiceChip(label: const Text('禁用'), selected: ctrl.statusFilter.value == 0, onSelected: (_) => ctrl.filterByStatus(0)),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Obx(() {
            if (ctrl.isLoading.value) return const Center(child: CircularProgressIndicator());
            if (ctrl.communities.isEmpty) return const Center(child: Text('暂无数据'));

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columns: [
                    DataColumn(label: Checkbox(value: ctrl.selectedIds.length == ctrl.communities.length && ctrl.communities.isNotEmpty, onChanged: (_) => ctrl.toggleSelectAll())),
                    const DataColumn(label: Text('小区名称')),
                    const DataColumn(label: Text('地址')),
                    const DataColumn(label: Text('物业电话')),
                    const DataColumn(label: Text('状态')),
                    const DataColumn(label: Text('创建时间')),
                    const DataColumn(label: Text('操作')),
                  ],
                  rows: ctrl.communities.map((c) {
                    final id = c['id'].toString();
                    return DataRow(
                      selected: ctrl.selectedIds.contains(id),
                      onSelectChanged: (_) => ctrl.toggleSelect(id),
                      cells: [
                        DataCell(Checkbox(value: ctrl.selectedIds.contains(id), onChanged: (_) => ctrl.toggleSelect(id))),
                        DataCell(Text(c['name'] ?? '')),
                        DataCell(Text(c['address'] ?? '-')),
                        DataCell(Text(c['phone'] ?? '-')),
                        DataCell(StatusChip(status: c['status'] as int?)),
                        DataCell(Text(c['created_at'] ?? '-')),
                        DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => Get.to(() => CommunityFormPage(communityData: c))?.then((_) => ctrl.loadItems())),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            onPressed: () async {
                              final pwd = await ConfirmDeleteDialog.show(context, itemName: c['name'] ?? '');
                              if (pwd != null) ctrl.deleteItem(id, pwd);
                            },
                          ),
                        ])),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Obx(() => PaginationRow(
          page: ctrl.page.value,
          total: ctrl.total.value,
          pageSize: ctrl.limit.value,
          onPrev: ctrl.prevPage,
          onNext: ctrl.nextPage,
        )),
      ],
    );
  }
}
