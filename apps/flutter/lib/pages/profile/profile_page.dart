/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../config/theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _ownerName = '';
  String _phone = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ownerName = prefs.getString('owner_name') ?? '业主';
      _phone = prefs.getString('phone') ?? '';
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('logout'.tr),
        content: Text('确认退出登录？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('cancel'.tr)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('confirm'.tr)),
        ],
      ),
    );
    if (confirmed == true) {
      await Get.find<AuthService>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('profile'.tr)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SizedBox(
            width: 600,
            child: Column(
              children: [
                // 头像 + 名称区域
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                          child: Text(
                            _ownerName.isNotEmpty ? _ownerName.substring(0, 1) : '?',
                            style: TextStyle(fontSize: 32, color: AppTheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(_ownerName, style: Theme.of(context).textTheme.titleLarge),
                        if (_phone.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(_phone, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 功能列表
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text('profile_info'.tr),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Get.snackbar('提示', '个人信息编辑即将上线', backgroundColor: Colors.blue.shade50);
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock_outline),
                        title: Text('change_password'.tr),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Get.snackbar('提示', '修改密码功能即将上线', backgroundColor: Colors.blue.shade50);
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: Text('关于'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Get.snackbar('关于', '物业管理平台 v1.0.0');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 退出按钮
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: _logout,
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger),
                    child: Text('logout'.tr),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
