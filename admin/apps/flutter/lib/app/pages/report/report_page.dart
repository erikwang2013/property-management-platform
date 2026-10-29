/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'report_controller.dart';
import '../../widgets/pet_mark.dart';

/// 报表中心：汇总卡片 + 缴费方式 + 欠费排行
class ReportPage extends GetView<ReportController> {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ReportController());
    return Obx(() {
      if (controller.isLoading.value) {
        return PetLoading();
      }
      final s = controller.summary;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('报表中心',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                _buildRangeSelector(context),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  tooltip: '导出 PDF',
                  onPressed: controller.exportPdf,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSummaryCards(context, s),
            const SizedBox(height: 24),
            _buildPaymentCard(context),
            const SizedBox(height: 24),
            _buildArrearsCard(context),
          ],
        ),
      );
    });
  }

  Widget _buildRangeSelector(BuildContext context) {
    final ranges = {30: '近 30 天', 90: '近 90 天', 0: '本年'};
    return DropdownButton<int>(
      value: controller.rangeDays.value,
      items: ranges.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: (v) {
        if (v != null) {
          controller.rangeDays.value = v;
          controller.load();
        }
      },
    );
  }

  Widget _buildSummaryCards(BuildContext context, Map<String, dynamic> s) {
    final cards = [
      ('应收金额', '¥${s['total_billed'] ?? 0}', Icons.receipt_long, Color(0xFF1677FF)),
      ('实收金额', '¥${s['total_paid'] ?? 0}', Icons.payments, Color(0xFF52C41A)),
      ('欠费金额', '¥${s['arrears'] ?? 0}', Icons.warning_amber, Color(0xFFFA8C16)),
      ('收缴率', '${s['collection_rate'] ?? 0}%', Icons.percent, Color(0xFF722ED1)),
      ('入住率', '${s['occupancy_rate'] ?? 0}%', Icons.home, Color(0xFF13A8A8)),
    ];
    return LayoutBuilder(builder: (context, c) {
      final width = (c.maxWidth - 48) / 4;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final (label, value, icon, color) in cards)
            SizedBox(
              width: width,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildPaymentCard(BuildContext context) {
    final methods = List<Map<String, dynamic>>.from(controller.data['payment_methods'] ?? []);
    final total = methods.fold<double>(0, (sum, e) => sum + ((e['total'] as num?) ?? 0));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('缴费方式分布', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (methods.isEmpty)
              const SizedBox(height: 160, child: PetEmpty())
            else ...[
              SizedBox(
                height: 120,
                child: PieChart(
                  PieChartData(
                    sections: [
                      for (var i = 0; i < methods.length; i++)
                        PieChartSectionData(
                          color: ReportController.payMethodColors[i % ReportController.payMethodColors.length],
                          value: ((methods[i]['total'] as num?) ?? 0).toDouble(),
                          title: total > 0
                              ? '${(((methods[i]['total'] as num?) ?? 0) / total * 100).toStringAsFixed(0)}%'
                              : '',
                          radius: 36,
                          titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
              ),
              for (var i = 0; i < methods.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: ReportController.payMethodColors[i % ReportController.payMethodColors.length], shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('${methods[i]['name']}  ¥${methods[i]['total']}（${methods[i]['count']}笔）', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildArrearsCard(BuildContext context) {
    final rows = List<Map<String, dynamic>>.from(controller.data['arrears_ranking'] ?? []);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('欠费排行 TOP 10', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: PetEmpty(message: '暂无欠费数据'),
              )
            else
              DataTable(
                columns: const [
                  DataColumn(label: Text('排名')),
                  DataColumn(label: Text('业主')),
                  DataColumn(label: Text('联系电话')),
                  DataColumn(label: Text('房产')),
                  DataColumn(label: Text('欠费金额')),
                ],
                rows: [
                  for (var i = 0; i < rows.length; i++)
                    DataRow(cells: [
                      DataCell(Text('${i + 1}')),
                      DataCell(Text(rows[i]['owner_name'] ?? '-')),
                      DataCell(Text(rows[i]['owner_phone'] ?? '-')),
                      DataCell(Text(rows[i]['room_name'] ?? '-')),
                      DataCell(Text('¥${rows[i]['arrears'] ?? 0}', style: const TextStyle(color: Color(0xFFD4380D), fontWeight: FontWeight.bold))),
                    ]),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
