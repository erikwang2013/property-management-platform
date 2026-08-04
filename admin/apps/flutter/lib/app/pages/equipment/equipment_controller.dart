/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:get/get.dart';
import '../../config/api_config.dart';
import '../../widgets/base_crud_controller.dart';

class EquipmentController extends BaseCrudController {
  final equipment = <Map<String, dynamic>>[].obs;
  @override String get basePath => ApiConfig.equipment;
  @override List<dynamic> get items => equipment;
  @override void onLoadSuccess(Map<String, dynamic> d) {
    equipment.value = List<Map<String, dynamic>>.from(d['data'] ?? []);
    total.value = d['total'] as int? ?? 0;
  }
}

class EquipmentMaintenanceController extends BaseCrudController {
  final maintenances = <Map<String, dynamic>>[].obs;
  @override String get basePath => ApiConfig.equipmentMaintenance;
  @override bool get hasStatus => false;
  @override List<dynamic> get items => maintenances;
  @override void onLoadSuccess(Map<String, dynamic> d) {
    maintenances.value = List<Map<String, dynamic>>.from(d['data'] ?? []);
    total.value = d['total'] as int? ?? 0;
  }
}
