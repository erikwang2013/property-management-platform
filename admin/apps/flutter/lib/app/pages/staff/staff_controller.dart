/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:get/get.dart';
import '../../config/api_config.dart';
import '../../widgets/base_crud_controller.dart';

class StaffController extends BaseCrudController {
  final staff = <Map<String, dynamic>>[].obs;
  @override String get basePath => ApiConfig.staff;
  @override List<dynamic> get items => staff;
  @override void onLoadSuccess(Map<String, dynamic> d) {
    staff.value = List<Map<String, dynamic>>.from(d['data'] ?? []);
    total.value = d['total'] as int? ?? 0;
  }
  Future<void> batchToggleStatus(int status) async {
    if (selectedIds.isEmpty) { Get.snackbar('提示', '请先选择员工'); return; }
    try {
      await api.post(ApiConfig.staffBatchStatus, data: {'ids': selectedIds.toList(), 'status': status});
      selectedIds.clear(); await loadItems();
      Get.snackbar('成功', status == 1 ? '批量启用完成' : '批量禁用完成');
    } catch (e) { Get.snackbar('错误', '操作失败: $e'); }
  }
}
