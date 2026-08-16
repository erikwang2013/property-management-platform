/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:get/get.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../widgets/base_crud_controller.dart';

class FinanceController extends GetxController {
  final api = ApiService();
  final statistics = <String, dynamic>{}.obs;
  final isLoading = false.obs;

  @override void onInit() { super.onInit(); loadStats(); }
  Future<void> loadStats() async {
    isLoading.value = true;
    try {
      final r = await api.get(ApiConfig.financeStatistics);
      statistics.value = r['data'] as Map<String, dynamic>? ?? {};
    } catch (e) { Get.snackbar('错误', '加载统计数据失败: $e'); } finally { isLoading.value = false; }
  }
}

class FinanceIncomeController extends BaseCrudController {
  final incomes = <Map<String, dynamic>>[].obs;
  @override String get basePath => ApiConfig.financeIncome;
  @override bool get hasStatus => false;
  @override List<dynamic> get items => incomes;
  @override void onLoadSuccess(Map<String, dynamic> d) {
    incomes.value = List<Map<String, dynamic>>.from(d['data'] ?? []);
    total.value = d['total'] as int? ?? 0;
  }
}

class FinanceExpenseController extends BaseCrudController {
  final expenses = <Map<String, dynamic>>[].obs;
  @override String get basePath => ApiConfig.financeExpense;
  @override bool get hasStatus => false;
  @override List<dynamic> get items => expenses;
  @override void onLoadSuccess(Map<String, dynamic> d) {
    expenses.value = List<Map<String, dynamic>>.from(d['data'] ?? []);
    total.value = d['total'] as int? ?? 0;
  }
}
