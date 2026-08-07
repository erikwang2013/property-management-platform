/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:get/get.dart';
import '../../config/api_config.dart';
import '../../widgets/base_crud_controller.dart';

class ContractController extends BaseCrudController {
  final contracts = <Map<String, dynamic>>[].obs;
  @override String get basePath => ApiConfig.contract;
  @override List<dynamic> get items => contracts;
  @override void onLoadSuccess(Map<String, dynamic> d) {
    contracts.value = List<Map<String, dynamic>>.from(d['data'] ?? []);
    total.value = d['total'] as int? ?? 0;
  }
  Future<void> create(Map<String, dynamic> data) async {
    await api.post(ApiConfig.contract, data: data); await loadItems(reset: true);
  }
  @override
  Future<void> updateItem(String hid, Map<String, dynamic> data) async {
    await api.put('${ApiConfig.contract}/$hid', data: data); await loadItems();
  }
}
