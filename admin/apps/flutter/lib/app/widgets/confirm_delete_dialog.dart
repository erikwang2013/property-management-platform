/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';

class ConfirmDeleteDialog {
  ConfirmDeleteDialog._();

  static Future<String?> show(
    BuildContext context, {
    required String itemName,
    int? count,
  }) {
    final pwdCtrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(count != null && count > 1 ? '确认批量删除' : '确认删除'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(count != null && count > 1
                ? '确定要删除选中的 $count 个$itemName吗？'
                : '确定要删除「$itemName」吗？'),
            const SizedBox(height: 8),
            TextField(
              controller: pwdCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '请输入您的密码确认',
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              if (pwdCtrl.text.isNotEmpty) Navigator.pop(context, pwdCtrl.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
