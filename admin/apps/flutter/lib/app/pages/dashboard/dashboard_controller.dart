// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class DashboardController extends GetxController {
  final _api = ApiService();
  final isLoading = true.obs;

  final stats = <Map<String, dynamic>>[].obs;
  final trends = <String, dynamic>{}.obs;
  final distribution = <String, dynamic>{}.obs;
  final recentLogs = <Map<String, dynamic>>[].obs;

  List<List<FlSpot>> get trendSpots {
    final allSeries = trends['series'] as List<dynamic>? ?? [];
    return allSeries.map((s) {
      final data = s['data'] as List<dynamic>? ?? [];
      return data.asMap().entries
          .map((e) => FlSpot(e.key.toDouble(), (e.value as num).toDouble()))
          .toList();
    }).toList();
  }

  List<PieChartSectionData> get pieSections {
    final userStatus = distribution['user_status'] as List<dynamic>? ?? [];
    if (userStatus.isEmpty) return [];
    const colors = [Color(0xFF1677FF), Color(0xFF52C41A)];
    return userStatus.asMap().entries.map((e) {
      final item = e.value as Map<String, dynamic>;
      return PieChartSectionData(
        color: colors[e.key % colors.length],
        value: (item['value'] as num).toDouble(),
        title: '${item['value']}',
        radius: 30,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;
      final resp = await _api.get(ApiConfig.dashboard);
      final data = resp['data'] as Map<String, dynamic>;
      stats.value = List<Map<String, dynamic>>.from(data['stats'] ?? []);
      trends.value = Map<String, dynamic>.from(data['trends'] ?? {});
      distribution.value = Map<String, dynamic>.from(data['distribution'] ?? {});
      recentLogs.value = List<Map<String, dynamic>>.from(data['recent_logs'] ?? []);
    } catch (e) {
      stats.clear();
      trends.clear();
      distribution.clear();
      recentLogs.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> exportPdf() async {
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      build: (ctx) => [
        pw.Header(text: '仪表盘数据导出'),
        pw.Paragraph(text: 'Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz'),
        for (final s in stats)
          pw.Row(children: [
            pw.Text(s['label']),
            pw.Text(s['value'], style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ]),
      ],
    ));
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'dashboard_export.pdf');
  }

  Future<void> exportExcel() async {
    Get.snackbar('导出', 'Excel 导出功能已触发');
  }
}
