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
import 'pages/repair/repair_list_page.dart';
import 'pages/repair/repair_submit_page.dart';
import 'pages/repair/repair_detail_page.dart';
import 'pages/profile/profile_page.dart';

import 'pages/parking/parking_vehicles_page.dart';
import 'pages/parking/parking_spaces_page.dart';
import 'pages/parking/parking_records_page.dart';
import 'pages/visitor/visitor_list_page.dart';
import 'pages/visitor/visitor_create_page.dart';
import 'pages/activity/activity_list_page.dart';
import 'pages/activity/activity_detail_page.dart';
import 'pages/notification/notification_list_page.dart';
import 'pages/vote/vote_list_page.dart';
import 'pages/vote/vote_detail_page.dart';
import 'pages/mall/mall_products_page.dart';
import 'pages/mall/mall_product_detail_page.dart';
import 'pages/mall/mall_orders_page.dart';
import 'pages/chat/chat_page.dart';
import 'pages/face/face_register_page.dart';

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
        GetPage(name: '/repairs', page: () => const RepairListPage()),
        GetPage(name: '/repair-submit', page: () => const RepairSubmitPage()),
        GetPage(name: '/repair-detail', page: () => const RepairDetailPage()),
        GetPage(name: '/profile', page: () => const ProfilePage()),
        GetPage(name: '/parking-vehicles', page: () => const ParkingVehiclesPage()),
        GetPage(name: '/parking-spaces', page: () => const ParkingSpacesPage()),
        GetPage(name: '/parking-records', page: () => const ParkingRecordsPage()),
        GetPage(name: '/visitors', page: () => const VisitorListPage()),
        GetPage(name: '/visitor-create', page: () => const VisitorCreatePage()),
        GetPage(name: '/activities', page: () => const ActivityListPage()),
        GetPage(name: '/activity-detail', page: () => const ActivityDetailPage()),
        GetPage(name: '/notifications', page: () => const NotificationListPage()),
        GetPage(name: '/votes', page: () => const VoteListPage()),
        GetPage(name: '/vote-detail', page: () => const VoteDetailPage()),
        GetPage(name: '/mall-products', page: () => const MallProductsPage()),
        GetPage(name: '/mall-product-detail', page: () => const MallProductDetailPage()),
        GetPage(name: '/mall-orders', page: () => const MallOrdersPage()),
        GetPage(name: '/chat', page: () => const ChatPage()),
        GetPage(name: '/face-register', page: () => const FaceRegisterPage()),
      ],
    );
  }
}
