/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class MallProductsPage extends StatefulWidget {
  const MallProductsPage({super.key});
  @override State<MallProductsPage> createState() => _MallProductsPageState();
}

class _MallProductsPageState extends State<MallProductsPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() => _loading = true);
    try { final api = Get.find<ApiService>(); final r = await api.dio.get(ApiConfig.mallProducts);
      setState(() => _items = List<Map<String, dynamic>>.from(r.data['data'] ?? [])); } catch (_) {} finally { setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('社区商城'), actions: [IconButton(icon: const Icon(Icons.shopping_cart), onPressed: () => Get.toNamed('/mall-orders'))]),
    body: Center(child: SizedBox(width: 800, child: _loading ? const Center(child: CircularProgressIndicator()) : GridView.builder(padding: const EdgeInsets.all(16), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.85), itemCount: _items.length, itemBuilder: (_, i) {
      final p = _items[i];
      return Card(child: InkWell(onTap: () => Get.toNamed('/mall-product-detail', arguments: p), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.shopping_bag, size: 48, color: Colors.blue),
        const SizedBox(height: 8), Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
        const Spacer(),
        Row(children: [Text('¥${p['price'] ?? '-'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)), const Spacer(), Text('库存:${p['stock'] ?? 0}', style: const TextStyle(fontSize: 11, color: Colors.grey))]),
      ]))));
    })))),
  );
}
