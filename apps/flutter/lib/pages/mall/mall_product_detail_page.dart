/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class MallProductDetailPage extends StatefulWidget {
  const MallProductDetailPage({super.key});
  @override State<MallProductDetailPage> createState() => _MallProductDetailPageState();
}

class _MallProductDetailPageState extends State<MallProductDetailPage> {
  Map<String, dynamic>? _detail;
  bool _loading = true;
  String? get _hashid => (Get.arguments as Map<String, dynamic>?)?['id'] ?? (Get.arguments as Map<String, dynamic>?)?['hashid'];

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    if (_hashid == null) return;
    try { final api = Get.find<ApiService>(); final r = await api.dio.get(ApiConfig.mallProductDetail(_hashid!));
      setState(() => _detail = r.data['data']); } catch (_) {} finally { setState(() => _loading = false); }
  }
  Future<void> _order() async {
    try { final api = Get.find<ApiService>(); await api.dio.post(ApiConfig.mallOrder, data: {'product_id': _hashid, 'quantity': 1}); Get.snackbar('成功', '下单成功'); Get.offNamed('/mall-orders'); } catch (e) { Get.snackbar('错误', '下单失败: $e'); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(_detail?['name'] ?? '商品详情')),
    body: Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 600), child: _loading ? const Center(child: CircularProgressIndicator()) : Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.shopping_bag, size: 80, color: Colors.blue), const SizedBox(height: 16),
      Text(_detail?['name'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
      Text('¥${_detail?['price'] ?? '-'}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red)), const SizedBox(height: 8),
      Text('库存: ${_detail?['stock'] ?? 0}', style: const TextStyle(color: Colors.grey)), const SizedBox(height: 16),
      Text(_detail?['description'] ?? '', style: const TextStyle(fontSize: 14)), const SizedBox(height: 24),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _order, child: const Text('立即购买'))),
    ]))))),
  );
}
