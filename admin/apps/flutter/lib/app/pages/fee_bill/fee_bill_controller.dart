/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:get/get.dart';
import '../../config/api_config.dart';
import '../../widgets/base_crud_controller.dart';

class FeeBillController extends BaseCrudController {
  final bills = <Map<String, dynamic>>[].obs;
  @override String get basePath => ApiConfig.feeBill;
  @override List<dynamic> get items => bills;

  @override void onLoadSuccess(Map<String, dynamic> data) {
    bills.value = List<Map<String, dynamic>>.from(data['data'] ?? []);
    total.value = data['total'] as int? ?? 0;
  }

  Future<void> batchGenerate() async {
    try {
      await api.post(ApiConfig.feeBillBatchGenerate);
      await loadItems(reset: true);
      Get.snackbar('成功', '批量生成账单完成');
    } catch (e) { Get.snackbar('错误', '批量生成失败: $e'); }
  }
}
