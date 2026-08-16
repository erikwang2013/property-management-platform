/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class ActivityDetailPage extends StatefulWidget {
  const ActivityDetailPage({super.key});
  @override State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  Map<String, dynamic>? _detail;
  bool _loading = true;
  String? get _hashid => (Get.arguments as Map<String, dynamic>?)?['id'] ?? (Get.arguments as Map<String, dynamic>?)?['hashid'];

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    if (_hashid == null) return;
    try { final api = Get.find<ApiService>(); final r = await api.dio.get(ApiConfig.activityDetail(_hashid!));
      setState(() => _detail = r.data['data']); } catch (_) {} finally { setState(() => _loading = false); }
  }
  Future<void> _signup() async {
    try { final api = Get.find<ApiService>(); await api.dio.post(ApiConfig.activitySignup, data: {'activity_id': _hashid}); Get.snackbar('成功', '报名成功'); _load(); } catch (e) { Get.snackbar('错误', '报名失败: $e'); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(_detail?['title'] ?? '活动详情')),
    body: Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 600), child: _loading ? const Center(child: CircularProgressIndicator()) : Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_detail?['title'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16), _row('地点', _detail?['location']), _row('时间', '${_detail?['start_time']} - ${_detail?['end_time']}'),
      _row('报名', '${_detail?['signup_count'] ?? 0}/${_detail?['max_signup'] ?? '-'}'),
      const SizedBox(height: 16), Text(_detail?['description'] ?? '', style: const TextStyle(fontSize: 14)),
      const SizedBox(height: 24), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _signup, child: const Text('立即报名'))),
    ]))))),
  );
  Widget _row(String label, String? value) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [SizedBox(width: 80, child: Text('$label:', style: const TextStyle(color: Colors.grey))), Text(value ?? '-')]));
}
