/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'contract_controller.dart';

class ContractListPage extends GetView<ContractController> {
  const ContractListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ContractController>()) Get.put(ContractController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('合同管理', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Spacer(),
        ElevatedButton.icon(onPressed: () => _showForm(context, c), icon: const Icon(Icons.add), label: const Text('新增合同')),
      ]),
      const SizedBox(height: 12),
      Expanded(child: Obx(() {
        if (c.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (c.contracts.isEmpty) return const Center(child: Text('暂无数据'));
        return DataTable(columns: const [
          DataColumn(label: Text('合同编号')), DataColumn(label: Text('类型')), DataColumn(label: Text('签署方')),
          DataColumn(label: Text('金额')), DataColumn(label: Text('状态')), DataColumn(label: Text('到期日')), DataColumn(label: Text('操作')),
        ], rows: c.contracts.map((x) {
          final id = x['id'].toString();
          return DataRow(cells: [
            DataCell(Text(x['contract_no'] ?? '-')), DataCell(Text(x['type'] ?? '-')),
            DataCell(Text(x['party_name'] ?? '-')), DataCell(Text('${x['amount'] ?? '-'}')),
            DataCell(StatusChip(status: x['status'] as int?, labels: const {0:'草稿',1:'生效中',2:'已到期',3:'已终止'})),
            DataCell(Text(x['end_date'] ?? '-')),
            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showForm(context, c, data: x)),
              IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () async {
                final pwd = await ConfirmDeleteDialog.show(context, itemName: x['contract_no'] ?? '');
                if (pwd != null) c.deleteItem(id, pwd);
              }),
            ])),
          ]);
        }).toList());
      })),
      Obx(() => PaginationRow(page: c.page.value, total: c.total.value, pageSize: c.limit.value, onPrev: c.prevPage, onNext: c.nextPage)),
    ]);
  }
  void _showForm(BuildContext ctx, ContractController c, {Map<String, dynamic>? data}) {
    final no = TextEditingController(text: data?['contract_no'] ?? '');
    final party = TextEditingController(text: data?['party_name'] ?? '');
    final amount = TextEditingController(text: data?['amount']?.toString() ?? '');
    final end = TextEditingController(text: data?['end_date'] ?? '');
    int status = data?['status'] as int? ?? 1;
    final isEdit = data != null;
    showDialog(context: ctx, builder: (_) => StatefulBuilder(builder: (_, st) => AlertDialog(
      title: Text(isEdit ? '编辑合同' : '新增合同'),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: no, decoration: const InputDecoration(labelText: '合同编号', isDense: true)),
        const SizedBox(height: 12), TextField(controller: party, decoration: const InputDecoration(labelText: '签署方', isDense: true)),
        const SizedBox(height: 12), TextField(controller: amount, decoration: const InputDecoration(labelText: '金额', isDense: true)),
        const SizedBox(height: 12), TextField(controller: end, decoration: const InputDecoration(labelText: '到期日(YYYY-MM-DD)', isDense: true)),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(value: status, decoration: const InputDecoration(labelText: '状态', isDense: true),
          items: const [DropdownMenuItem(value:1,child:Text('生效中')),DropdownMenuItem(value:0,child:Text('草稿')),DropdownMenuItem(value:2,child:Text('已到期'))],
          onChanged: (v) => st(() => status = v ?? 1)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(onPressed: () async {
          if (no.text.trim().isEmpty) return;
          try {
            final d = {'contract_no': no.text.trim(), 'party_name': party.text.trim(), 'amount': double.tryParse(amount.text), 'end_date': end.text.trim(), 'status': status};
            if (isEdit) await c.updateItem(data!['id'], d); else await c.create(d);
            if (ctx.mounted) Navigator.pop(ctx);
          } catch (e) { if (ctx.mounted) Get.snackbar('错误', '操作失败: $e'); }
        }, child: Text(isEdit ? '保存' : '创建')),
      ],
    )));
  }
}
