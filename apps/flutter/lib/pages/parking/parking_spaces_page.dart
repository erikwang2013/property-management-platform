/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class ParkingSpacesPage extends StatefulWidget {
  const ParkingSpacesPage({super.key});
  @override State<ParkingSpacesPage> createState() => _ParkingSpacesPageState();
}

class _ParkingSpacesPageState extends State<ParkingSpacesPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() => _loading = true);
    try { final api = Get.find<ApiService>(); final r = await api.dio.get(ApiConfig.parkingSpaces);
      setState(() => _items = List<Map<String, dynamic>>.from(r.data['data'] ?? [])); } catch (_) {} finally { setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('我的车位')),
    body: Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 600), child: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(16), children: _items.map((s) => Card(child: ListTile(leading: const Icon(Icons.local_parking), title: Text(s['space_number'] ?? ''), subtitle: Text('类型: ${s['type'] ?? '-'} | 面积: ${s['area'] ?? '-'}m²')))).toList()))),
  );
}
