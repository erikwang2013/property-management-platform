/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:get/get.dart';
import '../../config/api_config.dart';
import '../../widgets/base_crud_controller.dart';

class FeeTypeController extends BaseCrudController {
  final feeTypes = <Map<String, dynamic>>[].obs;
  @override String get basePath => ApiConfig.feeType;
  @override bool get hasStatus => false;
  @override List<dynamic> get items => feeTypes;

  @override void onLoadSuccess(Map<String, dynamic> data) {
    feeTypes.value = List<Map<String, dynamic>>.from(data['data'] ?? []);
    total.value = data['total'] as int? ?? 0;
  }
  Future<void> create(Map<String, dynamic> data) async {
    await api.post(ApiConfig.feeType, data: data); await loadItems(reset: true);
  }
  @override
  Future<void> updateItem(String hid, Map<String, dynamic> data) async {
    await api.put('${ApiConfig.feeType}/$hid', data: data); await loadItems();
  }
}
