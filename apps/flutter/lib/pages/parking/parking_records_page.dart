/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class ParkingRecordsPage extends StatefulWidget {
  const ParkingRecordsPage({super.key});
  @override State<ParkingRecordsPage> createState() => _ParkingRecordsPageState();
}

class _ParkingRecordsPageState extends State<ParkingRecordsPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() => _loading = true);
    try { final api = Get.find<ApiService>(); final r = await api.dio.get(ApiConfig.parkingRecords);
      setState(() => _items = List<Map<String, dynamic>>.from(r.data['data'] ?? [])); } catch (_) {} finally { setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('停车记录')),
    body: Center(child: SizedBox(width: 600, child: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(16), children: _items.map((r) => Card(child: ListTile(title: Text(r['plate_number'] ?? ''), subtitle: Text('进入: ${r['enter_time'] ?? '-'} | 离开: ${r['leave_time'] ?? '-'}')))).toList()))),
  );
}
