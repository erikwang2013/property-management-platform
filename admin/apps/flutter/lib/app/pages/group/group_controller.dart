/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:get/get.dart';
import '../../config/api_config.dart';
import '../../widgets/base_crud_controller.dart';

class GroupController extends BaseCrudController {
  final groups = <Map<String, dynamic>>[].obs;
  final summary = <String, dynamic>{}.obs;
  @override String get basePath => ApiConfig.group;
  @override bool get hasStatus => false;
  @override List<dynamic> get items => groups;
  @override void onLoadSuccess(Map<String, dynamic> d) {
    groups.value = List<Map<String, dynamic>>.from(d['data'] ?? []);
    total.value = d['total'] as int? ?? 0;
  }
  Future<void> loadSummary(String hid) async {
    try {
      final r = await api.get(ApiConfig.groupSummary(hid));
      summary.value = r['data'] as Map<String, dynamic>? ?? {};
    } catch (e) { Get.snackbar('错误', '加载汇总失败: $e'); }
  }
}
