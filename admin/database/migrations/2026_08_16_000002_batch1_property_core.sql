-- ============================================================
-- Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
-- 迁移: 物业管理系统 — 第1批 基础域（物业核心，14 张）
-- 拆分规则: 小区/楼栋/单元/户型/房产/业主/租户/费用/报修/公告 10 模块
--   (community/building/unit/room_type/room/owner/room_owner/tenant/
--    fee_type/fee_bill/fee_payment/repair_order/repair_progress/announcement)
-- 依赖: 000000 核心域（外键均为普通索引，无 FK 约束）
-- 增量升级: 按文件名序号顺序执行；全量安装仍用 docs/install.sql
-- ============================================================
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
