-- ============================================================
-- Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
-- 迁移: 物业管理系统 — 第3批 服务域（11 张）
-- 拆分规则: 安保巡逻/保洁/绿化/社区活动/能耗/员工 6 模块
--   (security_patrol/patrol_record/cleaning_area/cleaning_record/
--    green_area/green_maintenance/community_activity/activity_signup/
--    energy_meter/energy_record/staff)
-- 依赖: 批1 基础域（room/community/owner 等引用表均在其后创建，
--   外键均为普通索引，无 FK 约束）
-- 增量升级: 按文件名序号顺序执行；全量安装仍用 docs/install.sql
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
