// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../services/auth_service.dart';
import '../pages/user/user_list_page.dart';
import '../pages/role/role_list_page.dart';
import '../pages/config/config_page.dart';
import '../pages/log/log_page.dart';
import '../pages/dashboard/dashboard_page.dart';
import '../pages/profile/profile_page.dart';

class _MenuItem {
  final String label;
  final IconData icon;
  final String route;
  const _MenuItem(this.label, this.icon, this.route);
}

class _MenuGroup {
  final String title;
  final IconData icon;
  final List<_MenuItem> items;
  const _MenuGroup(this.title, this.icon, this.items);
}

class AdminLayout extends StatefulWidget {
  final Widget child;
  final int initialIndex;
  const AdminLayout({super.key, required this.child, this.initialIndex = 0});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  late int _selectedIndex = widget.initialIndex;
  late Widget _currentChild;
  bool _sidebarCollapsed = false;
  String? _previousBreakpoint;
  String _selectedRoute = '/dashboard';
  static const double sidebarWidth = 240;
  static const double sidebarCollapsedWidth = 64;
  static const double headerHeight = 56;

  static const _pages = <Widget>[
    DashboardPage(),
    UserListPage(),
    RoleListPage(),
    ConfigPage(),
    LogPage(),
  ];

  static const _coreRoutes = {'/dashboard': 0, '/users': 1, '/roles': 2, '/config': 3, '/logs': 4};

  static const _menuGroups = <_MenuGroup>[
    _MenuGroup('系统管理', Icons.admin_panel_settings, [
      _MenuItem('仪表盘', Icons.dashboard, '/dashboard'),
      _MenuItem('用户管理', Icons.people, '/users'),
      _MenuItem('角色权限', Icons.security, '/roles'),
      _MenuItem('系统配置', Icons.settings, '/config'),
      _MenuItem('操作日志', Icons.description, '/logs'),
      _MenuItem('个人中心', Icons.account_circle, '/profile'),
    ]),
    _MenuGroup('核心业务', Icons.apartment, [
      _MenuItem('小区管理', Icons.apartment, '/communities'),
      _MenuItem('楼栋管理', Icons.domain, '/buildings'),
      _MenuItem('单元管理', Icons.layers, '/units'),
      _MenuItem('户型管理', Icons.aspect_ratio, '/room-types'),
      _MenuItem('房产管理', Icons.home, '/rooms'),
      _MenuItem('业主管理', Icons.person, '/owners'),
      _MenuItem('租户管理', Icons.group, '/tenants'),
      _MenuItem('费用类型', Icons.category, '/fee-types'),
      _MenuItem('账单管理', Icons.receipt_long, '/fee-bills'),
      _MenuItem('缴费记录', Icons.payments, '/fee-payments'),
      _MenuItem('报修管理', Icons.build, '/repairs'),
      _MenuItem('公告管理', Icons.campaign, '/announcements'),
    ]),
    _MenuGroup('辅助业务', Icons.widgets, [
      _MenuItem('车位管理', Icons.local_parking, '/parking-spaces'),
      _MenuItem('车辆管理', Icons.directions_car, '/parking-vehicles'),
      _MenuItem('停车记录', Icons.history, '/parking-records'),
      _MenuItem('设备管理', Icons.settings_input_component, '/equipment'),
      _MenuItem('投诉管理', Icons.feedback, '/complaints'),
      _MenuItem('访客管理', Icons.how_to_reg, '/visitors'),
      _MenuItem('合同管理', Icons.assignment, '/contracts'),
      _MenuItem('财务统计', Icons.bar_chart, '/finance-statistics'),
      _MenuItem('收入记录', Icons.trending_up, '/finance-income'),
      _MenuItem('支出记录', Icons.trending_down, '/finance-expense'),
    ]),
    _MenuGroup('高级功能', Icons.star, [
      _MenuItem('安防巡逻', Icons.shield, '/security-patrols'),
      _MenuItem('巡逻记录', Icons.list_alt, '/patrol-records'),
      _MenuItem('保洁区域', Icons.cleaning_services, '/cleaning-areas'),
      _MenuItem('保洁记录', Icons.check_circle, '/cleaning-records'),
      _MenuItem('绿化区域', Icons.park, '/green-areas'),
      _MenuItem('绿化维护', Icons.grass, '/green-maintenance'),
      _MenuItem('社区活动', Icons.celebration, '/activities'),
      _MenuItem('活动报名', Icons.how_to_vote, '/activity-signups'),
      _MenuItem('能耗表计', Icons.speed, '/energy-meters'),
      _MenuItem('能耗记录', Icons.query_stats, '/energy-records'),
      _MenuItem('员工管理', Icons.badge, '/staff'),
    ]),
    _MenuGroup('扩展功能', Icons.extension, [
      _MenuItem('通知管理', Icons.notifications, '/notifications'),
      _MenuItem('审批管理', Icons.fact_check, '/approvals'),
      _MenuItem('支付管理', Icons.account_balance_wallet, '/payments'),
      _MenuItem('投票管理', Icons.ballot, '/votes'),
      _MenuItem('SLA规则', Icons.timer, '/sla-rules'),
      _MenuItem('SLA记录', Icons.history_toggle_off, '/sla-records'),
      _MenuItem('催缴策略', Icons.event_repeat, '/collection-strategies'),
      _MenuItem('催缴记录', Icons.repeat, '/collection-records'),
      _MenuItem('巡检管理', Icons.travel_explore, '/inspections'),
      _MenuItem('商城分类', Icons.storefront, '/mall-categories'),
      _MenuItem('商城商品', Icons.shopping_cart, '/mall-products'),
      _MenuItem('商城订单', Icons.receipt, '/mall-orders'),
      _MenuItem('人脸管理', Icons.face, '/faces'),
      _MenuItem('集团管理', Icons.corporate_fare, '/groups'),
      _MenuItem('知识分类', Icons.library_books, '/knowledge-categories'),
      _MenuItem('知识文章', Icons.article, '/knowledge-articles'),
      _MenuItem('对话记录', Icons.chat, '/chat-records'),
    ]),
  ];

  ResponsiveBreakpointsData get _bp => ResponsiveBreakpoints.of(context);
  bool get _isPhone => _bp.smallerThan(TABLET);
  bool get _isTablet => _bp.equals(TABLET);

  @override
  void initState() {
    super.initState();
    _currentChild = widget.child;
    _selectedRoute = Get.currentRoute.isEmpty ? '/dashboard' : Get.currentRoute;
    _checkAuth();
  }

  void _checkAuth() async {
    final loggedIn = await AuthService.isLoggedIn();
    if (!loggedIn && mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = _bp.breakpoint.name;
    if (_previousBreakpoint != null && _previousBreakpoint != current) {
      _sidebarCollapsed = _isTablet;
    }
    _previousBreakpoint = current;
  }

  void _onNavChanged(int index) {
    setState(() {
      _selectedIndex = index;
      _currentChild = _pages[index.clamp(0, _pages.length - 1)];
    });
  }

  void _navigateTo(String route) {
    setState(() => _selectedRoute = route);
    Get.toNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    if (_isPhone) return _buildPhoneLayout();
    return _buildDesktopLayout();
  }

  // ─── PHONE layout: AppBar + Drawer ────────────────────────────────

  Widget _buildPhoneLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理后台'),
        actions: [_buildUserMenu()],
      ),
      drawer: Drawer(
        child: NavigationDrawer(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onNavChanged,
          children: [
            Container(
              height: headerHeight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: const Row(
                children: [
                  Icon(Icons.admin_panel_settings, size: 24),
                  SizedBox(width: 8),
                  Text('管理后台',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Divider(),
            ..._buildNavItems(),
          ],
        ),
      ),
      body: Container(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        padding: const EdgeInsets.all(16),
        child: _currentChild,
      ),
    );
  }

  // ─── DESKTOP / TABLET layout: sidebar + header + content ───────────

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Container(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    padding: const EdgeInsets.all(16),
                    child: _currentChild,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final width = _sidebarCollapsed ? sidebarCollapsedWidth : sidebarWidth;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: _sidebarCollapsed ? _buildCollapsedSidebar() : _buildMenuList(),
      ),
    );
  }

  Widget _buildMenuList() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          height: headerHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: const Row(
            children: [
              Icon(Icons.admin_panel_settings, size: 24),
              SizedBox(width: 8),
              Text('管理后台',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const Divider(),
        for (final group in _menuGroups) ...[
          ExpansionTile(
            leading: Icon(group.icon, size: 20),
            title: Text(group.title, style: const TextStyle(fontSize: 14)),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: EdgeInsets.zero,
            initiallyExpanded: group.items.any((m) => m.route == _selectedRoute),
            children: [
              for (final item in group.items)
                ListTile(
                  dense: true,
                  leading: Icon(item.icon, size: 18),
                  title: Text(item.label, style: const TextStyle(fontSize: 13)),
                  selected: item.route == _selectedRoute,
                  selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                  onTap: () => _navigateTo(item.route),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCollapsedSidebar() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          height: headerHeight,
          alignment: Alignment.center,
          child: const Icon(Icons.admin_panel_settings, size: 28),
        ),
        const Divider(),
        for (final item in _menuGroups.expand((g) => g.items).take(5))
          ListTile(
            dense: true,
            leading: Icon(item.icon, size: 20),
            onTap: () {
              final idx = _coreRoutes[item.route];
              if (idx != null) {
                _onNavChanged(idx);
              } else {
                _navigateTo(item.route);
              }
            },
          ),
      ],
    );
  }

  List<NavigationDrawerDestination> _buildNavItems() {
    return const [
      NavigationDrawerDestination(
        icon: Icon(Icons.dashboard, size: 20),
        label: Text('仪表盘'),
        selectedIcon: Icon(Icons.dashboard, size: 20),
      ),
      NavigationDrawerDestination(
        icon: Icon(Icons.people, size: 20),
        label: Text('用户管理'),
        selectedIcon: Icon(Icons.people, size: 20),
      ),
      NavigationDrawerDestination(
        icon: Icon(Icons.security, size: 20),
        label: Text('角色权限'),
        selectedIcon: Icon(Icons.security, size: 20),
      ),
      NavigationDrawerDestination(
        icon: Icon(Icons.settings, size: 20),
        label: Text('系统配置'),
        selectedIcon: Icon(Icons.settings, size: 20),
      ),
      NavigationDrawerDestination(
        icon: Icon(Icons.description, size: 20),
        label: Text('操作日志'),
        selectedIcon: Icon(Icons.description, size: 20),
      ),
    ];
  }

  Widget _buildHeader() {
    return Container(
      height: headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_sidebarCollapsed ? Icons.menu_open : Icons.menu),
            tooltip: _sidebarCollapsed ? '展开菜单' : '收起菜单',
            onPressed: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
          ),
          const Spacer(),
          _buildUserMenu(),
        ],
      ),
    );
  }

  Widget _buildUserMenu() {
    return PopupMenuButton<String>(
      offset: const Offset(0, headerHeight),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 14, child: Icon(Icons.person, size: 16)),
          SizedBox(width: 8),
          Text('管理员', style: TextStyle(fontSize: 14)),
          Icon(Icons.arrow_drop_down, size: 20),
        ],
      ),
      onSelected: (value) {
        if (value == 'profile') {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfilePage()));
        } else if (value == 'logout') {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('确认退出'),
              content: const Text('确定要退出登录吗？'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                TextButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    Navigator.pop(ctx);
                    await AuthService.clearToken();
                    navigator.pushReplacementNamed('/login');
                  },
                  child: const Text('确定退出', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'profile', child: Text('个人中心')),
        const PopupMenuItem(value: 'logout', child: Text('退出登录')),
      ],
    );
  }
}
