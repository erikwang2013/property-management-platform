/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:get/get.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../widgets/base_crud_controller.dart';

class EnergyMeterController extends BaseCrudController {
  final meters = <Map<String, dynamic>>[].obs;
  @override String get basePath => ApiConfig.energyMeter;
  @override List<dynamic> get items => meters;
  @override void onLoadSuccess(Map<String, dynamic> d) {
    meters.value = List<Map<String, dynamic>>.from(d['data'] ?? []);
    total.value = d['total'] as int? ?? 0;
  }
}

class EnergyRecordController extends GetxController {
  final api = ApiService();
  final records = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final total = 0.obs;
  final page = 1.obs;
  @override void onInit() { super.onInit(); loadItems(); }
  Future<void> loadItems({bool reset = false}) async {
    if (reset) page.value = 1; isLoading.value = true;
    try {
      final r = await api.get(ApiConfig.energyRecord, params: {'page': page.value, 'limit': 15});
      final d = r['data'] as Map<String, dynamic>;
      records.value = List<Map<String, dynamic>>.from(d['data'] ?? []);
      total.value = d['total'] as int? ?? 0;
    } catch (e) { Get.snackbar('错误', '加载列表失败: $e'); } finally { isLoading.value = false; }
  }
  Future<void> record(String meterId, double reading) async {
    await api.post(ApiConfig.energyRecord, data: {'meter_id': meterId, 'reading': reading});
    await loadItems(reset: true);
    Get.snackbar('成功', '抄表记录已保存');
  }
  void nextPage() { if (page.value * 15 < total.value) { page.value++; loadItems(); } }
  void prevPage() { if (page.value > 1) { page.value--; loadItems(); } }
}
