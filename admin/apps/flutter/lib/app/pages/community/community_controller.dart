/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:get/get.dart';
import '../../config/api_config.dart';
import '../../widgets/base_crud_controller.dart';

class CommunityController extends BaseCrudController {
  final communities = <Map<String, dynamic>>[].obs;

  @override
  String get basePath => ApiConfig.community;

  @override
  List<dynamic> get items => communities;

  @override
  void onLoadSuccess(Map<String, dynamic> data) {
    communities.value = List<Map<String, dynamic>>.from(data['data'] ?? []);
    total.value = data['total'] as int? ?? 0;
  }

  Future<void> create(Map<String, dynamic> data) async {
    await api.post(ApiConfig.community, data: data);
    await loadItems(reset: true);
  }

  @override
  Future<void> updateItem(String hid, Map<String, dynamic> data) async {
    await api.put('${ApiConfig.community}/$hid', data: data);
    await loadItems();
  }
}
