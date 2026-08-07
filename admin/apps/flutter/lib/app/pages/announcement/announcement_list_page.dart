/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'announcement_controller.dart';

class AnnouncementListPage extends GetView<AnnouncementController> {
  const AnnouncementListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AnnouncementController>()) Get.put(AnnouncementController(), permanent: false);
    final ctrl = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('公告管理', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        ElevatedButton.icon(onPressed: () => _showForm(context, ctrl), icon: const Icon(Icons.add), label: const Text('发布公告')),
      ]),
      const SizedBox(height: 12),
      Expanded(child: Obx(() {
        if (ctrl.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (ctrl.announcements.isEmpty) return const Center(child: Text('暂无数据'));
        return DataTable(columns: const [
          DataColumn(label: Text('标题')), DataColumn(label: Text('状态')),
          DataColumn(label: Text('发布时间')), DataColumn(label: Text('操作')),
        ], rows: ctrl.announcements.map((a) {
          final id = a['id'].toString();
          return DataRow(cells: [
            DataCell(Text(a['title'] ?? '')),
            DataCell(StatusChip(status: a['status'] as int?, labels: const {0: '草稿', 1: '已发布'})),
            DataCell(Text(a['published_at'] ?? a['created_at'] ?? '-')),
            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showForm(context, ctrl, data: a)),
              IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () async {
                final pwd = await ConfirmDeleteDialog.show(context, itemName: a['title'] ?? '');
                if (pwd != null) ctrl.deleteItem(id, pwd);
              }),
            ])),
          ]);
        }).toList());
      })),
      Obx(() => PaginationRow(page: ctrl.page.value, total: ctrl.total.value, pageSize: ctrl.limit.value, onPrev: ctrl.prevPage, onNext: ctrl.nextPage)),
    ]);
  }

  void _showForm(BuildContext ctx, AnnouncementController ctrl, {Map<String, dynamic>? data}) {
    final title = TextEditingController(text: data?['title'] ?? '');
    final content = TextEditingController(text: data?['content'] ?? '');
    int status = data?['status'] as int? ?? 0;
    final isEdit = data != null;
    showDialog(context: ctx, builder: (_) => StatefulBuilder(builder: (_, st) => AlertDialog(
      title: Text(isEdit ? '编辑公告' : '发布公告'),
      content: SizedBox(width: 500, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, decoration: const InputDecoration(labelText: '标题', isDense: true)),
        const SizedBox(height: 12),
        TextField(controller: content, decoration: const InputDecoration(labelText: '内容', isDense: true), maxLines: 5),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(initialValue: status, decoration: const InputDecoration(labelText: '状态', isDense: true),
          items: const [DropdownMenuItem(value: 1, child: Text('发布')), DropdownMenuItem(value: 0, child: Text('草稿'))],
          onChanged: (v) => st(() => status = v ?? 0)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(onPressed: () async {
          if (title.text.trim().isEmpty) return;
          try {
            final d = {'title': title.text.trim(), 'content': content.text.trim(), 'status': status};
            if (isEdit) { await ctrl.updateItem(data['id'], d); } else { await ctrl.create(d); }
            if (ctx.mounted) Navigator.pop(ctx);
          } catch (e) { if (ctx.mounted) Get.snackbar('错误', '操作失败: $e'); }
        }, child: Text(isEdit ? '保存' : '发布')),
      ],
    )));
  }
}
