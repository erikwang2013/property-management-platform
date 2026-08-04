/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:get/get.dart';
import '../../config/api_config.dart';
import '../../widgets/base_crud_controller.dart';

class PaymentController extends BaseCrudController {
  final payments = <Map<String, dynamic>>[].obs;
  @override String get basePath => ApiConfig.payment;
  @override bool get hasStatus => false;
  @override List<dynamic> get items => payments;
  @override void onLoadSuccess(Map<String, dynamic> d) {
    payments.value = List<Map<String, dynamic>>.from(d['data'] ?? []);
    total.value = d['total'] as int? ?? 0;
  }
}
