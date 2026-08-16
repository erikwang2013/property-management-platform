-- ============================================================
-- Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
-- 迁移: RBAC 权限种子数据（增量拆分自 docs/install.sql）
-- 拆分规则: 权限树为单一逻辑单元，含全部模块（含批2/批3/扩展域）路由权限，
--   整体归入核心域种子文件，避免跨文件重复。依赖 000000 的核心表。
-- 注意: 固定主键 INSERT 非幂等，仅适用于未初始化过的数据库
-- ============================================================
-- ============================================================
-- 插入默认管理员角色
-- ============================================================
INSERT INTO `erik_admin_role` (`id`, `name`, `slug`, `description`, `status`) VALUES
(10000000000000001, '超级管理员', 'super_admin', '系统超级管理员，拥有所有权限', 1);
-- ============================================================
-- 权限种子数据
-- Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
--
-- 初始化 RBAC 权限树和角色-权限关联
-- 超级管理员 (super_admin) 自动获得所有权限
-- ============================================================

-- 菜单权限 (type=1)
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000001, 0, '仪表盘',    'dashboard',     1, 'dashboard', '/dashboard',        1, NOW(), NOW()),
(21000000000000002, 0, '用户管理',  'user',           1, 'people',    '/admin/user',        2, NOW(), NOW()),
(21000000000000003, 0, '角色管理',  'role',           1, 'shield',    '/admin/role',        3, NOW(), NOW()),
(21000000000000004, 0, '权限管理',  'permission',     1, 'lock',      '/admin/permission',  4, NOW(), NOW()),
(21000000000000005, 0, '系统配置',  'config',         1, 'settings',  '/admin/config',      5, NOW(), NOW()),
(21000000000000006, 0, '操作日志',  'log',            1, 'article',   '/admin/log',         6, NOW(), NOW());

-- 按钮权限 (type=2)
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000011, 21000000000000002, '批量删除',     'batch.destroy', 2, '', '', 1, NOW(), NOW()),
(21000000000000012, 21000000000000002, '批量启用/禁用', 'batch.status', 2, '', '', 2, NOW(), NOW()),
(21000000000000013, 21000000000000002, '导入用户',     'import.users',  2, '', '', 3, NOW(), NOW()),
(21000000000000014, 21000000000000002, '导出Excel',     'export.excel',  2, '', '', 4, NOW(), NOW()),
(21000000000000015, 21000000000000002, '导出PDF',       'export.pdf',    2, '', '', 5, NOW(), NOW()),
(21000000000000016, 21000000000000002, '文件上传',     'upload',         2, '', '', 6, NOW(), NOW());

-- API 权限 (type=3) — 仪表盘
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000021, 21000000000000001, '查看仪表盘',   'get.admin/dashboard', 3, '', '', 1, NOW(), NOW());

-- API 权限 — 用户管理
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000031, 21000000000000002, '查看用户',     'get.admin/user',             3, '', '', 1, NOW(), NOW()),
(21000000000000032, 21000000000000002, '创建用户',     'post.admin/user',            3, '', '', 2, NOW(), NOW()),
(21000000000000033, 21000000000000002, '更新用户',     'put.admin/user',             3, '', '', 3, NOW(), NOW()),
(21000000000000034, 21000000000000002, '删除用户',     'delete.admin/user',          3, '', '', 4, NOW(), NOW()),
(21000000000000035, 21000000000000002, '批量删除用户', 'post.admin/user/batch/destroy', 3, '', '', 5, NOW(), NOW()),
(21000000000000036, 21000000000000002, '批量启禁用',   'post.admin/user/batch/status',  3, '', '', 6, NOW(), NOW());

-- API 权限 — 角色管理
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000041, 21000000000000003, '查看角色', 'get.admin/role',    3, '', '', 1, NOW(), NOW()),
(21000000000000042, 21000000000000003, '创建角色', 'post.admin/role',   3, '', '', 2, NOW(), NOW()),
(21000000000000043, 21000000000000003, '更新角色', 'put.admin/role',    3, '', '', 3, NOW(), NOW()),
(21000000000000044, 21000000000000003, '删除角色', 'delete.admin/role', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 权限管理
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000051, 21000000000000004, '查看权限', 'get.admin/permission',    3, '', '', 1, NOW(), NOW()),
(21000000000000052, 21000000000000004, '创建权限', 'post.admin/permission',   3, '', '', 2, NOW(), NOW()),
(21000000000000053, 21000000000000004, '更新权限', 'put.admin/permission',    3, '', '', 3, NOW(), NOW()),
(21000000000000054, 21000000000000004, '删除权限', 'delete.admin/permission', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 系统配置
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000061, 21000000000000005, '查看配置', 'get.admin/config',    3, '', '', 1, NOW(), NOW()),
(21000000000000062, 21000000000000005, '创建配置', 'post.admin/config',   3, '', '', 2, NOW(), NOW()),
(21000000000000063, 21000000000000005, '更新配置', 'put.admin/config',    3, '', '', 3, NOW(), NOW()),
(21000000000000064, 21000000000000005, '删除配置', 'delete.admin/config', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 操作日志
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000071, 21000000000000006, '查看日志', 'get.admin/log', 3, '', '', 1, NOW(), NOW());

-- API 权限 — 个人中心
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000081, 0, '个人中心-更新信息', 'put.admin/profile',         3, '', '', 1, NOW(), NOW()),
(21000000000000082, 0, '个人中心-修改密码', 'put.admin/profile/password', 3, '', '', 2, NOW(), NOW()),
(21000000000000083, 0, '个人中心-登出',     'post.admin/profile/logout',  3, '', '', 3, NOW(), NOW());

-- API 权限 — 导出
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000091, 0, '导出Excel', 'post.admin/export/excel', 3, '', '', 1, NOW(), NOW()),
(21000000000000092, 0, '导出PDF',   'post.admin/export/pdf',   3, '', '', 2, NOW(), NOW());

-- API 权限 — 导入
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000093, 0, '导入用户', 'post.admin/import/users', 3, '', '', 1, NOW(), NOW());

-- API 权限 — 上传
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000094, 0, '文件上传', 'post.admin/upload', 3, '', '', 1, NOW(), NOW());

-- ============================================================
-- API 权限 (type=3) — 物业管理业务模块
-- ID 段: 21000000000100xx 起始，每模块一组（查看/创建/更新/删除）
-- parent_id 全部为 0（顶级，列定义 0 表示顶级），slug = 小写方法.路由路径
-- ============================================================

-- API 权限 — 小区管理
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010001, 0, '查看小区', 'get.admin/community',    3, '', '', 1, NOW(), NOW()),
(2100000000010002, 0, '创建小区', 'post.admin/community',   3, '', '', 2, NOW(), NOW()),
(2100000000010003, 0, '更新小区', 'put.admin/community',    3, '', '', 3, NOW(), NOW()),
(2100000000010004, 0, '删除小区', 'delete.admin/community', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 楼栋管理
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010005, 0, '查看楼栋', 'get.admin/building',    3, '', '', 1, NOW(), NOW()),
(2100000000010006, 0, '创建楼栋', 'post.admin/building',   3, '', '', 2, NOW(), NOW()),
(2100000000010007, 0, '更新楼栋', 'put.admin/building',    3, '', '', 3, NOW(), NOW()),
(2100000000010008, 0, '删除楼栋', 'delete.admin/building', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 单元管理
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010009, 0, '查看单元', 'get.admin/unit',    3, '', '', 1, NOW(), NOW()),
(2100000000010010, 0, '创建单元', 'post.admin/unit',   3, '', '', 2, NOW(), NOW()),
(2100000000010011, 0, '更新单元', 'put.admin/unit',    3, '', '', 3, NOW(), NOW()),
(2100000000010012, 0, '删除单元', 'delete.admin/unit', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 户型管理
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010013, 0, '查看户型', 'get.admin/room-type',    3, '', '', 1, NOW(), NOW()),
(2100000000010014, 0, '创建户型', 'post.admin/room-type',   3, '', '', 2, NOW(), NOW()),
(2100000000010015, 0, '更新户型', 'put.admin/room-type',    3, '', '', 3, NOW(), NOW()),
(2100000000010016, 0, '删除户型', 'delete.admin/room-type', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 房产管理
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010017, 0, '查看房产', 'get.admin/room',    3, '', '', 1, NOW(), NOW()),
(2100000000010018, 0, '创建房产', 'post.admin/room',   3, '', '', 2, NOW(), NOW()),
(2100000000010019, 0, '更新房产', 'put.admin/room',    3, '', '', 3, NOW(), NOW()),
(2100000000010020, 0, '删除房产', 'delete.admin/room', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 业主管理
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010021, 0, '查看业主', 'get.admin/owner',    3, '', '', 1, NOW(), NOW()),
(2100000000010022, 0, '创建业主', 'post.admin/owner',   3, '', '', 2, NOW(), NOW()),
(2100000000010023, 0, '更新业主', 'put.admin/owner',    3, '', '', 3, NOW(), NOW()),
(2100000000010024, 0, '删除业主', 'delete.admin/owner', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 租户管理
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010025, 0, '查看租户', 'get.admin/tenant',    3, '', '', 1, NOW(), NOW()),
(2100000000010026, 0, '创建租户', 'post.admin/tenant',   3, '', '', 2, NOW(), NOW()),
(2100000000010027, 0, '更新租户', 'put.admin/tenant',    3, '', '', 3, NOW(), NOW()),
(2100000000010028, 0, '删除租户', 'delete.admin/tenant', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 费用类型
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010029, 0, '查看费用类型', 'get.admin/fee-type',    3, '', '', 1, NOW(), NOW()),
(2100000000010030, 0, '创建费用类型', 'post.admin/fee-type',   3, '', '', 2, NOW(), NOW()),
(2100000000010031, 0, '更新费用类型', 'put.admin/fee-type',    3, '', '', 3, NOW(), NOW()),
(2100000000010032, 0, '删除费用类型', 'delete.admin/fee-type', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 账单管理
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010033, 0, '查看账单', 'get.admin/fee-bill',    3, '', '', 1, NOW(), NOW()),
(2100000000010034, 0, '创建账单', 'post.admin/fee-bill',   3, '', '', 2, NOW(), NOW()),
(2100000000010035, 0, '更新账单', 'put.admin/fee-bill',    3, '', '', 3, NOW(), NOW()),
(2100000000010036, 0, '删除账单', 'delete.admin/fee-bill', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 报修管理
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010037, 0, '查看报修', 'get.admin/repair',    3, '', '', 1, NOW(), NOW()),
(2100000000010038, 0, '创建报修', 'post.admin/repair',   3, '', '', 2, NOW(), NOW()),
(2100000000010039, 0, '更新报修', 'put.admin/repair',    3, '', '', 3, NOW(), NOW()),
(2100000000010040, 0, '删除报修', 'delete.admin/repair', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 公告管理
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010041, 0, '查看公告', 'get.admin/announcement',    3, '', '', 1, NOW(), NOW()),
(2100000000010042, 0, '创建公告', 'post.admin/announcement',   3, '', '', 2, NOW(), NOW()),
(2100000000010043, 0, '更新公告', 'put.admin/announcement',    3, '', '', 3, NOW(), NOW()),
(2100000000010044, 0, '删除公告', 'delete.admin/announcement', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 停车位管理
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010045, 0, '查看停车位', 'get.admin/parking-space',    3, '', '', 1, NOW(), NOW()),
(2100000000010046, 0, '创建停车位', 'post.admin/parking-space',   3, '', '', 2, NOW(), NOW()),
(2100000000010047, 0, '更新停车位', 'put.admin/parking-space',    3, '', '', 3, NOW(), NOW()),
(2100000000010048, 0, '删除停车位', 'delete.admin/parking-space', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 车辆管理
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010049, 0, '查看车辆', 'get.admin/parking-vehicle',    3, '', '', 1, NOW(), NOW()),
(2100000000010050, 0, '创建车辆', 'post.admin/parking-vehicle',   3, '', '', 2, NOW(), NOW()),
(2100000000010051, 0, '更新车辆', 'put.admin/parking-vehicle',    3, '', '', 3, NOW(), NOW()),
(2100000000010052, 0, '删除车辆', 'delete.admin/parking-vehicle', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 设备管理
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010053, 0, '查看设备', 'get.admin/equipment',    3, '', '', 1, NOW(), NOW()),
(2100000000010054, 0, '创建设备', 'post.admin/equipment',   3, '', '', 2, NOW(), NOW()),
(2100000000010055, 0, '更新设备', 'put.admin/equipment',    3, '', '', 3, NOW(), NOW()),
(2100000000010056, 0, '删除设备', 'delete.admin/equipment', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 设备维保
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010057, 0, '查看维保', 'get.admin/equipment-maintenance',    3, '', '', 1, NOW(), NOW()),
(2100000000010058, 0, '创建维保', 'post.admin/equipment-maintenance',   3, '', '', 2, NOW(), NOW()),
(2100000000010059, 0, '更新维保', 'put.admin/equipment-maintenance',    3, '', '', 3, NOW(), NOW()),
(2100000000010060, 0, '删除维保', 'delete.admin/equipment-maintenance', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 合同管理
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010061, 0, '查看合同', 'get.admin/contract',    3, '', '', 1, NOW(), NOW()),
(2100000000010062, 0, '创建合同', 'post.admin/contract',   3, '', '', 2, NOW(), NOW()),
(2100000000010063, 0, '更新合同', 'put.admin/contract',    3, '', '', 3, NOW(), NOW()),
(2100000000010064, 0, '删除合同', 'delete.admin/contract', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 安防巡逻
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010065, 0, '查看巡逻', 'get.admin/security-patrol',    3, '', '', 1, NOW(), NOW()),
(2100000000010066, 0, '创建巡逻', 'post.admin/security-patrol',   3, '', '', 2, NOW(), NOW()),
(2100000000010067, 0, '更新巡逻', 'put.admin/security-patrol',    3, '', '', 3, NOW(), NOW()),
(2100000000010068, 0, '删除巡逻', 'delete.admin/security-patrol', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 保洁区域
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010069, 0, '查看保洁区域', 'get.admin/cleaning-area',    3, '', '', 1, NOW(), NOW()),
(2100000000010070, 0, '创建保洁区域', 'post.admin/cleaning-area',   3, '', '', 2, NOW(), NOW()),
(2100000000010071, 0, '更新保洁区域', 'put.admin/cleaning-area',    3, '', '', 3, NOW(), NOW()),
(2100000000010072, 0, '删除保洁区域', 'delete.admin/cleaning-area', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 绿化区域
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010073, 0, '查看绿化区域', 'get.admin/green-area',    3, '', '', 1, NOW(), NOW()),
(2100000000010074, 0, '创建绿化区域', 'post.admin/green-area',   3, '', '', 2, NOW(), NOW()),
(2100000000010075, 0, '更新绿化区域', 'put.admin/green-area',    3, '', '', 3, NOW(), NOW()),
(2100000000010076, 0, '删除绿化区域', 'delete.admin/green-area', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 社区活动
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010077, 0, '查看活动', 'get.admin/activity',    3, '', '', 1, NOW(), NOW()),
(2100000000010078, 0, '创建活动', 'post.admin/activity',   3, '', '', 2, NOW(), NOW()),
(2100000000010079, 0, '更新活动', 'put.admin/activity',    3, '', '', 3, NOW(), NOW()),
(2100000000010080, 0, '删除活动', 'delete.admin/activity', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 能耗仪表
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010081, 0, '查看仪表', 'get.admin/energy-meter',    3, '', '', 1, NOW(), NOW()),
(2100000000010082, 0, '创建仪表', 'post.admin/energy-meter',   3, '', '', 2, NOW(), NOW()),
(2100000000010083, 0, '更新仪表', 'put.admin/energy-meter',    3, '', '', 3, NOW(), NOW()),
(2100000000010084, 0, '删除仪表', 'delete.admin/energy-meter', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 员工管理
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010085, 0, '查看员工', 'get.admin/staff',    3, '', '', 1, NOW(), NOW()),
(2100000000010086, 0, '创建员工', 'post.admin/staff',   3, '', '', 2, NOW(), NOW()),
(2100000000010087, 0, '更新员工', 'put.admin/staff',    3, '', '', 3, NOW(), NOW()),
(2100000000010088, 0, '删除员工', 'delete.admin/staff', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 巡检任务
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010089, 0, '查看巡检任务', 'get.admin/inspection-task',    3, '', '', 1, NOW(), NOW()),
(2100000000010090, 0, '创建巡检任务', 'post.admin/inspection-task',   3, '', '', 2, NOW(), NOW()),
(2100000000010091, 0, '更新巡检任务', 'put.admin/inspection-task',    3, '', '', 3, NOW(), NOW()),
(2100000000010092, 0, '删除巡检任务', 'delete.admin/inspection-task', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 商城分类
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010093, 0, '查看商城分类', 'get.admin/mall-category',    3, '', '', 1, NOW(), NOW()),
(2100000000010094, 0, '创建商城分类', 'post.admin/mall-category',   3, '', '', 2, NOW(), NOW()),
(2100000000010095, 0, '更新商城分类', 'put.admin/mall-category',    3, '', '', 3, NOW(), NOW()),
(2100000000010096, 0, '删除商城分类', 'delete.admin/mall-category', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 商城商品
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010097, 0, '查看商品', 'get.admin/mall-product',    3, '', '', 1, NOW(), NOW()),
(2100000000010098, 0, '创建商品', 'post.admin/mall-product',   3, '', '', 2, NOW(), NOW()),
(2100000000010099, 0, '更新商品', 'put.admin/mall-product',    3, '', '', 3, NOW(), NOW()),
(2100000000010100, 0, '删除商品', 'delete.admin/mall-product', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 集团管理
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010101, 0, '查看集团', 'get.admin/group',    3, '', '', 1, NOW(), NOW()),
(2100000000010102, 0, '创建集团', 'post.admin/group',   3, '', '', 2, NOW(), NOW()),
(2100000000010103, 0, '更新集团', 'put.admin/group',    3, '', '', 3, NOW(), NOW()),
(2100000000010104, 0, '删除集团', 'delete.admin/group', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 问答分类
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010105, 0, '查看问答分类', 'get.admin/knowledge-category',    3, '', '', 1, NOW(), NOW()),
(2100000000010106, 0, '创建问答分类', 'post.admin/knowledge-category',   3, '', '', 2, NOW(), NOW()),
(2100000000010107, 0, '更新问答分类', 'put.admin/knowledge-category',    3, '', '', 3, NOW(), NOW()),
(2100000000010108, 0, '删除问答分类', 'delete.admin/knowledge-category', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 智能问答
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010109, 0, '查看文章', 'get.admin/knowledge',    3, '', '', 1, NOW(), NOW()),
(2100000000010110, 0, '创建文章', 'post.admin/knowledge',   3, '', '', 2, NOW(), NOW()),
(2100000000010111, 0, '更新文章', 'put.admin/knowledge',    3, '', '', 3, NOW(), NOW()),
(2100000000010112, 0, '删除文章', 'delete.admin/knowledge', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 业务模块特殊端点
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010113, 0, '房产层级树',       'get.admin/room/tree',               3, '', '', 1, NOW(), NOW()),
(2100000000010114, 0, '业主批量导入',     'post.admin/owner/batch/import',     3, '', '', 2, NOW(), NOW()),
(2100000000010115, 0, '业主批量删除',     'post.admin/owner/batch/destroy',    3, '', '', 3, NOW(), NOW()),
(2100000000010116, 0, '账单批量生成',     'post.admin/fee-bill/batch/generate', 3, '', '', 4, NOW(), NOW()),
(2100000000010117, 0, '查看缴费记录',     'get.admin/fee-payment',             3, '', '', 5, NOW(), NOW()),
(2100000000010118, 0, '线下收款',         'post.admin/fee-payment/offline',    3, '', '', 6, NOW(), NOW()),
(2100000000010119, 0, '报修派单',         'put.admin/repair/assign',           3, '', '', 7, NOW(), NOW()),
(2100000000010120, 0, '报修进度更新',     'post.admin/repair/progress',        3, '', '', 8, NOW(), NOW()),
(2100000000010121, 0, '查看投诉',         'get.admin/complaint',               3, '', '', 9, NOW(), NOW()),
(2100000000010122, 0, '投诉处理',         'put.admin/complaint/handle',        3, '', '', 10, NOW(), NOW()),
(2100000000010123, 0, '访客审核',         'put.admin/visitor/approve',         3, '', '', 11, NOW(), NOW()),
(2100000000010124, 0, '财务统计',         'get.admin/finance/statistics',      3, '', '', 12, NOW(), NOW()),
(2100000000010125, 0, '查看巡逻记录',     'get.admin/patrol-record',           3, '', '', 13, NOW(), NOW()),
(2100000000010126, 0, '创建巡逻记录',     'post.admin/patrol-record',          3, '', '', 14, NOW(), NOW()),
(2100000000010127, 0, '查看保洁记录',     'get.admin/cleaning-record',         3, '', '', 15, NOW(), NOW()),
(2100000000010128, 0, '创建保洁记录',     'post.admin/cleaning-record',        3, '', '', 16, NOW(), NOW()),
(2100000000010129, 0, '查看绿化养护',     'get.admin/green-maintenance',       3, '', '', 17, NOW(), NOW()),
(2100000000010130, 0, '创建绿化养护',     'post.admin/green-maintenance',      3, '', '', 18, NOW(), NOW()),
(2100000000010131, 0, '查看活动报名',     'get.admin/activity-signup',         3, '', '', 19, NOW(), NOW()),
(2100000000010132, 0, '活动签到',         'put.admin/activity-signup/checkin', 3, '', '', 20, NOW(), NOW()),
(2100000000010133, 0, '查看能耗记录',     'get.admin/energy-record',           3, '', '', 21, NOW(), NOW()),
(2100000000010134, 0, '创建能耗记录',     'post.admin/energy-record',          3, '', '', 22, NOW(), NOW()),
(2100000000010135, 0, '查看SLA规则',      'get.admin/sla-rule',                3, '', '', 23, NOW(), NOW()),
(2100000000010136, 0, '创建SLA规则',      'post.admin/sla-rule',               3, '', '', 24, NOW(), NOW()),
(2100000000010137, 0, '更新SLA规则',      'put.admin/sla-rule',                3, '', '', 25, NOW(), NOW()),
(2100000000010138, 0, '删除SLA规则',      'delete.admin/sla-rule',             3, '', '', 26, NOW(), NOW()),
(2100000000010139, 0, '查看SLA记录',      'get.admin/sla-record',              3, '', '', 27, NOW(), NOW()),
(2100000000010140, 0, '查看催缴策略',     'get.admin/collection-strategy',     3, '', '', 28, NOW(), NOW()),
(2100000000010141, 0, '创建催缴策略',     'post.admin/collection-strategy',    3, '', '', 29, NOW(), NOW()),
(2100000000010142, 0, '更新催缴策略',     'put.admin/collection-strategy',     3, '', '', 30, NOW(), NOW()),
(2100000000010143, 0, '删除催缴策略',     'delete.admin/collection-strategy',  3, '', '', 31, NOW(), NOW()),
(2100000000010144, 0, '查看催缴记录',     'get.admin/collection-record',       3, '', '', 32, NOW(), NOW()),
(2100000000010145, 0, '执行催缴',         'post.admin/collection/run',         3, '', '', 33, NOW(), NOW()),
(2100000000010146, 0, '查看商城订单',     'get.admin/mall-order',              3, '', '', 34, NOW(), NOW()),
(2100000000010147, 0, '商城订单发货',     'put.admin/mall-order/ship',         3, '', '', 35, NOW(), NOW()),
(2100000000010148, 0, '商城订单退款',     'post.admin/mall-order/refund',      3, '', '', 36, NOW(), NOW()),
(2100000000010149, 0, '查看人脸库',       'get.admin/face',                    3, '', '', 37, NOW(), NOW()),
(2100000000010150, 0, '人脸审核通过',     'put.admin/face/verify',             3, '', '', 38, NOW(), NOW()),
(2100000000010151, 0, '人脸审核拒绝',     'put.admin/face/reject',             3, '', '', 39, NOW(), NOW()),
(2100000000010152, 0, '集团小区列表',     'get.admin/group/communities',       3, '', '', 40, NOW(), NOW()),
(2100000000010153, 0, '集团添加小区',     'post.admin/group/community',        3, '', '', 41, NOW(), NOW()),
(2100000000010154, 0, '集团统计',         'get.admin/group/summary',           3, '', '', 42, NOW(), NOW()),
(2100000000010155, 0, '查看聊天记录',     'get.admin/chat-record',             3, '', '', 43, NOW(), NOW()),
(2100000000010156, 0, '聊天统计',         'get.admin/chat-stats',              3, '', '', 44, NOW(), NOW()),
(2100000000010157, 0, '查看访客',         'get.admin/visitor',                 3, '', '', 45, NOW(), NOW()),
(2100000000010158, 0, '投诉回访',         'post.admin/complaint/visit',        3, '', '', 46, NOW(), NOW()),
(2100000000010159, 0, '查看停车记录',     'get.admin/parking-record',          3, '', '', 47, NOW(), NOW()),
(2100000000010160, 0, '物业仪表盘统计',   'get.admin/dashboard/property',      3, '', '', 48, NOW(), NOW());

-- API 权限 — 财务收支
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010161, 0, '查看财务收入', 'get.admin/finance-income',    3, '', '', 1, NOW(), NOW()),
(2100000000010162, 0, '创建财务收入', 'post.admin/finance-income',   3, '', '', 2, NOW(), NOW()),
(2100000000010163, 0, '更新财务收入', 'put.admin/finance-income',    3, '', '', 3, NOW(), NOW()),
(2100000000010164, 0, '删除财务收入', 'delete.admin/finance-income', 3, '', '', 4, NOW(), NOW()),
(2100000000010165, 0, '查看财务支出', 'get.admin/finance-expense',    3, '', '', 5, NOW(), NOW()),
(2100000000010166, 0, '创建财务支出', 'post.admin/finance-expense',   3, '', '', 6, NOW(), NOW()),
(2100000000010167, 0, '更新财务支出', 'put.admin/finance-expense',    3, '', '', 7, NOW(), NOW()),
(2100000000010168, 0, '删除财务支出', 'delete.admin/finance-expense', 3, '', '', 8, NOW(), NOW());

-- API 权限 — 员工批量状态
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010169, 0, '员工批量启禁用', 'post.admin/staff/batch/status', 3, '', '', 1, NOW(), NOW());

-- API 权限 — 巡检扩展端点
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010170, 0, '查看巡检点',       'get.admin/inspection-task/checkpoints',     3, '', '', 1, NOW(), NOW()),
(2100000000010171, 0, '开始巡检任务',     'put.admin/inspection-task/start',           3, '', '', 2, NOW(), NOW()),
(2100000000010172, 0, '完成巡检任务',     'put.admin/inspection-task/complete',        3, '', '', 3, NOW(), NOW()),
(2100000000010173, 0, '巡检点打卡',       'put.admin/inspection-checkpoint/checkin',   3, '', '', 4, NOW(), NOW());

-- API 权限 — 集团移除小区
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010174, 0, '集团移除小区', 'delete.admin/group/community', 3, '', '', 1, NOW(), NOW());

-- API 权限 — 审批管理
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010175, 0, '查看审批类型', 'get.admin/approval-type',     3, '', '', 1, NOW(), NOW()),
(2100000000010176, 0, '创建审批类型', 'post.admin/approval-type',    3, '', '', 2, NOW(), NOW()),
(2100000000010177, 0, '更新审批类型', 'put.admin/approval-type',     3, '', '', 3, NOW(), NOW()),
(2100000000010178, 0, '删除审批类型', 'delete.admin/approval-type',  3, '', '', 4, NOW(), NOW()),
(2100000000010179, 0, '查看审批',     'get.admin/approval',          3, '', '', 5, NOW(), NOW()),
(2100000000010180, 0, '提交审批',     'post.admin/approval',         3, '', '', 6, NOW(), NOW()),
(2100000000010181, 0, '审批处理',     'put.admin/approval/approve',  3, '', '', 7, NOW(), NOW()),
(2100000000010182, 0, '我的待办审批', 'get.admin/approval/my-pending', 3, '', '', 8, NOW(), NOW());

-- API 权限 — 通知管理
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010183, 0, '查看通知模板', 'get.admin/notification-template',   3, '', '', 1, NOW(), NOW()),
(2100000000010184, 0, '创建通知模板', 'post.admin/notification-template',  3, '', '', 2, NOW(), NOW()),
(2100000000010185, 0, '更新通知模板', 'put.admin/notification-template',   3, '', '', 3, NOW(), NOW()),
(2100000000010186, 0, '删除通知模板', 'delete.admin/notification-template', 3, '', '', 4, NOW(), NOW()),
(2100000000010187, 0, '查看通知',     'get.admin/notification',            3, '', '', 5, NOW(), NOW()),
(2100000000010188, 0, '发送通知',     'post.admin/notification/send',      3, '', '', 6, NOW(), NOW());

-- API 权限 — 投票管理
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010189, 0, '查看投票',     'get.admin/vote',           3, '', '', 1, NOW(), NOW()),
(2100000000010190, 0, '创建投票',     'post.admin/vote',          3, '', '', 2, NOW(), NOW()),
(2100000000010191, 0, '更新投票',     'put.admin/vote',           3, '', '', 3, NOW(), NOW()),
(2100000000010192, 0, '删除投票',     'delete.admin/vote',        3, '', '', 4, NOW(), NOW()),
(2100000000010193, 0, '查看投票选项', 'get.admin/vote/options',   3, '', '', 5, NOW(), NOW()),
(2100000000010194, 0, '创建投票选项', 'post.admin/vote/option',   3, '', '', 6, NOW(), NOW()),
(2100000000010195, 0, '更新投票选项', 'put.admin/vote/option',    3, '', '', 7, NOW(), NOW()),
(2100000000010196, 0, '删除投票选项', 'delete.admin/vote/option', 3, '', '', 8, NOW(), NOW()),
(2100000000010197, 0, '投票记录',     'get.admin/vote/records',   3, '', '', 9, NOW(), NOW()),
(2100000000010198, 0, '投票统计',     'get.admin/vote/statistics', 3, '', '', 10, NOW(), NOW()),
(2100000000010199, 0, '发布投票',     'put.admin/vote/publish',   3, '', '', 11, NOW(), NOW()),
(2100000000010200, 0, '结束投票',     'put.admin/vote/end',       3, '', '', 12, NOW(), NOW());

-- API 权限 — 支付管理
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010201, 0, '查看支付订单',       'get.admin/payment-order',           3, '', '', 1, NOW(), NOW()),
(2100000000010202, 0, '支付订单退款',       'post.admin/payment-order/refund',   3, '', '', 2, NOW(), NOW()),
(2100000000010203, 0, '支付统计',           'get.admin/payment-order/statistics', 3, '', '', 3, NOW(), NOW());

-- ============================================================
-- 超级管理员角色 (ID=10000000000000001) 关联所有权限
-- ============================================================
INSERT INTO `erik_admin_role_permission` (`role_id`, `permission_id`)
SELECT 10000000000000001, `id` FROM `erik_admin_permission`
WHERE `id` NOT IN (
    SELECT `permission_id` FROM `erik_admin_role_permission` WHERE `role_id` = 10000000000000001
);
