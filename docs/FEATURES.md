# 功能文档 (Features)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## 功能清单

| 序号 | 模块 | 所属批次 | 管理员端 | 业主端 | 数据表 |
|------|------|---------|---------|--------|--------|
| 1 | 小区管理 | 第1批 | CRUD + 搜索分页 | 绑定小区查看 | erik_community |
| 2 | 楼栋管理 | 第1批 | CRUD + 按小区筛选 | - | erik_building |
| 3 | 单元管理 | 第1批 | CRUD + 按楼栋筛选 | - | erik_unit |
| 4 | 户型管理 | 第1批 | CRUD | - | erik_room_type |
| 5 | 房产管理 | 第1批 | CRUD + 房屋树 + 批量绑定业主 | 我的房产列表/详情 | erik_room |
| 6 | 业主管理 | 第1批 | CRUD + 批量导入/启禁用/删除 | 注册/登录/个人信息 | erik_owner, erik_room_owner |
| 7 | 租户管理 | 第1批 | CRUD + 按房产筛选 | - | erik_tenant |
| 8 | 费用管理 | 第1批 | 费用类型CRUD + 账单管理 + 批量生成 + 线下收款 | 账单查询 + 在线缴费 + 费用统计 | erik_fee_type, erik_fee_bill, erik_fee_payment |
| 9 | 报修管理 | 第1批 | 报修列表 + 派单 + 进度更新 | 提交报修 + 查看进度 + 评价 | erik_repair_order, erik_repair_progress |
| 10 | 公告通知 | 第1批 | CRUD + 发布/置顶 | 公告列表/详情 | erik_announcement |
| 11 | 停车管理 | 第2批 | 车位/车辆管理 + 停车记录 | 我的车位/车辆 + 停车记录 | erik_parking_space, erik_parking_vehicle, erik_parking_record |
| 12 | 设备管理 | 第2批 | 设备台账 + 维保记录 | - | erik_equipment, erik_equipment_maintenance |
| 13 | 投诉建议 | 第2批 | 投诉列表 + 处理 + 回访 | 提交投诉 + 查看进度 + 评价 | erik_complaint |
| 14 | 访客管理 | 第2批 | 访客审批 + 记录查询 | 访客预约 + 通行码 | erik_visitor |
| 15 | 合同管理 | 第2批 | CRUD + 状态管理 | - | erik_contract |
| 16 | 财务管理 | 第2批 | 收支管理 + 统计报表 | - | erik_finance_income, erik_finance_expense |
| 17 | 安保巡逻 | 第3批 | 巡逻路线 + 巡逻记录 | - | erik_security_patrol, erik_patrol_record |
| 18 | 保洁管理 | 第3批 | 保洁区域 + 保洁记录 | - | erik_cleaning_area, erik_cleaning_record |
| 19 | 绿化管理 | 第3批 | 绿化区域 + 养护记录 | - | erik_green_area, erik_green_maintenance |
| 20 | 社区活动 | 第3批 | 活动管理 + 报名查看 | 活动列表 + 报名 | erik_community_activity, erik_activity_signup |
| 21 | 能耗管理 | 第3批 | 仪表管理 + 抄表记录 | - | erik_energy_meter, erik_energy_record |
| 22 | 员工管理 | 第3批 | CRUD + 状态管理 | - | erik_staff |

## 管理后台模块（admin 已有）

| 模块 | 功能 |
|------|------|
| 仪表盘 | 实时统计/趋势/分布/日志（Redis 5m 缓存）|
| 用户管理 | 管理员用户 CRUD + 批量删除/启禁用 + Excel 导入 |
| 角色权限 | CRUD + 权限树 + RBAC method.path 鉴权 |
| 系统配置 | 键值对 CRUD |
| 操作审计 | 日志查询 + 8 平台来源端自动检测 |
| 文件管理 | 上传 + Excel/PDF 导出（敏感数据脱敏）|
| 安全管理 | 18 层纵深防御 + security.txt |
| 运维监控 | 健康检查 + Prometheus 指标 + API 文档 |
| 国际化 | 中文/英文双语，PHP symfony/translation + Flutter GetX Translations + HarmonyOS 资源限定符 |

## 跨功能特性

### ID 加密传输
所有 API 接口请求和响应中的 ID 字段使用 `erikwang2013/hashids` 编解码。客户端收到的是 hashid 字符串（如 `aB3xK9mW2pQ7rT5v`），后端解码为 BIGINT 操作。

### 敏感数据保护
- API 传输层：`erikwang2013/encryption` — AES-256-CBC
- 数据库存储层：`erikwang2013/encryptable` — Eloquent Model casts 自动加解密
- 前端展示层：手机号 138****1234，邮箱 a***@e.com

### 操作审计
所有管理端 POST/PUT/DELETE 操作自动记录，包含操作用户、IP、路径、参数（已脱敏）、操作时间、来源端（web/ios/android/harmonyos/windows/macos/linux/ipados）。

### 权限控制
- 管理员端：RBAC method.path 粒度鉴权，超级管理员 `*` 跳过检查
- 业主端：JWT Bearer Token 认证，业主只能操作自己的数据

### 安全防护
18 层纵深防御：验证码 → 密码确认 → 随机验证 → 安全扫描 → 攻击拦截 → 传输加密 → JWT → 会话控制 → 账号锁定 → RBAC → 限流 → ID保护 → 请求加密 → 存储加密 → 展示脱敏 → 审计 → CSP → 版权水印

### 导出功能
- Excel：PhpSpreadsheet，蓝底白字表头 + 冻结首行 + 自动筛选 + 敏感数据脱敏
- PDF：Dompdf A4 横向，页头版权 + 页脚不可移除版权水印
- 面板可视化数据导出 PDF

### 搜索引擎
- `erikwang2013/webman-scout` 驱动 Elasticsearch
- 自动索引同步（增删改自动推送）
- 索引前缀 `erik_`，与数据库表前缀一致

### 国际化 (i18n)
- **PHP 后端**: symfony/translation — `resource/translations/{zh_CN,en}/messages.php`，42个翻译键，控制器通过 `__()` 方法获取翻译
- **Flutter Web**: GetX `Translations` — `lib/i18n/messages.dart`，101个翻译键，页面通过 `.tr` 扩展使用
- **HarmonyOS**: `resources/{base,en_US}/element/string.json` 资源限定符
- **默认语言**: 简体中文（zh_CN），降级语言英语（en）
- **请求头**: 支持 `Accept-Language` 控制响应语言

### 测试覆盖
- **测试框架**: PHPUnit 12.x
- **TDD 流程**: 红→绿→重构，先测试后代码
- **管理端**: 60个测试，164个断言，覆盖基础服务、环境配置、安全验证
- **业务端**: 18个测试，45个断言，100%通过率
- **合计**: 78个测试，209个断言
- **覆盖范围**: Snowflake ID生成唯一性、Hashids编解码往返、统一响应格式、35张表Schema验证、中英文翻译键一致性
- **Flutter**: flutter analyze 零问题
- **前端页面**: 10个 Flutter 页面（登录/首页/费用3/报修3/个人中心/公告）+ HarmonyOS 完整骨架
