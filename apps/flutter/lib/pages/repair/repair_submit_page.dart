/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../config/theme.dart';

class RepairSubmitPage extends StatefulWidget {
  const RepairSubmitPage({super.key});
  @override
  State<RepairSubmitPage> createState() => _RepairSubmitPageState();
}

class _RepairSubmitPageState extends State<RepairSubmitPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String? _selectedRoom;
  String? _selectedCategory;
  String _urgency = 'normal';
  final List<String> _imageUrls = [];
  DateTime? _scheduledDate;
  bool _loading = false;
  bool _loadingRooms = true;

  List<Map<String, dynamic>> _rooms = [];
  final List<String> _categories = ['水电维修', '门窗维修', '管道疏通', '墙面修补', '家电维修', '电梯故障', '其他'];

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      final api = Get.find<ApiService>();
      final response = await api.dio.get(ApiConfig.rooms);
      setState(() {
        _rooms = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      });
    } catch (_) {
      // Use empty list
    } finally {
      setState(() => _loadingRooms = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoom == null) {
      Get.snackbar('提示', '请选择房产', backgroundColor: Colors.orange.shade50);
      return;
    }
    if (_selectedCategory == null) {
      Get.snackbar('提示', '请选择报修分类', backgroundColor: Colors.orange.shade50);
      return;
    }

    setState(() => _loading = true);
    try {
      final api = Get.find<ApiService>();
      await api.dio.post(ApiConfig.repairStore, data: {
        'room_id': _selectedRoom,
        'category': _selectedCategory,
        'urgency': _urgency,
        'description': _descriptionController.text.trim(),
        'images': _imageUrls,
        'scheduled_date': _scheduledDate?.toIso8601String(),
      });
      Get.snackbar('成功', 'operation_success'.tr, backgroundColor: Colors.green.shade50);
      Get.back(result: true);
    } catch (e) {
      Get.snackbar('提交失败', e.toString(), backgroundColor: Colors.red.shade50);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickScheduledDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? now.add(const Duration(days: 1)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) {
      if (!mounted) return;
      // Also pick time
      final timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (timePicked != null) {
        setState(() {
          _scheduledDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        });
      } else {
        setState(() => _scheduledDate = picked);
      }
    }
  }

  Future<void> _pickImages() async {
    // Placeholder — image_picker import would need the package
    Get.snackbar('提示', '图片上传功能即将上线', backgroundColor: Colors.blue.shade50);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('repair_submit'.tr)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('repair_submit'.tr, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text('请填写以下信息提交报修申请', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                      const SizedBox(height: 24),

                      // 选择房产
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRoom,
                        decoration: const InputDecoration(labelText: '选择房产', prefixIcon: Icon(Icons.home)),
                        items: _loadingRooms
                            ? null
                            : _rooms.map((r) => DropdownMenuItem<String>(
                                  value: r['hashid']?.toString() ?? r['id']?.toString(),
                                  child: Text(r['room_number'] ?? ''),
                                )).toList(),
                        onChanged: (v) => setState(() => _selectedRoom = v),
                        hint: Text(_loadingRooms ? 'loading...' : '请选择'),
                      ),
                      const SizedBox(height: 16),

                      // 分类
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: InputDecoration(labelText: 'repair_category'.tr, prefixIcon: const Icon(Icons.category)),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() => _selectedCategory = v),
                      ),
                      const SizedBox(height: 16),

                      // 紧急程度
                      Text('repair_urgency'.tr, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildUrgencyRadio('urgency_normal'.tr, 'normal', AppTheme.success),
                          const SizedBox(width: 16),
                          _buildUrgencyRadio('urgency_urgent'.tr, 'urgent', AppTheme.warning),
                          const SizedBox(width: 16),
                          _buildUrgencyRadio('urgency_critical'.tr, 'critical', AppTheme.danger),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 描述
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'repair_description'.tr,
                          hintText: '请详细描述问题...',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        validator: (v) => (v == null || v.trim().isEmpty) ? '请输入问题描述' : null,
                      ),
                      const SizedBox(height: 16),

                      // 图片上传
                      InkWell(
                        onTap: _pickImages,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade50,
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text('${'repair_images'.tr}（点击上传）', style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 预约时间
                      InkWell(
                        onTap: _pickScheduledDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'repair_schedule'.tr,
                            prefixIcon: const Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _scheduledDate != null
                                ? DateFormat('yyyy-MM-dd HH:mm').format(_scheduledDate!)
                                : '请选择预约时间',
                            style: TextStyle(
                              color: _scheduledDate != null ? null : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 提交按钮
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text('submit'.tr),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUrgencyRadio(String label, String value, Color color) {
    final selected = _urgency == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _urgency = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: selected ? color : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: selected ? color.withValues(alpha: 0.05) : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.grey.shade600,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
