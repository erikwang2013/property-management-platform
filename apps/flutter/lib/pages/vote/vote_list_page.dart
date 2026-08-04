/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class VoteListPage extends StatefulWidget {
  const VoteListPage({super.key});
  @override State<VoteListPage> createState() => _VoteListPageState();
}

class _VoteListPageState extends State<VoteListPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() => _loading = true);
    try { final api = Get.find<ApiService>(); final r = await api.dio.get(ApiConfig.votes);
      setState(() => _items = List<Map<String, dynamic>>.from(r.data['data'] ?? [])); } catch (_) {} finally { setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('业主投票')),
    body: Center(child: SizedBox(width: 600, child: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(16), children: _items.map((v) => Card(child: ListTile(
      leading: const Icon(Icons.how_to_vote, color: Colors.blue), title: Text(v['title'] ?? ''),
      subtitle: Text('${v['voted_count'] ?? 0}人已投票 | 截止: ${v['end_time'] ?? '-'}'),
      trailing: const Icon(Icons.chevron_right), onTap: () => Get.toNamed('/vote-detail', arguments: v),
    ))).toList()))),
  );
}
