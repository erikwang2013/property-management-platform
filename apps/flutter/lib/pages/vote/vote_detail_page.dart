/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class VoteDetailPage extends StatefulWidget {
  const VoteDetailPage({super.key});
  @override State<VoteDetailPage> createState() => _VoteDetailPageState();
}

class _VoteDetailPageState extends State<VoteDetailPage> {
  Map<String, dynamic>? _detail;
  List<Map<String, dynamic>> _options = [];
  String? _selectedOption;
  bool _loading = true;
  String? get _hashid => (Get.arguments as Map<String, dynamic>?)?['id'] ?? (Get.arguments as Map<String, dynamic>?)?['hashid'];

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    if (_hashid == null) return;
    try { final api = Get.find<ApiService>(); final r = await api.dio.get(ApiConfig.voteDetail(_hashid!));
      setState(() { _detail = r.data['data']; _options = List<Map<String, dynamic>>.from(r.data['data']?['options'] ?? []); });
    } catch (_) {} finally { setState(() => _loading = false); }
  }
  Future<void> _cast() async {
    if (_selectedOption == null) { Get.snackbar('提示', '请选择投票选项'); return; }
    try { final api = Get.find<ApiService>(); await api.dio.post(ApiConfig.voteCast, data: {'vote_id': _hashid, 'option_id': _selectedOption}); Get.snackbar('成功', '投票成功'); _load(); } catch (e) { Get.snackbar('错误', '投票失败: $e'); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(_detail?['title'] ?? '投票详情')),
    body: Center(child: SizedBox(width: 600, child: _loading ? const Center(child: CircularProgressIndicator()) : Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_detail?['title'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16), Text('截止时间: ${_detail?['end_time'] ?? '-'}', style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 16), RadioGroup<String>(groupValue: _selectedOption, onChanged: (v) => setState(() => _selectedOption = v), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [for (final o in _options) RadioListTile<String>(title: Text(o['name'] ?? ''), subtitle: Text('${o['vote_count'] ?? 0} 票'), value: o['id'].toString())])),
      const SizedBox(height: 16), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _cast, child: const Text('提交投票'))),
    ]))))),
  );
}
