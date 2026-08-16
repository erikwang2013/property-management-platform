/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:get/get.dart';
import '../../config/api_config.dart';
import '../../widgets/base_crud_controller.dart';

class RoomController extends BaseCrudController {
  final rooms = <Map<String, dynamic>>[].obs;
  final communities = <Map<String, dynamic>>[].obs;
  final buildings = <Map<String, dynamic>>[].obs;
  final units = <Map<String, dynamic>>[].obs;
  final roomTypes = <Map<String, dynamic>>[].obs;

  @override String get basePath => ApiConfig.room;
  @override bool get hasKeyword => false;
  @override List<dynamic> get items => rooms;

  @override
  void onInit() {
    super.onInit();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final cr = await api.get(ApiConfig.community, params: {'page': 1, 'limit': 100});
      communities.value = List<Map<String, dynamic>>.from(cr['data']['data'] ?? []);
      final rr = await api.get(ApiConfig.roomType, params: {'page': 1, 'limit': 100});
      roomTypes.value = List<Map<String, dynamic>>.from(rr['data']['data'] ?? []);
    } catch (e) { Get.snackbar('错误', '加载失败: $e'); }
  }

  Future<void> loadBuildings(String communityHashId) async {
    try {
      final br = await api.get(ApiConfig.building, params: {'community_id': communityHashId, 'page': 1, 'limit': 100});
      buildings.value = List<Map<String, dynamic>>.from(br['data']['data'] ?? []);
      units.clear();
    } catch (e) { Get.snackbar('错误', '加载失败: $e'); }
  }

  Future<void> loadUnits(String buildingHashId) async {
    try {
      final ur = await api.get(ApiConfig.unit, params: {'building_id': buildingHashId, 'page': 1, 'limit': 100});
      units.value = List<Map<String, dynamic>>.from(ur['data']['data'] ?? []);
    } catch (e) { Get.snackbar('错误', '加载失败: $e'); }
  }

  @override
  void onLoadSuccess(Map<String, dynamic> data) {
    rooms.value = List<Map<String, dynamic>>.from(data['data'] ?? []);
    total.value = data['total'] as int? ?? 0;
  }

  Future<void> create(Map<String, dynamic> data) async {
    await api.post(ApiConfig.room, data: data);
    await loadItems(reset: true);
  }

  @override
  Future<void> updateItem(String hid, Map<String, dynamic> data) async {
    await api.put('${ApiConfig.room}/$hid', data: data);
    await loadItems();
  }
}
