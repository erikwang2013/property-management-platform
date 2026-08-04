/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'community_controller.dart';

class CommunityFormPage extends StatefulWidget {
  final Map<String, dynamic>? communityData;
  const CommunityFormPage({super.key, this.communityData});

  @override
  State<CommunityFormPage> createState() => _CommunityFormPageState();
}

class _CommunityFormPageState extends State<CommunityFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  late int _status;

  bool get isEdit => widget.communityData != null;

  @override
  void initState() {
    super.initState();
    final d = widget.communityData;
    _nameCtrl = TextEditingController(text: d?['name'] ?? '');
    _addressCtrl = TextEditingController(text: d?['address'] ?? '');
    _phoneCtrl = TextEditingController(text: d?['phone'] ?? '');
    _status = d?['status'] as int? ?? 1;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final ctrl = Get.find<CommunityController>();
    final data = {
      'name': _nameCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'status': _status,
    };

    try {
      if (isEdit) {
        await ctrl.updateItem(widget.communityData!['id'], data);
      } else {
        await ctrl.create(data);
      }
      if (mounted) Get.back(result: true);
    } catch (e) {
      if (mounted) Get.snackbar('错误', isEdit ? '更新失败: $e' : '创建失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? '编辑小区' : '新增小区')),
      body: Center(
        child: SizedBox(
          width: 500,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: '小区名称', isDense: true),
                      validator: (v) => (v == null || v.trim().isEmpty) ? '请输入小区名称' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(labelText: '地址', isDense: true),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(labelText: '物业电话', isDense: true),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _status,
                      decoration: const InputDecoration(labelText: '状态', isDense: true),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('启用')),
                        DropdownMenuItem(value: 0, child: Text('禁用')),
                      ],
                      onChanged: (v) => setState(() => _status = v ?? 1),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Get.back(), child: const Text('取消')),
                        const SizedBox(width: 8),
                        ElevatedButton(onPressed: _submit, child: Text(isEdit ? '保存' : '创建')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
