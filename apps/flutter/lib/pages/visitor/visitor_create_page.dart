/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class VisitorCreatePage extends StatefulWidget {
  const VisitorCreatePage({super.key});
  @override State<VisitorCreatePage> createState() => _VisitorCreatePageState();
}

class _VisitorCreatePageState extends State<VisitorCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _visitTime = TextEditingController();
  final _reason = TextEditingController();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final api = Get.find<ApiService>();
      await api.dio.post(ApiConfig.visitorStore, data: {
        'visitor_name': _name.text.trim(), 'visitor_phone': _phone.text.trim(),
        'visit_time': _visitTime.text.trim(), 'reason': _reason.text.trim(),
      });
      Get.back(result: true);
    } catch (e) { Get.snackbar('错误', '提交失败: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('访客预约')),
      body: Center(child: SizedBox(width: 500, child: Card(child: Padding(padding: const EdgeInsets.all(32), child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextFormField(controller: _name, decoration: const InputDecoration(labelText: '访客姓名'), validator: (v) => v?.isEmpty == true ? '必填' : null),
        const SizedBox(height: 16), TextFormField(controller: _phone, decoration: const InputDecoration(labelText: '手机号')),
        const SizedBox(height: 16), TextFormField(controller: _visitTime, decoration: const InputDecoration(labelText: '访问时间')),
        const SizedBox(height: 16), TextFormField(controller: _reason, decoration: const InputDecoration(labelText: '访问事由'), maxLines: 3),
        const SizedBox(height: 24), ElevatedButton(onPressed: _submit, child: const Text('提交预约')),
      ]))))),
    ));
  }
}
