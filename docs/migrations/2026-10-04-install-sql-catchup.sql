-- ============================================================
-- 存量库补齐：install.sql 的修正补齐（2026-10-04）
-- Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
-- ============================================================
-- 背景：install.sql 原有 19 张有 created_at 的表缺 updated_at 列，而对应 Eloquent 模型
-- 的 timestamps 默认开启 —— 任何走模型写入的路径都报 1054 Unknown column 'updated_at'
-- （报修派单落 repair_progress 时实测触发）。新建库已由 install.sql 直接带列；
-- 本文件供已建库一次性补齐，执行后与 install.sql 的 schema 等价。
--
-- 用法：mysql --force -uroot -p management < docs/migrations/2026-10-04-install-sql-catchup.sql
-- 幂等性：① 已补过的列会报 1060 Duplicate column name —— 可忽略，但要用 --force（不加则 mysql
-- 在首条 1060 处中断，后面的段不会执行）；②③ 段本身幂等（slug 级 WHERE NOT EXISTS / 去重无重复即
-- 0 行 / 唯一索引按 information_schema 判定后再加），可重复执行。
-- 注意客户端字符集：中文权限名要 --default-character-set=utf8mb4。
-- ============================================================

-- ---------- 1. 补 19 张表的 updated_at（位置与 install.sql 一致：紧跟 created_at）----------
ALTER TABLE `management_operation_log` ADD COLUMN `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间' AFTER `created_at`;
ALTER TABLE `management_fee_payment` ADD COLUMN `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间' AFTER `created_at`;
ALTER TABLE `management_repair_progress` ADD COLUMN `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间' AFTER `created_at`;
ALTER TABLE `management_parking_record` ADD COLUMN `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间' AFTER `created_at`;
ALTER TABLE `management_patrol_record` ADD COLUMN `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间' AFTER `created_at`;
ALTER TABLE `management_cleaning_record` ADD COLUMN `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间' AFTER `created_at`;
ALTER TABLE `management_green_maintenance` ADD COLUMN `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间' AFTER `created_at`;
ALTER TABLE `management_activity_signup` ADD COLUMN `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间' AFTER `created_at`;
ALTER TABLE `management_energy_record` ADD COLUMN `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间' AFTER `created_at`;
ALTER TABLE `management_notification` ADD COLUMN `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间' AFTER `created_at`;
ALTER TABLE `management_approval_record` ADD COLUMN `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间' AFTER `created_at`;
ALTER TABLE `management_vote_option` ADD COLUMN `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间' AFTER `created_at`;
ALTER TABLE `management_vote_record` ADD COLUMN `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间' AFTER `created_at`;
ALTER TABLE `management_collection_strategy` ADD COLUMN `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间' AFTER `created_at`;
ALTER TABLE `management_collection_record` ADD COLUMN `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间' AFTER `created_at`;
ALTER TABLE `management_inspection_checkpoint` ADD COLUMN `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间' AFTER `created_at`;
ALTER TABLE `management_mall_category` ADD COLUMN `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间' AFTER `created_at`;
ALTER TABLE `management_group_community` ADD COLUMN `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间' AFTER `created_at`;
ALTER TABLE `management_chat_record` ADD COLUMN `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间' AFTER `created_at`;

-- ---------- 2. 补 RBAC 权限种子（原库缺 slug，超管也 403）----------
-- 与 install.sql「API 权限 — 报表中心 / 物业数据导出 / 动作型端点」同格式。
-- 幂等**不能只用 INSERT IGNORE**：`slug` 上没有唯一索引，若库里已存在同 slug 但不同 id 的行
-- （管理库的 /admin/report 就是这样：既有行 id=21000000000000095），IGNORE 只挡主键/唯一键冲突，
-- 仍会插出第二行同 slug 的权限。故统一改为 INSERT ... SELECT ... WHERE NOT EXISTS(slug)。
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`)
SELECT 2100000000010204, 0, '查看报表', 'get.admin/report', 3, '', '', 1, NOW(), NOW() FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `management_admin_permission` WHERE `slug` = 'get.admin/report');
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`)
SELECT 2100000000010205, 0, '导出物业数据', 'post.admin/export/property-excel', 3, '', '', 3, NOW(), NOW() FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `management_admin_permission` WHERE `slug` = 'post.admin/export/property-excel');
-- 无任何祖先 slug 可命中的 3 条动作型端点（其余 11 条由 AdminPermission 剥 {…} 段后命中既有种子）
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`)
SELECT 2100000000010206, 0, '创建支付订单', 'post.admin/payment-order/create', 3, '', '', 4, NOW(), NOW() FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `management_admin_permission` WHERE `slug` = 'post.admin/payment-order/create');
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`)
SELECT 2100000000010207, 0, '支付订单对账', 'post.admin/payment-order/reconcile', 3, '', '', 5, NOW(), NOW() FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `management_admin_permission` WHERE `slug` = 'post.admin/payment-order/reconcile');
INSERT INTO `management_admin_permission` (`id`, `parent_id`, `name`, `slug`, `type`, `icon`, `path`, `sort`, `created_at`, `updated_at`)
SELECT 2100000000010208, 0, '个人中心-查看', 'get.admin/profile', 3, '', '', 1, NOW(), NOW() FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM `management_admin_permission` WHERE `slug` = 'get.admin/profile');

-- 与 install.sql 同一授权逻辑：超管获得所有尚未关联的权限（含上面两条）
INSERT INTO `management_admin_role_permission` (`role_id`, `permission_id`)
SELECT 10000000000000001, `id` FROM `management_admin_permission`
WHERE `id` NOT IN (
    SELECT `permission_id` FROM `management_admin_role_permission` WHERE `role_id` = 10000000000000001
);

-- ---------- 3. permission.slug 加唯一索引（先并重复，再加约束）----------
-- 背景：role 表早有 `uk_slug`，permission 表却只有普通索引 —— 没有唯一约束时，
-- `INSERT IGNORE`（只挡主键/唯一键）挡不住「同 slug 不同 id」的重复行，2026-10-04 实测撞出过。
-- 先做去重保护：每个重复 slug 保留 id 最小的一行，其余行的授权并过去（INSERT IGNORE 避开
-- (role_id,permission_id) 主键冲突）再删行。无重复时这几条语句影响 0 行，可反复执行。
-- 注意：slug 比较只在同表内做（同 column 同 collation），临时表只存 BIGINT —— 若把 slug 拷进
-- 临时表再 JOIN，会撞 MySQL 8 的库默认 collation(utf8mb4_0900_ai_ci) 与表定义
-- (utf8mb4_unicode_ci) 不一致 → ERROR 1267，去重全废（实测踩过）。
DROP TEMPORARY TABLE IF EXISTS `tmp_dup_map`;
CREATE TEMPORARY TABLE `tmp_dup_map` (`dup_id` BIGINT UNSIGNED NOT NULL PRIMARY KEY, `keep_id` BIGINT UNSIGNED NOT NULL);
INSERT INTO `tmp_dup_map` (`dup_id`, `keep_id`)
SELECT p.`id`, m.`keep_id` FROM `management_admin_permission` p
    JOIN (SELECT `slug`, MIN(`id`) AS `keep_id` FROM `management_admin_permission` GROUP BY `slug` HAVING COUNT(*) > 1) m
      ON m.`slug` = p.`slug`
    WHERE p.`id` <> m.`keep_id`;
INSERT IGNORE INTO `management_admin_role_permission` (`role_id`, `permission_id`)
SELECT rp.`role_id`, t.`keep_id` FROM `management_admin_role_permission` rp JOIN `tmp_dup_map` t ON t.`dup_id` = rp.`permission_id`;
DELETE rp FROM `management_admin_role_permission` rp JOIN `tmp_dup_map` t ON t.`dup_id` = rp.`permission_id`;
DELETE p FROM `management_admin_permission` p JOIN `tmp_dup_map` t ON t.`dup_id` = p.`id`;
DROP TEMPORARY TABLE IF EXISTS `tmp_dup_map`;

-- 加约束用 information_schema 判定做成幂等（重复执行不再依赖 --force 容忍 1061）
SET @uk_exists := (SELECT COUNT(*) FROM information_schema.statistics
                   WHERE table_schema = DATABASE() AND table_name = 'management_admin_permission' AND index_name = 'uk_slug');
SET @ddl := IF(@uk_exists = 0,
    'ALTER TABLE `management_admin_permission` ADD UNIQUE KEY `uk_slug` (`slug`)',
    'SELECT ''uk_slug 已存在，跳过'' AS msg');
PREPARE stmt_uk FROM @ddl; EXECUTE stmt_uk; DEALLOCATE PREPARE stmt_uk;