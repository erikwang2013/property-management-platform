# 移动端补齐差距清单

> 生成日期：2026-08-16 · 来源：pmp-team ci-agent（P3-③ 现状盘点，只读）
> 对应路线图：docs/PROJECT_PLAN.md P3 — "HarmonyOS 7 页扩至核心路径（缴费/报修/公告/访客/停车），Flutter 业主端移动适配"

## 一、HarmonyOS 业主端现状（apps/harmonyos，7 页）

| 页面 | 路由（main_pages.json 已注册） | 调用 API |
|------|------------------------------|---------|
| LoginPage | pages/LoginPage | 登录（AuthService） |
| HomePage | pages/HomePage | GET /service/home（仪表盘：待缴/工单/房产数 + 公告列表） |
| FeeBillsPage | pages/FeeBillsPage | GET /service/fees/bills?page=1&per_page=50 |
| RepairListPage | pages/RepairListPage | GET /service/repairs |
| RepairSubmitPage | pages/RepairSubmitPage | POST /service/repair |
| AnnouncementPage | pages/AnnouncementPage | GET /service/announcements?page=1&per_page=50 |
| ProfilePage | pages/ProfilePage | GET /service/profile、POST /service/profile/logout |

**导航现状**（全应用仅 4 条跳转）：Login→Home、Home→Login（退出）、Profile→Login、RepairList→RepairSubmit。HomePage 只有统计卡 + 公告列表，无功能入口网格；FeeBills/Announcement/Profile 页面存在但**无入口，不可达**。

## 二、HarmonyOS 核心路径对照

| 核心路径 | 现状 | 差距类型 |
|---------|------|---------|
| 缴费 | 页面有、API 通 | 纯前端：Home 无入口（不可达） |
| 报修 | 列表+提交页有、API 通 | 纯前端：Home 无入口（不可达） |
| 公告 | 页面有、API 通 | 纯前端：Home 无入口（不可达） |
| 访客 | 页面缺失 | 需新建页面（API 已有：GET/POST/PUT/DELETE /visitor*） |
| 停车 | 页面缺失 | 需新建页面（API 已有：/parking/vehicles、/parking/spaces、/parking/records） |

后端无缺口：5 条核心路径的 service API 全部就绪（fees/repairs/announcements 常驻路由；parking/visitors 在 standard 版门禁内）。ApiService.ets 已有通用 get/post/put/delete，新页面可直接复用。

## 三、Flutter 业主端现状（apps/flutter，13 模块）

**页面清单**：login、home、fee、repair、parking×3、visitor×2、activity、notification、vote、mall×3、chat、face、profile — 全部已路由注册（app.dart getPages），5 条核心路径全部已实现。

**移动适配问题**：仅 home_page / login_page 使用 LayoutBuilder/MediaQuery 响应式断点；**10 个页面硬编码桌面宽度**，手机宽度（<400px）下必然 RenderFlex 溢出：

| 页面 | 硬编码 |
|------|--------|
| chat_page | SizedBox(width: 600) |
| mall_products_page | width: 800 |
| mall_product_detail / mall_orders | SizedBox(width: 600) |
| notification_list | width: 480 + SizedBox(width: 600) |
| vote_list / vote_detail | SizedBox(width: 600) |
| activity_detail、parking_records/vehicles、visitor_list、face_register | 无断点处理（预期同类问题，未逐行核验） |

另：无底部导航栏（BottomNavigationBar），入口靠 AppBar + 网格；页面 padding 24 偏桌面风格。i18n 双语已具备。

## 四、差距清单（分类 + 工作量）

### 依赖后端（无）

### 纯前端

| # | 项 | 工作量 |
|---|----|--------|
| 1 | HarmonyOS HomePage 加功能入口网格（对照 Flutter 版 12 入口），接通缴费/报修/公告/访客/停车/个人中心 | M |
| 2 | HarmonyOS 新增 VisitorPage（列表 + 新增，复用 VisitorController） | M |
| 3 | HarmonyOS 新增 ParkingPage（车辆/车位/记录，复用 ParkingController） | M |
| 4 | Flutter 业主端消除硬编码宽度（600/800/480 → 约束在 maxWidth 内或改 ConstrainedBox） | S |
| 5 | Flutter 业主端补底部导航栏 + 紧凑 padding（若手机端为验收目标） | M |

### 需联调

| # | 项 | 工作量 |
|---|----|--------|
| 6 | HarmonyOS 真机/模拟器验证缴费→支付、报修提交、访客登记全链路 | S（受测试设备约束，PROJECT_PLAN 已列此风险） |

## 五、实施顺序建议

1. 差距 1（最高性价比：复用现有 3 个页面，零新页面）
2. 差距 4（Flutter 溢出是硬伤，手机必崩）
3. 差距 2、3（新页面）
4. 差距 5（体验优化）
5. 差距 6（需设备，独立进行）
