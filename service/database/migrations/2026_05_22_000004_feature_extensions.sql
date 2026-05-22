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
