/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:get/get.dart';
import '../../config/api_config.dart';

class FaceController extends GetxController {
  final api = ApiService();
  final faces = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  @override void onInit() { super.onInit(); loadItems(); }
  Future<void> loadItems() async {
    isLoading.value = true;
    try {
      final r = await api.get(ApiConfig.face);
      faces.value = List<Map<String, dynamic>>.from(r['data'] is List ? r['data'] : []);
    } catch (_) {} finally { isLoading.value = false; }
  }
  Future<void> verify(String hid) async {
    await api.put('${ApiConfig.face}/$hid/verify');
    await loadItems();
    Get.snackbar('成功', '人脸审核通过');
  }
  Future<void> reject(String hid) async {
    await api.put('${ApiConfig.face}/$hid/reject');
    await loadItems();
    Get.snackbar('成功', '已驳回');
  }
}
