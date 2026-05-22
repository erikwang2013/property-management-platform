# 物业管理系统 — 完整设计规范

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## 项目概述

物业管理系统，包含管理员端（admin）和业主业务端（service），前端覆盖 Flutter Web（PC风格）、HarmonyOS App。

### 项目结构

```
property-management-platform/
├── admin/                         # 管理端 webman v2 项目（独立）
│   ├── app/                       # PHP 应用代码
│   │   ├── admin/controller/      # 管理端控制器（已有+扩展15模块）
│   │   ├── api/v1/controller/     # 公开API（已有 Captcha/Auth）
│   │   ├── common/                # Hashids/Snowflake/Encryption
│   │   ├── middleware/            # 7个中间件
│   │   ├── model/                 # 数据模型（已有+扩展35个）
│   │   ├── queue/                 # 队列任务
│   │   └── process/               # 进程
│   ├── apps/
│   │   ├── flutter/               # 管理后台 Flutter Web (PC风格)
│   │   └── harmonyos/             # 管理后台 HarmonyOS App
│   ├── config/                    # 配置文件（含中文注释）
│   ├── database/migrations/       # SQL迁移文件
│   ├── docs/                      # 文档
│   ├── tests/                     # 测试
│   └── ...                        # Docker/CI/Env
├── service/                       # 业务端 webman v2 项目（独立）
│   ├── app/
│   │   ├── api/v1/controller/     # 业主端控制器
│   │   ├── common/                # 工具类
│   │   ├── middleware/            # ServiceAuth/SecurityFilter/RateLimit
│   │   └── model/                 # 业务模型
│   ├── config/
│   ├── database/migrations/
│   └── tests/
└── apps/
    ├── flutter/                   # 业主端 Flutter Web (PC风格)
    └── harmonyos/                 # 业主端 HarmonyOS App
```

### 技术栈

- PHP 8.3+, webman v2
- MySQL 8.0+（表前缀 `erik_`，主键 BIGINT 非自增）
- Snowflake ID 生成（`erikwang2013/snowflake-php`）
- Hashids ID 编解码（`erikwang2013/hashids`）
- JWT 认证（`erikwang2013/jwt-webman`）
- API 加密（`erikwang2013/encryption`）
- DB 加密（`erikwang2013/encryptable`）
- ES 搜索引擎（`erikwang2013/webman-scout`）
- 国家旗帜（`erikwang2013/season`）
- 安全检测（`erikwang2013/security-php`）
- 随机验证（`erikwang2013/poster-php`）
- Excel 导出（`phpoffice/phpspreadsheet`）
- PDF 导出（`barryvdh/laravel-dompdf`）
- Flutter 3.x, GetX, Dio, fl_chart
- HarmonyOS ArkTS, @ohos.net.http

### 代码规范

- 版权声明：所有新建文件头包含 `Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz`
- 全局变量不加前置 `\`，使用 `use` 导入
- 配置文件包含中文注释
- ID 传输使用 Hashids 编码

---

## 第1章：数据库设计（35张业务表 + 已有表）

### 第1批：核心业务（14张表）

**erik_community**（小区）：id, name, address, province/city/district, area_total, building_count, room_count, developer, property_company, contact_phone(加密), description, status, created_at/updated_at/deleted_at

**erik_building**（楼栋）：id, community_id(FK), name, building_type(1塔楼2板楼3别墅4商业), floor_count, unit_count, elevator_count, build_year, structure_type, sort, created_at/updated_at

**erik_unit**（单元）：id, building_id(FK), name, room_count_per_floor, sort, created_at/updated_at

**erik_room**（房产）：id, community_id(FK), building_id(FK), unit_id(FK), room_number, floor, room_type_id(FK), area_indoor, area_shared, area_total, orientation, decoration(1毛坯2简装3精装4豪装), usage_type(1住宅2商业3办公4仓储), status(0空置1已售2出租3自住), remark, created_at/updated_at/deleted_at

**erik_room_type**（户型）：id, name, bedrooms, halls, bathrooms, image, created_at/updated_at

**erik_owner**（业主）：id, name, phone(加密), email(加密), id_card(加密), gender, birthday, emergency_contact(加密), emergency_phone(加密), check_in_date, remark, status(0迁出1入住), created_at/updated_at/deleted_at

**erik_room_owner**（房产-业主关联）：id, room_id(FK), owner_id(FK), relation_type(1所有权2使用权3共有), ownership_ratio, cert_number, start_date, end_date, created_at/updated_at

**erik_tenant**（租户）：id, room_id(FK), owner_id(FK), name, phone(加密), id_card(加密), lease_start, lease_end, rent_amount, status(0到期1在租), created_at/updated_at

**erik_fee_type**（费用类型）：id, name, category(1物业费2水费3电费4燃气5暖气6停车7维修基金8其他), unit_price, unit_type(1元/m²/月2元/吨3元/度4元/月/辆5固定), cycle_type(1每月2每季3每半年4每年5一次性), is_required, sort, created_at/updated_at

**erik_fee_bill**（费用账单）：id, room_id(FK), owner_id(FK), fee_type_id(FK), bill_number, amount, paid_amount, late_fee, start_date, end_date, due_date, status(0未缴1部分缴2已缴3逾期4豁免), paid_at, remark, created_at/updated_at

**erik_fee_payment**（缴费记录）：id, bill_id(FK), owner_id(FK), payment_number, amount, payment_method(1微信2支付宝3现金4银行转账5刷卡), payment_channel(1在线2线下), paid_at, operator_id, receipt_url, remark, created_at

**erik_repair_order**（报修单）：id, order_number, room_id(FK), owner_id(FK), contact_phone(加密), category(1水电2门窗3墙面地面4管道5家电6电梯7公共设施8其他), urgency(1普通2紧急3非常紧急), description, images(JSON), scheduled_at, status(0待派单1已派单2维修中3已完成4已评价5已取消), staff_id(FK), completed_at, rating(1-5), feedback, created_at/updated_at

**erik_repair_progress**（报修进度）：id, repair_order_id(FK), staff_id(FK), status_from, status_to, remark, images(JSON), created_at

**erik_announcement**（公告）：id, community_id(FK), title, content, category(1通知2公告3提醒4活动), is_top, is_published, published_at, publisher_id, created_at/updated_at/deleted_at

### 第2批：辅助业务（10张表）

**erik_parking_space**（停车位）：id, community_id(FK), space_number, space_type(1地上2地下), area, status(0空闲1已售2已租3维修), fee_monthly, created_at/updated_at

**erik_parking_vehicle**（车辆）：id, owner_id(FK), space_id(FK), plate_number(加密), vehicle_brand, vehicle_color, vehicle_type(1小汽车2SUV3MPV4货车5新能源), start_date, end_date, status(0过期1正常), created_at/updated_at

**erik_parking_record**（停车记录）：id, vehicle_id(FK), space_id(FK), entry_time, exit_time, duration, fee, created_at

**erik_complaint**（投诉建议）：id, owner_id(FK), room_id(FK), type(1投诉2建议3表扬), category(1服务2环境3安全4设施5噪音6违建7其他), title, content, images(JSON), is_anonymous, status(0待处理1处理中2已处理3已回访4已关闭), handler_id, handler_remark, handled_at, visitor_id, visitor_remark, visitor_at, satisfaction(1-5), created_at/updated_at

**erik_visitor**（访客）：id, room_id(FK), owner_id(FK), visitor_name, visitor_phone(加密), visitor_id_card(加密), plate_number(加密), visitor_count, purpose, expected_start, expected_end, actual_start, actual_end, pass_code, status(0已预约1已到访2已离开3已取消), created_at/updated_at

**erik_equipment**（设备）：id, community_id(FK), name, equipment_number, category(1电梯2消防3门禁4监控5给排水6供电7暖通8其他), brand, model, location, install_date, warranty_end, service_life, status(0故障1正常2维修3报废), created_at/updated_at

**erik_equipment_maintenance**（设备维保）：id, equipment_id(FK), maintenance_type(1日常巡检2定期保养3故障维修4大修5更换), description, staff_id, cost, company, started_at, completed_at, result, next_at, created_at/updated_at

**erik_contract**（合同）：id, contract_number, contract_type(1物业2租赁3维保4服务5采购), party_a_type, party_a_id, party_b_type, party_b_id, title, amount, start_date, end_date, sign_date, content(JSON), attachments(JSON), status(0草稿1履行中2已到期3已终止4续签), created_at/updated_at

**erik_finance_income**（财务收入）：id, income_number, income_type(1物业费2停车费3租金4广告费5维修基金6其他), amount, payer_type, payer_id, payment_method, income_date, operator_id, remark, created_at/updated_at

**erik_finance_expense**（财务支出）：id, expense_number, expense_type(1人力成本2设备采购3维保维修4水电能耗5保洁绿化6办公费用7税金8其他), amount, payee, expense_date, operator_id, receipt_url, remark, created_at/updated_at

### 第3批：高级功能（10张表）

**erik_security_patrol**（巡逻路线）：id, community_id(FK), name, route_points(JSON), checkpoints(JSON), sort, status, created_at/updated_at

**erik_patrol_record**（巡逻记录）：id, patrol_id(FK), staff_id(FK), started_at, ended_at, duration, checkpoints_done(JSON), abnormal_note, created_at

**erik_cleaning_area**（保洁区域）：id, community_id(FK), name, location, area, frequency(1每日2每周3每半月4每月), responsible_staff, sort, status, created_at/updated_at

**erik_cleaning_record**（保洁记录）：id, area_id(FK), staff_id, cleaned_at, status(0未清洁1已清洁), inspector_id, inspection_remark, inspection_at, images(JSON), created_at

**erik_green_area**（绿化区域）：id, community_id(FK), name, location, area, plant_types, responsible_staff, sort, status, created_at/updated_at

**erik_green_maintenance**（绿化养护）：id, area_id(FK), maintenance_type(1浇水2修剪3施肥4除虫5补种), staff_id, description, cost, maintained_at, created_at

**erik_community_activity**（社区活动）：id, community_id(FK), title, content, category(1文体2节日3公益4讲座5亲子6其他), cover_image, location, max_participants, start_time, end_time, signup_start, signup_end, is_free, cost, organizer, contact_phone(加密), status(0草稿1报名中2进行中3已结束4已取消), created_at/updated_at

**erik_activity_signup**（活动报名）：id, activity_id(FK), owner_id(FK), participant_count, contact_phone(加密), remark, signup_status(0已报名1已签到2已取消), signup_at, checkin_at, created_at

**erik_energy_meter**（能耗仪表）：id, room_id(FK), meter_type(1电表2水表3燃气表4暖气表), meter_number, install_reading, install_date, status, created_at/updated_at

**erik_energy_record**（能耗记录）：id, meter_id(FK), room_id(FK), reading, previous_reading, usage_amount, unit_price, amount, record_date, reader_id, bill_id(FK), created_at

**erik_staff**（员工）：id, community_id(FK), name, phone(加密), id_card(加密), job_title, department(1管理2客服3工程4安保5保洁6绿化7财务), hire_date, salary(加密), status(0离职1在职2休假), created_at/updated_at

### 已有表（admin 项目）

erik_admin_user, erik_admin_role, erik_admin_permission, erik_admin_user_role, erik_admin_role_permission, erik_system_config, erik_operation_log

---

## 第2章：service 业务端 API 设计

### 中间件执行链

```
/service/* : SecurityFilter → RateLimit → ServiceAuth(JWT) → Controller
/api/*     : SecurityFilter → RateLimit → ApiVersion → Controller
```

### API 端点

**公开接口（无需认证）**
- `POST /api/captcha/generate` — 获取点击验证码
- `POST /api/auth/login` — 业主登录
- `POST /api/auth/register` — 业主注册（需房产绑定验证）
- `POST /api/auth/refresh` — 刷新Token
- `GET /api/community/list` — 小区列表

**首页**
- `GET /service/home` — 首页数据

**我的房产**
- `GET /service/rooms` — 列表
- `GET /service/room/{hashid}` — 详情

**费用管理**
- `GET /service/fees/bills` — 账单列表
- `GET /service/fees/bill/{hashid}` — 账单详情
- `GET /service/fees/payments` — 缴费记录
- `POST /service/fees/pay` — 在线缴费（需密码确认）
- `GET /service/fees/statistics` — 费用统计

**报修**
- `GET /service/repairs` — 列表
- `GET /service/repair/{hashid}` — 详情
- `POST /service/repair` — 提交
- `PUT /service/repair/{hashid}` — 修改（仅待派单）
- `DELETE /service/repair/{hashid}` — 取消（需密码确认）
- `POST /service/repair/{hashid}/rate` — 评价

**投诉建议**
- `GET /service/complaints` — 列表
- `GET /service/complaint/{hashid}` — 详情
- `POST /service/complaint` — 提交
- `POST /service/complaint/{hashid}/satisfaction` — 满意度

**公告**
- `GET /service/announcements` — 列表
- `GET /service/announcement/{hashid}` — 详情

**社区活动**
- `GET /service/activities` — 列表
- `GET /service/activity/{hashid}` — 详情
- `POST /service/activity/{hashid}/signup` — 报名
- `POST /service/activity/{hashid}/cancel` — 取消

**访客**
- `GET /service/visitors` — 列表
- `POST /service/visitor` — 预约
- `PUT /service/visitor/{hashid}` — 修改
- `DELETE /service/visitor/{hashid}` — 取消

**停车**
- `GET /service/parking/vehicles` — 车辆列表
- `GET /service/parking/spaces` — 车位列表
- `GET /service/parking/records` — 停车记录

**个人信息**
- `GET /service/profile` — 获取
- `PUT /service/profile` — 修改
- `PUT /service/profile/password` — 改密码
- `POST /service/profile/logout` — 退出登录

### 设计要点

- 统一响应格式：`{"code": 0, "message": "success", "data": {...}}`
- 所有ID传输使用Hashids编解码
- 敏感字段使用encryption/encryptable加解密
- 业主注册需房产绑定验证（房号+姓名+身份证后4位）
- 在线缴费需密码二次确认

---

## 第3章：admin 管理端扩展

### 新增控制器（15模块 + 扩展）

**业务模块控制器：** CommunityController, BuildingController, UnitController, RoomTypeController, RoomController, OwnerController, TenantController, FeeTypeController, FeeBillController, FeePaymentController, RepairController, ComplaintController, AnnouncementController, ParkingController(Space/Vehicle/Record), VisitorController, EquipmentController, EquipmentMaintenanceController, ContractController, FinanceController(Income/Expense/Statistics), SecurityPatrolController, CleaningController(Area/Record), GreenController(Area/Maintenance), ActivityController, EnergyController(Meter/Record), StaffController

**已有扩展：** DashboardController（新增物业统计面板）、ExportController（新增物业数据导出）、ImportController（新增批量导入）

### 敏感操作确认

删除小区/楼栋/房屋/账单、强制取消报修、合并业主、合同终止、财务删改等需 `confirmPassword()`。

### 新增模型

所有业务表对应的 Model，使用 encryptable trait 处理敏感字段，使用 webman-scout trait 实现 ES 同步。

---

## 第4章：Flutter Web 前端

### 两套项目

- `apps/flutter/` — 业主端（PC门户风格）
- `admin/apps/flutter/` — 管理端（PC后台风格）

### 技术选型

GetX 状态管理 + Dio HTTP + fl_chart 图表 + shared_preferences 持久化

### PC风格特征

- 管理端：可折叠侧边栏(64/240px) + 顶栏 + 内容区
- 业主端：顶栏导航 + 内容区
- 高密度数据表格、鼠标悬停交互、键盘快捷键
- 响应式断点：768px

### 核心功能

- JWT拦截器（401自动刷新）
- 点击验证码组件（GestureDetector + Stack）
- 密码确认弹窗（敏感操作）
- Excel/PDF导出
- 面板可视化（折线图、饼图、柱状图）
- 权限控制组件（菜单+按钮级）

---

## 第5章：HarmonyOS App

### 两套项目

- `apps/harmonyos/` — 业主端
- `admin/apps/harmonyos/` — 管理端

### 技术选型

ArkTS + @ohos.net.http + Preference 持久化

### 核心功能

- Token无感刷新（401拦截）
- Canvas点击验证码
- List+LazyForEach长列表
- 下拉刷新+上滑加载
- 管理端ECharts图表（Web组件）
- 密码确认弹窗

### 与Flutter Web差异

| 特性 | Flutter Web (PC) | HarmonyOS (Mobile) |
|------|-----------------|-------------------|
| 布局 | 侧边栏+顶栏+内容区 | 单列纵向滚动 |
| 表格 | 高密度DataTable | 卡片列表Card+List |
| 操作 | 行内按钮+右键菜单 | 长按弹出菜单 |
| 图表 | fl_chart | Web+ECharts |
| 导出 | 浏览器下载 | 保存本地+分享 |

---

## 第6章：安全与部署

### 18层纵深防御

1. 点击验证码 → 2. 二次密码确认 → 3. poster随机验证 → 4. security-php安全扫描 → 5. SecurityFilter攻击拦截 → 6. HTTPS+AES传输 → 7. JWT HS256 → 8. 并发Token限制 → 9. 账号锁定 → 10. RBAC权限 → 11. 限流 → 12. Hashids ID保护 → 13. 请求体加密 → 14. 存储加密 → 15. 展示脱敏 → 16. 审计日志 → 17. CSP头 → 18. PDF版权水印

### 部署拓扑

```
Nginx(:443) → admin webman(:8787) + service webman(:8788) → MySQL + Redis + ES
静态文件: Flutter Web build/
```

### 开发顺序（方案B — 3批交付）

**第1批（核心）：** 数据库14张表 + service核心API + admin核心模块 + Flutter基础框架
**第2批（辅助）：** 数据库10张表 + service/api辅助模块 + admin辅助模块 + 面板可视化 + Excel/PDF导出
**第3批（高级）：** 数据库10张表 + 高级模块 + HarmonyOS App + ES搜索 + 性能优化
