/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';

abstract class BaseCrudController extends GetxController {
  final api = ApiService();
  final isLoading = false.obs;
  final total = 0.obs;
  final page = 1.obs;
  final limit = 15.obs;
  final keyword = ''.obs;
  final statusFilter = Rx<int?>(null);
  final selectedIds = <String>{}.obs;

  String get basePath;
  bool get hasStatus => true;
  bool get hasKeyword => true;

  Future<void> loadItems({bool reset = false}) async {
    if (reset) page.value = 1;
    isLoading.value = true;
    try {
      final params = <String, dynamic>{'page': page.value, 'limit': limit.value};
      if (hasKeyword && keyword.value.isNotEmpty) params['keyword'] = keyword.value;
      if (hasStatus && statusFilter.value != null) params['status'] = statusFilter.value;

      final resp = await api.get(basePath, params: params);
      onLoadSuccess(resp['data'] as Map<String, dynamic>);
    } catch (e) {
      Get.snackbar('错误', '加载列表失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void onLoadSuccess(Map<String, dynamic> data);
  List<dynamic> get items;

  Future<void> search(String kw) async {
    keyword.value = kw;
    await loadItems(reset: true);
  }

  Future<void> filterByStatus(int? status) async {
    statusFilter.value = status;
    await loadItems(reset: true);
  }

  Future<void> nextPage() async {
    if (page.value * limit.value < total.value) {
      page.value++;
      await loadItems();
    }
  }

  Future<void> prevPage() async {
    if (page.value > 1) {
      page.value--;
      await loadItems();
    }
  }

  Future<bool> deleteItem(String id, String password) async {
    try {
      await api.delete('$basePath/$id', data: {'password': password});
      await loadItems();
      return true;
    } catch (e) {
      Get.snackbar('错误', '删除失败: $e');
      return false;
    }
  }

  Future<bool> batchDelete(String password) async {
    if (selectedIds.isEmpty) {
      Get.snackbar('提示', '请先选择项目');
      return false;
    }
    try {
      await api.post('$basePath/batch/destroy', data: {
        'ids': selectedIds.toList(),
        'password': password,
      });
      selectedIds.clear();
      await loadItems();
      Get.snackbar('成功', '批量删除完成');
      return true;
    } catch (e) {
      Get.snackbar('错误', '批量删除失败: $e');
      return false;
    }
  }

  void toggleSelect(String id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
  }

  void toggleSelectAll() {
    if (selectedIds.length == items.length) {
      selectedIds.clear();
    } else {
      selectedIds.addAll(items.map((item) => (item as Map<String, dynamic>)['id'].toString()));
    }
  }
}
