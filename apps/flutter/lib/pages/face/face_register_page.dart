/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class FaceRegisterPage extends StatefulWidget {
  const FaceRegisterPage({super.key});
  @override State<FaceRegisterPage> createState() => _FaceRegisterPageState();
}

class _FaceRegisterPageState extends State<FaceRegisterPage> {
  bool _loading = true;
  Map<String, dynamic>? _status;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() => _loading = true);
    try { final api = Get.find<ApiService>(); final r = await api.dio.get(ApiConfig.faceStatus);
      setState(() => _status = r.data['data']); } catch (_) {} finally { setState(() => _loading = false); }
  }
  Future<void> _register() async {
    try { final api = Get.find<ApiService>(); await api.dio.post(ApiConfig.faceRegister); Get.snackbar('成功', '人脸注册请求已提交，请等待审核'); _load(); } catch (e) { Get.snackbar('错误', '注册失败: $e'); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('人脸注册')),
    body: Center(child: SizedBox(width: 500, child: _loading ? const Center(child: CircularProgressIndicator()) : Card(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.face, size: 80, color: _status?['status'] == 1 ? Colors.green : Colors.blue),
      const SizedBox(height: 16),
      Text(_status?['status'] == 1 ? '人脸已审核通过' : _status?['status'] == 2 ? '人脸审核被驳回' : _status?['status'] == 0 ? '人脸待审核' : '尚未注册人脸', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text(_status?['status'] == null ? '注册人脸后可快速通行门禁' : _status?['status'] == 2 ? '请重新提交注册' : '', style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 24),
      if (_status?['status'] == null || _status?['status'] == 2)
        SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _register, icon: const Icon(Icons.camera_alt), label: const Text('注册人脸'))),
    ]))))),
  );
}
