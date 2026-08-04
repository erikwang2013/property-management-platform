/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pagination_row.dart';
import 'finance_controller.dart';

class FinanceStatisticsPage extends GetView<FinanceController> {
  const FinanceStatisticsPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<FinanceController>()) Get.put(FinanceController(), permanent: false);
    final c = controller;
    return Obx(() {
      if (c.isLoading.value) return const Center(child: CircularProgressIndicator());
      final s = c.statistics;
      return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('财务统计', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Wrap(spacing: 16, runSpacing: 16, children: [
          _statCard('总收入', '${s['total_income'] ?? 0}', Colors.green),
          _statCard('总支出', '${s['total_expense'] ?? 0}', Colors.red),
          _statCard('结余', '${s['balance'] ?? 0}', Colors.blue),
        ]),
      ]));
    });
  }
  Widget _statCard(String label, String value, Color color) => Card(child: SizedBox(width: 200, child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
    Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)), const SizedBox(height: 8),
    Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
  ]))));
}

class FinanceIncomeListPage extends GetView<FinanceIncomeController> {
  const FinanceIncomeListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<FinanceIncomeController>()) Get.put(FinanceIncomeController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('收入记录', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Expanded(child: Obx(() {
        if (c.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (c.incomes.isEmpty) return const Center(child: Text('暂无数据'));
        return DataTable(columns: const [
          DataColumn(label: Text('科目')), DataColumn(label: Text('金额')), DataColumn(label: Text('来源')), DataColumn(label: Text('日期')),
        ], rows: c.incomes.map((x) => DataRow(cells: [
          DataCell(Text(x['category'] ?? '-')), DataCell(Text('${x['amount'] ?? '-'}')),
          DataCell(Text(x['source'] ?? '-')), DataCell(Text(x['income_date'] ?? '-')),
        ])).toList());
      })),
      Obx(() => PaginationRow(page: c.page.value, total: c.total.value, pageSize: c.limit.value, onPrev: c.prevPage, onNext: c.nextPage)),
    ]);
  }
}

class FinanceExpenseListPage extends GetView<FinanceExpenseController> {
  const FinanceExpenseListPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<FinanceExpenseController>()) Get.put(FinanceExpenseController(), permanent: false);
    final c = controller;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('支出记录', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Expanded(child: Obx(() {
        if (c.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (c.expenses.isEmpty) return const Center(child: Text('暂无数据'));
        return DataTable(columns: const [
          DataColumn(label: Text('科目')), DataColumn(label: Text('金额')), DataColumn(label: Text('用途')), DataColumn(label: Text('日期')),
        ], rows: c.expenses.map((x) => DataRow(cells: [
          DataCell(Text(x['category'] ?? '-')), DataCell(Text('${x['amount'] ?? '-'}')),
          DataCell(Text(x['purpose'] ?? '-')), DataCell(Text(x['expense_date'] ?? '-')),
        ])).toList());
      })),
      Obx(() => PaginationRow(page: c.page.value, total: c.total.value, pageSize: c.limit.value, onPrev: c.prevPage, onNext: c.nextPage)),
    ]);
  }
}
