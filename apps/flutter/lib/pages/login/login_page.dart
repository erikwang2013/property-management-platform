/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart';
import '../../config/theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Get.find<AuthService>().login(
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        captchaKey: '',
        clicks: [],
      );
      Get.offAllNamed('/home');
    } catch (e) {
      Get.snackbar('登录失败', e.toString(), backgroundColor: Colors.red.shade50);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          child: SizedBox(
            width: 420,
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.apartment, size: 48, color: AppTheme.primary),
                    const SizedBox(height: 16),
                    Text('app_name'.tr, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text('业主登录', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(labelText: 'phone_hint'.tr, prefixIcon: const Icon(Icons.phone_android)),
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.isEmpty) ? '请输入手机号' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(labelText: 'password_hint'.tr, prefixIcon: const Icon(Icons.lock_outline)),
                      obscureText: true,
                      validator: (v) => (v == null || v.isEmpty) ? '请输入密码' : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text('login_btn'.tr),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(onPressed: () {}, child: Text('no_account'.tr)),
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
