/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});
  @override State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() => _loading = true);
    try { final api = Get.find<ApiService>(); final r = await api.dio.get(ApiConfig.notifications);
      setState(() => _items = List<Map<String, dynamic>>.from(r.data['data'] ?? [])); } catch (_) {} finally { setState(() => _loading = false); }
  }
  Future<void> _readAll() async {
    try { final api = Get.find<ApiService>(); await api.dio.post(ApiConfig.notificationReadAll); _load(); } catch (_) {}
  }
  void _showDetail(Map<String, dynamic> n) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(n['title'] ?? ''),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if ((n['sent_at'] ?? '') != '')
                  Text(n['sent_at'].toString(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                Text(n['content'] ?? '', style: const TextStyle(height: 1.6)),
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('cancel'.tr))],
      ),
    );
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('消息通知'), actions: [TextButton(onPressed: _readAll, child: const Text('全部已读'))]),
    body: Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 600), child: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(16), children: _items.map((n) => Card(
      color: n['read_at'] == null ? Colors.blue.shade50 : null,
      child: ListTile(leading: Icon(n['read_at'] == null ? Icons.markunread : Icons.drafts, color: n['read_at'] == null ? Colors.blue : Colors.grey), title: Text(n['title'] ?? ''), subtitle: Text(n['content'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis), trailing: Text(n['sent_at'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)), onTap: () => _showDetail(n)),
    )).toList()))),
  );
}
