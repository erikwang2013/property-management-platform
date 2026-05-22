/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('login'.tr)),
      body: Center(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('app_name'.tr, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 32),
              TextField(decoration: InputDecoration(labelText: 'phone_hint'.tr, prefixIcon: const Icon(Icons.phone))),
              const SizedBox(height: 16),
              TextField(decoration: InputDecoration(labelText: 'password_hint'.tr, prefixIcon: const Icon(Icons.lock)), obscureText: true),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Get.offAllNamed('/home'), child: Text('login_btn'.tr))),
              const SizedBox(height: 12),
              TextButton(onPressed: () {}, child: Text('no_account'.tr)),
            ],
          ),
        ),
      ),
    );
  }
}
