/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:get/get.dart';
import '../../config/api_config.dart';
import '../../widgets/base_crud_controller.dart';

class ApprovalController extends BaseCrudController {
  final approvals = <Map<String, dynamic>>[].obs;
  @override String get basePath => ApiConfig.approval;
  @override List<dynamic> get items => approvals;
  @override void onLoadSuccess(Map<String, dynamic> d) {
    approvals.value = List<Map<String, dynamic>>.from(d['data'] ?? []);
    total.value = d['total'] as int? ?? 0;
  }
}
