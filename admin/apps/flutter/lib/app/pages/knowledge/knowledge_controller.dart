/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:get/get.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../widgets/base_crud_controller.dart';

class KnowledgeCategoryController extends BaseCrudController {
  final categories = <Map<String, dynamic>>[].obs;
  @override String get basePath => ApiConfig.knowledgeCategory;
  @override bool get hasStatus => false;
  @override bool get hasKeyword => false;
  @override List<dynamic> get items => categories;
  @override void onLoadSuccess(Map<String, dynamic> d) {
    categories.value = List<Map<String, dynamic>>.from(d['data'] ?? []);
    total.value = d['total'] as int? ?? 0;
  }
}

class KnowledgeArticleController extends BaseCrudController {
  final articles = <Map<String, dynamic>>[].obs;
  @override String get basePath => ApiConfig.knowledge;
  @override bool get hasStatus => false;
  @override List<dynamic> get items => articles;
  @override void onLoadSuccess(Map<String, dynamic> d) {
    articles.value = List<Map<String, dynamic>>.from(d['data'] ?? []);
    total.value = d['total'] as int? ?? 0;
  }
}

class ChatRecordController extends GetxController {
  final api = ApiService();
  final records = <Map<String, dynamic>>[].obs;
  final stats = <String, dynamic>{}.obs;
  final isLoading = false.obs;
  @override void onInit() { super.onInit(); loadRecords(); loadStats(); }
  Future<void> loadRecords() async {
    isLoading.value = true;
    try {
      final r = await api.get(ApiConfig.chatRecord);
      records.value = List<Map<String, dynamic>>.from(r['data'] is List ? r['data'] : (r['data']['data'] ?? []));
    } catch (e) { Get.snackbar('错误', '加载列表失败: $e'); } finally { isLoading.value = false; }
  }
  Future<void> loadStats() async {
    try {
      final r = await api.get(ApiConfig.chatStats);
      stats.value = r['data'] as Map<String, dynamic>? ?? {};
    } catch (e) { Get.snackbar('错误', '加载统计数据失败: $e'); }
  }
}
