-- ============================================================
-- 审计修复：账单周期唯一索引 + 业主手机号盲索引 + 支付实际入账金额 + 退款幂等键（2026-10-30）
-- Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
-- ============================================================
-- 用法：mysql --default-character-set=utf8mb4 -uroot -p management < docs/migrations/2026-10-30-audit-fix-schema.sql
--
-- 幂等：MySQL 8 没有 CREATE INDEX IF NOT EXISTS，故所有 DDL 先查 information_schema，
-- 再用 PREPARE/EXECUTE 只在缺失时执行，可重复运行。
-- 第 4 节「历史账单状态归一化」是一次性数据升级：以 management_system_config 的
-- migration/2026_10_30_fee_bill_status_v1 标记为闸门，仅在标记首次写入时执行一次；
-- 之后重跑本脚本（deploy.sh 每次部署都会执行）不会再改动账单状态。
--
-- 注意：management_fee_bill 已存在重复的 (room_id, fee_type_id, start_date) 行时，
-- 唯一索引无法创建（ERROR 1062）。本脚本不会自动删除任何数据；先执行下面的 SELECT
-- 找出重复行，人工合并/清理后重跑本脚本。start_date 为 NULL 的行不参与唯一冲突
-- （MySQL 唯一索引允许多个 NULL）。
--
--   SELECT room_id, fee_type_id, start_date, COUNT(*) AS cnt, GROUP_CONCAT(id) AS ids
--   FROM management_fee_bill
--   GROUP BY room_id, fee_type_id, start_date
--   HAVING COUNT(*) > 1;
-- ============================================================

-- ---------- 1. management_owner：手机号盲索引列 + 普通索引 ----------
SET @col_exists := (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'management_owner' AND column_name = 'phone_hash');
SET @ddl := IF(@col_exists = 0,
    'ALTER TABLE `management_owner` ADD COLUMN `phone_hash` CHAR(64) NOT NULL DEFAULT '''' COMMENT ''手机号盲索引(SHA-256)'' AFTER `phone`',
    'SELECT ''phone_hash 列已存在，跳过'' AS msg');
PREPARE stmt_col FROM @ddl; EXECUTE stmt_col; DEALLOCATE PREPARE stmt_col;

SET @idx_exists := (SELECT COUNT(*) FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'management_owner' AND index_name = 'idx_phone_hash');
SET @ddl := IF(@idx_exists = 0,
    'ALTER TABLE `management_owner` ADD KEY `idx_phone_hash` (`phone_hash`)',
    'SELECT ''idx_phone_hash 索引已存在，跳过'' AS msg');
PREPARE stmt_idx FROM @ddl; EXECUTE stmt_idx; DEALLOCATE PREPARE stmt_idx;

-- ---------- 2. management_fee_bill：账单周期唯一索引 ----------
-- 有输出即存在重复行，必须先人工去重（脚本不删数据）；NULL 组仅提示，不阻塞唯一索引
SELECT room_id, fee_type_id, start_date, COUNT(*) AS cnt, GROUP_CONCAT(id) AS ids
FROM management_fee_bill
GROUP BY room_id, fee_type_id, start_date
HAVING COUNT(*) > 1;

SET @uk_exists := (SELECT COUNT(*) FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'management_fee_bill' AND index_name = 'uk_room_fee_period');
-- 唯一索引允许多个 NULL，故 start_date IS NULL 的重复组不阻塞建索引
SET @dup_rows := (SELECT COUNT(*) FROM (
    SELECT 1 FROM management_fee_bill
    WHERE start_date IS NOT NULL
    GROUP BY room_id, fee_type_id, start_date
    HAVING COUNT(*) > 1
) AS dup);
SET @ddl := IF(@uk_exists = 0,
    IF(@dup_rows = 0,
        'ALTER TABLE `management_fee_bill` ADD UNIQUE KEY `uk_room_fee_period` (`room_id`,`fee_type_id`,`start_date`)',
        'SELECT ''management_fee_bill 存在重复周期行，已跳过唯一索引；请先去重后重跑本脚本'' AS msg'),
    'SELECT ''uk_room_fee_period 已存在，跳过'' AS msg');
PREPARE stmt_uk FROM @ddl; EXECUTE stmt_uk; DEALLOCATE PREPARE stmt_uk;

-- ---------- 3. management_payment_order：实际入账金额列 ----------
SET @col_exists := (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'management_payment_order' AND column_name = 'credited_amount');
SET @ddl := IF(@col_exists = 0,
    'ALTER TABLE `management_payment_order` ADD COLUMN `credited_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT ''实际入账到账单的金额'' AFTER `amount`',
    'SELECT ''credited_amount 列已存在，跳过'' AS msg');
PREPARE stmt_credited FROM @ddl; EXECUTE stmt_credited; DEALLOCATE PREPARE stmt_credited;

-- 历史订单入账回填：独立标记 + 事务，保证「加列成功但回填中断」时重跑仍能补齐；
-- 标记与回填同事务，失败一起回滚，不会出现标记已落、回填永久跳过。
START TRANSACTION;
INSERT INTO `management_system_config` (`id`, `group`, `key`, `value`, `type`, `description`, `created_at`, `updated_at`)
SELECT 2100000000090302, 'migration', '2026_10_30_credited_backfill_v1', '1', 'int', '一次性入账金额回填标记', NOW(), NOW()
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM `management_system_config` WHERE `group` = 'migration' AND `key` = '2026_10_30_credited_backfill_v1'
);
SET @credited_migrated := ROW_COUNT();
UPDATE `management_payment_order`
SET `credited_amount` = `amount`
WHERE @credited_migrated = 1 AND `status` IN (1, 3) AND `credited_amount` = 0;
COMMIT;

-- ---------- 4. management_fee_bill：历史账单状态一次性归一化 ----------
-- 旧版 status 语义：1=已缴、2=部分缴、3=逾期；当前语义：0=未缴 1=部分缴 2=已缴 3=逾期 4=豁免。
-- 按 已缴(含滞纳金)/部分缴/逾期/未缴 重算旧 1/2/3 行，4=豁免保持不变。
-- 一次性：以 management_system_config 的 migration 标记为闸门；标记+更新同事务，失败回滚后可重跑。
START TRANSACTION;
INSERT INTO `management_system_config` (`id`, `group`, `key`, `value`, `type`, `description`, `created_at`, `updated_at`)
SELECT 2100000000090301, 'migration', '2026_10_30_fee_bill_status_v1', '1', 'int', '一次性账单状态归一化标记', NOW(), NOW()
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM `management_system_config` WHERE `group` = 'migration' AND `key` = '2026_10_30_fee_bill_status_v1'
);
-- ROW_COUNT() = 1 仅当标记刚插入（首次执行）；重跑时为 0，更新整体跳过
SET @fee_status_migrated := ROW_COUNT();
UPDATE `management_fee_bill`
SET `status` = CASE
    WHEN `paid_amount` >= `amount` + `late_fee` THEN 2  -- 已缴（含滞纳金）
    WHEN `paid_amount` > 0 THEN 1                       -- 部分缴
    WHEN `due_date` IS NOT NULL AND `due_date` < CURDATE() THEN 3 -- 逾期
    ELSE 0                                              -- 未缴
END
WHERE @fee_status_migrated = 1 AND `status` IN (1, 2, 3);
-- 旧数据里 status=0 但已缴过款的异常行归为部分缴，避免漏计
UPDATE `management_fee_bill`
SET `status` = 1
WHERE @fee_status_migrated = 1 AND `status` = 0 AND `paid_amount` > 0;
COMMIT;

-- ---------- 5. management_payment_order：退款调用方幂等键（无回填） ----------
SET @col_exists := (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'management_payment_order' AND column_name = 'refund_request_id');
SET @ddl := IF(@col_exists = 0,
    'ALTER TABLE `management_payment_order` ADD COLUMN `refund_request_id` VARCHAR(64) NOT NULL DEFAULT '''' COMMENT ''最近一次退款的调用方幂等键'' AFTER `refund_amount`',
    'SELECT ''refund_request_id 列已存在，跳过'' AS msg');
PREPARE stmt_refund_req FROM @ddl; EXECUTE stmt_refund_req; DEALLOCATE PREPARE stmt_refund_req;
