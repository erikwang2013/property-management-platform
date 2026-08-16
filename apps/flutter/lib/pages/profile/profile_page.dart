/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import '../../config/theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _ownerName = '';
  String _phone = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _ownerName = prefs.getString('owner_name') ?? '业主';
      _phone = prefs.getString('phone') ?? '';
      _email = prefs.getString('email') ?? '';
    });

    // GET /api/profile — 拉取最新个人信息
    try {
      final api = Get.find<ApiService>();
      final response = await api.dio.get(ApiConfig.profile);
      final data = response.data['data'];
      if (data is Map<String, dynamic>) {
        if (!mounted) return;
        setState(() {
          _ownerName = data['name']?.toString() ?? _ownerName;
          _phone = data['phone']?.toString() ?? _phone;
          _email = data['email']?.toString() ?? _email;
        });
        await prefs.setString('owner_name', _ownerName);
        await prefs.setString('phone', _phone);
        await prefs.setString('email', _email);
      }
    } catch (_) {
      // 离线时使用本地缓存
    }
  }

  /// 编辑个人信息（姓名/邮箱；手机号由后端管理，不可修改）
  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: _ownerName);
    final emailController = TextEditingController(text: _email);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('profile_info'.tr),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'name'.tr),
                validator: (v) => (v == null || v.trim().isEmpty) ? '请输入姓名' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'email'.tr),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('cancel'.tr)),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('save'.tr)),
        ],
      ),
    );
    if (saved != true) return;

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    if (name.isEmpty) {
      Get.snackbar('提示', '姓名不能为空', backgroundColor: Colors.orange.shade50);
      return;
    }

    try {
      // PUT /api/profile — 仅支持 name/email/gender/birthday
      final api = Get.find<ApiService>();
      final response = await api.dio.put(ApiConfig.profile, data: {'name': name, 'email': email});
      if (response.data['code'] == 0) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('owner_name', name);
        await prefs.setString('email', email);
        if (!mounted) return;
        setState(() {
          _ownerName = name;
          _email = email;
        });
        Get.snackbar('成功', '个人信息已更新', backgroundColor: Colors.green.shade50);
      } else {
        Get.snackbar('失败', response.data['message'] ?? '保存失败', backgroundColor: Colors.red.shade50);
      }
    } catch (e) {
      Get.snackbar('失败', e.toString(), backgroundColor: Colors.red.shade50);
    }
  }

  /// 修改密码 — PUT /api/profile/password { old_password, new_password }
  Future<void> _changePassword() async {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool submitting = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('change_password'.tr),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'old_password'.tr),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'new_password'.tr),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'confirm_password'.tr),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.of(ctx).pop(false),
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      final oldPassword = oldController.text;
                      final newPassword = newController.text;
                      final confirmPassword = confirmController.text;
                      if (oldPassword.isEmpty || newPassword.isEmpty) {
                        Get.snackbar('提示', '请填写旧密码和新密码', backgroundColor: Colors.orange.shade50);
                        return;
                      }
                      if (newPassword.length < 6) {
                        Get.snackbar('提示', '新密码至少6位', backgroundColor: Colors.orange.shade50);
                        return;
                      }
                      if (newPassword != confirmPassword) {
                        Get.snackbar('提示', '两次输入的新密码不一致', backgroundColor: Colors.orange.shade50);
                        return;
                      }
                      setDialogState(() => submitting = true);
                      try {
                        final api = Get.find<ApiService>();
                        final response = await api.dio.put(ApiConfig.profilePassword, data: {
                          'old_password': oldPassword,
                          'new_password': newPassword,
                        });
                        if (response.data['code'] == 0) {
                          Get.snackbar('成功', '密码修改成功', backgroundColor: Colors.green.shade50);
                          if (ctx.mounted) Navigator.of(ctx).pop(true);
                        } else {
                          setDialogState(() => submitting = false);
                          Get.snackbar('失败', response.data['message'] ?? '修改失败', backgroundColor: Colors.red.shade50);
                        }
                      } catch (e) {
                        setDialogState(() => submitting = false);
                        Get.snackbar('失败', e.toString(), backgroundColor: Colors.red.shade50);
                      }
                    },
              child: submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('confirm'.tr),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      // 密码已修改，强制重新登录
      await Get.find<AuthService>().logout();
    }
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
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
                        if (_email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(_email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
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
                        onTap: _editProfile,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock_outline),
                        title: Text('change_password'.tr),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _changePassword,
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
