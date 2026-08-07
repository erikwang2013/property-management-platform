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
import 'app/pages/security/security_list_page.dart';
import 'app/pages/cleaning/cleaning_list_page.dart';
import 'app/pages/green/green_list_page.dart';
import 'app/pages/activity/activity_list_page.dart';
import 'app/pages/energy/energy_list_page.dart';
import 'app/pages/staff/staff_list_page.dart';
import 'app/pages/notification/notification_list_page.dart';
import 'app/pages/approval/approval_list_page.dart';
import 'app/pages/payment/payment_list_page.dart';
import 'app/pages/vote/vote_list_page.dart';
import 'app/pages/sla/sla_list_page.dart';
import 'app/pages/collection/collection_list_page.dart';
import 'app/pages/inspection/inspection_list_page.dart';
import 'app/pages/mall/mall_list_page.dart';
import 'app/pages/face/face_list_page.dart';
import 'app/pages/group/group_list_page.dart';
import 'app/pages/knowledge/knowledge_list_page.dart';

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
        GetPage(name: '/users', page: () => const AdminLayout(initialIndex: 1, child: UserListPage())),
        GetPage(name: '/roles', page: () => const AdminLayout(initialIndex: 2, child: RoleListPage())),
        GetPage(name: '/config', page: () => const AdminLayout(initialIndex: 3, child: ConfigPage())),
        GetPage(name: '/logs', page: () => const AdminLayout(initialIndex: 4, child: LogPage())),
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
        GetPage(name: '/security-patrols', page: () => const AdminLayout(child: SecurityPatrolListPage())),
        GetPage(name: '/patrol-records', page: () => const AdminLayout(child: PatrolRecordListPage())),
        GetPage(name: '/cleaning-areas', page: () => const AdminLayout(child: CleaningAreaListPage())),
        GetPage(name: '/cleaning-records', page: () => const AdminLayout(child: CleaningRecordListPage())),
        GetPage(name: '/green-areas', page: () => const AdminLayout(child: GreenAreaListPage())),
        GetPage(name: '/green-maintenance', page: () => const AdminLayout(child: GreenMaintenanceListPage())),
        GetPage(name: '/activities', page: () => const AdminLayout(child: ActivityListPage())),
        GetPage(name: '/activity-signups', page: () => const AdminLayout(child: ActivitySignupListPage())),
        GetPage(name: '/energy-meters', page: () => const AdminLayout(child: EnergyMeterListPage())),
        GetPage(name: '/energy-records', page: () => const AdminLayout(child: EnergyRecordListPage())),
        GetPage(name: '/staff', page: () => const AdminLayout(child: StaffListPage())),
        GetPage(name: '/notifications', page: () => const AdminLayout(child: NotificationListPage())),
        GetPage(name: '/approvals', page: () => const AdminLayout(child: ApprovalListPage())),
        GetPage(name: '/payments', page: () => const AdminLayout(child: PaymentListPage())),
        GetPage(name: '/votes', page: () => const AdminLayout(child: VoteListPage())),
        GetPage(name: '/sla-rules', page: () => const AdminLayout(child: SlaRuleListPage())),
        GetPage(name: '/sla-records', page: () => const AdminLayout(child: SlaRecordListPage())),
        GetPage(name: '/collection-strategies', page: () => const AdminLayout(child: CollectionStrategyListPage())),
        GetPage(name: '/collection-records', page: () => const AdminLayout(child: CollectionRecordListPage())),
        GetPage(name: '/inspections', page: () => const AdminLayout(child: InspectionListPage())),
        GetPage(name: '/mall-categories', page: () => const AdminLayout(child: MallCategoryListPage())),
        GetPage(name: '/mall-products', page: () => const AdminLayout(child: MallProductListPage())),
        GetPage(name: '/mall-orders', page: () => const AdminLayout(child: MallOrderListPage())),
        GetPage(name: '/faces', page: () => const AdminLayout(child: FaceListPage())),
        GetPage(name: '/groups', page: () => const AdminLayout(child: GroupListPage())),
        GetPage(name: '/knowledge-categories', page: () => const AdminLayout(child: KnowledgeCategoryListPage())),
        GetPage(name: '/knowledge-articles', page: () => const AdminLayout(child: KnowledgeArticleListPage())),
        GetPage(name: '/chat-records', page: () => const AdminLayout(child: ChatRecordListPage())),
      ],
      initialRoute: '/login',
    );
  }
}
