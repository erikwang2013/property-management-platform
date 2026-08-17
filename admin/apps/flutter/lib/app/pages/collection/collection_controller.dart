/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:get/get.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../widgets/base_crud_controller.dart';

class CollectionStrategyController extends BaseCrudController {
  final strategies = <Map<String, dynamic>>[].obs;
  @override String get basePath => ApiConfig.collectionStrategy;
  @override bool get hasStatus => false;
  @override List<dynamic> get items => strategies;
  @override void onLoadSuccess(Map<String, dynamic> d) {
    strategies.value = List<Map<String, dynamic>>.from(d['data'] ?? []);
    total.value = d['total'] as int? ?? 0;
  }
}

class CollectionRecordController extends GetxController {
  final api = ApiService();
  final records = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  @override void onInit() { super.onInit(); loadItems(); }
  Future<void> loadItems() async {
    isLoading.value = true;
    try {
      final r = await api.get(ApiConfig.collectionRecord);
      records.value = List<Map<String, dynamic>>.from(r['data'] is List ? r['data'] : (r['data']['data'] ?? []));
    } catch (e) { Get.snackbar('错误', '加载列表失败: $e'); } finally { isLoading.value = false; }
  }
  bool _running = false;
  Future<void> run() async {
    if (_running) return;
    _running = true;
    try {
      await api.post(ApiConfig.collectionRun);
      // 后台队列异步处理，提示后延迟刷新避免拉取到未完成状态
      Get.snackbar('成功', '催缴任务已提交，正在异步处理');
      await Future.delayed(const Duration(seconds: 3));
      await loadItems();
    } catch (e) {
      Get.snackbar('错误', '催缴执行失败: $e');
    } finally {
      _running = false;
    }
  }
}
