/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../widgets/pet_mark.dart';

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
      setState(() => _items = List<Map<String, dynamic>>.from(r.data['data']?['data'] ?? [])); } catch (e) { debugPrint('[visitor_list_page] $e'); } finally { setState(() => _loading = false); }
  }

  // 状态枚举以 management_visitor.status 为准: 0=已预约 1=已到访 2=已离开 3=已取消
  String _statusLabel(dynamic s) =>
      {0: '已预约', 1: '已到访', 2: '已离开', 3: '已取消'}[s] ?? '未知';
  Color _statusColor(dynamic s) =>
      {0: Colors.orange, 1: Colors.green, 2: Colors.blueGrey, 3: Colors.grey}[s] ??
      Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('访客预约'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: () => Get.toNamed('/visitor-create')?.then((_) => _load())),
      ]),
      body: Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 600), child: _loading ? PetLoading() : ListView(padding: const EdgeInsets.all(16), children: _items.map((v) => Card(child: ListTile(
        leading: CircleAvatar(child: Text((v['visitor_name'] as String? ?? '?')[0])),
        title: Text(v['visitor_name'] ?? ''), subtitle: Text('访问时间: ${v['expected_start'] ?? '-'}'),
        trailing: Chip(label: Text(_statusLabel(v['status']), style: const TextStyle(fontSize: 12)), backgroundColor: _statusColor(v['status'])),
      ))).toList()))),
    );
  }
}
