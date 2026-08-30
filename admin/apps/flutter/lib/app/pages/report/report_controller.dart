/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'dart:ui' show Color;
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

/// 报表中心控制器：日期范围筛选 + 报表数据加载 + PDF 导出
class ReportController extends GetxController {
  final api = ApiService();
  final isLoading = false.obs;
  final rangeDays = 30.obs; // 30/90/本年/全部
  final data = <String, dynamic>{}.obs;

  static const payMethodColors = [Color(0xFF1677FF), Color(0xFF52C41A), Color(0xFFFA8C16), Color(0xFF722ED1), Color(0xFF13A8A8)];
  static const repairStatusLabels = {0: '待处理', 1: '已分配', 2: '维修中', 3: '已完成', 4: '已评价', 5: '已取消'};
  static const complaintStatusLabels = {0: '待处理', 1: '已处理', 2: '已回访'};
  static const visitorStatusLabels = {0: '待审批', 1: '已通过', 2: '已拒绝'};

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final end = DateTime.now();
      final start = rangeDays.value == 0
          ? DateTime(end.year, 1, 1)
          : end.subtract(Duration(days: rangeDays.value - 1));
      final r = await api.get(ApiConfig.report, params: {
        'start_date': _fmt(start),
        'end_date': _fmt(end),
      });
      data.value = r['data'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      Get.snackbar('错误', '加载报表数据失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> get summary =>
      data['summary'] as Map<String, dynamic>? ?? {};

  Future<void> exportPdf() async {
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      build: (ctx) => [
        pw.Header(text: '报表中心导出（${_fmt(DateTime.now())}）'),
        pw.Paragraph(text: 'Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz'),
        pw.Text('—— 汇总 ——', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        for (final e in summary.entries)
          pw.Paragraph(text: '${e.key}: ${e.value}'),
        pw.Text('—— 欠费排行 ——', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        for (final item in List<dynamic>.from(data['arrears_ranking'] ?? []))
          pw.Paragraph(
              text: '${item['owner_name']} ${item['room_name']} ¥${item['arrears']}'),
      ],
    ));
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'report.pdf');
  }
}
