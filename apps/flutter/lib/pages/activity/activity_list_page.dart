/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class ActivityListPage extends StatefulWidget {
  const ActivityListPage({super.key});
  @override State<ActivityListPage> createState() => _ActivityListPageState();
}

class _ActivityListPageState extends State<ActivityListPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() => _loading = true);
    try { final api = Get.find<ApiService>(); final r = await api.dio.get(ApiConfig.activities);
      setState(() => _items = List<Map<String, dynamic>>.from(r.data['data'] ?? [])); } catch (_) {} finally { setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('社区活动')),
      body: Center(child: SizedBox(width: 600, child: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(16), children: _items.map((a) => Card(child: ListTile(
        leading: const Icon(Icons.event, color: Colors.blue), title: Text(a['title'] ?? ''),
        subtitle: Text('${a['location'] ?? ''} | ${a['start_time'] ?? ''} | ${a['signup_count'] ?? 0}/${a['max_signup'] ?? '-'}人'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Get.toNamed('/activity-detail', arguments: a),
      ))).toList()))),
    );
  }
}
