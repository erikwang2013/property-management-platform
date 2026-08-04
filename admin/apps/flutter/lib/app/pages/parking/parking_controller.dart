/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:get/get.dart';
import '../../config/api_config.dart';
import '../../widgets/base_crud_controller.dart';

class ParkingSpaceController extends BaseCrudController {
  final spaces = <Map<String, dynamic>>[].obs;
  @override String get basePath => ApiConfig.parkingSpace;
  @override List<dynamic> get items => spaces;
  @override void onLoadSuccess(Map<String, dynamic> d) {
    spaces.value = List<Map<String, dynamic>>.from(d['data'] ?? []);
    total.value = d['total'] as int? ?? 0;
  }
}

class ParkingVehicleController extends BaseCrudController {
  final vehicles = <Map<String, dynamic>>[].obs;
  @override String get basePath => ApiConfig.parkingVehicle;
  @override List<dynamic> get items => vehicles;
  @override void onLoadSuccess(Map<String, dynamic> d) {
    vehicles.value = List<Map<String, dynamic>>.from(d['data'] ?? []);
    total.value = d['total'] as int? ?? 0;
  }
}

class ParkingRecordController extends GetxController {
  final api = ApiService();
  final records = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final total = 0.obs;
  final page = 1.obs;
  final limit = 15.obs;
  @override void onInit() { super.onInit(); loadItems(); }
  Future<void> loadItems({bool reset = false}) async {
    if (reset) page.value = 1;
    isLoading.value = true;
    try {
      final r = await api.get(ApiConfig.parkingRecord, params: {'page': page.value, 'limit': limit.value});
      final d = r['data'] as Map<String, dynamic>;
      records.value = List<Map<String, dynamic>>.from(d['data'] ?? []);
      total.value = d['total'] as int? ?? 0;
    } catch (_) {} finally { isLoading.value = false; }
  }
}
