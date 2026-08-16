/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class VisitorListPage extends StatefulWidget {
  const VisitorListPage({super.key});
  @override State<VisitorListPage> createState() => _VisitorListPageState();
}

class _VisitorListPageState extends State<VisitorListPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() => _loading = true);
    try { final api = Get.find<ApiService>(); final r = await api.dio.get(ApiConfig.visitors);
      setState(() => _items = List<Map<String, dynamic>>.from(r.data['data'] ?? [])); } catch (_) {} finally { setState(() => _loading = false); }
  }

  String _statusLabel(dynamic s) => s == 1 ? '已通过' : s == 2 ? '已拒绝' : '待审批';
  Color _statusColor(dynamic s) => s == 1 ? Colors.green : s == 2 ? Colors.red : Colors.orange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('访客预约'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: () => Get.toNamed('/visitor-create')?.then((_) => _load())),
      ]),
      body: Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 600), child: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(16), children: _items.map((v) => Card(child: ListTile(
        leading: CircleAvatar(child: Text((v['visitor_name'] as String? ?? '?')[0])),
        title: Text(v['visitor_name'] ?? ''), subtitle: Text('访问时间: ${v['visit_time'] ?? '-'}'),
        trailing: Chip(label: Text(_statusLabel(v['status']), style: const TextStyle(fontSize: 12)), backgroundColor: _statusColor(v['status'])),
      ))).toList()))),
    );
  }
}
