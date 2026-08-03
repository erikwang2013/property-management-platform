-- ============================================================
-- Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
-- 迁移: 初始化管理后台核心数据表
-- 注意: 主键 id 使用 BIGINT 非自增，由 snowflake-php 在应用层生成
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
    `last_login_at` DATETIME DEFAULT NULL COMMENT '最后登录时间',
    `last_login_ip` VARCHAR(50) NOT NULL DEFAULT '' COMMENT '最后登录IP',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at` DATETIME DEFAULT NULL COMMENT '软删除标记',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_username` (`username`),
    KEY `idx_status` (`status`),
    KEY `idx_deleted_at` (`deleted_at`),
    KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='管理用户表';

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
(21000000000000001, NULL, '仪表盘',    'dashboard',     1, 'dashboard', '/dashboard',        1, NOW(), NOW()),
(21000000000000002, NULL, '用户管理',  'user',           1, 'people',    '/admin/user',        2, NOW(), NOW()),
(21000000000000003, NULL, '角色管理',  'role',           1, 'shield',    '/admin/role',        3, NOW(), NOW()),
(21000000000000004, NULL, '权限管理',  'permission',     1, 'lock',      '/admin/permission',  4, NOW(), NOW()),
(21000000000000005, NULL, '系统配置',  'config',         1, 'settings',  '/admin/config',      5, NOW(), NOW()),
(21000000000000006, NULL, '操作日志',  'log',            1, 'article',   '/admin/log',         6, NOW(), NOW());

-- 按钮权限 (type=2)
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000011, 21000000000000002, '批量删除',     'batch.destroy', 2, NULL, NULL, 1, NOW(), NOW()),
(21000000000000012, 21000000000000002, '批量启用/禁用', 'batch.status', 2, NULL, NULL, 2, NOW(), NOW()),
(21000000000000013, 21000000000000002, '导入用户',     'import.users',  2, NULL, NULL, 3, NOW(), NOW()),
(21000000000000014, 21000000000000002, '导出Excel',     'export.excel',  2, NULL, NULL, 4, NOW(), NOW()),
(21000000000000015, 21000000000000002, '导出PDF',       'export.pdf',    2, NULL, NULL, 5, NOW(), NOW()),
(21000000000000016, 21000000000000002, '文件上传',     'upload',         2, NULL, NULL, 6, NOW(), NOW());

-- API 权限 (type=3) — 仪表盘
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000021, 21000000000000001, '查看仪表盘',   'get.admin/dashboard', 3, NULL, NULL, 1, NOW(), NOW());

-- API 权限 — 用户管理
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000031, 21000000000000002, '查看用户',     'get.admin/user',             3, NULL, NULL, 1, NOW(), NOW()),
(21000000000000032, 21000000000000002, '创建用户',     'post.admin/user',            3, NULL, NULL, 2, NOW(), NOW()),
(21000000000000033, 21000000000000002, '更新用户',     'put.admin/user',             3, NULL, NULL, 3, NOW(), NOW()),
(21000000000000034, 21000000000000002, '删除用户',     'delete.admin/user',          3, NULL, NULL, 4, NOW(), NOW()),
(21000000000000035, 21000000000000002, '批量删除用户', 'post.admin/user/batch/destroy', 3, NULL, NULL, 5, NOW(), NOW()),
(21000000000000036, 21000000000000002, '批量启禁用',   'post.admin/user/batch/status',  3, NULL, NULL, 6, NOW(), NOW());

-- API 权限 — 角色管理
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000041, 21000000000000003, '查看角色', 'get.admin/role',    3, NULL, NULL, 1, NOW(), NOW()),
(21000000000000042, 21000000000000003, '创建角色', 'post.admin/role',   3, NULL, NULL, 2, NOW(), NOW()),
(21000000000000043, 21000000000000003, '更新角色', 'put.admin/role',    3, NULL, NULL, 3, NOW(), NOW()),
(21000000000000044, 21000000000000003, '删除角色', 'delete.admin/role', 3, NULL, NULL, 4, NOW(), NOW());

-- API 权限 — 权限管理
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000051, 21000000000000004, '查看权限', 'get.admin/permission',    3, NULL, NULL, 1, NOW(), NOW()),
(21000000000000052, 21000000000000004, '创建权限', 'post.admin/permission',   3, NULL, NULL, 2, NOW(), NOW()),
(21000000000000053, 21000000000000004, '更新权限', 'put.admin/permission',    3, NULL, NULL, 3, NOW(), NOW()),
(21000000000000054, 21000000000000004, '删除权限', 'delete.admin/permission', 3, NULL, NULL, 4, NOW(), NOW());

-- API 权限 — 系统配置
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000061, 21000000000000005, '查看配置', 'get.admin/config',    3, NULL, NULL, 1, NOW(), NOW()),
(21000000000000062, 21000000000000005, '创建配置', 'post.admin/config',   3, NULL, NULL, 2, NOW(), NOW()),
(21000000000000063, 21000000000000005, '更新配置', 'put.admin/config',    3, NULL, NULL, 3, NOW(), NOW()),
(21000000000000064, 21000000000000005, '删除配置', 'delete.admin/config', 3, NULL, NULL, 4, NOW(), NOW());

-- API 权限 — 操作日志
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000071, 21000000000000006, '查看日志', 'get.admin/log', 3, NULL, NULL, 1, NOW(), NOW());

-- API 权限 — 个人中心
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000081, NULL, '个人中心-更新信息', 'put.admin/profile',         3, NULL, NULL, 1, NOW(), NOW()),
(21000000000000082, NULL, '个人中心-修改密码', 'put.admin/profile/password', 3, NULL, NULL, 2, NOW(), NOW()),
(21000000000000083, NULL, '个人中心-登出',     'post.admin/profile/logout',  3, NULL, NULL, 3, NOW(), NOW());

-- API 权限 — 导出
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000091, NULL, '导出Excel', 'post.admin/export/excel', 3, NULL, NULL, 1, NOW(), NOW()),
(21000000000000092, NULL, '导出PDF',   'post.admin/export/pdf',   3, NULL, NULL, 2, NOW(), NOW());

-- API 权限 — 导入
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000093, NULL, '导入用户', 'post.admin/import/users', 3, NULL, NULL, 1, NOW(), NOW());

-- API 权限 — 上传
INSERT INTO `erik_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`) VALUES
(21000000000000094, NULL, '文件上传', 'post.admin/upload', 3, NULL, NULL, 1, NOW(), NOW());

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
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at` DATETIME DEFAULT NULL COMMENT '软删除',
    PRIMARY KEY (`id`),
    KEY `idx_status` (`status`),
    KEY `idx_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='小区表';

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
