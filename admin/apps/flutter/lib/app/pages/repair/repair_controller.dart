/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:get/get.dart';
import '../../config/api_config.dart';
import '../../widgets/base_crud_controller.dart';

class RepairController extends BaseCrudController {
  final repairs = <Map<String, dynamic>>[].obs;
  @override String get basePath => ApiConfig.repair;
  @override bool get hasStatus => false;
  @override List<dynamic> get items => repairs;

  @override void onLoadSuccess(Map<String, dynamic> data) {
    repairs.value = List<Map<String, dynamic>>.from(data['data'] ?? []);
    total.value = data['total'] as int? ?? 0;
  }

  Future<void> assign(String hid, String staffId) async {
    await api.put(ApiConfig.repairAssign(hid), data: {'staff_id': staffId});
    await loadItems();
  }

  Future<void> addProgress(String hid, String content, int status) async {
    await api.post(ApiConfig.repairProgress(hid), data: {'content': content, 'status': status});
    await loadItems();
  }
}
