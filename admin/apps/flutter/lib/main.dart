// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'app/theme/app_theme.dart';
import 'app/layouts/admin_layout.dart';
import 'app/pages/login/login_page.dart';
import 'app/pages/dashboard/dashboard_page.dart';
import 'app/pages/user/user_list_page.dart';
import 'app/pages/role/role_list_page.dart';
import 'app/pages/config/config_page.dart';
import 'app/pages/log/log_page.dart';
import 'app/pages/profile/profile_page.dart';
import 'app/pages/community/community_list_page.dart';
import 'app/pages/building/building_list_page.dart';
import 'app/pages/unit/unit_list_page.dart';
import 'app/pages/room_type/room_type_list_page.dart';
import 'app/pages/room/room_list_page.dart';
import 'app/pages/owner/owner_list_page.dart';
import 'app/pages/tenant/tenant_list_page.dart';
import 'app/pages/fee_type/fee_type_list_page.dart';
import 'app/pages/fee_bill/fee_bill_list_page.dart';
import 'app/pages/fee_payment/fee_payment_list_page.dart';
import 'app/pages/repair/repair_list_page.dart';
import 'app/pages/announcement/announcement_list_page.dart';
import 'app/pages/parking/parking_space_list_page.dart';
import 'app/pages/parking/parking_vehicle_list_page.dart';
import 'app/pages/parking/parking_record_list_page.dart';
import 'app/pages/equipment/equipment_list_page.dart';
import 'app/pages/complaint/complaint_list_page.dart';
import 'app/pages/visitor/visitor_list_page.dart';
import 'app/pages/contract/contract_list_page.dart';
import 'app/pages/finance/finance_list_page.dart';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '开放管理后台',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 767, name: PHONE),
          const Breakpoint(start: 768, end: 1199, name: TABLET),
          const Breakpoint(start: 1200, end: 4500, name: DESKTOP),
        ],
      ),
      getPages: [
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/dashboard', page: () => const AdminLayout(child: DashboardPage())),
        GetPage(name: '/users', page: () => const AdminLayout(child: UserListPage(), initialIndex: 1)),
        GetPage(name: '/roles', page: () => const AdminLayout(child: RoleListPage(), initialIndex: 2)),
        GetPage(name: '/config', page: () => const AdminLayout(child: ConfigPage(), initialIndex: 3)),
        GetPage(name: '/logs', page: () => const AdminLayout(child: LogPage(), initialIndex: 4)),
        GetPage(name: '/profile', page: () => const ProfilePage()),
        GetPage(name: '/communities', page: () => const AdminLayout(child: CommunityListPage())),
        GetPage(name: '/buildings', page: () => const AdminLayout(child: BuildingListPage())),
        GetPage(name: '/units', page: () => const AdminLayout(child: UnitListPage())),
        GetPage(name: '/room-types', page: () => const AdminLayout(child: RoomTypeListPage())),
        GetPage(name: '/rooms', page: () => const AdminLayout(child: RoomListPage())),
        GetPage(name: '/owners', page: () => const AdminLayout(child: OwnerListPage())),
        GetPage(name: '/tenants', page: () => const AdminLayout(child: TenantListPage())),
        GetPage(name: '/fee-types', page: () => const AdminLayout(child: FeeTypeListPage())),
        GetPage(name: '/fee-bills', page: () => const AdminLayout(child: FeeBillListPage())),
        GetPage(name: '/fee-payments', page: () => const AdminLayout(child: FeePaymentListPage())),
        GetPage(name: '/repairs', page: () => const AdminLayout(child: RepairListPage())),
        GetPage(name: '/announcements', page: () => const AdminLayout(child: AnnouncementListPage())),
        GetPage(name: '/parking-spaces', page: () => const AdminLayout(child: ParkingSpaceListPage())),
        GetPage(name: '/parking-vehicles', page: () => const AdminLayout(child: ParkingVehicleListPage())),
        GetPage(name: '/parking-records', page: () => const AdminLayout(child: ParkingRecordListPage())),
        GetPage(name: '/equipment', page: () => const AdminLayout(child: EquipmentListPage())),
        GetPage(name: '/complaints', page: () => const AdminLayout(child: ComplaintListPage())),
        GetPage(name: '/visitors', page: () => const AdminLayout(child: VisitorListPage())),
        GetPage(name: '/contracts', page: () => const AdminLayout(child: ContractListPage())),
        GetPage(name: '/finance-statistics', page: () => const AdminLayout(child: FinanceStatisticsPage())),
        GetPage(name: '/finance-income', page: () => const AdminLayout(child: FinanceIncomeListPage())),
        GetPage(name: '/finance-expense', page: () => const AdminLayout(child: FinanceExpenseListPage())),
      ],
      initialRoute: '/login',
    );
  }
}
