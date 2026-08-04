/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:get/get.dart';
import '../../config/api_config.dart';
import '../../widgets/base_crud_controller.dart';

class FeePaymentController extends BaseCrudController {
  final payments = <Map<String, dynamic>>[].obs;
  @override String get basePath => ApiConfig.feePayment;
  @override bool get hasStatus => false;
  @override bool get hasKeyword => false;
  @override List<dynamic> get items => payments;

  @override void onLoadSuccess(Map<String, dynamic> data) {
    payments.value = List<Map<String, dynamic>>.from(data['data'] ?? []);
    total.value = data['total'] as int? ?? 0;
  }

  Future<void> offlinePay(Map<String, dynamic> d) async {
    await api.post(ApiConfig.feePaymentOffline, data: d);
    await loadItems(reset: true);
  }
}
