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
