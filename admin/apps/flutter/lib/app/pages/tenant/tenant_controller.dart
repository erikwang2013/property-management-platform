/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:get/get.dart';
import '../../config/api_config.dart';
import '../../widgets/base_crud_controller.dart';

class TenantController extends BaseCrudController {
  final tenants = <Map<String, dynamic>>[].obs;
  @override String get basePath => ApiConfig.tenant;
  @override List<dynamic> get items => tenants;

  @override
  void onLoadSuccess(Map<String, dynamic> data) {
    tenants.value = List<Map<String, dynamic>>.from(data['data'] ?? []);
    total.value = data['total'] as int? ?? 0;
  }

  Future<void> create(Map<String, dynamic> d) async {
    await api.post(ApiConfig.tenant, data: d);
    await loadItems(reset: true);
  }

  Future<void> updateItem(String hid, Map<String, dynamic> d) async {
    await api.put('${ApiConfig.tenant}/$hid', data: d);
    await loadItems();
  }
}
