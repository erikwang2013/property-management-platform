-- ============================================================
-- Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
-- 迁移: 初始化管理后台核心数据表
-- 注意: 主键 id 使用 BIGINT 非自增，由 snowflake-php 在应用层生成
-- 注意: 本文件为全量安装入口（34 张表 + RBAC 种子数据），唯一建库入口。
--       幂等口径: 表/列/种子幂等；索引重跑需向导或 mysql --force——
--       建表走 IF NOT EXISTS，但 ALTER 加索引/列与种子 INSERT 重跑会分别报
--       1061/1060/1062「已存在」（向导导入循环把这四类 [含 1050] 降级为跳过，直连 mysql 重灌需 --force）。
-- ============================================================

-- ============================================================
-- 管理用户表
-- ============================================================
CREATE TABLE IF NOT EXISTS `management_admin_user` (
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
-- SaaS 租户表（与租客表 management_tenant 语义区分）
-- ============================================================
CREATE TABLE IF NOT EXISTS `management_platform_tenant` (
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
CREATE TABLE IF NOT EXISTS `management_admin_role` (
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
CREATE TABLE IF NOT EXISTS `management_admin_permission` (
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
    KEY `idx_type` (`type`),
    UNIQUE KEY `uk_slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='权限表';

-- ============================================================
-- 用户角色关联表（多对多中间表）
-- ============================================================
CREATE TABLE IF NOT EXISTS `management_admin_user_role` (
    `user_id` BIGINT UNSIGNED NOT NULL COMMENT '用户ID',
    `role_id` BIGINT UNSIGNED NOT NULL COMMENT '角色ID',
    PRIMARY KEY (`user_id`, `role_id`),
    KEY `idx_role_id` (`role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户角色关联表';

-- ============================================================
-- 角色权限关联表（多对多中间表）
-- ============================================================
CREATE TABLE IF NOT EXISTS `management_admin_role_permission` (
    `role_id` BIGINT UNSIGNED NOT NULL COMMENT '角色ID',
    `permission_id` BIGINT UNSIGNED NOT NULL COMMENT '权限ID',
    PRIMARY KEY (`role_id`, `permission_id`),
    KEY `idx_permission_id` (`permission_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='角色权限关联表';

-- ============================================================
-- 系统配置表
-- ============================================================
CREATE TABLE IF NOT EXISTS `management_system_config` (
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
CREATE TABLE IF NOT EXISTS `management_operation_log` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID，由snowflake生成',
    `user_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '操作用户ID',
    `action` VARCHAR(100) NOT NULL COMMENT '操作动作，如 admin.user.store',
    `method` VARCHAR(10) NOT NULL DEFAULT '' COMMENT '请求方法: GET|POST|PUT|DELETE',
    `path` VARCHAR(255) NOT NULL DEFAULT '' COMMENT '请求路径',
    `ip` VARCHAR(50) NOT NULL DEFAULT '' COMMENT '操作IP',
    `input` TEXT COMMENT '请求参数（敏感字段已脱敏）',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_action` (`action`),
    KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='操作日志表';

-- ============================================================
-- 插入默认管理员角色
-- ============================================================
INSERT INTO `management_admin_role` (`id`, `name`, `slug`, `description`, `status`) VALUES
(10000000000000001, '超级管理员', 'super_admin', '系统超级管理员，拥有所有权限', 1);
-- ============================================================
-- 权限种子数据
-- Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
--
-- 初始化 RBAC 权限树和角色-权限关联
-- 超级管理员 (super_admin) 自动获得所有权限
-- ============================================================

-- 菜单权限 (type=1)
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000001, 0, '仪表盘',    'dashboard',     1, 'dashboard', '/dashboard',        1, NOW(), NOW()),
(21000000000000002, 0, '用户管理',  'user',           1, 'people',    '/admin/user',        2, NOW(), NOW()),
(21000000000000003, 0, '角色管理',  'role',           1, 'shield',    '/admin/role',        3, NOW(), NOW()),
(21000000000000004, 0, '权限管理',  'permission',     1, 'lock',      '/admin/permission',  4, NOW(), NOW()),
(21000000000000005, 0, '系统配置',  'config',         1, 'settings',  '/admin/config',      5, NOW(), NOW()),
(21000000000000006, 0, '操作日志',  'log',            1, 'article',   '/admin/log',         6, NOW(), NOW());

-- 按钮权限 (type=2)
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000011, 21000000000000002, '批量删除',     'batch.destroy', 2, '', '', 1, NOW(), NOW()),
(21000000000000012, 21000000000000002, '批量启用/禁用', 'batch.status', 2, '', '', 2, NOW(), NOW()),
(21000000000000013, 21000000000000002, '导入用户',     'import.users',  2, '', '', 3, NOW(), NOW()),
(21000000000000014, 21000000000000002, '导出Excel',     'export.excel',  2, '', '', 4, NOW(), NOW()),
(21000000000000015, 21000000000000002, '导出PDF',       'export.pdf',    2, '', '', 5, NOW(), NOW()),
(21000000000000016, 21000000000000002, '文件上传',     'upload',         2, '', '', 6, NOW(), NOW());

-- API 权限 (type=3) — 仪表盘
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000021, 21000000000000001, '查看仪表盘',   'get.admin/dashboard', 3, '', '', 1, NOW(), NOW());

-- API 权限 — 用户管理
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000031, 21000000000000002, '查看用户',     'get.admin/user',             3, '', '', 1, NOW(), NOW()),
(21000000000000032, 21000000000000002, '创建用户',     'post.admin/user',            3, '', '', 2, NOW(), NOW()),
(21000000000000033, 21000000000000002, '更新用户',     'put.admin/user',             3, '', '', 3, NOW(), NOW()),
(21000000000000034, 21000000000000002, '删除用户',     'delete.admin/user',          3, '', '', 4, NOW(), NOW()),
(21000000000000035, 21000000000000002, '批量删除用户', 'post.admin/user/batch/destroy', 3, '', '', 5, NOW(), NOW()),
(21000000000000036, 21000000000000002, '批量启禁用',   'post.admin/user/batch/status',  3, '', '', 6, NOW(), NOW());

-- API 权限 — 角色管理
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000041, 21000000000000003, '查看角色', 'get.admin/role',    3, '', '', 1, NOW(), NOW()),
(21000000000000042, 21000000000000003, '创建角色', 'post.admin/role',   3, '', '', 2, NOW(), NOW()),
(21000000000000043, 21000000000000003, '更新角色', 'put.admin/role',    3, '', '', 3, NOW(), NOW()),
(21000000000000044, 21000000000000003, '删除角色', 'delete.admin/role', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 权限管理
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000051, 21000000000000004, '查看权限', 'get.admin/permission',    3, '', '', 1, NOW(), NOW()),
(21000000000000052, 21000000000000004, '创建权限', 'post.admin/permission',   3, '', '', 2, NOW(), NOW()),
(21000000000000053, 21000000000000004, '更新权限', 'put.admin/permission',    3, '', '', 3, NOW(), NOW()),
(21000000000000054, 21000000000000004, '删除权限', 'delete.admin/permission', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 系统配置
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000061, 21000000000000005, '查看配置', 'get.admin/config',    3, '', '', 1, NOW(), NOW()),
(21000000000000062, 21000000000000005, '创建配置', 'post.admin/config',   3, '', '', 2, NOW(), NOW()),
(21000000000000063, 21000000000000005, '更新配置', 'put.admin/config',    3, '', '', 3, NOW(), NOW()),
(21000000000000064, 21000000000000005, '删除配置', 'delete.admin/config', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 操作日志
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000071, 21000000000000006, '查看日志', 'get.admin/log', 3, '', '', 1, NOW(), NOW());

-- API 权限 — 个人中心
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000081, 0, '个人中心-更新信息', 'put.admin/profile',         3, '', '', 1, NOW(), NOW()),
(21000000000000082, 0, '个人中心-修改密码', 'put.admin/profile/password', 3, '', '', 2, NOW(), NOW()),
(21000000000000083, 0, '个人中心-登出',     'post.admin/profile/logout',  3, '', '', 3, NOW(), NOW());

-- API 权限 — 导出
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000091, 0, '导出Excel', 'post.admin/export/excel', 3, '', '', 1, NOW(), NOW()),
(21000000000000092, 0, '导出PDF',   'post.admin/export/pdf',   3, '', '', 2, NOW(), NOW());

-- API 权限 — 导入
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000093, 0, '导入用户', 'post.admin/import/users', 3, '', '', 1, NOW(), NOW());

-- API 权限 — 上传
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000094, 0, '文件上传', 'post.admin/upload', 3, '', '', 1, NOW(), NOW());

-- ============================================================
-- API 权限 (type=3) — 物业管理业务模块
-- ID 段: 21000000000100xx 起始，每模块一组（查看/创建/更新/删除）
-- parent_id 全部为 0（顶级，列定义 0 表示顶级），slug = 小写方法.路由路径
-- ============================================================

-- API 权限 — 小区管理
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010001, 0, '查看小区', 'get.admin/community',    3, '', '', 1, NOW(), NOW()),
(2100000000010002, 0, '创建小区', 'post.admin/community',   3, '', '', 2, NOW(), NOW()),
(2100000000010003, 0, '更新小区', 'put.admin/community',    3, '', '', 3, NOW(), NOW()),
(2100000000010004, 0, '删除小区', 'delete.admin/community', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 楼栋管理
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010005, 0, '查看楼栋', 'get.admin/building',    3, '', '', 1, NOW(), NOW()),
(2100000000010006, 0, '创建楼栋', 'post.admin/building',   3, '', '', 2, NOW(), NOW()),
(2100000000010007, 0, '更新楼栋', 'put.admin/building',    3, '', '', 3, NOW(), NOW()),
(2100000000010008, 0, '删除楼栋', 'delete.admin/building', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 单元管理
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010009, 0, '查看单元', 'get.admin/unit',    3, '', '', 1, NOW(), NOW()),
(2100000000010010, 0, '创建单元', 'post.admin/unit',   3, '', '', 2, NOW(), NOW()),
(2100000000010011, 0, '更新单元', 'put.admin/unit',    3, '', '', 3, NOW(), NOW()),
(2100000000010012, 0, '删除单元', 'delete.admin/unit', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 户型管理
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010013, 0, '查看户型', 'get.admin/room-type',    3, '', '', 1, NOW(), NOW()),
(2100000000010014, 0, '创建户型', 'post.admin/room-type',   3, '', '', 2, NOW(), NOW()),
(2100000000010015, 0, '更新户型', 'put.admin/room-type',    3, '', '', 3, NOW(), NOW()),
(2100000000010016, 0, '删除户型', 'delete.admin/room-type', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 房产管理
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010017, 0, '查看房产', 'get.admin/room',    3, '', '', 1, NOW(), NOW()),
(2100000000010018, 0, '创建房产', 'post.admin/room',   3, '', '', 2, NOW(), NOW()),
(2100000000010019, 0, '更新房产', 'put.admin/room',    3, '', '', 3, NOW(), NOW()),
(2100000000010020, 0, '删除房产', 'delete.admin/room', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 业主管理
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010021, 0, '查看业主', 'get.admin/owner',    3, '', '', 1, NOW(), NOW()),
(2100000000010022, 0, '创建业主', 'post.admin/owner',   3, '', '', 2, NOW(), NOW()),
(2100000000010023, 0, '更新业主', 'put.admin/owner',    3, '', '', 3, NOW(), NOW()),
(2100000000010024, 0, '删除业主', 'delete.admin/owner', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 租户管理
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010025, 0, '查看租户', 'get.admin/tenant',    3, '', '', 1, NOW(), NOW()),
(2100000000010026, 0, '创建租户', 'post.admin/tenant',   3, '', '', 2, NOW(), NOW()),
(2100000000010027, 0, '更新租户', 'put.admin/tenant',    3, '', '', 3, NOW(), NOW()),
(2100000000010028, 0, '删除租户', 'delete.admin/tenant', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 费用类型
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010029, 0, '查看费用类型', 'get.admin/fee-type',    3, '', '', 1, NOW(), NOW()),
(2100000000010030, 0, '创建费用类型', 'post.admin/fee-type',   3, '', '', 2, NOW(), NOW()),
(2100000000010031, 0, '更新费用类型', 'put.admin/fee-type',    3, '', '', 3, NOW(), NOW()),
(2100000000010032, 0, '删除费用类型', 'delete.admin/fee-type', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 账单管理
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010033, 0, '查看账单', 'get.admin/fee-bill',    3, '', '', 1, NOW(), NOW()),
(2100000000010034, 0, '创建账单', 'post.admin/fee-bill',   3, '', '', 2, NOW(), NOW()),
(2100000000010035, 0, '更新账单', 'put.admin/fee-bill',    3, '', '', 3, NOW(), NOW()),
(2100000000010036, 0, '删除账单', 'delete.admin/fee-bill', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 公告管理
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010041, 0, '查看公告', 'get.admin/announcement',    3, '', '', 1, NOW(), NOW()),
(2100000000010042, 0, '创建公告', 'post.admin/announcement',   3, '', '', 2, NOW(), NOW()),
(2100000000010043, 0, '更新公告', 'put.admin/announcement',    3, '', '', 3, NOW(), NOW()),
(2100000000010044, 0, '删除公告', 'delete.admin/announcement', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 停车位管理
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010045, 0, '查看停车位', 'get.admin/parking-space',    3, '', '', 1, NOW(), NOW()),
(2100000000010046, 0, '创建停车位', 'post.admin/parking-space',   3, '', '', 2, NOW(), NOW()),
(2100000000010047, 0, '更新停车位', 'put.admin/parking-space',    3, '', '', 3, NOW(), NOW()),
(2100000000010048, 0, '删除停车位', 'delete.admin/parking-space', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 车辆管理
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010049, 0, '查看车辆', 'get.admin/parking-vehicle',    3, '', '', 1, NOW(), NOW()),
(2100000000010050, 0, '创建车辆', 'post.admin/parking-vehicle',   3, '', '', 2, NOW(), NOW()),
(2100000000010051, 0, '更新车辆', 'put.admin/parking-vehicle',    3, '', '', 3, NOW(), NOW()),
(2100000000010052, 0, '删除车辆', 'delete.admin/parking-vehicle', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 设备管理
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010053, 0, '查看设备', 'get.admin/equipment',    3, '', '', 1, NOW(), NOW()),
(2100000000010054, 0, '创建设备', 'post.admin/equipment',   3, '', '', 2, NOW(), NOW()),
(2100000000010055, 0, '更新设备', 'put.admin/equipment',    3, '', '', 3, NOW(), NOW()),
(2100000000010056, 0, '删除设备', 'delete.admin/equipment', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 设备维保
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010057, 0, '查看维保', 'get.admin/equipment-maintenance',    3, '', '', 1, NOW(), NOW()),
(2100000000010058, 0, '创建维保', 'post.admin/equipment-maintenance',   3, '', '', 2, NOW(), NOW()),
(2100000000010059, 0, '更新维保', 'put.admin/equipment-maintenance',    3, '', '', 3, NOW(), NOW()),
(2100000000010060, 0, '删除维保', 'delete.admin/equipment-maintenance', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 安防巡逻
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010065, 0, '查看巡逻', 'get.admin/security-patrol',    3, '', '', 1, NOW(), NOW()),
(2100000000010066, 0, '创建巡逻', 'post.admin/security-patrol',   3, '', '', 2, NOW(), NOW()),
(2100000000010067, 0, '更新巡逻', 'put.admin/security-patrol',    3, '', '', 3, NOW(), NOW()),
(2100000000010068, 0, '删除巡逻', 'delete.admin/security-patrol', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 保洁区域
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010069, 0, '查看保洁区域', 'get.admin/cleaning-area',    3, '', '', 1, NOW(), NOW()),
(2100000000010070, 0, '创建保洁区域', 'post.admin/cleaning-area',   3, '', '', 2, NOW(), NOW()),
(2100000000010071, 0, '更新保洁区域', 'put.admin/cleaning-area',    3, '', '', 3, NOW(), NOW()),
(2100000000010072, 0, '删除保洁区域', 'delete.admin/cleaning-area', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 绿化区域
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010073, 0, '查看绿化区域', 'get.admin/green-area',    3, '', '', 1, NOW(), NOW()),
(2100000000010074, 0, '创建绿化区域', 'post.admin/green-area',   3, '', '', 2, NOW(), NOW()),
(2100000000010075, 0, '更新绿化区域', 'put.admin/green-area',    3, '', '', 3, NOW(), NOW()),
(2100000000010076, 0, '删除绿化区域', 'delete.admin/green-area', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 员工管理
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010085, 0, '查看员工', 'get.admin/staff',    3, '', '', 1, NOW(), NOW()),
(2100000000010086, 0, '创建员工', 'post.admin/staff',   3, '', '', 2, NOW(), NOW()),
(2100000000010087, 0, '更新员工', 'put.admin/staff',    3, '', '', 3, NOW(), NOW()),
(2100000000010088, 0, '删除员工', 'delete.admin/staff', 3, '', '', 4, NOW(), NOW());

-- API 权限 — 业务模块特殊端点
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010113, 0, '房产层级树',       'get.admin/room/tree',               3, '', '', 1, NOW(), NOW()),
(2100000000010114, 0, '业主批量导入',     'post.admin/owner/batch/import',     3, '', '', 2, NOW(), NOW()),
(2100000000010115, 0, '业主批量删除',     'post.admin/owner/batch/destroy',    3, '', '', 3, NOW(), NOW()),
(2100000000010116, 0, '账单批量生成',     'post.admin/fee-bill/batch/generate', 3, '', '', 4, NOW(), NOW()),
(2100000000010117, 0, '查看缴费记录',     'get.admin/fee-payment',             3, '', '', 5, NOW(), NOW()),
(2100000000010118, 0, '线下收款',         'post.admin/fee-payment/offline',    3, '', '', 6, NOW(), NOW()),
(2100000000010125, 0, '查看巡逻记录',     'get.admin/patrol-record',           3, '', '', 13, NOW(), NOW()),
(2100000000010126, 0, '创建巡逻记录',     'post.admin/patrol-record',          3, '', '', 14, NOW(), NOW()),
(2100000000010127, 0, '查看保洁记录',     'get.admin/cleaning-record',         3, '', '', 15, NOW(), NOW()),
(2100000000010128, 0, '创建保洁记录',     'post.admin/cleaning-record',        3, '', '', 16, NOW(), NOW()),
(2100000000010129, 0, '查看绿化养护',     'get.admin/green-maintenance',       3, '', '', 17, NOW(), NOW()),
(2100000000010130, 0, '创建绿化养护',     'post.admin/green-maintenance',      3, '', '', 18, NOW(), NOW()),
(2100000000010159, 0, '查看停车记录',     'get.admin/parking-record',          3, '', '', 47, NOW(), NOW()),
(2100000000010160, 0, '物业仪表盘统计',   'get.admin/dashboard/property',      3, '', '', 48, NOW(), NOW());

-- API 权限 — 员工批量状态
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010169, 0, '员工批量启禁用', 'post.admin/staff/batch/status', 3, '', '', 1, NOW(), NOW());

-- API 权限 — 支付管理
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010201, 0, '查看支付订单',       'get.admin/payment-order',           3, '', '', 1, NOW(), NOW()),
(2100000000010202, 0, '支付订单退款',       'post.admin/payment-order/refund',   3, '', '', 2, NOW(), NOW()),
(2100000000010203, 0, '支付统计',           'get.admin/payment-order/statistics', 3, '', '', 3, NOW(), NOW());

-- API 权限 — 报表中心
-- GET /admin/report（ReportController::index）经 AdminPermission 中间件按「方法.路径」鉴权，
-- 缺此种子时超级管理员也会 403（slug 必须在 permission 表中存在）
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010204, 0, '查看报表',           'get.admin/report',                  3, '', '', 1, NOW(), NOW());

-- API 权限 — 物业数据导出（补种）
-- POST /admin/export/property-excel（ExportController::propertyExcel，路由 route.php:110 与 API 文档均已存在），
-- 同样经 AdminPermission 按「方法.路径」鉴权：slug 缺失时任何角色（含超管）一律 403。
-- AdminPermission.php:39 的前缀回退只退到 post.admin/export，种子中也没有该级 slug，故必须精确补此条。
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010205, 0, '导出物业数据',       'post.admin/export/property-excel',  3, '', '', 3, NOW(), NOW());

-- API 权限 — 动作型端点补种（无任何祖先 slug 可命中者，必须显式登记）
-- 背景：部分动作型端点的种子写成了不带参数的逻辑路径（如 put.admin/xxx/{hashid}），
-- 而路由带 {hashid}；待 AdminPermission 先剥离 `{...}` 段再回退即可命中，无需在此重复登记。
-- 以下 3 条在两种匹配方式下都没有祖先可命中，故在此补条：
--   POST /admin/payment-order/create、POST /admin/payment-order/reconcile → PaymentController
--   GET  /admin/profile（ProfileController::show）→ 个人中心查看
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(2100000000010206, 0, '创建支付订单',       'post.admin/payment-order/create',    3, '', '', 4, NOW(), NOW()),
(2100000000010207, 0, '支付订单对账',       'post.admin/payment-order/reconcile', 3, '', '', 5, NOW(), NOW()),
(2100000000010208, 0, '个人中心-查看',      'get.admin/profile',                  3, '', '', 1, NOW(), NOW());

-- ============================================================
-- 超级管理员角色 (ID=10000000000000001) 关联所有权限
-- ============================================================
INSERT INTO `management_admin_role_permission` (`role_id`, `permission_id`)
SELECT 10000000000000001, `id` FROM `management_admin_permission`
WHERE `id` NOT IN (
    SELECT `permission_id` FROM `management_admin_role_permission` WHERE `role_id` = 10000000000000001
);
-- ============================================================
-- 操作日志表增加操作来源端字段
-- Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
-- ============================================================

ALTER TABLE `management_operation_log`
ADD COLUMN `source` VARCHAR(20) NOT NULL DEFAULT 'web' COMMENT '操作来源端: ipados|macos|windows|linux|ios|android|harmonyos|web' AFTER `ip`;

ALTER TABLE `management_operation_log`
ADD KEY `idx_source` (`source`);
-- ============================================================
-- Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
-- 迁移: 物业管理系统 — 第1批核心业务表（14张）
-- 主键 id 使用 BIGINT UNSIGNED NOT NULL，由 snowflake-php 应用层生成
-- ============================================================

-- 1. 小区/社区表
CREATE TABLE IF NOT EXISTS `management_community` (
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
INSERT IGNORE INTO `management_platform_tenant` (`id`, `name`, `status`, `created_at`, `updated_at`)
VALUES (1, '默认租户', 1, NOW(), NOW());
UPDATE `management_community` SET `tenant_id` = 1 WHERE `tenant_id` = 0;
UPDATE `management_admin_user` SET `tenant_id` = 1 WHERE `tenant_id` = 0;

-- 2. 楼栋表
CREATE TABLE IF NOT EXISTS `management_building` (
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
CREATE TABLE IF NOT EXISTS `management_unit` (
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
CREATE TABLE IF NOT EXISTS `management_room_type` (
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
CREATE TABLE IF NOT EXISTS `management_room` (
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
CREATE TABLE IF NOT EXISTS `management_owner` (
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
CREATE TABLE IF NOT EXISTS `management_room_owner` (
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
CREATE TABLE IF NOT EXISTS `management_tenant` (
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
CREATE TABLE IF NOT EXISTS `management_fee_type` (
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
CREATE TABLE IF NOT EXISTS `management_fee_bill` (
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
CREATE TABLE IF NOT EXISTS `management_fee_payment` (
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
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_bill_id` (`bill_id`),
    KEY `idx_owner_id` (`owner_id`),
    KEY `idx_payment_number` (`payment_number`),
    KEY `idx_paid_at` (`paid_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='缴费记录表';

-- 14. 公告通知表
CREATE TABLE IF NOT EXISTS `management_announcement` (
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
CREATE TABLE IF NOT EXISTS `management_parking_space` (
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
CREATE TABLE IF NOT EXISTS `management_parking_vehicle` (
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
CREATE TABLE IF NOT EXISTS `management_parking_record` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `vehicle_id` BIGINT UNSIGNED NOT NULL COMMENT '车辆ID',
    `space_id` BIGINT UNSIGNED NOT NULL COMMENT '车位ID',
    `entry_time` DATETIME DEFAULT NULL COMMENT '入场时间',
    `exit_time` DATETIME DEFAULT NULL COMMENT '出场时间',
    `duration` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '停留时长(分钟)',
    `fee` DECIMAL(8,2) NOT NULL DEFAULT 0.00 COMMENT '停车费(临停)',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_vehicle_id` (`vehicle_id`),
    KEY `idx_entry_time` (`entry_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='停车记录表';

-- 18. 设备表
CREATE TABLE IF NOT EXISTS `management_equipment` (
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
    KEY `idx_community_status` (`community_id`, `status`),
    KEY `idx_category` (`category`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='设备表';

-- 19. 设备维保表
CREATE TABLE IF NOT EXISTS `management_equipment_maintenance` (
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

-- 25. 安保巡逻路线表
CREATE TABLE IF NOT EXISTS `management_security_patrol` (
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
CREATE TABLE IF NOT EXISTS `management_patrol_record` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `patrol_id` BIGINT UNSIGNED NOT NULL COMMENT '巡逻路线ID',
    `staff_id` BIGINT UNSIGNED NOT NULL COMMENT '巡逻人员ID',
    `started_at` DATETIME DEFAULT NULL COMMENT '开始时间',
    `ended_at` DATETIME DEFAULT NULL COMMENT '结束时间',
    `duration` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '巡逻时长(分钟)',
    `checkpoints_done` TEXT COMMENT '已完成打卡点 (JSON)',
    `abnormal_note` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '异常备注',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`), KEY `idx_patrol_id` (`patrol_id`), KEY `idx_staff_id` (`staff_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='巡逻记录表';

-- 27. 保洁区域表
CREATE TABLE IF NOT EXISTS `management_cleaning_area` (
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
CREATE TABLE IF NOT EXISTS `management_cleaning_record` (
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
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`), KEY `idx_area_id` (`area_id`), KEY `idx_cleaned_at` (`cleaned_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='保洁记录表';

-- 29. 绿化区域表
CREATE TABLE IF NOT EXISTS `management_green_area` (
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
CREATE TABLE IF NOT EXISTS `management_green_maintenance` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID',
    `area_id` BIGINT UNSIGNED NOT NULL COMMENT '绿化区域ID',
    `maintenance_type` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '类型: 1=浇水 2=修剪 3=施肥 4=除虫 5=补种',
    `staff_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '养护人员ID',
    `description` VARCHAR(500) NOT NULL DEFAULT '' COMMENT '养护描述',
    `cost` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '费用',
    `maintained_at` DATETIME DEFAULT NULL COMMENT '养护时间',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`), KEY `idx_area_id` (`area_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='绿化养护记录表';

-- 35. 员工表
CREATE TABLE IF NOT EXISTS `management_staff` (
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
-- 迁移: 功能扩展（支付）
-- ============================================================

-- ============================================================
-- 3. 支付集成
-- ============================================================

-- 支付订单表
CREATE TABLE IF NOT EXISTS `management_payment_order` (
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

-- 开放 API Key 表（service 端入站对外接口鉴权，X-API-Key 头）
CREATE TABLE IF NOT EXISTS `management_api_key` (
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

-- ============================================================
-- 查询索引补充（P11 审计）— 增量场景（表已存在）幂等追加
-- 注: MySQL 不支持 ADD INDEX IF NOT EXISTS（MariaDB 扩展），故用 INFORMATION_SCHEMA 探测 + 动态 SQL 保证可重复执行
-- 新建库由上方 CREATE TABLE 内 KEY 直接建立，此处仅覆盖旧库
-- Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
-- ============================================================




SET @ix := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'management_equipment' AND index_name = 'idx_community_status');
SET @sql := IF(@ix = 0, 'ALTER TABLE `management_equipment` ADD INDEX `idx_community_status` (`community_id`, `status`)', 'DO 0');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
