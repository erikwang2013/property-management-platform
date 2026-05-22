/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('home'.tr),
        actions: [
          TextButton(onPressed: () => Get.offAllNamed('/login'), child: Text('logout'.tr)),
        ],
      ),
      body: Center(child: Text('app_name'.tr)),
    );
  }
}
