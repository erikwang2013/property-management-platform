/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class ParkingVehiclesPage extends StatefulWidget {
  const ParkingVehiclesPage({super.key});
  @override State<ParkingVehiclesPage> createState() => _ParkingVehiclesPageState();
}

class _ParkingVehiclesPageState extends State<ParkingVehiclesPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = Get.find<ApiService>();
      final r = await api.dio.get(ApiConfig.parkingVehicles);
      setState(() => _items = List<Map<String, dynamic>>.from(r.data['data'] ?? []));
    } catch (_) {} finally { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的车辆')),
      body: Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 600), child: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(padding: const EdgeInsets.all(16), children: _items.map((v) => Card(
          child: ListTile(leading: const Icon(Icons.directions_car), title: Text(v['plate_number'] ?? ''), subtitle: Text('车位: ${v['space_number'] ?? '-'}'), trailing: const Icon(Icons.chevron_right)),
        )).toList()),
      )),
    );
  }
}
