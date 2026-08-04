/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class MallOrdersPage extends StatefulWidget {
  const MallOrdersPage({super.key});
  @override State<MallOrdersPage> createState() => _MallOrdersPageState();
}

class _MallOrdersPageState extends State<MallOrdersPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() => _loading = true);
    try { final api = Get.find<ApiService>(); final r = await api.dio.get(ApiConfig.mallOrders);
      setState(() => _items = List<Map<String, dynamic>>.from(r.data['data'] ?? [])); } catch (_) {} finally { setState(() => _loading = false); }
  }
  String _status(dynamic s) => {0: '待支付', 1: '已支付', 2: '已发货', 3: '已完成', 4: '已退款'}[s as int?] ?? '-';
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('我的订单')),
    body: Center(child: SizedBox(width: 600, child: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(16), children: _items.map((o) => Card(child: ListTile(
      leading: const Icon(Icons.receipt), title: Text(o['product_name'] ?? o['order_no'] ?? ''),
      subtitle: Text('¥${o['amount'] ?? '-'} | ${_status(o['status'])}'), trailing: Text(o['created_at'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ))).toList()))),
  );
}
