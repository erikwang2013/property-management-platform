/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:get/get.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';

class ComplaintController extends GetxController {
  final api = ApiService();
  final complaints = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final total = 0.obs;
  final page = 1.obs;
  final limit = 15.obs;
  final statusFilter = Rx<int?>(null);

  @override void onInit() { super.onInit(); loadItems(); }

  Future<void> loadItems({bool reset = false}) async {
    if (reset) page.value = 1;
    isLoading.value = true;
    try {
      final p = <String, dynamic>{'page': page.value, 'limit': limit.value};
      if (statusFilter.value != null) p['status'] = statusFilter.value;
      final r = await api.get(ApiConfig.complaint, params: p);
      final d = r['data'] as Map<String, dynamic>;
      complaints.value = List<Map<String, dynamic>>.from(d['data'] ?? []);
      total.value = d['total'] as int? ?? 0;
    } catch (_) {} finally { isLoading.value = false; }
  }

  Future<void> handle(String hid, String result) async {
    await api.put(ApiConfig.complaintHandle(hid), data: {'handle_result': result});
    await loadItems();
  }

  Future<void> visit(String hid, String satisfaction) async {
    await api.post(ApiConfig.complaintVisit(hid), data: {'satisfaction': satisfaction});
    await loadItems();
  }

  void nextPage() { if (page.value * limit.value < total.value) { page.value++; loadItems(); } }
  void prevPage() { if (page.value > 1) { page.value--; loadItems(); } }
}
