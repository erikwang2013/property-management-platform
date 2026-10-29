/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'config/theme.dart';
import 'i18n/messages.dart';
import 'pages/login/login_page.dart';
import 'pages/home/home_page.dart';
import 'pages/fee/fee_bills_page.dart';
import 'pages/fee/fee_bill_detail_page.dart';
import 'pages/profile/profile_page.dart';

import 'pages/parking/parking_vehicles_page.dart';
import 'pages/parking/parking_spaces_page.dart';
import 'pages/parking/parking_records_page.dart';

class PortalApp extends StatelessWidget {
  const PortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Property Management',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(),
      locale: const Locale('zh', 'CN'),
      fallbackLocale: const Locale('en', 'US'),
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/home', page: () => const HomePage()),
        GetPage(name: '/fee-bills', page: () => const FeeBillsPage()),
        GetPage(name: '/fee-bill-detail', page: () => const FeeBillDetailPage()),
        GetPage(name: '/profile', page: () => const ProfilePage()),
        GetPage(name: '/parking-vehicles', page: () => const ParkingVehiclesPage()),
        GetPage(name: '/parking-spaces', page: () => const ParkingSpacesPage()),
        GetPage(name: '/parking-records', page: () => const ParkingRecordsPage()),
      ],
    );
  }
}
