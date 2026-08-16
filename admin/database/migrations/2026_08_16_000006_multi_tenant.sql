-- ============================================================
-- Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
-- 迁移: 多租户数据层（方案A 共享库 + tenant_id 行隔离）
--  1. erik_platform_tenant 租户表（避名 erik_tenant 租客表）
--  2. erik_community / erik_admin_user 加 tenant_id 列（0 = 平台）
--  3. 默认租户初始化并回填存量数据（幂等，可重复执行）
-- 增量升级: 按文件名序号顺序执行；全量安装仍用 docs/install.sql
-- ============================================================

-- 1. 租户表
CREATE TABLE IF NOT EXISTS `erik_platform_tenant` (
    `id` BIGINT UNSIGNED NOT NULL COMMENT '主键ID（默认租户固定 1）',
    `name` VARCHAR(100) NOT NULL COMMENT '租户名称',
    `status` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '状态: 0=停用 1=正常',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='SaaS租户表（与租客表 erik_tenant 语义区分）';

-- 2. 加列（INFORMATION_SCHEMA 守护，幂等可重复执行）
SET @col := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'erik_community' AND COLUMN_NAME = 'tenant_id');
SET @sql := IF(@col = 0,
    'ALTER TABLE `erik_community` ADD COLUMN `tenant_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT ''所属租户ID, 0=平台'', ADD KEY `idx_tenant_community` (`tenant_id`, `id`)',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @col := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'erik_admin_user' AND COLUMN_NAME = 'tenant_id');
SET @sql := IF(@col = 0,
    'ALTER TABLE `erik_admin_user` ADD COLUMN `tenant_id` BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT ''所属租户ID, 0=平台超级管理员'', ADD KEY `idx_tenant_id` (`tenant_id`)',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 3. 默认租户 + 存量回填（存量数据全部归入默认租户，不删不改业务数据）
INSERT IGNORE INTO `erik_platform_tenant` (`id`, `name`, `status`, `created_at`, `updated_at`)
VALUES (1, '默认租户', 1, NOW(), NOW());

UPDATE `erik_community` SET `tenant_id` = 1 WHERE `tenant_id` = 0;
UPDATE `erik_admin_user` SET `tenant_id` = 1 WHERE `tenant_id` = 0;

-- 回填校验（孤儿数据应为 0）：
-- SELECT COUNT(*) AS orphan_community FROM `erik_community` WHERE `tenant_id` = 0;
-- SELECT COUNT(*) AS orphan_admin FROM `erik_admin_user` WHERE `tenant_id` = 0;
