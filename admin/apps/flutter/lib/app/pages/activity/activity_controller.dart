/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:get/get.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../widgets/base_crud_controller.dart';

class ActivityController extends BaseCrudController {
  final activities = <Map<String, dynamic>>[].obs;
  @override String get basePath => ApiConfig.activity;
  @override List<dynamic> get items => activities;
  @override void onLoadSuccess(Map<String, dynamic> d) {
    activities.value = List<Map<String, dynamic>>.from(d['data'] ?? []);
    total.value = d['total'] as int? ?? 0;
  }
}

class ActivitySignupController extends GetxController {
  final api = ApiService();
  final signups = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  @override void onInit() { super.onInit(); loadItems(); }
  Future<void> loadItems() async {
    isLoading.value = true;
    try {
      final r = await api.get(ApiConfig.activitySignup);
      signups.value = List<Map<String, dynamic>>.from(r['data'] is List ? r['data'] : (r['data']['data'] ?? []));
    } catch (_) {} finally { isLoading.value = false; }
  }
  Future<void> checkin(String hid) async {
    await api.put(ApiConfig.activitySignupCheckin(hid));
    await loadItems();
    Get.snackbar('成功', '签到完成');
  }
}
