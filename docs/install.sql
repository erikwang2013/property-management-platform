-- ============================================================
-- Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
-- 迁移: 初始化管理后台核心数据表
-- 注意: 主键 id 使用 BIGINT 非自增，由 snowflake-php 在应用层生成
-- 注意: 本文件为全量安装入口（66 张表 + RBAC 种子数据），唯一建库入口；
--       采用 CREATE TABLE IF NOT EXISTS 确保可重复执行
-- ============================================================

-- ============================================================
-- 管理用户表
-- ============================================================
CREATE TABLE IF NOT EXISTS `erik_admin_user` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID，由snowflake生成',
    `username` VARCHAR(50) NOT NULL COMMENT '用户名',
    `password` VARCHAR(255) NOT NULL COMMENT '密码（bcrypt哈希）',
    `real_name` VARCHAR(50) NOT NULL DEFAULT '' COMMENT '真实姓名',
    `avatar` VARCHAR(255) NOT NULL DEFAULT '' COMMENT '头像URL',
    `email` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '邮箱（加密存储）',
    `phone` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '手机号（加密存储）',
    `id_card` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '身份证号（加密存储）',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '状态: 0=禁用 1=启用',
    `tenant_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '所属租户ID, 0=平台超级管理员',
    `last_login_at` DATETIME DEFAULT NULL COMMENT '最后登录时间',
    `last_login_ip` VARCHAR(50) NOT NULL DEFAULT '' COMMENT '最后登录IP',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at` DATETIME DEFAULT NULL COMMENT '软删除标记',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_username` (`username`),
    KEY `idx_status` (`status`),
    KEY `idx_tenant_id` (`tenant_id`),
    KEY `idx_deleted_at` (`deleted_at`),
    KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='管理用户表';

-- ============================================================
-- SaaS 租户表（与租客表 erik_tenant 语义区分）
-- ============================================================
CREATE TABLE IF NOT EXISTS `erik_platform_tenant` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID（默认租户固定 1）',
    `name` VARCHAR(100) NOT NULL COMMENT '租户名称',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '状态: 0=停用 1=正常',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='SaaS租户表';

-- ============================================================
-- 角色表
-- ============================================================
CREATE TABLE IF NOT EXISTS `erik_admin_role` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID，由snowflake生成',
    `name` VARCHAR(50) NOT NULL COMMENT '角色名称',
    `slug` VARCHAR(50) NOT NULL COMMENT '角色标识，用于权限判断',
    `description` VARCHAR(255) NOT NULL DEFAULT '' COMMENT '角色描述',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '状态: 0=禁用 1=启用',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='角色表';

-- ============================================================
-- 权限表（菜单/按钮/接口）
-- ============================================================
CREATE TABLE IF NOT EXISTS `erik_admin_permission` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID，由snowflake生成',
    `parent_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '父级权限ID，0表示顶级',
    `name` VARCHAR(50) NOT NULL COMMENT '权限名称',
    `slug` VARCHAR(100) NOT NULL COMMENT '权限标识，格式: 模块.操作（如 user.create）',
    `type` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '类型: 1=菜单 2=按钮 3=API接口',
    `icon` VARCHAR(50) NOT NULL DEFAULT '' COMMENT '菜单图标（仅type=1时使用）',
    `path` VARCHAR(255) NOT NULL DEFAULT '' COMMENT '前端路由路径（仅type=1时使用）',
    `sort` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '排序值，越小越靠前',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_parent_id` (`parent_id`),
    KEY `idx_sort` (`sort`),
    KEY `idx_type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='权限表';

-- ============================================================
-- 用户角色关联表（多对多中间表）
-- ============================================================
CREATE TABLE IF NOT EXISTS `erik_admin_user_role` (
    `user_id` BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
    `role_id` BIGINT UNSIGNED NOT NULL COMMENT '角色ID',
    PRIMARY KEY (`user_id`, `role_id`),
    KEY `idx_role_id` (`role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户角色关联表';

-- ============================================================
-- 角色权限关联表（多对多中间表）
-- ============================================================
CREATE TABLE IF NOT EXISTS `erik_admin_role_permission` (
    `role_id` BIGINT UNSIGNED NOT NULL COMMENT '角色ID',
    `permission_id` BIGINT UNSIGNED NOT NULL COMMENT '权限ID',
    PRIMARY KEY (`role_id`, `permission_id`),
    KEY `idx_permission_id` (`permission_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='角色权限关联表';

-- ============================================================
-- 系统配置表
-- ============================================================
CREATE TABLE IF NOT EXISTS `erik_system_config` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID，由snowflake生成',
    `group` VARCHAR(50) NOT NULL DEFAULT 'default' COMMENT '配置分组标识',
    `key` VARCHAR(100) NOT NULL COMMENT '配置键名',
    `value` TEXT COMMENT '配置值',
    `type` VARCHAR(20) NOT NULL DEFAULT 'string' COMMENT '值类型: string|int|bool|json|array',
    `description` VARCHAR(255) NOT NULL DEFAULT '' COMMENT '配置项说明',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_group_key` (`group`, `key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统配置表';

-- ============================================================
-- 操作日志表
-- ============================================================
CREATE TABLE IF NOT EXISTS `erik_operation_log` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID，由snowflake生成',
    `user_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '操作用户ID',
    `action` VARCHAR(100) NOT NULL COMMENT '操作动作，如 admin.user.store',
    `method` VARCHAR(10) NOT NULL DEFAULT '' COMMENT '请求方法: GET|POST|PUT|DELETE',
    `path` VARCHAR(255) NOT NULL DEFAULT '' COMMENT '请求路径',
    `ip` VARCHAR(50) NOT NULL DEFAULT '' COMMENT '操作IP',
    `input` TEXT COMMENT '请求参数（敏感字段已脱敏）',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间',
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_action` (`action`),
    KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='操作日志表';

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
-- ============================================================
-- 操作日志表增加操作来源端字段
-- Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
-- ============================================================

ALTER TABLE `erik_operation_log`
ADD COLUMN `source` VARCHAR(20) NOT NULL DEFAULT 'web' COMMENT '操作来源端: ipados|macos|windows|linux|ios|android|harmonyos|web' AFTER `ip`;

ALTER TABLE `erik_operation_log`
ADD KEY `idx_source` (`source`);
-- ============================================================
-- Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
-- 迁移: 物业管理系统 — 第1批核心业务表（14张）
-- 主键 id 使用 BIGINT UNSIGNED NOT NULL，由 snowflake-php 应用层生成
-- ============================================================

-- 1. 小区/社区表
CREATE TABLE IF NOT EXISTS `erik_community` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID，snowflake生成',
    `name` VARCHAR(100) NOT NULL COMMENT '小区名称',
    `address` VARCHAR(255) NOT NULL DEFAULT '' COMMENT '详细地址',
    `province` VARCHAR(50) NOT NULL DEFAULT '' COMMENT '省',
    `city` VARCHAR(50) NOT NULL DEFAULT '' COMMENT '市',
    `district` VARCHAR(50) NOT NULL DEFAULT '' COMMENT '区',
    `area_total` DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '总建筑面积(m²)',
    `building_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '楼栋总数',
    `room_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '房屋总套数',
    `developer` VARCHAR(100) NOT NULL DEFAULT '' COMMENT '开发商',
    `property_company` VARCHAR(100) NOT NULL DEFAULT '' COMMENT '物业公司',
    `contact_phone` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '联系电话（加密存储）',
    `description` TEXT COMMENT '小区简介',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '状态: 0=停用 1=正常',
    `tenant_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '所属租户ID, 0=平台',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at` DATETIME DEFAULT NULL COMMENT '软删除',
    PRIMARY KEY (`id`),
    KEY `idx_status` (`status`),
    KEY `idx_tenant_community` (`tenant_id`, `id`),
    KEY `idx_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='小区表';

-- ============================================================
-- 多租户：默认租户初始化 + 存量回填（存量数据归入默认租户）
-- ============================================================
INSERT IGNORE INTO `erik_platform_tenant` (`id`, `name`, `status`, `created_at`, `updated_at`)
VALUES (1, '默认租户', 1, NOW(), NOW());
UPDATE `erik_community` SET `tenant_id` = 1 WHERE `tenant_id` = 0;
UPDATE `erik_admin_user` SET `tenant_id` = 1 WHERE `tenant_id` = 0;

-- 2. 楼栋表
CREATE TABLE IF NOT EXISTS `erik_building` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `community_id` BIGINT UNSIGNED NOT NULL COMMENT '所属小区ID',
    `name` VARCHAR(50) NOT NULL COMMENT '楼栋名称',
    `building_type` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '类型: 1=塔楼 2=板楼 3=别墅 4=商业',
    `floor_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '总层数',
    `unit_count` INT UNSIGNED NOT NULL DEFAULT 1 COMMENT '单元数',
    `elevator_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '电梯数',
    `build_year` YEAR DEFAULT NULL COMMENT '建成年份',
    `structure_type` VARCHAR(30) NOT NULL DEFAULT '' COMMENT '结构类型: 砖混/框架/剪力墙',
    `sort` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '排序',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_community_id` (`community_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='楼栋表';

-- 3. 单元表
CREATE TABLE IF NOT EXISTS `erik_unit` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `building_id` BIGINT UNSIGNED NOT NULL COMMENT '所属楼栋ID',
    `name` VARCHAR(30) NOT NULL COMMENT '单元名称',
    `room_count_per_floor` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '每层户数',
    `sort` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '排序',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_building_id` (`building_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='单元表';

-- 4. 户型表
CREATE TABLE IF NOT EXISTS `erik_room_type` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `name` VARCHAR(50) NOT NULL COMMENT '户型名称',
    `bedrooms` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '室',
    `halls` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '厅',
    `bathrooms` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '卫',
    `image` VARCHAR(255) NOT NULL DEFAULT '' COMMENT '户型图URL',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='户型表';

-- 5. 房产/房屋表
CREATE TABLE IF NOT EXISTS `erik_room` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `community_id` BIGINT UNSIGNED NOT NULL COMMENT '所属小区ID',
    `building_id` BIGINT UNSIGNED NOT NULL COMMENT '所属楼栋ID',
    `unit_id` BIGINT UNSIGNED NOT NULL COMMENT '所属单元ID',
    `room_number` VARCHAR(20) NOT NULL COMMENT '房号',
    `floor` INT NOT NULL DEFAULT 1 COMMENT '所在楼层',
    `room_type_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '户型ID',
    `area_indoor` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '套内面积(m²)',
    `area_shared` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '公摊面积(m²)',
    `area_total` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '总面积(m²)',
    `orientation` VARCHAR(20) NOT NULL DEFAULT '' COMMENT '朝向: 南/北/东/西/南北/东西',
    `decoration` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '装修: 1=毛坯 2=简装 3=精装 4=豪装',
    `usage_type` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '用途: 1=住宅 2=商业 3=办公 4=仓储',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '状态: 0=空置 1=已售 2=出租 3=自住',
    `remark` VARCHAR(255) NOT NULL DEFAULT '' COMMENT '备注',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at` DATETIME DEFAULT NULL COMMENT '软删除',
    PRIMARY KEY (`id`),
    KEY `idx_community_id` (`community_id`),
    KEY `idx_building_id` (`building_id`),
    KEY `idx_unit_id` (`unit_id`),
    KEY `idx_room_number` (`room_number`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='房产表';

-- 6. 业主表
CREATE TABLE IF NOT EXISTS `erik_owner` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `name` VARCHAR(50) NOT NULL COMMENT '姓名',
    `phone` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '手机号（加密存储）',
    `email` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '邮箱（加密存储）',
    `id_card` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '身份证号（加密存储）',
    `password` VARCHAR(255) NOT NULL DEFAULT '' COMMENT '登录密码（bcrypt哈希）',
    `gender` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '性别: 0=未知 1=男 2=女',
    `birthday` DATE DEFAULT NULL COMMENT '生日',
    `emergency_contact` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '紧急联系人（加密存储）',
    `emergency_phone` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '紧急联系电话（加密存储）',
    `check_in_date` DATE DEFAULT NULL COMMENT '入住日期',
    `remark` VARCHAR(255) NOT NULL DEFAULT '' COMMENT '备注',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '状态: 0=迁出 1=入住',
    `last_login_at` DATETIME DEFAULT NULL COMMENT '最后登录时间',
    `last_login_ip` VARCHAR(50) NOT NULL DEFAULT '' COMMENT '最后登录IP',
    `login_failures` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '连续登录失败次数',
    `locked_until` DATETIME DEFAULT NULL COMMENT '账号锁定截止时间',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at` DATETIME DEFAULT NULL COMMENT '软删除',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_phone` (`phone`),
    KEY `idx_status` (`status`),
    KEY `idx_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='业主表';

-- 7. 房产-业主关联表
CREATE TABLE IF NOT EXISTS `erik_room_owner` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `room_id` BIGINT UNSIGNED NOT NULL COMMENT '房产ID',
    `owner_id` BIGINT UNSIGNED NOT NULL COMMENT '业主ID',
    `relation_type` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '关系: 1=所有权 2=使用权 3=共有',
    `ownership_ratio` DECIMAL(5,2) NOT NULL DEFAULT 100.00 COMMENT '产权比例(%)',
    `cert_number` VARCHAR(100) NOT NULL DEFAULT '' COMMENT '产权证号',
    `start_date` DATE DEFAULT NULL COMMENT '产权起始日期',
    `end_date` DATE DEFAULT NULL COMMENT '产权截止日期',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_room_id` (`room_id`),
    KEY `idx_owner_id` (`owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='房产业主关联表';

-- 8. 租户表
CREATE TABLE IF NOT EXISTS `erik_tenant` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `room_id` BIGINT UNSIGNED NOT NULL COMMENT '房产ID',
    `owner_id` BIGINT UNSIGNED NOT NULL COMMENT '房东(业主)ID',
    `name` VARCHAR(50) NOT NULL COMMENT '姓名',
    `phone` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '手机号（加密存储）',
    `id_card` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '身份证号（加密存储）',
    `lease_start` DATE DEFAULT NULL COMMENT '租约起始',
    `lease_end` DATE DEFAULT NULL COMMENT '租约截止',
    `rent_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '月租金',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '状态: 0=到期 1=在租',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_room_id` (`room_id`),
    KEY `idx_owner_id` (`owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='租户表';

-- 9. 费用类型表
CREATE TABLE IF NOT EXISTS `erik_fee_type` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `name` VARCHAR(50) NOT NULL COMMENT '费用名称',
    `category` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '分类: 1=物业费 2=水费 3=电费 4=燃气 5=暖气 6=停车 7=维修基金 8=其他',
    `unit_price` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '单价',
    `unit_type` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '单位: 1=元/m²/月 2=元/吨 3=元/度 4=元/月/辆 5=固定金额',
    `cycle_type` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '周期: 1=每月 2=每季 3=每半年 4=每年 5=一次性',
    `is_required` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '是否必须: 0=可选 1=必须',
    `sort` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '排序',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='费用类型表';

-- 10. 费用账单表
CREATE TABLE IF NOT EXISTS `erik_fee_bill` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `room_id` BIGINT UNSIGNED NOT NULL COMMENT '房产ID',
    `owner_id` BIGINT UNSIGNED NOT NULL COMMENT '业主ID',
    `fee_type_id` BIGINT UNSIGNED NOT NULL COMMENT '费用类型ID',
    `bill_number` VARCHAR(32) NOT NULL COMMENT '账单编号',
    `amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '账单金额',
    `paid_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '已缴金额',
    `late_fee` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '滞纳金',
    `start_date` DATE DEFAULT NULL COMMENT '费用周期起始',
    `end_date` DATE DEFAULT NULL COMMENT '费用周期截止',
    `due_date` DATE DEFAULT NULL COMMENT '截止日期',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '状态: 0=未缴 1=部分缴 2=已缴 3=逾期 4=豁免',
    `paid_at` DATETIME DEFAULT NULL COMMENT '最后缴费时间',
    `remark` VARCHAR(255) NOT NULL DEFAULT '' COMMENT '备注',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_room_id` (`room_id`),
    KEY `idx_owner_id` (`owner_id`),
    KEY `idx_fee_type_id` (`fee_type_id`),
    KEY `idx_status` (`status`),
    KEY `idx_due_date` (`due_date`),
    KEY `idx_bill_number` (`bill_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='费用账单表';

-- 11. 缴费记录表
CREATE TABLE IF NOT EXISTS `erik_fee_payment` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `bill_id` BIGINT UNSIGNED NOT NULL COMMENT '账单ID',
    `owner_id` BIGINT UNSIGNED NOT NULL COMMENT '业主ID',
    `payment_number` VARCHAR(32) NOT NULL COMMENT '支付单号',
    `amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '支付金额',
    `payment_method` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '支付方式: 1=微信 2=支付宝 3=现金 4=银行转账 5=刷卡',
    `payment_channel` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '渠道: 1=在线 2=线下',
    `paid_at` DATETIME NOT NULL COMMENT '支付时间',
    `operator_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '操作员ID（线下收款时记录）',
    `receipt_url` VARCHAR(255) NOT NULL DEFAULT '' COMMENT '收据URL',
    `remark` VARCHAR(255) NOT NULL DEFAULT '' COMMENT '备注',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`id`),
    KEY `idx_bill_id` (`bill_id`),
    KEY `idx_owner_id` (`owner_id`),
    KEY `idx_payment_number` (`payment_number`),
    KEY `idx_paid_at` (`paid_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='缴费记录表';

-- 12. 报修单表
CREATE TABLE IF NOT EXISTS `erik_repair_order` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `order_number` VARCHAR(32) NOT NULL COMMENT '报修编号',
    `room_id` BIGINT UNSIGNED NOT NULL COMMENT '房产ID',
    `owner_id` BIGINT UNSIGNED NOT NULL COMMENT '报修人ID',
    `contact_phone` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '联系电话（加密存储）',
    `category` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '分类: 1=水电 2=门窗 3=墙面地面 4=管道 5=家电 6=电梯 7=公共设施 8=其他',
    `urgency` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '紧急程度: 1=普通 2=紧急 3=非常紧急',
    `description` TEXT COMMENT '问题描述',
    `images` TEXT COMMENT '图片URL (JSON数组)',
    `scheduled_at` DATETIME DEFAULT NULL COMMENT '预约维修时间',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '状态: 0=待派单 1=已派单 2=维修中 3=已完成 4=已评价 5=已取消',
    `staff_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '维修人员ID',
    `completed_at` DATETIME DEFAULT NULL COMMENT '完成时间',
    `rating` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '评分 1-5',
    `feedback` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '评价内容',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_room_id` (`room_id`),
    KEY `idx_owner_id` (`owner_id`),
    KEY `idx_status` (`status`),
    KEY `idx_order_number` (`order_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='报修单表';

-- 13. 报修进度表
CREATE TABLE IF NOT EXISTS `erik_repair_progress` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `repair_order_id` BIGINT UNSIGNED NOT NULL COMMENT '报修单ID',
    `staff_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '操作人员ID',
    `status_from` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '变更前状态',
    `status_to` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '变更后状态',
    `remark` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '进度说明',
    `images` TEXT COMMENT '现场图片 (JSON数组)',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`id`),
    KEY `idx_repair_order_id` (`repair_order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='报修进度表';

-- 14. 公告通知表
CREATE TABLE IF NOT EXISTS `erik_announcement` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `community_id` BIGINT UNSIGNED NOT NULL COMMENT '小区ID',
    `title` VARCHAR(200) NOT NULL COMMENT '标题',
    `content` TEXT COMMENT '内容',
    `category` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '分类: 1=通知 2=公告 3=提醒 4=活动',
    `is_top` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '是否置顶: 0=否 1=是',
    `is_published` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '发布状态: 0=草稿 1=已发布',
    `published_at` DATETIME DEFAULT NULL COMMENT '发布时间',
    `publisher_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '发布人ID',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at` DATETIME DEFAULT NULL COMMENT '软删除',
    PRIMARY KEY (`id`),
    KEY `idx_community_id` (`community_id`),
    KEY `idx_category` (`category`),
    KEY `idx_is_published` (`is_published`),
    KEY `idx_published_at` (`published_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='公告通知表';
-- ============================================================
-- Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
-- 迁移: 物业管理系统 — 第2批辅助业务表（10张）
-- 主键 id 使用 BIGINT UNSIGNED NOT NULL，由 snowflake-php 应用层生成
-- ============================================================

-- 15. 停车位表
CREATE TABLE IF NOT EXISTS `erik_parking_space` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `community_id` BIGINT UNSIGNED NOT NULL COMMENT '所属小区ID',
    `space_number` VARCHAR(20) NOT NULL COMMENT '车位编号',
    `space_type` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '类型: 1=地上 2=地下',
    `area` DECIMAL(8,2) NOT NULL DEFAULT 0.00 COMMENT '面积(m²)',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '状态: 0=空闲 1=已售 2=已租 3=维修',
    `fee_monthly` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '月租费',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_community_id` (`community_id`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='停车位表';

-- 16. 车辆表
CREATE TABLE IF NOT EXISTS `erik_parking_vehicle` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `owner_id` BIGINT UNSIGNED NOT NULL COMMENT '车主ID',
    `space_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '绑定车位ID',
    `plate_number` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '车牌号（加密存储）',
    `vehicle_brand` VARCHAR(50) NOT NULL DEFAULT '' COMMENT '品牌',
    `vehicle_color` VARCHAR(20) NOT NULL DEFAULT '' COMMENT '颜色',
    `vehicle_type` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '类型: 1=小汽车 2=SUV 3=MPV 4=货车 5=新能源',
    `start_date` DATE DEFAULT NULL COMMENT '租用起始',
    `end_date` DATE DEFAULT NULL COMMENT '租用截止',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '状态: 0=过期 1=正常',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_owner_id` (`owner_id`),
    KEY `idx_space_id` (`space_id`),
    KEY `idx_plate_number` (`plate_number`(100))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='车辆表';

-- 17. 停车记录表
CREATE TABLE IF NOT EXISTS `erik_parking_record` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `vehicle_id` BIGINT UNSIGNED NOT NULL COMMENT '车辆ID',
    `space_id` BIGINT UNSIGNED NOT NULL COMMENT '车位ID',
    `entry_time` DATETIME DEFAULT NULL COMMENT '入场时间',
    `exit_time` DATETIME DEFAULT NULL COMMENT '出场时间',
    `duration` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '停留时长(分钟)',
    `fee` DECIMAL(8,2) NOT NULL DEFAULT 0.00 COMMENT '停车费(临停)',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_vehicle_id` (`vehicle_id`),
    KEY `idx_entry_time` (`entry_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='停车记录表';

-- 18. 设备表
CREATE TABLE IF NOT EXISTS `erik_equipment` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `community_id` BIGINT UNSIGNED NOT NULL COMMENT '所属小区ID',
    `name` VARCHAR(100) NOT NULL COMMENT '设备名称',
    `equipment_number` VARCHAR(50) NOT NULL DEFAULT '' COMMENT '设备编号',
    `category` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '分类: 1=电梯 2=消防 3=门禁 4=监控 5=给排水 6=供电 7=暖通 8=其他',
    `brand` VARCHAR(50) NOT NULL DEFAULT '' COMMENT '品牌',
    `model` VARCHAR(50) NOT NULL DEFAULT '' COMMENT '型号',
    `location` VARCHAR(255) NOT NULL DEFAULT '' COMMENT '安装位置',
    `install_date` DATE DEFAULT NULL COMMENT '安装日期',
    `warranty_end` DATE DEFAULT NULL COMMENT '质保到期',
    `service_life` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '设计寿命(年)',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '状态: 0=故障 1=正常 2=维修 3=报废',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_community_id` (`community_id`),
    KEY `idx_category` (`category`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='设备表';

-- 19. 设备维保表
CREATE TABLE IF NOT EXISTS `erik_equipment_maintenance` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `equipment_id` BIGINT UNSIGNED NOT NULL COMMENT '设备ID',
    `maintenance_type` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '类型: 1=日常巡检 2=定期保养 3=故障维修 4=大修 5=更换',
    `description` TEXT COMMENT '维保内容',
    `staff_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '维保人员ID',
    `cost` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '费用',
    `company` VARCHAR(100) NOT NULL DEFAULT '' COMMENT '维保单位(外委)',
    `started_at` DATETIME DEFAULT NULL COMMENT '开始时间',
    `completed_at` DATETIME DEFAULT NULL COMMENT '完成时间',
    `result` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '维保结果',
    `next_at` DATE DEFAULT NULL COMMENT '下次维保日期',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_equipment_id` (`equipment_id`),
    KEY `idx_next_at` (`next_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='设备维保表';

-- 20. 投诉建议表
CREATE TABLE IF NOT EXISTS `erik_complaint` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `owner_id` BIGINT UNSIGNED NOT NULL COMMENT '投诉人ID',
    `room_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '房产ID',
    `type` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '类型: 1=投诉 2=建议 3=表扬',
    `category` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '分类: 1=服务态度 2=环境卫生 3=安全管理 4=设施维护 5=噪音 6=违建 7=其他',
    `title` VARCHAR(200) NOT NULL COMMENT '标题',
    `content` TEXT COMMENT '内容',
    `images` TEXT COMMENT '图片 (JSON数组)',
    `is_anonymous` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '是否匿名: 0=实名 1=匿名',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '状态: 0=待处理 1=处理中 2=已处理 3=已回访 4=已关闭',
    `handler_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '处理人ID',
    `handler_remark` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '处理备注',
    `handled_at` DATETIME DEFAULT NULL COMMENT '处理时间',
    `visitor_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '回访人ID',
    `visitor_remark` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '回访备注',
    `visitor_at` DATETIME DEFAULT NULL COMMENT '回访时间',
    `satisfaction` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '满意度 1-5',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_owner_id` (`owner_id`),
    KEY `idx_room_id` (`room_id`),
    KEY `idx_type` (`type`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='投诉建议表';

-- 21. 访客表
CREATE TABLE IF NOT EXISTS `erik_visitor` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `room_id` BIGINT UNSIGNED NOT NULL COMMENT '到访房产ID',
    `owner_id` BIGINT UNSIGNED NOT NULL COMMENT '被访业主ID',
    `visitor_name` VARCHAR(50) NOT NULL COMMENT '访客姓名',
    `visitor_phone` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '访客电话（加密存储）',
    `visitor_id_card` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '访客身份证（加密存储）',
    `plate_number` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '来访车牌（加密存储）',
    `visitor_count` INT UNSIGNED NOT NULL DEFAULT 1 COMMENT '同行人数',
    `purpose` VARCHAR(200) NOT NULL DEFAULT '' COMMENT '来访事由',
    `expected_start` DATETIME DEFAULT NULL COMMENT '预计到访时间',
    `expected_end` DATETIME DEFAULT NULL COMMENT '预计离开时间',
    `actual_start` DATETIME DEFAULT NULL COMMENT '实际到访时间',
    `actual_end` DATETIME DEFAULT NULL COMMENT '实际离开时间',
    `pass_code` VARCHAR(20) NOT NULL DEFAULT '' COMMENT '通行码',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '状态: 0=已预约 1=已到访 2=已离开 3=已取消',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_room_id` (`room_id`),
    KEY `idx_owner_id` (`owner_id`),
    KEY `idx_status` (`status`),
    KEY `idx_pass_code` (`pass_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='访客表';

-- 22. 合同表
CREATE TABLE IF NOT EXISTS `erik_contract` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `contract_number` VARCHAR(50) NOT NULL COMMENT '合同编号',
    `contract_type` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '类型: 1=物业合同 2=租赁合同 3=维保合同 4=服务合同 5=采购合同',
    `party_a_type` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '甲方类型: 1=业主 2=物业 3=供应商',
    `party_a_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '甲方ID',
    `party_b_type` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '乙方类型',
    `party_b_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '乙方ID',
    `title` VARCHAR(200) NOT NULL COMMENT '合同标题',
    `amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '合同金额',
    `start_date` DATE DEFAULT NULL COMMENT '合同起始',
    `end_date` DATE DEFAULT NULL COMMENT '合同截止',
    `sign_date` DATE DEFAULT NULL COMMENT '签订日期',
    `content` TEXT COMMENT '合同内容 (JSON)',
    `attachments` TEXT COMMENT '附件 (JSON)',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '状态: 0=草稿 1=履行中 2=已到期 3=已终止 4=续签',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_contract_type` (`contract_type`),
    KEY `idx_status` (`status`),
    KEY `idx_start_date` (`start_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='合同表';

-- 23. 财务收入表
CREATE TABLE IF NOT EXISTS `erik_finance_income` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `income_number` VARCHAR(32) NOT NULL COMMENT '收入单号',
    `income_type` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '类型: 1=物业费 2=停车费 3=租金 4=广告费 5=维修基金 6=其他',
    `amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '金额',
    `payer_type` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '付款方类型: 1=业主 2=租户 3=商户 4=其他',
    `payer_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '付款方ID',
    `payment_method` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '支付方式: 1=微信 2=支付宝 3=现金 4=银行转账',
    `income_date` DATE NOT NULL COMMENT '收入日期',
    `operator_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '经手人ID',
    `remark` VARCHAR(255) NOT NULL DEFAULT '' COMMENT '备注',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_income_type` (`income_type`),
    KEY `idx_income_date` (`income_date`),
    KEY `idx_income_number` (`income_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='财务收入表';

-- 24. 财务支出表
CREATE TABLE IF NOT EXISTS `erik_finance_expense` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `expense_number` VARCHAR(32) NOT NULL COMMENT '支出单号',
    `expense_type` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '类型: 1=人力成本 2=设备采购 3=维保维修 4=水电能耗 5=保洁绿化 6=办公费用 7=税金 8=其他',
    `amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '金额',
    `payee` VARCHAR(100) NOT NULL DEFAULT '' COMMENT '收款方',
    `expense_date` DATE NOT NULL COMMENT '支出日期',
    `operator_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '经手人ID',
    `receipt_url` VARCHAR(255) NOT NULL DEFAULT '' COMMENT '凭证URL',
    `remark` VARCHAR(255) NOT NULL DEFAULT '' COMMENT '备注',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_expense_type` (`expense_type`),
    KEY `idx_expense_date` (`expense_date`),
    KEY `idx_expense_number` (`expense_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='财务支出表';
-- ============================================================
-- Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
-- 迁移: 物业管理系统 — 第3批高级功能表（10张）
-- 主键 id 使用 BIGINT UNSIGNED NOT NULL，由 snowflake-php 应用层生成
-- ============================================================

-- 25. 安保巡逻路线表
CREATE TABLE IF NOT EXISTS `erik_security_patrol` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `community_id` BIGINT UNSIGNED NOT NULL COMMENT '所属小区ID',
    `name` VARCHAR(100) NOT NULL COMMENT '巡逻路线名称',
    `route_points` TEXT COMMENT '路线坐标点 (JSON)',
    `checkpoints` TEXT COMMENT '打卡点列表 (JSON)',
    `sort` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '排序',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '状态: 0=停用 1=启用',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`), KEY `idx_community_id` (`community_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='安保巡逻路线表';

-- 26. 巡逻记录表
CREATE TABLE IF NOT EXISTS `erik_patrol_record` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `patrol_id` BIGINT UNSIGNED NOT NULL COMMENT '巡逻路线ID',
    `staff_id` BIGINT UNSIGNED NOT NULL COMMENT '巡逻人员ID',
    `started_at` DATETIME DEFAULT NULL COMMENT '开始时间',
    `ended_at` DATETIME DEFAULT NULL COMMENT '结束时间',
    `duration` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '巡逻时长(分钟)',
    `checkpoints_done` TEXT COMMENT '已完成打卡点 (JSON)',
    `abnormal_note` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '异常备注',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`), KEY `idx_patrol_id` (`patrol_id`), KEY `idx_staff_id` (`staff_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='巡逻记录表';

-- 27. 保洁区域表
CREATE TABLE IF NOT EXISTS `erik_cleaning_area` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `community_id` BIGINT UNSIGNED NOT NULL COMMENT '所属小区ID',
    `name` VARCHAR(100) NOT NULL COMMENT '区域名称',
    `location` VARCHAR(255) NOT NULL DEFAULT '' COMMENT '位置描述',
    `area` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '面积(m²)',
    `frequency` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '频次: 1=每日 2=每周 3=每半月 4=每月',
    `responsible_staff` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '负责人ID',
    `sort` INT UNSIGNED NOT NULL DEFAULT 0,
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '0=停用 1=启用',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`), KEY `idx_community_id` (`community_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='保洁区域表';

-- 28. 保洁记录表
CREATE TABLE IF NOT EXISTS `erik_cleaning_record` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `area_id` BIGINT UNSIGNED NOT NULL COMMENT '保洁区域ID',
    `staff_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '保洁人员ID',
    `cleaned_at` DATETIME DEFAULT NULL COMMENT '清洁时间',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0=未清洁 1=已清洁',
    `inspector_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '检查人ID',
    `inspection_remark` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '检查备注',
    `inspection_at` DATETIME DEFAULT NULL COMMENT '检查时间',
    `images` TEXT COMMENT '现场图片 (JSON)',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`), KEY `idx_area_id` (`area_id`), KEY `idx_cleaned_at` (`cleaned_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='保洁记录表';

-- 29. 绿化区域表
CREATE TABLE IF NOT EXISTS `erik_green_area` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `community_id` BIGINT UNSIGNED NOT NULL COMMENT '所属小区ID',
    `name` VARCHAR(100) NOT NULL COMMENT '区域名称',
    `location` VARCHAR(255) NOT NULL DEFAULT '' COMMENT '位置描述',
    `area` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '面积(m²)',
    `plant_types` VARCHAR(200) NOT NULL DEFAULT '' COMMENT '主要植物',
    `responsible_staff` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '负责人ID',
    `sort` INT UNSIGNED NOT NULL DEFAULT 0,
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '0=停用 1=启用',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`), KEY `idx_community_id` (`community_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='绿化区域表';

-- 30. 绿化养护记录表
CREATE TABLE IF NOT EXISTS `erik_green_maintenance` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `area_id` BIGINT UNSIGNED NOT NULL COMMENT '绿化区域ID',
    `maintenance_type` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '类型: 1=浇水 2=修剪 3=施肥 4=除虫 5=补种',
    `staff_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '养护人员ID',
    `description` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '养护描述',
    `cost` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '费用',
    `maintained_at` DATETIME DEFAULT NULL COMMENT '养护时间',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`), KEY `idx_area_id` (`area_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='绿化养护记录表';

-- 31. 社区活动表
CREATE TABLE IF NOT EXISTS `erik_community_activity` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `community_id` BIGINT UNSIGNED NOT NULL COMMENT '所属小区ID',
    `title` VARCHAR(200) NOT NULL COMMENT '活动标题',
    `content` TEXT COMMENT '活动内容',
    `category` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '分类: 1=文体 2=节日 3=公益 4=讲座 5=亲子 6=其他',
    `cover_image` VARCHAR(255) NOT NULL DEFAULT '' COMMENT '封面图URL',
    `location` VARCHAR(255) NOT NULL DEFAULT '' COMMENT '活动地点',
    `max_participants` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '最大参与人数,0不限',
    `start_time` DATETIME DEFAULT NULL COMMENT '活动开始时间',
    `end_time` DATETIME DEFAULT NULL COMMENT '活动结束时间',
    `signup_start` DATETIME DEFAULT NULL COMMENT '报名开始时间',
    `signup_end` DATETIME DEFAULT NULL COMMENT '报名截止时间',
    `is_free` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '是否免费: 0=收费 1=免费',
    `cost` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '费用',
    `organizer` VARCHAR(100) NOT NULL DEFAULT '' COMMENT '组织者',
    `contact_phone` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '联系电话（加密存储）',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '状态: 0=草稿 1=报名中 2=进行中 3=已结束 4=已取消',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`), KEY `idx_community_id` (`community_id`), KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='社区活动表';

-- 32. 活动报名表
CREATE TABLE IF NOT EXISTS `erik_activity_signup` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `activity_id` BIGINT UNSIGNED NOT NULL COMMENT '活动ID',
    `owner_id` BIGINT UNSIGNED NOT NULL COMMENT '报名人ID',
    `participant_count` INT UNSIGNED NOT NULL DEFAULT 1 COMMENT '参与人数',
    `contact_phone` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '联系电话（加密存储）',
    `remark` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '备注',
    `signup_status` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '状态: 0=已报名 1=已签到 2=已取消',
    `signup_at` DATETIME DEFAULT NULL COMMENT '报名时间',
    `checkin_at` DATETIME DEFAULT NULL COMMENT '签到时间',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`), KEY `idx_activity_id` (`activity_id`), KEY `idx_owner_id` (`owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='活动报名表';

-- 33. 能耗仪表表
CREATE TABLE IF NOT EXISTS `erik_energy_meter` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `room_id` BIGINT UNSIGNED NOT NULL COMMENT '房产ID',
    `meter_type` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '类型: 1=电表 2=水表 3=燃气表 4=暖气表',
    `meter_number` VARCHAR(50) NOT NULL DEFAULT '' COMMENT '仪表编号',
    `install_reading` DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '安装读数',
    `install_date` DATE DEFAULT NULL COMMENT '安装日期',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '状态: 0=停用 1=正常',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`), KEY `idx_room_id` (`room_id`), KEY `idx_meter_number` (`meter_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='能耗仪表表';

-- 34. 能耗记录表
CREATE TABLE IF NOT EXISTS `erik_energy_record` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `meter_id` BIGINT UNSIGNED NOT NULL COMMENT '仪表ID',
    `room_id` BIGINT UNSIGNED NOT NULL COMMENT '房产ID',
    `reading` DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '本次读数',
    `previous_reading` DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '上次读数',
    `usage_amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '用量',
    `unit_price` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '单价',
    `amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '费用',
    `record_date` DATE NOT NULL COMMENT '记录日期',
    `reader_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '抄表人ID',
    `bill_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '关联账单ID',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`), KEY `idx_meter_id` (`meter_id`), KEY `idx_room_id` (`room_id`), KEY `idx_record_date` (`record_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='能耗记录表';

-- 35. 员工表
CREATE TABLE IF NOT EXISTS `erik_staff` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `community_id` BIGINT UNSIGNED NOT NULL COMMENT '所属小区ID',
    `name` VARCHAR(50) NOT NULL COMMENT '姓名',
    `phone` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '手机号（加密存储）',
    `id_card` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '身份证号（加密存储）',
    `job_title` VARCHAR(50) NOT NULL DEFAULT '' COMMENT '职位',
    `department` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '部门: 1=管理 2=客服 3=工程 4=安保 5=保洁 6=绿化 7=财务',
    `hire_date` DATE DEFAULT NULL COMMENT '入职日期',
    `salary` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '薪资（加密存储）',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '状态: 0=离职 1=在职 2=休假',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`), KEY `idx_community_id` (`community_id`), KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='员工表';
-- ============================================================
-- Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
-- 迁移: 功能扩展（消息通知/审批工作流/支付/ES搜索/投票/SLA/数据大屏/催缴/巡检/商城/人脸/集团/智能问答）
-- ============================================================

-- ============================================================
-- 1. 消息通知中心
-- ============================================================

-- 消息模板表
CREATE TABLE IF NOT EXISTS `erik_notification_template` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `code` VARCHAR(50) NOT NULL COMMENT '模板代码: bill_remind/repair_update/announcement',
    `name` VARCHAR(100) NOT NULL COMMENT '模板名称',
    `title_template` VARCHAR(200) NOT NULL DEFAULT '' COMMENT '标题模板: 您的账单{amount}元已逾期',
    `content_template` TEXT COMMENT '内容模板',
    `channels` VARCHAR(100) NOT NULL DEFAULT '["in_app"]' COMMENT '渠道: in_app/sms/email/push (JSON)',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '0=停用 1=启用',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`), UNIQUE KEY `uk_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='消息模板表';

-- 通知消息表
CREATE TABLE IF NOT EXISTS `erik_notification` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `user_id` BIGINT UNSIGNED NOT NULL COMMENT '接收人ID',
    `user_type` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '用户类型: 1=业主 2=管理员',
    `template_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '模板ID',
    `title` VARCHAR(200) NOT NULL COMMENT '消息标题',
    `content` TEXT COMMENT '消息内容',
    `type` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '类型: 1=系统通知 2=账单提醒 3=报修进度 4=公告 5=活动 6=审批',
    `channel` VARCHAR(20) NOT NULL DEFAULT 'in_app' COMMENT '发送渠道: in_app/sms/email/push',
    `is_read` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '已读: 0=未读 1=已读',
    `read_at` DATETIME DEFAULT NULL COMMENT '阅读时间',
    `ref_type` VARCHAR(30) NOT NULL DEFAULT '' COMMENT '关联类型: bill/repair/announcement/activity',
    `ref_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '关联ID',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_user` (`user_id`, `user_type`),
    KEY `idx_is_read` (`is_read`),
    KEY `idx_created_at` (`created_at`),
    KEY `idx_type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='通知消息表';

-- ============================================================
-- 2. 审批工作流引擎
-- ============================================================

-- 审批类型表
CREATE TABLE IF NOT EXISTS `erik_approval_type` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `code` VARCHAR(50) NOT NULL COMMENT '类型代码: repair_assign/visitor_approve/contract_approve',
    `name` VARCHAR(100) NOT NULL COMMENT '类型名称',
    `steps` TEXT COMMENT '审批步骤配置 (JSON): [{"step":1,"name":"主管审批","role":"manager"},...]',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`), UNIQUE KEY `uk_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='审批类型表';

-- 审批实例表
CREATE TABLE IF NOT EXISTS `erik_approval` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `approval_type_id` BIGINT UNSIGNED NOT NULL COMMENT '审批类型ID',
    `title` VARCHAR(200) NOT NULL COMMENT '审批标题',
    `applicant_id` BIGINT UNSIGNED NOT NULL COMMENT '申请人ID',
    `applicant_type` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '1=业主 2=管理员',
    `ref_type` VARCHAR(30) NOT NULL DEFAULT '' COMMENT '关联业务类型',
    `ref_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '关联业务ID',
    `current_step` INT UNSIGNED NOT NULL DEFAULT 1 COMMENT '当前步骤',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '状态: 0=审批中 1=已通过 2=已驳回 3=已撤回',
    `remark` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '申请备注',
    `completed_at` DATETIME DEFAULT NULL COMMENT '审批完成时间',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_approval_type` (`approval_type_id`),
    KEY `idx_applicant` (`applicant_id`, `applicant_type`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='审批实例表';

-- 审批记录表
CREATE TABLE IF NOT EXISTS `erik_approval_record` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `approval_id` BIGINT UNSIGNED NOT NULL COMMENT '审批实例ID',
    `step` INT UNSIGNED NOT NULL DEFAULT 1 COMMENT '步骤',
    `approver_id` BIGINT UNSIGNED NOT NULL COMMENT '审批人ID',
    `action` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '操作: 0=待审批 1=通过 2=驳回',
    `remark` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '审批意见',
    `acted_at` DATETIME DEFAULT NULL COMMENT '操作时间',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_approval_id` (`approval_id`),
    KEY `idx_approver` (`approver_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='审批记录表';

-- ============================================================
-- 3. 支付集成
-- ============================================================

-- 支付订单表
CREATE TABLE IF NOT EXISTS `erik_payment_order` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `order_number` VARCHAR(32) NOT NULL COMMENT '支付订单号',
    `bill_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '关联账单ID',
    `user_id` BIGINT UNSIGNED NOT NULL COMMENT '支付人ID',
    `user_type` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '1=业主 2=租户',
    `amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '支付金额(元)',
    `channel` VARCHAR(20) NOT NULL DEFAULT 'wechat' COMMENT '支付渠道: wechat/alipay/cash/bank_transfer',
    `trade_no` VARCHAR(64) NOT NULL DEFAULT '' COMMENT '第三方交易号',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '状态: 0=待支付 1=支付成功 2=支付失败 3=已退款 4=已关闭',
    `paid_at` DATETIME DEFAULT NULL COMMENT '支付时间',
    `refund_at` DATETIME DEFAULT NULL COMMENT '退款时间',
    `refund_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '退款金额',
    `notify_data` TEXT COMMENT '回调原始数据 (JSON)',
    `expire_at` DATETIME DEFAULT NULL COMMENT '过期时间',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_order_number` (`order_number`),
    KEY `idx_bill_id` (`bill_id`),
    KEY `idx_user` (`user_id`, `user_type`),
    KEY `idx_trade_no` (`trade_no`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='支付订单表';

-- ============================================================
-- 5. 业主投票/表决
-- ============================================================

-- 投票表
CREATE TABLE IF NOT EXISTS `erik_vote` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `community_id` BIGINT UNSIGNED NOT NULL COMMENT '所属小区ID',
    `title` VARCHAR(200) NOT NULL COMMENT '投票标题',
    `description` TEXT COMMENT '投票说明',
    `vote_type` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '类型: 1=普通投票 2=业主大会表决(按面积加权)',
    `start_time` DATETIME NOT NULL COMMENT '开始时间',
    `end_time` DATETIME NOT NULL COMMENT '结束时间',
    `is_anonymous` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '是否匿名: 0=实名 1=匿名',
    `min_participation_rate` DECIMAL(5,2) NOT NULL DEFAULT 0.00 COMMENT '最低参与率(%)',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0=草稿 1=进行中 2=已结束 3=已取消',
    `publisher_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '发布人',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_community_id` (`community_id`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='投票表';

-- 投票选项表
CREATE TABLE IF NOT EXISTS `erik_vote_option` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `vote_id` BIGINT UNSIGNED NOT NULL COMMENT '投票ID',
    `content` VARCHAR(200) NOT NULL COMMENT '选项内容',
    `sort` INT UNSIGNED NOT NULL DEFAULT 0,
    `vote_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '得票数',
    `area_weighted_count` DECIMAL(15,2) NOT NULL DEFAULT 0.00 COMMENT '面积加权得票',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_vote_id` (`vote_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='投票选项表';

-- 投票记录表
CREATE TABLE IF NOT EXISTS `erik_vote_record` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `vote_id` BIGINT UNSIGNED NOT NULL COMMENT '投票ID',
    `option_id` BIGINT UNSIGNED NOT NULL COMMENT '选项ID',
    `owner_id` BIGINT UNSIGNED NOT NULL COMMENT '投票人ID',
    `room_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '关联房产',
    `area_ratio` DECIMAL(5,2) NOT NULL DEFAULT 0.00 COMMENT '面积占比(%)',
    `voted_at` DATETIME NOT NULL COMMENT '投票时间',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_vote_owner` (`vote_id`, `owner_id`),
    KEY `idx_vote_id` (`vote_id`),
    KEY `idx_option_id` (`option_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='投票记录表';

-- ============================================================
-- 6. 报修 SLA 自动升级
-- ============================================================

-- SLA规则表
CREATE TABLE IF NOT EXISTS `erik_sla_rule` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `name` VARCHAR(100) NOT NULL COMMENT '规则名称',
    `category` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '报修分类: 1=水电 2=门窗 ...',
    `urgency` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '紧急程度: 1=普通 2=紧急 3=非常紧急',
    `response_minutes` INT UNSIGNED NOT NULL DEFAULT 60 COMMENT '响应时限(分钟)',
    `resolve_minutes` INT UNSIGNED NOT NULL DEFAULT 480 COMMENT '解决时限(分钟)',
    `escalate_to_role` VARCHAR(50) NOT NULL DEFAULT '' COMMENT '升级目标角色slug',
    `escalate_minutes` INT UNSIGNED NOT NULL DEFAULT 120 COMMENT '超时多久后升级(分钟)',
    `penalty_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '超时罚款金额',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='SLA规则表';

-- SLA记录表
CREATE TABLE IF NOT EXISTS `erik_sla_record` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `repair_order_id` BIGINT UNSIGNED NOT NULL COMMENT '报修单ID',
    `rule_id` BIGINT UNSIGNED NOT NULL COMMENT 'SLA规则ID',
    `response_deadline` DATETIME DEFAULT NULL COMMENT '响应截止时间',
    `resolve_deadline` DATETIME DEFAULT NULL COMMENT '解决截止时间',
    `escalated_at` DATETIME DEFAULT NULL COMMENT '升级时间',
    `escalate_level` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '当前升级级别',
    `is_response_overtime` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '是否响应超时',
    `is_resolve_overtime` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '是否解决超时',
    `penalty_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '罚款金额',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_repair_order_id` (`repair_order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='SLA记录表';

-- ============================================================
-- 8. 智能催缴
-- ============================================================

-- 催缴策略表
CREATE TABLE IF NOT EXISTS `erik_collection_strategy` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `name` VARCHAR(100) NOT NULL COMMENT '策略名称',
    `overdue_days` INT UNSIGNED NOT NULL DEFAULT 7 COMMENT '逾期天数触发',
    `action` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '动作: 1=App推送 2=短信 3=电话 4=上门 5=律师函',
    `template_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '消息模板ID',
    `late_fee_rate` DECIMAL(5,3) NOT NULL DEFAULT 0.001 COMMENT '日滞纳金率(千分比)',
    `sort` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '执行顺序',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='催缴策略表';

-- 催缴记录表
CREATE TABLE IF NOT EXISTS `erik_collection_record` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `bill_id` BIGINT UNSIGNED NOT NULL COMMENT '账单ID',
    `strategy_id` BIGINT UNSIGNED NOT NULL COMMENT '策略ID',
    `action` TINYINT UNSIGNED NOT NULL COMMENT '执行动作',
    `executed_by` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '执行人(0=系统)',
    `remark` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '催缴备注',
    `executed_at` DATETIME NOT NULL COMMENT '执行时间',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_bill_id` (`bill_id`),
    KEY `idx_executed_at` (`executed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='催缴记录表';

-- ============================================================
-- 9. 巡检记录（移动端）
-- ============================================================

-- 巡检任务表
CREATE TABLE IF NOT EXISTS `erik_inspection_task` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `community_id` BIGINT UNSIGNED NOT NULL COMMENT '所属小区',
    `title` VARCHAR(200) NOT NULL COMMENT '任务标题',
    `task_type` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '类型: 1=安保 2=保洁 3=设备 4=绿化 5=消防',
    `route_points` TEXT COMMENT '巡检路线 (JSON坐标)',
    `checkpoints` TEXT COMMENT '检查点列表 (JSON)',
    `assigned_to` BIGINT UNSIGNED NOT NULL COMMENT '指派人员ID',
    `scheduled_date` DATE NOT NULL COMMENT '计划日期',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0=待执行 1=执行中 2=已完成 3=已超时',
    `started_at` DATETIME DEFAULT NULL,
    `completed_at` DATETIME DEFAULT NULL,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_community` (`community_id`),
    KEY `idx_assigned` (`assigned_to`),
    KEY `idx_scheduled` (`scheduled_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='巡检任务表';

-- 巡检打卡记录表
CREATE TABLE IF NOT EXISTS `erik_inspection_checkpoint` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `task_id` BIGINT UNSIGNED NOT NULL COMMENT '巡检任务ID',
    `checkpoint_index` INT UNSIGNED NOT NULL COMMENT '检查点序号',
    `checkpoint_name` VARCHAR(100) NOT NULL DEFAULT '' COMMENT '检查点名称',
    `latitude` DECIMAL(10,7) NOT NULL DEFAULT 0 COMMENT '纬度',
    `longitude` DECIMAL(10,7) NOT NULL DEFAULT 0 COMMENT '经度',
    `photo_url` VARCHAR(255) NOT NULL DEFAULT '' COMMENT '现场照片',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0=未打卡 1=正常 2=异常',
    `remark` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '检查备注',
    `checked_at` DATETIME DEFAULT NULL COMMENT '打卡时间',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_task_id` (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='巡检打卡记录表';

-- ============================================================
-- 12. 社区商城
-- ============================================================

-- 商品分类表
CREATE TABLE IF NOT EXISTS `erik_mall_category` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `name` VARCHAR(50) NOT NULL COMMENT '分类名称',
    `icon` VARCHAR(255) NOT NULL DEFAULT '' COMMENT '图标',
    `sort` INT UNSIGNED NOT NULL DEFAULT 0,
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商城分类表';

-- 商品表
CREATE TABLE IF NOT EXISTS `erik_mall_product` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `category_id` BIGINT UNSIGNED NOT NULL COMMENT '分类ID',
    `community_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '所属小区(0=全平台)',
    `name` VARCHAR(200) NOT NULL COMMENT '商品名称',
    `description` TEXT COMMENT '商品描述',
    `images` TEXT COMMENT '商品图片 (JSON)',
    `price` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '价格',
    `original_price` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '原价',
    `stock` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '库存',
    `sales` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '销量',
    `is_recommend` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '是否推荐',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '0=下架 1=上架',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_category` (`category_id`),
    KEY `idx_community` (`community_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商城商品表';

-- 订单表
CREATE TABLE IF NOT EXISTS `erik_mall_order` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `order_number` VARCHAR(32) NOT NULL COMMENT '订单编号',
    `owner_id` BIGINT UNSIGNED NOT NULL COMMENT '买家ID',
    `product_id` BIGINT UNSIGNED NOT NULL COMMENT '商品ID',
    `quantity` INT UNSIGNED NOT NULL DEFAULT 1 COMMENT '数量',
    `amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '实付金额',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0=待付款 1=已付款 2=已发货 3=已完成 4=已取消 5=退款中 6=已退款',
    `address` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '收货地址',
    `contact_phone` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '联系电话(加密)',
    `express_company` VARCHAR(50) NOT NULL DEFAULT '' COMMENT '快递公司',
    `express_number` VARCHAR(50) NOT NULL DEFAULT '' COMMENT '快递单号',
    `paid_at` DATETIME DEFAULT NULL,
    `shipped_at` DATETIME DEFAULT NULL,
    `completed_at` DATETIME DEFAULT NULL,
    `remark` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '买家备注',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_order_number` (`order_number`),
    KEY `idx_owner` (`owner_id`),
    KEY `idx_product` (`product_id`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商城订单表';

-- ============================================================
-- 13. 人脸识别
-- ============================================================

-- 人脸信息表
CREATE TABLE IF NOT EXISTS `erik_face_info` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `owner_id` BIGINT UNSIGNED NOT NULL COMMENT '业主ID',
    `face_image` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '人脸照片URL',
    `face_token` VARCHAR(100) NOT NULL DEFAULT '' COMMENT '第三方人脸标识',
    `feature_data` TEXT COMMENT '人脸特征数据(加密)',
    `verify_status` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '认证状态: 0=未认证 1=审核中 2=已认证 3=认证失败',
    `verified_at` DATETIME DEFAULT NULL COMMENT '认证时间',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_owner_id` (`owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='人脸信息表';

-- ============================================================
-- 14. 多小区集团管理
-- ============================================================

-- 集团表
CREATE TABLE IF NOT EXISTS `erik_group` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `name` VARCHAR(100) NOT NULL COMMENT '集团名称',
    `contact_person` VARCHAR(50) NOT NULL DEFAULT '' COMMENT '联系人',
    `contact_phone` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '联系电话(加密)',
    `description` TEXT COMMENT '集团简介',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='集团表';

-- 集团公司关联表（集团→小区 多对多）
CREATE TABLE IF NOT EXISTS `erik_group_community` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `group_id` BIGINT UNSIGNED NOT NULL COMMENT '集团ID',
    `community_id` BIGINT UNSIGNED NOT NULL COMMENT '小区ID',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_group_community` (`group_id`, `community_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='集团小区关联表';

-- ============================================================
-- 15. 智能问答
-- ============================================================

-- 知识库表
CREATE TABLE IF NOT EXISTS `erik_knowledge_base` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `category_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '分类ID(自引用)',
    `question` VARCHAR(500) NOT NULL COMMENT '问题',
    `answer` TEXT COMMENT '答案',
    `keywords` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '关键词(逗号分隔)',
    `view_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '查看次数',
    `helpful_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '有用次数',
    `sort` INT UNSIGNED NOT NULL DEFAULT 0,
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '0=停用 1=启用',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_category` (`category_id`),
    KEY `idx_keywords` (`keywords`(100))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='知识库表';

-- 对话记录表
CREATE TABLE IF NOT EXISTS `erik_chat_record` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `user_id` BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
    `user_type` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '1=业主 2=管理员',
    `question` TEXT COMMENT '用户问题',
    `answer` TEXT COMMENT '回答',
    `match_type` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '匹配方式: 0=关键词 1=AI 2=转人工',
    `matched_kb_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '匹配知识库ID',
    `is_helpful` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '是否解决: 0=未评价 1=已解决 2=未解决',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_user` (`user_id`, `user_type`),
    KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='对话记录表';

-- 开放 API Key 表（service 端入站对外接口鉴权，X-API-Key 头）
CREATE TABLE IF NOT EXISTS `erik_api_key` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `name` VARCHAR(64) NOT NULL COMMENT 'Key 名称/用途',
    `api_key_hash` CHAR(64) NOT NULL COMMENT 'API Key SHA-256 摘要（明文不落库）',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '状态: 0=禁用 1=启用',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_api_key_hash` (`api_key_hash`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='开放 API Key 表';
