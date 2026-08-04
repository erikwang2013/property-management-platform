/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:get/get.dart';
import '../../config/api_config.dart';

class VisitorController extends GetxController {
  final api = ApiService();
  final visitors = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final total = 0.obs;
  final page = 1.obs;
  final limit = 15.obs;
  @override void onInit() { super.onInit(); loadItems(); }
  Future<void> loadItems({bool reset = false}) async {
    if (reset) page.value = 1;
    isLoading.value = true;
    try {
      final r = await api.get(ApiConfig.visitor, params: {'page': page.value, 'limit': limit.value});
      final d = r['data'] as Map<String, dynamic>;
      visitors.value = List<Map<String, dynamic>>.from(d['data'] ?? []);
      total.value = d['total'] as int? ?? 0;
    } catch (_) {} finally { isLoading.value = false; }
  }
  Future<void> approve(String hid) async {
    await api.put(ApiConfig.visitorApprove(hid));
    await loadItems();
  }
  void nextPage() { if (page.value * limit.value < total.value) { page.value++; loadItems(); } }
  void prevPage() { if (page.value > 1) { page.value--; loadItems(); } }
}
