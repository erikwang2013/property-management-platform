# 物业管理系统 — 第1批（核心业务）实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 搭建物业管理系统核心基础架构：service业务端后端、核心数据库表、admin管理端扩展、Flutter PC前端框架

**Architecture:** service 和 admin 为两个独立 webman v2 项目，共享 MySQL 数据库。service 面向业主端提供 API，admin 面向管理端提供 API。Flutter Web 按 PC 桌面风格（侧边栏+顶栏+内容区）。

**Tech Stack:** PHP 8.3+, webman v2, MySQL 8.0, erikwang2013/* 全家桶, Flutter 3.x, GetX

---

## File Map

```
service/                                  # 新建独立 webman v2 项目
├── .env.example
├── composer.json
├── start.php
├── windows.php
├── config/
│   ├── app.php, autoload.php, bootstrap.php, container.php
│   ├── database.php, dependence.php, exception.php
│   ├── hashids.php, snowflake.php, encryption.php, encryptable.php
│   ├── jwt.php, middleware.php, poster.php, scout.php
│   ├── route.php, server.php, process.php, log.php
│   ├── session.php, static.php, translation.php, view.php
├── app/
│   ├── functions.php
│   ├── common/
│   │   ├── HashidsService.php, SnowflakeService.php, EncryptionService.php
│   │   └── BaseController.php
│   ├── middleware/
│   │   ├── Cors.php, SecurityFilter.php, RateLimit.php
│   │   ├── ApiVersion.php, ServiceAuth.php
│   │   └── CaptchaMiddleware.php
│   ├── model/
│   │   ├── Owner.php, Room.php, RoomOwner.php, Tenant.php
│   │   ├── FeeType.php, FeeBill.php, FeePayment.php
│   │   ├── RepairOrder.php, RepairProgress.php
│   │   ├── Announcement.php
│   │   └── Community.php
│   ├── api/v1/controller/
│   │   ├── CaptchaController.php, AuthController.php
│   │   ├── HomeController.php, RoomController.php
│   │   ├── FeeController.php, RepairController.php
│   │   ├── ComplaintController.php, AnnouncementController.php
│   │   └── ProfileController.php
│   └── process/
│       └── Http.php
├── database/migrations/
│   └── 2026_05_22_000000_init_property_tables.sql
├── public/index.php
└── tests/

admin/app/                               # 已有项目，扩展
├── model/
│   └── (新增) Community.php, Building.php, Unit.php, Room.php, RoomType.php
│   └── (新增) Owner.php, Tenant.php, RoomOwner.php
│   └── (新增) FeeType.php, FeeBill.php, FeePayment.php
│   └── (新增) RepairOrder.php, RepairProgress.php
│   └── (新增) Announcement.php
├── admin/controller/
│   └── (新增) CommunityController.php, BuildingController.php, UnitController.php
│   └── (新增) RoomTypeController.php, RoomController.php
│   └── (新增) OwnerController.php, TenantController.php
│   └── (新增) FeeTypeController.php, FeeBillController.php, FeePaymentController.php
│   └── (新增) RepairController.php, AnnouncementController.php
│   └── (新增) DashboardController.php（扩展）, ExportController.php（扩展）
└── config/
    └── route.php（修改，新增路由）

admin/database/migrations/
└── 2026_05_22_000001_property_batch1_tables.sql
```

---

### Task 1: 创建 service 项目骨架

**Files:**
- Create: `service/composer.json`
- Create: `service/start.php`
- Create: `service/windows.php`
- Create: `service/.env.example`
- Create: `service/public/index.php`

- [ ] **Step 1: 创建 service/composer.json**

从 admin/composer.json 复制依赖结构，调整为 service 项目：

```json
{
  "name": "erik/property-service",
  "type": "project",
  "description": "物业管理系统 — 业主业务端",
  "license": "MIT",
  "require": {
    "php": ">=8.1",
    "workerman/webman-framework": "^2.1",
    "monolog/monolog": "^2.0",
    "erikwang2013/snowflake-php": "^2.0",
    "erikwang2013/hashids": "^1.0",
    "erikwang2013/jwt-webman": "^2.0",
    "erikwang2013/encryption": "^1.0",
    "erikwang2013/encryptable": "^2.0",
    "erikwang2013/webman-scout": "^2.0",
    "erikwang2013/season": "^2.0",
    "erikwang2013/security-php": "^1.0",
    "erikwang2013/poster-php": "^1.0",
    "phpoffice/phpspreadsheet": "^5.7",
    "barryvdh/laravel-dompdf": "^3.1",
    "vlucas/phpdotenv": "^5.6"
  },
  "autoload": {
    "psr-4": {
      "": "./",
      "app\\": "./app"
    }
  },
  "config": {
    "allow-plugins": {
      "erikwang2013/encryptable": true,
      "erikwang2013/webman-scout": true,
      "erikwang2013/encryption": true
    }
  },
  "require-dev": {
    "phpunit/phpunit": "^12.5"
  }
}
```

- [ ] **Step 2: 创建 service/start.php**

```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

ini_set('display_errors', 'on');
require_once __DIR__ . '/vendor/autoload.php';

app\process\Http::init();
app\process\Http::run();
```

- [ ] **Step 3: 创建 service/windows.php**

从 admin/windows.php 复制即可（启动脚本）。

- [ ] **Step 4: 创建 service/.env.example**

从 admin/.env.example 复制，修改：
- `APP_NAME=物业管理系统-业务端`
- `APP_URL=http://localhost:8788`
- 所有密钥重新生成独立值
- `DB_DATABASE=property_management`
- 新增 `SERVICE_PORT=8788`

- [ ] **Step 5: 创建 service/public/index.php**

```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

require_once __DIR__ . '/../vendor/autoload.php';
require_once __DIR__ . '/../config/container.php';

use support\App;

App::run();
```

- [ ] **Step 6: 安装依赖**

```bash
cd /home/wwwroot/property-management-platform/service && composer install
```
Expected: 依赖安装成功，生成 vendor/ 目录。

- [ ] **Step 7: Commit**

```bash
git add service/
git commit -m "feat(service): scaffold webman v2 project skeleton for property service"
```

---

### Task 2: service 配置文件

**Files:**
- Create: `service/config/app.php` 到 `service/config/view.php` 共19个配置文件
- 复用 admin/config/ 的结构，修改端口和服务名称

- [ ] **Step 1: 创建全部配置文件**

从 `admin/config/` 复制以下文件到 `service/config/`，修改关键差异：

每个文件头部添加版权声明，配置值中修改：
- `app.php`: app_name = '物业管理系统-业务端'
- `server.php`: listen = `http://0.0.0.0:8788`
- `database.php`: 数据库连接配置相同（共享数据库），表前缀 `erik_`
- `snowflake.php`: datacenter_id=1, worker_id=2 (区别于admin的worker_id=1)
- `hashids.php`: salt 使用独立值
- `jwt.php`: 密钥独立于admin
- `encryption.php`: 密钥独立于admin
- `encryptable.php`: 密钥独立于admin
- `route.php`: 空路由模板
- `middleware.php`: 引用 service 的中间件类
- 其余配置文件保持与 admin 一致

```bash
# 批量复制并修改
cp admin/config/app.php service/config/app.php
cp admin/config/autoload.php service/config/autoload.php
cp admin/config/bootstrap.php service/config/bootstrap.php
cp admin/config/container.php service/config/container.php
cp admin/config/database.php service/config/database.php
cp admin/config/dependence.php service/config/dependence.php
cp admin/config/encryptable.php service/config/encryptable.php
cp admin/config/encryption.php service/config/encryption.php
cp admin/config/exception.php service/config/exception.php
cp admin/config/hashids.php service/config/hashids.php
cp admin/config/jwt.php service/config/jwt.php
cp admin/config/log.php service/config/log.php
cp admin/config/middleware.php service/config/middleware.php
cp admin/config/poster.php service/config/poster.php
cp admin/config/process.php service/config/process.php
cp admin/config/route.php service/config/route.php
cp admin/config/scout.php service/config/scout.php
cp admin/config/server.php service/config/server.php
cp admin/config/session.php service/config/session.php
cp admin/config/snowflake.php service/config/snowflake.php
cp admin/config/static.php service/config/static.php
cp admin/config/translation.php service/config/translation.php
cp admin/config/view.php service/config/view.php
```
Expected: 所有配置文件复制完成。

修改每个文件中的命名空间引用路径（`app\middleware` → 保持一致，但 middleware 类在 service 项目中重新创建）。

关键修改 — `service/config/server.php`:
```php
'server.listen' => 'http://0.0.0.0:8788',
```

关键修改 — `service/config/middleware.php`:
```php
return [
    app\middleware\Cors::class,
    app\middleware\SecurityFilter::class,
    app\middleware\RateLimit::class,
];
```

- [ ] **Step 2: Commit**

```bash
git add service/config/
git commit -m "feat(service): add configuration files with Chinese annotations"
```

---

### Task 3: 创建 service 公共工具类和基础控制器

**Files:**
- Create: `service/app/functions.php`
- Create: `service/app/common/HashidsService.php`
- Create: `service/app/common/SnowflakeService.php`
- Create: `service/app/common/EncryptionService.php`
- Create: `service/app/common/BaseController.php`

直接从 admin/app/ 复制对应文件，修改命名空间保持为 `app\common`。

- [ ] **Step 1: 复制公共工具类**

```bash
mkdir -p service/app/common
cp admin/app/common/HashidsService.php service/app/common/
cp admin/app/common/SnowflakeService.php service/app/common/
cp admin/app/common/EncryptionService.php service/app/common/
cp admin/app/functions.php service/app/
```

- [ ] **Step 2: 创建 service/app/common/BaseController.php**

```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\common;

use app\model\Owner;
use support\Request;
use support\Response;

/**
 * 业务端基础控制器
 * 提供统一响应格式、ID编解码、业主身份验证
 */
class BaseController
{
    /**
     * 成功响应
     *
     * @param array|object $data 响应数据
     * @param string $message 提示消息
     * @param int $code 状态码，0 表示成功
     */
    protected function success($data = [], string $message = 'success', int $code = 0): Response
    {
        return json(['code' => $code, 'message' => $message, 'data' => $data]);
    }

    /**
     * 失败响应
     *
     * @param string $message 错误消息
     * @param int $code HTTP 状态码
     */
    protected function fail(string $message = 'fail', int $code = 500, $data = []): Response
    {
        return json(['code' => $code, 'message' => $message, 'data' => $data]);
    }

    /**
     * 将 BIGINT ID 编码为 hashid 字符串
     */
    protected function encodeId(int $id): string
    {
        return HashidsService::encode($id);
    }

    /**
     * 将 hashid 字符串解码为 BIGINT ID
     */
    protected function decodeId(string $hashid): int
    {
        return HashidsService::decode($hashid);
    }

    /**
     * 批量编码数组中的 ID 字段
     */
    protected function encodeIds(array $data, array $idFields = ['id']): array
    {
        return HashidsService::encodeIds($data, $idFields);
    }

    /**
     * 生成新的 snowflake ID
     */
    protected function generateId(): int
    {
        return SnowflakeService::generate();
    }

    /**
     * 获取当前登录业主 ID
     */
    protected function getOwnerId(Request $request): int
    {
        return $request->ownerId ?? 0;
    }

    /**
     * 密码二次确认 — 敏感操作验证
     *
     * @param int $ownerId 业主 ID
     * @param string $password 用户输入的密码
     * @return string|null null 表示验证通过，非 null 为错误消息
     */
    protected function confirmPassword(int $ownerId, string $password): ?string
    {
        if (empty($password)) {
            return '敏感操作需要输入密码确认';
        }

        $owner = Owner::find($ownerId);
        if (!$owner || !password_verify($password, $owner->password)) {
            return '密码验证失败';
        }

        return null;
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add service/app/common/ service/app/functions.php
git commit -m "feat(service): add common service classes and base controller"
```

---

### Task 4: 创建数据库迁移文件

**Files:**
- Create: `admin/database/migrations/2026_05_22_000001_property_batch1_tables.sql`
- Create: `service/database/migrations/2026_05_22_000000_init_property_tables.sql`

- [ ] **Step 1: 创建 admin 端迁移文件**

创建 `admin/database/migrations/2026_05_22_000001_property_batch1_tables.sql`，包含第1批14张表：

```sql
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
```

- [ ] **Step 2: 同步到 service 端**

```bash
cp admin/database/migrations/2026_05_22_000001_property_batch1_tables.sql \
   service/database/migrations/2026_05_22_000000_init_property_tables.sql
```

migrations 目录需要先创建：
```bash
mkdir -p service/database/migrations service/database/backup
```

- [ ] **Step 3: 执行迁移验证**

```bash
# 在 MySQL 中创建数据库（如未创建）
mysql -u root -e "CREATE DATABASE IF NOT EXISTS property_management DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# 导入迁移文件
mysql -u root property_management < admin/database/migrations/2026_05_22_000001_property_batch1_tables.sql
```
Expected: 表创建成功，`SHOW TABLES LIKE 'erik_%';` 列出14张新表。

- [ ] **Step 4: Commit**

```bash
git add admin/database/migrations/2026_05_22_000001_property_batch1_tables.sql
git add service/database/migrations/2026_05_22_000000_init_property_tables.sql
git commit -m "feat(db): add batch 1 property management tables (14 tables)"
```

---

### Task 5: service 端中间件

**Files:**
- Create: `service/app/middleware/Cors.php`
- Create: `service/app/middleware/SecurityFilter.php`
- Create: `service/app/middleware/RateLimit.php`
- Create: `service/app/middleware/ApiVersion.php`
- Create: `service/app/middleware/ServiceAuth.php`

从 `admin/app/middleware/` 复制 Cors、SecurityFilter、RateLimit、ApiVersion，保持不变。

- [ ] **Step 1: 复制已有中间件**

```bash
mkdir -p service/app/middleware
cp admin/app/middleware/Cors.php service/app/middleware/
cp admin/app/middleware/SecurityFilter.php service/app/middleware/
cp admin/app/middleware/RateLimit.php service/app/middleware/
cp admin/app/middleware/ApiVersion.php service/app/middleware/
```

- [ ] **Step 2: 创建 ServiceAuth 中间件**

基于 `admin/app/middleware/AdminAuth.php` 改写，认证 `erik_owner` 表：

创建 `service/app/middleware/ServiceAuth.php`:

```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\middleware;

use support\Request;
use support\Response;
use support\Redis;
use Erikwang2013\Jwt\JWT;
use Erikwang2013\Jwt\JWTFactory;
use Erikwang2013\Jwt\JWTException;

/**
 * 业主端 JWT 认证中间件
 * 验证 Bearer Token，注入 $request->ownerId 和 $request->ownerPhone
 */
class ServiceAuth
{
    private static ?JWT $jwt = null;

    private static function getJWT(): JWT
    {
        if (self::$jwt === null) {
            $config = config('plugin.erikwang2013.jwt.jwt', []);
            self::$jwt = JWTFactory::createFromConfig($config);
        }
        return self::$jwt;
    }

    public function process(Request $request, callable $next): Response
    {
        $token = $request->header('Authorization', '');
        $token = str_replace('Bearer ', '', $token);

        if (empty($token)) {
            return json(['code' => 401, 'message' => '未登录', 'data' => []]);
        }

        // 检查 JWT 黑名单
        $blacklistKey = 'jwt_blacklist:' . md5($token);
        try {
            if (Redis::get($blacklistKey)) {
                return json(['code' => 401, 'message' => 'Token已失效，请重新登录', 'data' => []]);
            }
        } catch (\Throwable $e) {
            // Redis down, skip blacklist check
        }

        try {
            $payload = self::getJWT()->decode($token);
            $request->ownerId = $payload['sub'] ?? 0;
            $request->ownerPhone = $payload['phone'] ?? '';
        } catch (JWTException | \Exception $e) {
            return json(['code' => 401, 'message' => 'Token已过期或无效', 'data' => []]);
        }

        return $next($request);
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add service/app/middleware/
git commit -m "feat(service): add middleware (Cors, SecurityFilter, RateLimit, ApiVersion, ServiceAuth)"
```

---

### Task 6: service 端数据模型

**Files (13 models):**
- Create: `service/app/model/Community.php`
- Create: `service/app/model/Owner.php`
- Create: `service/app/model/Room.php`
- Create: `service/app/model/RoomOwner.php`
- Create: `service/app/model/Tenant.php`
- Create: `service/app/model/FeeType.php`
- Create: `service/app/model/FeeBill.php`
- Create: `service/app/model/FeePayment.php`
- Create: `service/app/model/RepairOrder.php`
- Create: `service/app/model/RepairProgress.php`
- Create: `service/app/model/Announcement.php`
- Create: `service/app/model/BaseModel.php`

- [ ] **Step 1: 创建基础 Model**

`service/app/model/BaseModel.php`:

```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

use support\Model;

/**
 * 基础模型
 * 所有业务模型统一使用 BIGINT 非自增主键
 */
class BaseModel extends Model
{
    public $incrementing = false;
    protected $keyType = 'int';
}
```

- [ ] **Step 2: 创建 Community.php**

```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

use Illuminate\Database\Eloquent\SoftDeletes;

class Community extends BaseModel
{
    use SoftDeletes;

    protected $table = 'erik_community';

    protected $fillable = [
        'name', 'address', 'province', 'city', 'district',
        'area_total', 'building_count', 'room_count',
        'developer', 'property_company', 'contact_phone',
        'description', 'status',
    ];

    protected $casts = [
        'area_total' => 'decimal:2',
        'building_count' => 'integer',
        'room_count' => 'integer',
        'status' => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];
}
```

- [ ] **Step 3: 创建 Owner.php**

```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

use Erikwang2013\Encryptable\Encryptable;
use Illuminate\Database\Eloquent\SoftDeletes;

class Owner extends BaseModel
{
    use SoftDeletes;

    protected $table = 'erik_owner';

    protected $fillable = [
        'name', 'phone', 'email', 'id_card', 'password',
        'gender', 'birthday', 'emergency_contact', 'emergency_phone',
        'check_in_date', 'remark', 'status',
        'last_login_at', 'last_login_ip',
        'login_failures', 'locked_until',
    ];

    protected $hidden = ['password', 'id_card'];

    protected $casts = [
        'gender' => 'integer',
        'status' => 'integer',
        'login_failures' => 'integer',
        'birthday' => 'date',
        'check_in_date' => 'date',
        'last_login_at' => 'datetime',
        'locked_until' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'phone' => Encryptable::class,
        'email' => Encryptable::class,
        'id_card' => Encryptable::class,
        'emergency_contact' => Encryptable::class,
        'emergency_phone' => Encryptable::class,
    ];

    public function rooms()
    {
        return $this->belongsToMany(Room::class, 'erik_room_owner', 'owner_id', 'room_id')
            ->withPivot(['relation_type', 'ownership_ratio', 'cert_number']);
    }
}
```

- [ ] **Step 4: 创建 Room.php**

```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

use Illuminate\Database\Eloquent\SoftDeletes;

class Room extends BaseModel
{
    use SoftDeletes;

    protected $table = 'erik_room';

    protected $fillable = [
        'community_id', 'building_id', 'unit_id', 'room_number',
        'floor', 'room_type_id',
        'area_indoor', 'area_shared', 'area_total',
        'orientation', 'decoration', 'usage_type', 'status', 'remark',
    ];

    protected $casts = [
        'floor' => 'integer',
        'room_type_id' => 'integer',
        'area_indoor' => 'decimal:2',
        'area_shared' => 'decimal:2',
        'area_total' => 'decimal:2',
        'decoration' => 'integer',
        'usage_type' => 'integer',
        'status' => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function community()
    {
        return $this->belongsTo(Community::class, 'community_id');
    }

    public function owners()
    {
        return $this->belongsToMany(Owner::class, 'erik_room_owner', 'room_id', 'owner_id')
            ->withPivot(['relation_type', 'ownership_ratio', 'cert_number']);
    }
}
```

- [ ] **Step 5: 创建 RoomOwner.php**

```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class RoomOwner extends BaseModel
{
    protected $table = 'erik_room_owner';

    protected $fillable = [
        'room_id', 'owner_id', 'relation_type',
        'ownership_ratio', 'cert_number', 'start_date', 'end_date',
    ];

    protected $casts = [
        'relation_type' => 'integer',
        'ownership_ratio' => 'decimal:2',
        'start_date' => 'date',
        'end_date' => 'date',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];
}
```

- [ ] **Step 6: 创建 Tenant.php**

```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

use Erikwang2013\Encryptable\Encryptable;

class Tenant extends BaseModel
{
    protected $table = 'erik_tenant';

    protected $fillable = [
        'room_id', 'owner_id', 'name', 'phone', 'id_card',
        'lease_start', 'lease_end', 'rent_amount', 'status',
    ];

    protected $casts = [
        'rent_amount' => 'decimal:2',
        'status' => 'integer',
        'lease_start' => 'date',
        'lease_end' => 'date',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'phone' => Encryptable::class,
        'id_card' => Encryptable::class,
    ];
}
```

- [ ] **Step 7: 创建 FeeType.php, FeeBill.php, FeePayment.php**

FeeType.php:
```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class FeeType extends BaseModel
{
    protected $table = 'erik_fee_type';

    protected $fillable = [
        'name', 'category', 'unit_price', 'unit_type',
        'cycle_type', 'is_required', 'sort',
    ];

    protected $casts = [
        'category' => 'integer',
        'unit_price' => 'decimal:2',
        'unit_type' => 'integer',
        'cycle_type' => 'integer',
        'is_required' => 'integer',
        'sort' => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function bills()
    {
        return $this->hasMany(FeeBill::class, 'fee_type_id');
    }
}
```

FeeBill.php:
```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class FeeBill extends BaseModel
{
    protected $table = 'erik_fee_bill';

    protected $fillable = [
        'room_id', 'owner_id', 'fee_type_id', 'bill_number',
        'amount', 'paid_amount', 'late_fee',
        'start_date', 'end_date', 'due_date', 'status', 'paid_at', 'remark',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'paid_amount' => 'decimal:2',
        'late_fee' => 'decimal:2',
        'status' => 'integer',
        'start_date' => 'date',
        'end_date' => 'date',
        'due_date' => 'date',
        'paid_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function feeType()
    {
        return $this->belongsTo(FeeType::class, 'fee_type_id');
    }

    public function room()
    {
        return $this->belongsTo(Room::class, 'room_id');
    }

    public function payments()
    {
        return $this->hasMany(FeePayment::class, 'bill_id');
    }
}
```

FeePayment.php:
```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class FeePayment extends BaseModel
{
    protected $table = 'erik_fee_payment';

    protected $fillable = [
        'bill_id', 'owner_id', 'payment_number',
        'amount', 'payment_method', 'payment_channel',
        'paid_at', 'operator_id', 'receipt_url', 'remark',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'payment_method' => 'integer',
        'payment_channel' => 'integer',
        'paid_at' => 'datetime',
        'created_at' => 'datetime',
    ];

    public function bill()
    {
        return $this->belongsTo(FeeBill::class, 'bill_id');
    }
}
```

- [ ] **Step 8: 创建 RepairOrder.php, RepairProgress.php**

RepairOrder.php:
```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

use Erikwang2013\Encryptable\Encryptable;

class RepairOrder extends BaseModel
{
    protected $table = 'erik_repair_order';

    protected $fillable = [
        'order_number', 'room_id', 'owner_id', 'contact_phone',
        'category', 'urgency', 'description', 'images', 'scheduled_at',
        'status', 'staff_id', 'completed_at', 'rating', 'feedback',
    ];

    protected $casts = [
        'category' => 'integer',
        'urgency' => 'integer',
        'status' => 'integer',
        'rating' => 'integer',
        'scheduled_at' => 'datetime',
        'completed_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
        'contact_phone' => Encryptable::class,
    ];

    public function room()
    {
        return $this->belongsTo(Room::class, 'room_id');
    }

    public function progress()
    {
        return $this->hasMany(RepairProgress::class, 'repair_order_id')->orderBy('created_at', 'desc');
    }
}
```

RepairProgress.php:
```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class RepairProgress extends BaseModel
{
    protected $table = 'erik_repair_progress';

    protected $fillable = [
        'repair_order_id', 'staff_id',
        'status_from', 'status_to', 'remark', 'images',
    ];

    protected $casts = [
        'status_from' => 'integer',
        'status_to' => 'integer',
        'created_at' => 'datetime',
    ];
}
```

- [ ] **Step 9: 创建 Announcement.php**

```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

use Illuminate\Database\Eloquent\SoftDeletes;

class Announcement extends BaseModel
{
    use SoftDeletes;

    protected $table = 'erik_announcement';

    protected $fillable = [
        'community_id', 'title', 'content', 'category',
        'is_top', 'is_published', 'published_at', 'publisher_id',
    ];

    protected $casts = [
        'category' => 'integer',
        'is_top' => 'integer',
        'is_published' => 'integer',
        'published_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];
}
```

- [ ] **Step 10: Commit**

```bash
git add service/app/model/
git commit -m "feat(service): add batch 1 Eloquent models (13 models)"
```

---

### Task 7: service 端 API 控制器

**Files:**
- Create: `service/app/api/v1/controller/CaptchaController.php`
- Create: `service/app/api/v1/controller/AuthController.php`
- Create: `service/app/api/v1/controller/HomeController.php`
- Create: `service/app/api/v1/controller/RoomController.php`
- Create: `service/app/api/v1/controller/FeeController.php`
- Create: `service/app/api/v1/controller/RepairController.php`
- Create: `service/app/api/v1/controller/ComplaintController.php`
- Create: `service/app/api/v1/controller/AnnouncementController.php`
- Create: `service/app/api/v1/controller/ProfileController.php`

- [ ] **Step 1: 创建目录**

```bash
mkdir -p service/app/api/v1/controller
```

- [ ] **Step 2: 创建 CaptchaController.php**

从 `admin/app/api/v1/controller/CaptchaController.php` 复制。

- [ ] **Step 3: 创建 AuthController.php（业主认证）**

```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;

use app\common\BaseController;
use app\common\HashidsService;
use app\common\SnowflakeService;
use app\model\Owner;
use app\model\Room;
use app\model\RoomOwner;
use support\Request;
use support\Response;
use support\Redis;
use Erikwang2013\Jwt\JWTFactory;

class AuthController extends BaseController
{
    /**
     * 业主登录
     *
     * 请求体: { phone, password, captcha_key, clicks, community_id }
     * 响应: { access_token, refresh_token, owner }
     */
    public function login(Request $request): Response
    {
        $phone = $request->input('phone', '');
        $password = $request->input('password', '');
        $captchaKey = $request->input('captcha_key', '');
        $clicks = $request->input('clicks', []);

        if (empty($phone) || empty($password)) {
            return $this->fail('手机号和密码不能为空', 422);
        }

        // 验证码校验
        if (!captcha_verify($captchaKey, 'click', $clicks)) {
            return $this->fail('验证码错误', 422);
        }

        // 查找业主（phone 是加密字段，需要用明文匹配）
        $owner = Owner::where('phone', $phone)->first();
        if (!$owner || !password_verify($password, $owner->password)) {
            return $this->fail('手机号或密码错误', 401);
        }

        // 账号锁定检查
        if ($owner->locked_until && strtotime($owner->locked_until) > time()) {
            return $this->fail('账号已被锁定，请稍后再试', 429);
        }

        // 状态检查
        if ($owner->status !== 1) {
            return $this->fail('账号已被禁用', 403);
        }

        // 更新登录信息
        $owner->last_login_at = date('Y-m-d H:i:s');
        $owner->last_login_ip = $request->getRealIp();
        $owner->login_failures = 0;
        $owner->save();

        // 生成 Token
        $jwt = JWTFactory::createFromConfig(config('plugin.erikwang2013.jwt.jwt', []));
        $accessToken = $jwt->create([
            'sub' => $owner->id,
            'phone' => $owner->phone,
        ]);

        $refreshToken = $jwt->createRefresh([
            'sub' => $owner->id,
            'phone' => $owner->phone,
        ]);

        // 检测并限制并发会话（最多3个）
        $this->limitSessions($owner->id, $accessToken);

        return $this->success([
            'access_token' => $accessToken,
            'refresh_token' => $refreshToken,
            'owner' => [
                'id' => $this->encodeId($owner->id),
                'name' => $owner->name,
                'phone' => $this->maskPhone($owner->phone),
                'gender' => $owner->gender,
            ],
        ], '登录成功');
    }

    /**
     * 业主注册
     *
     * 请求体: { phone, password, name, room_id(hashid), id_card_last4, captcha_key, clicks }
     * 需验证房产绑定：房号 + 姓名 + 身份证后4位
     */
    public function register(Request $request): Response
    {
        $phone = $request->input('phone', '');
        $password = $request->input('password', '');
        $name = $request->input('name', '');
        $roomHashid = $request->input('room_id', '');
        $idCardLast4 = $request->input('id_card_last4', '');
        $captchaKey = $request->input('captcha_key', '');
        $clicks = $request->input('clicks', []);

        // 参数校验
        if (empty($phone) || empty($password) || empty($name)) {
            return $this->fail('手机号、密码、姓名不能为空', 422);
        }

        if (strlen($password) < 6) {
            return $this->fail('密码至少6位', 422);
        }

        if (!captcha_verify($captchaKey, 'click', $clicks)) {
            return $this->fail('验证码错误', 422);
        }

        // 检查手机号是否已注册
        if (Owner::where('phone', $phone)->exists()) {
            return $this->fail('该手机号已注册', 422);
        }

        // 如果提供了房号，验证房产绑定
        $roomId = 0;
        if (!empty($roomHashid)) {
            try {
                $roomId = $this->decodeId($roomHashid);
            } catch (\Exception $e) {
                return $this->fail('房产信息无效', 422);
            }

            $room = Room::find($roomId);
            if (!$room) {
                return $this->fail('房产不存在', 404);
            }

            // 验证房产是否已有绑定业主记录
            $roomOwner = RoomOwner::where('room_id', $roomId)->first();
            if (!$roomOwner || empty($idCardLast4)) {
                return $this->fail('请提供身份证后4位以验证房产绑定', 422);
            }
        }

        $ownerId = SnowflakeService::generate();

        Owner::create([
            'id' => $ownerId,
            'name' => $name,
            'phone' => $phone,
            'password' => password_hash($password, PASSWORD_BCRYPT),
            'status' => 1,
        ]);

        // 如果房产绑定已提供，创建关联
        if ($roomId > 0) {
            RoomOwner::create([
                'id' => SnowflakeService::generate(),
                'room_id' => $roomId,
                'owner_id' => $ownerId,
                'relation_type' => 1,
            ]);
        }

        return $this->success([], '注册成功');
    }

    /**
     * 刷新 Token
     */
    public function refresh(Request $request): Response
    {
        $refreshToken = $request->input('refresh_token', '');
        if (empty($refreshToken)) {
            return $this->fail('缺少 refresh_token', 422);
        }

        try {
            $jwt = JWTFactory::createFromConfig(config('plugin.erikwang2013.jwt.jwt', []));
            $payload = $jwt->decode($refreshToken);

            $accessToken = $jwt->create([
                'sub' => $payload['sub'],
                'phone' => $payload['phone'],
            ]);

            return $this->success([
                'access_token' => $accessToken,
            ]);
        } catch (\Exception $e) {
            return $this->fail('Token已过期，请重新登录', 401);
        }
    }

    /**
     * 限制并发会话，最多3个，超出时最旧的Token加入黑名单
     */
    private function limitSessions(int $ownerId, string $currentToken): void
    {
        try {
            $key = 'owner_sessions:' . $ownerId;
            $tokens = json_decode(Redis::get($key) ?: '[]', true);

            $tokens[] = [
                'token' => substr(md5($currentToken), 0, 16),
                'time' => time(),
            ];

            // 超过3个，最旧的入黑名单
            while (count($tokens) > 3) {
                $oldest = array_shift($tokens);
                Redis::setex(
                    'jwt_blacklist:' . $oldest['token'],
                    7200,
                    '1'
                );
            }

            Redis::setex($key, 86400, json_encode($tokens));
        } catch (\Throwable $e) {
            // Redis down, skip session limit
        }
    }

    private function maskPhone(string $phone): string
    {
        if (strlen($phone) >= 7) {
            return substr($phone, 0, 3) . '****' . substr($phone, -4);
        }
        return $phone;
    }
}
```

- [ ] **Step 4: 创建 HomeController.php**

```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;

use app\common\BaseController;
use app\model\FeeBill;
use app\model\RepairOrder;
use app\model\Announcement;
use app\model\Room;
use support\Request;
use support\Response;

class HomeController extends BaseController
{
    /**
     * 首页数据
     * 返回：我的房产数、待缴费金额及条数、处理中报修数、最新公告列表
     */
    public function index(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);

        // 我的房产数量
        $roomCount = Room::whereHas('owners', function ($q) use ($ownerId) {
            $q->where('owner_id', $ownerId);
        })->count();

        // 待缴费统计
        $pendingBills = FeeBill::where('owner_id', $ownerId)
            ->whereIn('status', [0, 3])
            ->get();
        $pendingAmount = $pendingBills->sum(function ($bill) {
            return $bill->amount - $bill->paid_amount + $bill->late_fee;
        });
        $pendingBillCount = $pendingBills->count();

        // 处理中的报修
        $repairingCount = RepairOrder::where('owner_id', $ownerId)
            ->whereIn('status', [0, 1, 2])
            ->count();

        // 最新公告（取最近5条已发布）
        $announcements = Announcement::where('is_published', 1)
            ->orderBy('is_top', 'desc')
            ->orderBy('published_at', 'desc')
            ->limit(5)
            ->get()
            ->map(function ($item) {
                return [
                    'id' => $this->encodeId($item->id),
                    'title' => $item->title,
                    'category' => $item->category,
                    'is_top' => $item->is_top,
                    'published_at' => $item->published_at
                        ? $item->published_at->format('Y-m-d H:i')
                        : '',
                ];
            });

        return $this->success([
            'room_count' => $roomCount,
            'pending_amount' => number_format($pendingAmount, 2, '.', ''),
            'pending_bill_count' => $pendingBillCount,
            'repairing_count' => $repairingCount,
            'announcements' => $announcements,
        ]);
    }
}
```

- [ ] **Step 5: 创建 RoomController.php**

```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;

use app\common\BaseController;
use app\model\Room;
use support\Request;
use support\Response;

class RoomController extends BaseController
{
    /**
     * 我的房产列表
     */
    public function index(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);

        $rooms = Room::whereHas('owners', function ($q) use ($ownerId) {
            $q->where('owner_id', $ownerId);
        })->with(['community:id,name'])->get()->map(function ($room) {
            return [
                'id' => $this->encodeId($room->id),
                'room_number' => $room->room_number,
                'floor' => $room->floor,
                'area_total' => $room->area_total,
                'decoration' => $room->decoration,
                'status' => $room->status,
                'community_name' => $room->community->name ?? '',
            ];
        });

        return $this->success($rooms);
    }

    /**
     * 房产详情
     */
    public function show(Request $request, string $hashid): Response
    {
        $ownerId = $this->getOwnerId($request);
        $roomId = $this->decodeId($hashid);

        $room = Room::whereHas('owners', function ($q) use ($ownerId) {
            $q->where('owner_id', $ownerId);
        })->with(['community', 'owners'])->find($roomId);

        if (!$room) {
            return $this->fail('房产不存在或无权查看', 404);
        }

        $data = [
            'id' => $this->encodeId($room->id),
            'room_number' => $room->room_number,
            'floor' => $room->floor,
            'area_indoor' => $room->area_indoor,
            'area_shared' => $room->area_shared,
            'area_total' => $room->area_total,
            'orientation' => $room->orientation,
            'decoration' => $room->decoration,
            'usage_type' => $room->usage_type,
            'status' => $room->status,
            'community' => [
                'id' => $this->encodeId($room->community->id ?? 0),
                'name' => $room->community->name ?? '',
            ],
            'owners' => $room->owners->map(function ($owner) {
                return [
                    'id' => $this->encodeId($owner->id),
                    'name' => $owner->name,
                    'relation_type' => $owner->pivot->relation_type ?? 1,
                    'ownership_ratio' => $owner->pivot->ownership_ratio ?? '100.00',
                ];
            }),
        ];

        return $this->success($data);
    }
}
```

- [ ] **Step 6: 创建 FeeController.php**

```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;

use app\common\BaseController;
use app\common\SnowflakeService;
use app\model\FeeBill;
use app\model\FeePayment;
use app\model\FeeType;
use support\Request;
use support\Response;

class FeeController extends BaseController
{
    /**
     * 账单列表
     * ?status=0未缴 1部分缴 2已缴 3逾期
     */
    public function bills(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);
        $status = $request->input('status');

        $query = FeeBill::where('owner_id', $ownerId)
            ->with(['feeType:id,name,category', 'room:id,room_number']);

        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        }

        $bills = $query->orderBy('created_at', 'desc')
            ->paginate(20)
            ->through(function ($bill) {
                return [
                    'id' => $this->encodeId($bill->id),
                    'bill_number' => $bill->bill_number,
                    'amount' => $bill->amount,
                    'paid_amount' => $bill->paid_amount,
                    'unpaid' => number_format(
                        $bill->amount - $bill->paid_amount + $bill->late_fee,
                        2, '.', ''
                    ),
                    'late_fee' => $bill->late_fee,
                    'due_date' => $bill->due_date ? $bill->due_date->format('Y-m-d') : '',
                    'status' => $bill->status,
                    'fee_type_name' => $bill->feeType->name ?? '',
                    'room_number' => $bill->room->room_number ?? '',
                ];
            });

        return $this->success($bills);
    }

    /**
     * 账单详情
     */
    public function billDetail(Request $request, string $hashid): Response
    {
        $ownerId = $this->getOwnerId($request);
        $billId = $this->decodeId($hashid);

        $bill = FeeBill::where('owner_id', $ownerId)
            ->with(['feeType', 'room', 'payments'])
            ->find($billId);

        if (!$bill) {
            return $this->fail('账单不存在', 404);
        }

        return $this->success([
            'id' => $this->encodeId($bill->id),
            'bill_number' => $bill->bill_number,
            'amount' => $bill->amount,
            'paid_amount' => $bill->paid_amount,
            'unpaid' => number_format(
                $bill->amount - $bill->paid_amount + $bill->late_fee,
                2, '.', ''
            ),
            'late_fee' => $bill->late_fee,
            'start_date' => $bill->start_date ? $bill->start_date->format('Y-m-d') : '',
            'end_date' => $bill->end_date ? $bill->end_date->format('Y-m-d') : '',
            'due_date' => $bill->due_date ? $bill->due_date->format('Y-m-d') : '',
            'status' => $bill->status,
            'fee_type' => [
                'id' => $this->encodeId($bill->feeType->id ?? 0),
                'name' => $bill->feeType->name ?? '',
                'category' => $bill->feeType->category ?? 0,
            ],
            'room_number' => $bill->room->room_number ?? '',
            'payments' => $bill->payments->map(function ($p) {
                return [
                    'id' => $this->encodeId($p->id),
                    'amount' => $p->amount,
                    'payment_method' => $p->payment_method,
                    'paid_at' => $p->paid_at ? $p->paid_at->format('Y-m-d H:i:s') : '',
                ];
            }),
        ]);
    }

    /**
     * 缴费记录
     */
    public function payments(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);

        $payments = FeePayment::where('owner_id', $ownerId)
            ->with('bill:id,bill_number,fee_type_id')
            ->orderBy('paid_at', 'desc')
            ->paginate(20)
            ->through(function ($p) {
                return [
                    'id' => $this->encodeId($p->id),
                    'payment_number' => $p->payment_number,
                    'amount' => $p->amount,
                    'payment_method' => $p->payment_method,
                    'payment_channel' => $p->payment_channel,
                    'paid_at' => $p->paid_at ? $p->paid_at->format('Y-m-d H:i:s') : '',
                    'bill_number' => $p->bill->bill_number ?? '',
                ];
            });

        return $this->success($payments);
    }

    /**
     * 在线缴费
     */
    public function pay(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);
        $billHashid = $request->input('bill_id', '');
        $paymentMethod = (int) $request->input('payment_method', 1);
        $password = $request->input('password', '');

        // 密码二次确认
        $error = $this->confirmPassword($ownerId, $password);
        if ($error !== null) {
            return $this->fail($error, 422);
        }

        try {
            $billId = $this->decodeId($billHashid);
        } catch (\Exception $e) {
            return $this->fail('账单信息无效', 422);
        }

        $bill = FeeBill::where('owner_id', $ownerId)->find($billId);
        if (!$bill) {
            return $this->fail('账单不存在', 404);
        }

        if (in_array($bill->status, [2, 4])) {
            return $this->fail('该账单已缴费或已豁免', 422);
        }

        $payAmount = $bill->amount - $bill->paid_amount + $bill->late_fee;

        // 记录缴费
        $payment = FeePayment::create([
            'id' => SnowflakeService::generate(),
            'bill_id' => $bill->id,
            'owner_id' => $ownerId,
            'payment_number' => 'PAY' . date('YmdHis') . rand(100, 999),
            'amount' => $payAmount,
            'payment_method' => $paymentMethod,
            'payment_channel' => 1,
            'paid_at' => date('Y-m-d H:i:s'),
        ]);

        // 更新账单
        $bill->paid_amount = $bill->amount + $bill->late_fee;
        $bill->status = 2;
        $bill->paid_at = date('Y-m-d H:i:s');
        $bill->save();

        return $this->success([
            'payment_id' => $this->encodeId($payment->id),
            'amount' => $payAmount,
        ], '缴费成功');
    }

    /**
     * 费用统计
     */
    public function statistics(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);
        $year = (int) $request->input('year', date('Y'));

        // 年度按月份统计
        $monthlyStats = FeeBill::where('owner_id', $ownerId)
            ->whereYear('created_at', (string) $year)
            ->selectRaw('MONTH(created_at) as month, SUM(amount) as total, SUM(paid_amount) as paid')
            ->groupBy('month')
            ->orderBy('month')
            ->get();

        // 费用分类占比
        $categoryStats = FeeBill::where('owner_id', $ownerId)
            ->whereYear('created_at', (string) $year)
            ->with('feeType:id,name,category')
            ->get()
            ->groupBy(function ($bill) {
                return $bill->feeType->category ?? 0;
            })
            ->map(function ($bills, $category) {
                return [
                    'category' => (int) $category,
                    'total' => $bills->sum('amount'),
                ];
            })->values();

        return $this->success([
            'monthly' => $monthlyStats,
            'category' => $categoryStats,
        ]);
    }
}
```

- [ ] **Step 7: 创建 RepairController.php**

```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;

use app\common\BaseController;
use app\common\SnowflakeService;
use app\model\RepairOrder;
use app\model\RepairProgress;
use app\model\Room;
use support\Request;
use support\Response;

class RepairController extends BaseController
{
    /**
     * 报修列表
     */
    public function index(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);
        $status = $request->input('status');

        $query = RepairOrder::where('owner_id', $ownerId)
            ->with(['room:id,room_number']);

        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        }

        $orders = $query->orderBy('created_at', 'desc')
            ->paginate(20)
            ->through(function ($order) {
                return [
                    'id' => $this->encodeId($order->id),
                    'order_number' => $order->order_number,
                    'category' => $order->category,
                    'urgency' => $order->urgency,
                    'status' => $order->status,
                    'room_number' => $order->room->room_number ?? '',
                    'created_at' => $order->created_at
                        ? $order->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($orders);
    }

    /**
     * 报修详情
     */
    public function show(Request $request, string $hashid): Response
    {
        $ownerId = $this->getOwnerId($request);
        $orderId = $this->decodeId($hashid);

        $order = RepairOrder::where('owner_id', $ownerId)
            ->with(['room:id,room_number,community_id', 'progress'])
            ->find($orderId);

        if (!$order) {
            return $this->fail('报修单不存在', 404);
        }

        return $this->success([
            'id' => $this->encodeId($order->id),
            'order_number' => $order->order_number,
            'category' => $order->category,
            'urgency' => $order->urgency,
            'description' => $order->description,
            'images' => json_decode($order->images ?: '[]', true),
            'scheduled_at' => $order->scheduled_at
                ? $order->scheduled_at->format('Y-m-d H:i') : '',
            'status' => $order->status,
            'rating' => $order->rating,
            'feedback' => $order->feedback,
            'room_number' => $order->room->room_number ?? '',
            'progress' => $order->progress->map(function ($p) {
                return [
                    'id' => $this->encodeId($p->id),
                    'status_from' => $p->status_from,
                    'status_to' => $p->status_to,
                    'remark' => $p->remark,
                    'created_at' => $p->created_at
                        ? $p->created_at->format('Y-m-d H:i') : '',
                ];
            }),
        ]);
    }

    /**
     * 提交报修
     */
    public function store(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);
        $roomHashid = $request->input('room_id', '');
        $category = (int) $request->input('category', 1);
        $urgency = (int) $request->input('urgency', 1);
        $description = $request->input('description', '');
        $contactPhone = $request->input('contact_phone', '');
        $images = $request->input('images', []);
        $scheduledAt = $request->input('scheduled_at', '');

        if (empty($description)) {
            return $this->fail('请描述问题', 422);
        }

        try {
            $roomId = $this->decodeId($roomHashid);
        } catch (\Exception $e) {
            return $this->fail('房产信息无效', 422);
        }

        // 验证该房产属于当前业主
        $room = Room::whereHas('owners', function ($q) use ($ownerId) {
            $q->where('owner_id', $ownerId);
        })->find($roomId);

        if (!$room) {
            return $this->fail('房产不存在或无权操作', 403);
        }

        $order = RepairOrder::create([
            'id' => SnowflakeService::generate(),
            'order_number' => 'REP' . date('YmdHis') . rand(100, 999),
            'room_id' => $roomId,
            'owner_id' => $ownerId,
            'contact_phone' => $contactPhone,
            'category' => $category,
            'urgency' => $urgency,
            'description' => $description,
            'images' => json_encode($images),
            'scheduled_at' => $scheduledAt ?: null,
            'status' => 0,
        ]);

        return $this->success([
            'id' => $this->encodeId($order->id),
            'order_number' => $order->order_number,
        ], '报修提交成功');
    }

    /**
     * 取消报修
     */
    public function destroy(Request $request, string $hashid): Response
    {
        $ownerId = $this->getOwnerId($request);
        $password = $request->input('password', '');

        // 密码确认
        $error = $this->confirmPassword($ownerId, $password);
        if ($error !== null) {
            return $this->fail($error, 422);
        }

        $orderId = $this->decodeId($hashid);
        $order = RepairOrder::where('owner_id', $ownerId)->find($orderId);

        if (!$order) {
            return $this->fail('报修单不存在', 404);
        }

        if ($order->status !== 0) {
            return $this->fail('只有待派单状态的报修可以取消', 422);
        }

        $order->status = 5;
        $order->save();

        return $this->success([], '已取消');
    }

    /**
     * 评价报修
     */
    public function rate(Request $request, string $hashid): Response
    {
        $ownerId = $this->getOwnerId($request);
        $rating = (int) $request->input('rating', 5);
        $feedback = $request->input('feedback', '');

        if ($rating < 1 || $rating > 5) {
            return $this->fail('评分范围为1-5', 422);
        }

        $orderId = $this->decodeId($hashid);
        $order = RepairOrder::where('owner_id', $ownerId)->find($orderId);

        if (!$order) {
            return $this->fail('报修单不存在', 404);
        }

        if ($order->status !== 3) {
            return $this->fail('只有已完成的报修可以评价', 422);
        }

        $order->rating = $rating;
        $order->feedback = $feedback;
        $order->status = 4;
        $order->save();

        return $this->success([], '评价成功');
    }
}
```

- [ ] **Step 8: 创建 ComplaintController.php（投诉建议）**

```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;

use app\common\BaseController;
use app\common\SnowflakeService;
use app\model\Room;
use support\Request;
use support\Response;
use support\Db;

class ComplaintController extends BaseController
{
    /**
     * 投诉列表
     */
    public function index(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);

        $complaints = Db::table('erik_complaint')
            ->where('owner_id', $ownerId)
            ->orderBy('created_at', 'desc')
            ->paginate(20)
            ->through(function ($item) {
                return [
                    'id' => $this->encodeId((int) $item->id),
                    'type' => (int) $item->type,
                    'category' => (int) $item->category,
                    'title' => $item->title,
                    'status' => (int) $item->status,
                    'satisfaction' => (int) $item->satisfaction,
                    'created_at' => $item->created_at,
                ];
            });

        return $this->success($complaints);
    }

    /**
     * 投诉详情
     */
    public function show(Request $request, string $hashid): Response
    {
        $ownerId = $this->getOwnerId($request);
        $complaintId = $this->decodeId($hashid);

        $complaint = Db::table('erik_complaint')
            ->where('owner_id', $ownerId)
            ->find($complaintId);

        if (!$complaint) {
            return $this->fail('投诉不存在', 404);
        }

        return $this->success([
            'id' => $this->encodeId((int) $complaint->id),
            'type' => (int) $complaint->type,
            'category' => (int) $complaint->category,
            'title' => $complaint->title,
            'content' => $complaint->content,
            'images' => json_decode($complaint->images ?: '[]', true),
            'is_anonymous' => (int) $complaint->is_anonymous,
            'status' => (int) $complaint->status,
            'handler_remark' => $complaint->handler_remark ?? '',
            'handled_at' => $complaint->handled_at ?? '',
            'visitor_remark' => $complaint->visitor_remark ?? '',
            'visitor_at' => $complaint->visitor_at ?? '',
            'satisfaction' => (int) $complaint->satisfaction,
            'created_at' => $complaint->created_at,
        ]);
    }

    /**
     * 提交投诉/建议
     */
    public function store(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);
        $type = (int) $request->input('type', 1);
        $category = (int) $request->input('category', 1);
        $title = $request->input('title', '');
        $content = $request->input('content', '');
        $isAnonymous = (int) $request->input('is_anonymous', 0);
        $images = $request->input('images', []);

        if (empty($title) || empty($content)) {
            return $this->fail('标题和内容不能为空', 422);
        }

        Db::table('erik_complaint')->insert([
            'id' => SnowflakeService::generate(),
            'owner_id' => $ownerId,
            'type' => $type,
            'category' => $category,
            'title' => $title,
            'content' => $content,
            'images' => json_encode($images),
            'is_anonymous' => $isAnonymous,
            'status' => 0,
            'created_at' => date('Y-m-d H:i:s'),
            'updated_at' => date('Y-m-d H:i:s'),
        ]);

        return $this->success([], '提交成功');
    }

    /**
     * 满意度评价
     */
    public function satisfaction(Request $request, string $hashid): Response
    {
        $ownerId = $this->getOwnerId($request);
        $satisfaction = (int) $request->input('satisfaction', 5);

        $complaintId = $this->decodeId($hashid);
        $complaint = Db::table('erik_complaint')
            ->where('owner_id', $ownerId)
            ->find($complaintId);

        if (!$complaint) {
            return $this->fail('投诉不存在', 404);
        }

        if ((int) $complaint->status !== 2) {
            return $this->fail('只能评价已处理的投诉', 422);
        }

        Db::table('erik_complaint')
            ->where('id', $complaintId)
            ->update([
                'satisfaction' => $satisfaction,
                'updated_at' => date('Y-m-d H:i:s'),
            ]);

        return $this->success([], '评价成功');
    }
}
```

- [ ] **Step 9: 创建 AnnouncementController.php**

```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;

use app\common\BaseController;
use app\model\Announcement;
use support\Request;
use support\Response;

class AnnouncementController extends BaseController
{
    /**
     * 公告列表
     */
    public function index(Request $request): Response
    {
        $category = $request->input('category');

        $query = Announcement::where('is_published', 1);

        if ($category !== null && $category !== '') {
            $query->where('category', (int) $category);
        }

        $announcements = $query
            ->orderBy('is_top', 'desc')
            ->orderBy('published_at', 'desc')
            ->paginate(20)
            ->through(function ($item) {
                return [
                    'id' => $this->encodeId($item->id),
                    'title' => $item->title,
                    'category' => $item->category,
                    'is_top' => $item->is_top,
                    'published_at' => $item->published_at
                        ? $item->published_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($announcements);
    }

    /**
     * 公告详情
     */
    public function show(Request $request, string $hashid): Response
    {
        $announcementId = $this->decodeId($hashid);

        $announcement = Announcement::where('is_published', 1)->find($announcementId);

        if (!$announcement) {
            return $this->fail('公告不存在', 404);
        }

        return $this->success([
            'id' => $this->encodeId($announcement->id),
            'title' => $announcement->title,
            'content' => $announcement->content,
            'category' => $announcement->category,
            'is_top' => $announcement->is_top,
            'published_at' => $announcement->published_at
                ? $announcement->published_at->format('Y-m-d H:i') : '',
        ]);
    }
}
```

- [ ] **Step 10: 创建 ProfileController.php**

```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\api\v1\controller;

use app\common\BaseController;
use app\model\Owner;
use support\Request;
use support\Response;
use support\Redis;

class ProfileController extends BaseController
{
    /**
     * 个人信息
     */
    public function index(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);
        $owner = Owner::find($ownerId);

        if (!$owner) {
            return $this->fail('用户不存在', 404);
        }

        return $this->success([
            'id' => $this->encodeId($owner->id),
            'name' => $owner->name,
            'phone' => $this->maskPhone($owner->phone),
            'email' => $this->maskEmail($owner->email),
            'gender' => $owner->gender,
            'birthday' => $owner->birthday ? $owner->birthday->format('Y-m-d') : '',
            'created_at' => $owner->created_at
                ? $owner->created_at->format('Y-m-d H:i') : '',
        ]);
    }

    /**
     * 修改个人信息
     */
    public function update(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);
        $owner = Owner::find($ownerId);

        if (!$owner) {
            return $this->fail('用户不存在', 404);
        }

        $name = $request->input('name', $owner->name);
        $email = $request->input('email', $owner->email);
        $gender = (int) $request->input('gender', $owner->gender);
        $birthday = $request->input('birthday', '');

        $owner->name = $name;
        $owner->email = $email;
        $owner->gender = $gender;
        if (!empty($birthday)) {
            $owner->birthday = $birthday;
        }
        $owner->save();

        return $this->success([], '修改成功');
    }

    /**
     * 修改密码
     */
    public function updatePassword(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);
        $owner = Owner::find($ownerId);

        $oldPassword = $request->input('old_password', '');
        $newPassword = $request->input('new_password', '');

        if (empty($oldPassword) || empty($newPassword)) {
            return $this->fail('旧密码和新密码不能为空', 422);
        }

        if (!password_verify($oldPassword, $owner->password)) {
            return $this->fail('旧密码错误', 422);
        }

        if (strlen($newPassword) < 6) {
            return $this->fail('新密码至少6位', 422);
        }

        $owner->password = password_hash($newPassword, PASSWORD_BCRYPT);
        $owner->save();

        return $this->success([], '密码修改成功');
    }

    /**
     * 退出登录
     */
    public function logout(Request $request): Response
    {
        $ownerId = $this->getOwnerId($request);
        $token = $request->header('Authorization', '');
        $token = str_replace('Bearer ', '', $token);

        // 将当前 Token 加入黑名单
        try {
            Redis::setex('jwt_blacklist:' . md5($token), 7200, '1');
            Redis::del('owner_sessions:' . $ownerId);
        } catch (\Throwable $e) {
            // Redis down
        }

        return $this->success([], '已退出');
    }

    private function maskPhone(string $phone): string
    {
        if (strlen($phone) >= 7) {
            return substr($phone, 0, 3) . '****' . substr($phone, -4);
        }
        return $phone;
    }

    private function maskEmail(string $email): string
    {
        if (strpos($email, '@') !== false) {
            [$name, $domain] = explode('@', $email);
            return substr($name, 0, 1) . '***@' . $domain;
        }
        return $email;
    }
}
```

- [ ] **Step 11: 创建 service 端 process/Http.php**

```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\process;

use Workerman\Worker;
use support\App;

class Http
{
    public static function init(): void
    {
        $config = config('server');
        $worker = new Worker(
            $config['listen'] ?? 'http://0.0.0.0:8788',
            $config['context'] ?? []
        );
        $worker->name = $config['name'] ?? 'property-service';
        $worker->count = $config['count'] ?? cpu_count() * 2;
        $worker->user = $config['user'] ?? '';
        $worker->onMessage = [App::class, 'onMessage'];
    }

    public static function run(): void
    {
        Worker::runAll();
    }
}
```

- [ ] **Step 12: Commit**

```bash
git add service/app/api/ service/app/process/
git commit -m "feat(service): add batch 1 API controllers (Auth, Home, Room, Fee, Repair, Complaint, Announcement, Profile)"
```

---

### Task 8: service 端路由配置

**Files:**
- Modify: `service/config/route.php`

- [ ] **Step 1: 配置 route.php**

```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

use Webman\Route;
use support\Request;

/**
 * 物业管理系统-业务端 API 路由配置
 *
 * 路由分组说明:
 * - /service/*  业主端接口，需要 JWT 认证
 * - /api/*      公开接口（验证码、登录注册）
 * - /health     健康检查
 */

function v(string $controller, string $action): \Closure
{
    return function (Request $request) use ($controller, $action) {
        $version = $request->apiVersion ?? 'v1';
        $class = "\\app\\api\\{$version}\\controller\\{$controller}";
        return (new $class)->{$action}($request);
    };
}

// 健康检查
Route::get('/health', function () {
    return json(['code' => 0, 'message' => 'ok', 'data' => ['service' => 'property-service']]);
});

// 小区列表（公开，登录页选择小区用）
Route::get('/api/community/list', v('AuthController', 'communityList'));

// 公开接口
Route::group('/api', function () {
    Route::post('/captcha/generate', v('CaptchaController', 'generate'));
    Route::post('/auth/login', v('AuthController', 'login'));
    Route::post('/auth/register', v('AuthController', 'register'));
    Route::post('/auth/refresh', v('AuthController', 'refresh'));
})->middleware([
    app\middleware\ApiVersion::class,
]);

// 业主端认证接口
Route::group('/service', function () {
    // 首页
    Route::get('/home', [app\api\v1\controller\HomeController::class, 'index']);

    // 我的房产
    Route::get('/rooms', [app\api\v1\controller\RoomController::class, 'index']);
    Route::get('/room/{hashid}', [app\api\v1\controller\RoomController::class, 'show']);

    // 费用管理
    Route::get('/fees/bills', [app\api\v1\controller\FeeController::class, 'bills']);
    Route::get('/fees/bill/{hashid}', [app\api\v1\controller\FeeController::class, 'billDetail']);
    Route::get('/fees/payments', [app\api\v1\controller\FeeController::class, 'payments']);
    Route::post('/fees/pay', [app\api\v1\controller\FeeController::class, 'pay']);
    Route::get('/fees/statistics', [app\api\v1\controller\FeeController::class, 'statistics']);

    // 报修
    Route::get('/repairs', [app\api\v1\controller\RepairController::class, 'index']);
    Route::get('/repair/{hashid}', [app\api\v1\controller\RepairController::class, 'show']);
    Route::post('/repair', [app\api\v1\controller\RepairController::class, 'store']);
    Route::delete('/repair/{hashid}', [app\api\v1\controller\RepairController::class, 'destroy']);
    Route::post('/repair/{hashid}/rate', [app\api\v1\controller\RepairController::class, 'rate']);

    // 投诉建议
    Route::get('/complaints', [app\api\v1\controller\ComplaintController::class, 'index']);
    Route::get('/complaint/{hashid}', [app\api\v1\controller\ComplaintController::class, 'show']);
    Route::post('/complaint', [app\api\v1\controller\ComplaintController::class, 'store']);
    Route::post('/complaint/{hashid}/satisfaction', [app\api\v1\controller\ComplaintController::class, 'satisfaction']);

    // 公告
    Route::get('/announcements', [app\api\v1\controller\AnnouncementController::class, 'index']);
    Route::get('/announcement/{hashid}', [app\api\v1\controller\AnnouncementController::class, 'show']);

    // 个人信息
    Route::get('/profile', [app\api\v1\controller\ProfileController::class, 'index']);
    Route::put('/profile', [app\api\v1\controller\ProfileController::class, 'update']);
    Route::put('/profile/password', [app\api\v1\controller\ProfileController::class, 'updatePassword']);
    Route::post('/profile/logout', [app\api\v1\controller\ProfileController::class, 'logout']);
})->middleware([
    app\middleware\ServiceAuth::class,
]);

Route::disableDefaultRoute();
```

- [ ] **Step 2: Commit**

```bash
git add service/config/route.php
git commit -m "feat(service): add route configuration for batch 1 APIs"
```

---

### Task 9: admin 端扩展 — 业务模型

**Files** (在 `admin/app/model/` 下新增):
- 与 service 端模型对应，共13个 Model

直接从 `service/app/model/` 复制到 `admin/app/model/`：

```bash
cp service/app/model/Community.php admin/app/model/
cp service/app/model/Owner.php admin/app/model/
cp service/app/model/Room.php admin/app/model/
cp service/app/model/RoomOwner.php admin/app/model/
cp service/app/model/Tenant.php admin/app/model/
cp service/app/model/FeeType.php admin/app/model/
cp service/app/model/FeeBill.php admin/app/model/
cp service/app/model/FeePayment.php admin/app/model/
cp service/app/model/RepairOrder.php admin/app/model/
cp service/app/model/RepairProgress.php admin/app/model/
cp service/app/model/Announcement.php admin/app/model/
cp service/app/model/BaseModel.php admin/app/model/
```

同时新增 Building.php 和 Unit.php（admin 管理端需要，service 端暂时不需要）：

Building.php:
```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class Building extends BaseModel
{
    protected $table = 'erik_building';

    protected $fillable = [
        'community_id', 'name', 'building_type',
        'floor_count', 'unit_count', 'elevator_count',
        'build_year', 'structure_type', 'sort',
    ];

    protected $casts = [
        'building_type' => 'integer',
        'floor_count' => 'integer',
        'unit_count' => 'integer',
        'elevator_count' => 'integer',
        'sort' => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function community()
    {
        return $this->belongsTo(Community::class, 'community_id');
    }

    public function units()
    {
        return $this->hasMany(Unit::class, 'building_id');
    }
}
```

Unit.php:
```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class Unit extends BaseModel
{
    protected $table = 'erik_unit';

    protected $fillable = [
        'building_id', 'name', 'room_count_per_floor', 'sort',
    ];

    protected $casts = [
        'room_count_per_floor' => 'integer',
        'sort' => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function building()
    {
        return $this->belongsTo(Building::class, 'building_id');
    }
}
```

RoomType.php:
```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\model;

class RoomType extends BaseModel
{
    protected $table = 'erik_room_type';

    protected $fillable = [
        'name', 'bedrooms', 'halls', 'bathrooms', 'image',
    ];

    protected $casts = [
        'bedrooms' => 'integer',
        'halls' => 'integer',
        'bathrooms' => 'integer',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];
}
```

- [ ] **Step 1: 执行复制和创建**

```bash
mkdir -p admin/app/model
cp service/app/model/BaseModel.php admin/app/model/
cp service/app/model/Community.php admin/app/model/
cp service/app/model/Owner.php admin/app/model/
cp service/app/model/Room.php admin/app/model/
cp service/app/model/RoomOwner.php admin/app/model/
cp service/app/model/Tenant.php admin/app/model/
cp service/app/model/FeeType.php admin/app/model/
cp service/app/model/FeeBill.php admin/app/model/
cp service/app/model/FeePayment.php admin/app/model/
cp service/app/model/RepairOrder.php admin/app/model/
cp service/app/model/RepairProgress.php admin/app/model/
cp service/app/model/Announcement.php admin/app/model/
```

然后手动创建 Building.php、Unit.php、RoomType.php。

- [ ] **Step 2: Commit**

```bash
git add admin/app/model/
git commit -m "feat(admin): add batch 1 property management models"
```

---

### Task 10: admin 端扩展 — 核心业务控制器

**Files (新增):**
- Create: `admin/app/admin/controller/CommunityController.php`

由于控制器数量众多（15+），此处列出核心模式和完整示例，其余控制器可遵循相同模式创建。

- [ ] **Step 1: 创建 CommunityController.php**

```php
<?php
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

declare(strict_types=1);

namespace app\admin\controller;

use app\common\SnowflakeService;
use app\model\Community;
use support\Request;

class CommunityController extends BaseController
{
    /**
     * 小区列表
     * ?keyword=搜索词&status=状态&page=1&page_size=20
     */
    public function index(Request $request)
    {
        $keyword = $request->input('keyword', '');
        $status = $request->input('status');

        $query = Community::query();
        if (!empty($keyword)) {
            $query->where('name', 'like', "%{$keyword}%");
        }
        if ($status !== null && $status !== '') {
            $query->where('status', (int) $status);
        }

        $list = $query->orderBy('created_at', 'desc')
            ->paginate((int) $request->input('page_size', 20))
            ->through(function ($item) {
                return [
                    'id' => $this->encodeId($item->id),
                    'name' => $item->name,
                    'address' => $item->address,
                    'city' => $item->city,
                    'building_count' => $item->building_count,
                    'room_count' => $item->room_count,
                    'property_company' => $item->property_company,
                    'status' => $item->status,
                    'created_at' => $item->created_at ? $item->created_at->format('Y-m-d H:i') : '',
                ];
            });

        return $this->success($list);
    }

    /**
     * 小区详情
     */
    public function show(Request $request, string $hashid)
    {
        $id = $this->decodeId($hashid);
        $item = Community::find($id);
        if (!$item) {
            return $this->fail('小区不存在', 404);
        }

        return $this->success([
            'id' => $this->encodeId($item->id),
            'name' => $item->name,
            'address' => $item->address,
            'province' => $item->province,
            'city' => $item->city,
            'district' => $item->district,
            'area_total' => $item->area_total,
            'building_count' => $item->building_count,
            'room_count' => $item->room_count,
            'developer' => $item->developer,
            'property_company' => $item->property_company,
            'contact_phone' => $item->contact_phone,
            'description' => $item->description,
            'status' => $item->status,
        ]);
    }

    /**
     * 创建小区
     */
    public function store(Request $request)
    {
        $data = $request->only([
            'name', 'address', 'province', 'city', 'district',
            'area_total', 'developer', 'property_company',
            'contact_phone', 'description',
        ]);

        if (empty($data['name'])) {
            return $this->fail('小区名称不能为空', 422);
        }

        $data['id'] = SnowflakeService::generate();
        $data['status'] = 1;

        Community::create($data);

        return $this->success(['id' => $this->encodeId($data['id'])], '创建成功');
    }

    /**
     * 更新小区
     */
    public function update(Request $request, string $hashid)
    {
        $id = $this->decodeId($hashid);
        $item = Community::find($id);
        if (!$item) {
            return $this->fail('小区不存在', 404);
        }

        $item->fill($request->only([
            'name', 'address', 'province', 'city', 'district',
            'area_total', 'developer', 'property_company',
            'contact_phone', 'description', 'status',
        ]));
        $item->save();

        return $this->success([], '更新成功');
    }

    /**
     * 删除小区（需密码确认）
     */
    public function destroy(Request $request, string $hashid)
    {
        $adminId = $request->adminId;
        $password = $request->input('password', '');

        $error = $this->confirmPassword($adminId, $password, $request);
        if ($error !== null) {
            return $this->fail($error, 422);
        }

        $id = $this->decodeId($hashid);
        $item = Community::find($id);
        if (!$item) {
            return $this->fail('小区不存在', 404);
        }

        $item->delete();

        return $this->success([], '删除成功');
    }
}
```

- [ ] **Step 2: 扩展 admin 路由**

在 `admin/config/route.php` 的 `/admin` 路由组内新增：

```php
// 小区管理
Route::resource('/community', app\admin\controller\CommunityController::class);
// 楼栋管理
Route::resource('/building', app\admin\controller\BuildingController::class);
// 单元管理
Route::resource('/unit', app\admin\controller\UnitController::class);
// 户型管理
Route::resource('/room-type', app\admin\controller\RoomTypeController::class);
// 房产管理
Route::resource('/room', app\admin\controller\RoomController::class);
Route::get('/room/tree', [app\admin\controller\RoomController::class, 'tree']);
// 业主管理
Route::resource('/owner', app\admin\controller\OwnerController::class);
Route::post('/owner/batch/import', [app\admin\controller\OwnerController::class, 'batchImport']);
Route::post('/owner/batch/destroy', [app\admin\controller\OwnerController::class, 'batchDestroy']);
// 租户管理
Route::resource('/tenant', app\admin\controller\TenantController::class);
// 费用类型
Route::resource('/fee-type', app\admin\controller\FeeTypeController::class);
// 账单管理
Route::resource('/fee-bill', app\admin\controller\FeeBillController::class);
Route::post('/fee-bill/batch/generate', [app\admin\controller\FeeBillController::class, 'batchGenerate']);
// 缴费记录
Route::get('/fee-payment', [app\admin\controller\FeePaymentController::class, 'index']);
Route::post('/fee-payment/offline', [app\admin\controller\FeePaymentController::class, 'offlinePay']);
// 报修管理
Route::resource('/repair', app\admin\controller\RepairController::class);
Route::put('/repair/{id}/assign', [app\admin\controller\RepairController::class, 'assign']);
Route::post('/repair/{id}/progress', [app\admin\controller\RepairController::class, 'progress']);
// 公告管理
Route::resource('/announcement', app\admin\controller\AnnouncementController::class);
```

- [ ] **Step 3: Commit**

```bash
git add admin/app/admin/controller/CommunityController.php admin/config/route.php
git commit -m "feat(admin): add CommunityController and batch 1 admin routes"
```

---

### Task 11: Flutter Web 项目基础 — 业主端

**Files:**
- Create: `apps/flutter/pubspec.yaml`
- Create: `apps/flutter/lib/main.dart`
- Create: `apps/flutter/lib/app.dart`
- Create: `apps/flutter/lib/config/api_config.dart`
- Create: `apps/flutter/lib/config/theme.dart`
- Create: `apps/flutter/lib/services/api_service.dart`
- Create: `apps/flutter/lib/services/auth_service.dart`

- [ ] **Step 1: 创建 Flutter 项目**

```bash
cd /home/wwwroot/property-management-platform/apps
flutter create --project-name property_portal --org com.erik flutter
```

- [ ] **Step 2: 更新 pubspec.yaml 依赖**

```yaml
dependencies:
  flutter:
    sdk: flutter
  get: ^4.6.6
  dio: ^5.4.0
  shared_preferences: ^2.2.2
  fl_chart: ^0.68.0
  excel: ^4.0.0
  pdf: ^3.10.0
  printing: ^5.12.0
  intl: ^0.19.0
  image_picker: ^1.0.7
```

- [ ] **Step 3: 创建 api_config.dart**

```dart
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

/// API 配置 — 业主端
class ApiConfig {
  static const String baseUrl = 'http://localhost:8788';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // 公开接口
  static const String captchaGenerate = '/api/captcha/generate';
  static const String authLogin = '/api/auth/login';
  static const String authRegister = '/api/auth/register';
  static const String authRefresh = '/api/auth/refresh';

  // 业主端接口
  static const String home = '/service/home';
  static const String rooms = '/service/rooms';
  static String roomDetail(String hashid) => '/service/room/$hashid';
  static const String feeBills = '/service/fees/bills';
  static String feeBillDetail(String hashid) => '/service/fees/bill/$hashid';
  static const String feePayments = '/service/fees/payments';
  static const String feePay = '/service/fees/pay';
  static const String feeStatistics = '/service/fees/statistics';
  static const String repairs = '/service/repairs';
  static String repairDetail(String hashid) => '/service/repair/$hashid';
  static const String repairStore = '/service/repair';
  static String repairDelete(String hashid) => '/service/repair/$hashid';
  static String repairRate(String hashid) => '/service/repair/$hashid/rate';
  static const String complaints = '/service/complaints';
  static String complaintDetail(String hashid) => '/service/complaint/$hashid';
  static const String complaintStore = '/service/complaint';
  static const String announcements = '/service/announcements';
  static String announcementDetail(String hashid) => '/service/announcement/$hashid';
  static const String profile = '/service/profile';
  static const String profilePassword = '/service/profile/password';
  static const String profileLogout = '/service/profile/logout';
}
```

- [ ] **Step 4: 创建 theme.dart**

```dart
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';

/// 物业管理系统 — PC 风格主题
class AppTheme {
  static const Color primary = Color(0xFF1677FF);
  static const Color success = Color(0xFF52C41A);
  static const Color warning = Color(0xFFFA8C16);
  static const Color danger = Color(0xFFFF4D4F);
  static const Color bgGray = Color(0xFFF5F5F5);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: primary,
    brightness: Brightness.light,
    scaffoldBackgroundColor: bgGray,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 1,
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF262626),
    ),
    cardTheme: CardTheme(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dataTableTheme: const DataTableThemeData(
      headingRowHeight: 40,
      dataRowMinHeight: 36,
      dataRowMaxHeight: 44,
      dividerThickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      isDense: true,
    ),
  );
}
```

- [ ] **Step 5: 创建 api_service.dart**

```dart
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

/// API 服务 — Dio 单例 + JWT 拦截器
class ApiService extends GetxService {
  late final Dio dio;

  @override
  void onInit() {
    super.onInit();
    dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    // JWT 拦截器
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // 401 自动刷新 Token
        if (error.response?.statusCode == 401) {
          final prefs = await SharedPreferences.getInstance();
          final refreshToken = prefs.getString('refresh_token');
          if (refreshToken != null) {
            try {
              final response = await Dio(BaseOptions(
                baseUrl: ApiConfig.baseUrl,
              )).post(ApiConfig.authRefresh, data: {
                'refresh_token': refreshToken,
              });
              final newToken = response.data['data']['access_token'];
              await prefs.setString('access_token', newToken);
              error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              final retryResponse = await dio.fetch(error.requestOptions);
              return handler.resolve(retryResponse);
            } catch (e) {
              await prefs.clear();
              Get.offAllNamed('/login');
              return handler.reject(error);
            }
          } else {
            Get.offAllNamed('/login');
          }
        }
        handler.next(error);
      },
    ));
  }
}
```

- [ ] **Step 6: 创建 auth_service.dart**

```dart
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'api_service.dart';

/// 认证服务
class AuthService extends GetxService {
  final _isLoggedIn = false.obs;
  bool get isLoggedIn => _isLoggedIn.value;
  set isLoggedIn(bool value) => _isLoggedIn.value = value;

  late final ApiService _api;

  @override
  void onInit() {
    super.onInit();
    _api = Get.find<ApiService>();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    isLoggedIn = token != null && token.isNotEmpty;
  }

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
    required String captchaKey,
    required List<Map<String, int>> clicks,
  }) async {
    final response = await _api.dio.post(ApiConfig.authLogin, data: {
      'phone': phone,
      'password': password,
      'captcha_key': captchaKey,
      'clicks': clicks,
    });

    final data = response.data['data'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', data['access_token']);
    await prefs.setString('refresh_token', data['refresh_token']);
    await prefs.setString('owner_name', data['owner']['name'] ?? '');

    isLoggedIn = true;
    return data;
  }

  Future<void> logout() async {
    try {
      await _api.dio.post(ApiConfig.profileLogout);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    isLoggedIn = false;
    Get.offAllNamed('/login');
  }
}
```

- [ ] `**Step 7: 创建 app.dart 和 main.dart**

main.dart:
```dart
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Get.putAsync(() async => ApiService());
  await Get.putAsync(() async => AuthService());
  runApp(const PortalApp());
}
```

app.dart:
```dart
/*
 * Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
 */

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'config/theme.dart';
import 'pages/login/login_page.dart';
import 'pages/home/home_page.dart';

class PortalApp extends StatelessWidget {
  const PortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '物业管理平台',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/home', page: () => const HomePage()),
        // 更多路由...
      ],
    );
  }
}
```

- [ ] **Step 8: 验证 Flutter 项目**

```bash
cd /home/wwwroot/property-management-platform/apps/flutter
flutter pub get
flutter analyze
```
Expected: 通过静态分析，无错误。

- [ ] **Step 9: Commit**

```bash
git add apps/flutter/
git commit -m "feat(flutter): scaffold portal Flutter Web project with PC-style theme"
```

---

### Task 12: 验证 service 端可运行

- [ ] **Step 1: 启动 service 并测试**

```bash
cd /home/wwwroot/property-management-platform/service
php start.php start -d
```

- [ ] **Step 2: 测试健康检查**

```bash
curl http://localhost:8788/health
```
Expected: `{"code":0,"message":"ok","data":{"service":"property-service"}}`

- [ ] **Step 3: 验证数据库连接**

```bash
mysql -u root property_management -e "SHOW TABLES LIKE 'erik_%';"
```
Expected: 列出所有已创建的表。

---

## 后续计划

第1批（核心业务）完成后，进入：

**第2批（辅助业务）：**
- 停车管理、设备管理、投诉管理、访客管理、合同管理、财务管理
- 10张新表 + 对应模型 + API控制器 + admin控制器
- Flutter 辅助页面 + 面板可视化 + Excel/PDF导出

**第3批（高级功能）：**
- 安保巡逻、保洁绿化、社区活动、能耗管理
- 10张新表 + 对应模型 + API控制器 + admin控制器
- HarmonyOS 项目
- ES 全文检索集成
- 性能优化与监控完善
