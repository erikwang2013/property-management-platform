/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:get/get.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../widgets/base_crud_controller.dart';

class CleaningAreaController extends BaseCrudController {
  final areas = <Map<String, dynamic>>[].obs;
  @override String get basePath => ApiConfig.cleaningArea;
  @override List<dynamic> get items => areas;
  @override void onLoadSuccess(Map<String, dynamic> d) {
    areas.value = List<Map<String, dynamic>>.from(d['data'] ?? []);
    total.value = d['total'] as int? ?? 0;
  }
}

class CleaningRecordController extends GetxController {
  final api = ApiService();
  final records = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final total = 0.obs;
  final page = 1.obs;
  @override void onInit() { super.onInit(); loadItems(); }
  Future<void> loadItems({bool reset = false}) async {
    if (reset) page.value = 1; isLoading.value = true;
    try {
      final r = await api.get(ApiConfig.cleaningRecord, params: {'page': page.value, 'limit': 15});
      final d = r['data'] as Map<String, dynamic>;
      records.value = List<Map<String, dynamic>>.from(d['data'] ?? []);
      total.value = d['total'] as int? ?? 0;
    } catch (_) {} finally { isLoading.value = false; }
  }
  void nextPage() { if (page.value * 15 < total.value) { page.value++; loadItems(); } }
  void prevPage() { if (page.value > 1) { page.value--; loadItems(); } }
}
