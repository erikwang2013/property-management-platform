# Changelog

## v1.7.0 (2026-10-04)

> **注意（行为变更）**：① admin 的 hashids 盐由「空串（可离线反解）」改为 `.env` 注入 —— **所有旧 hashid 串作废**，请从列表接口重新拉取；跨端（admin↔service）不要互传 hashid，传原始 BIGINT。② 非法 hashid 由 HTTP 500（响应体曾泄漏异常类名与栈帧绝对路径）改为 HTTP 200 + `code 422「无效的资源 ID」`；`findOrFail` 未命中由 500 改为 404。③ 权限动作端点 slug 判定改为「先剥 `{...}` 参数段再前缀回退」，非超管角色若原依赖短前缀兜底需核对其授权。

### 新增
- **宠物「小筑」扩展整合**：Android **adaptive icon**（`mipmap-anydpi-v26` + 5 档前景，圆裁出瓦片中心的小筑）；**加载态品牌化** `PetLoading`（两端 75 处页面级转圈 → 小筑标记呼吸动画，5 处按钮内与 1 处图块内转圈刻意保留）；**og 分享卡** 1200×630（`docs/images/og_card.png`，两端 `web/og_card.png` + 后端 `public/og_card.png`），两端 Flutter `web/index.html` 与安装向导四页补 og/twitter meta；`scripts/gen-pet-icons.sh` 扩到 **68 件产物**（新增 adaptive 前景、og 卡、PDF 用 `pet_mark_128.png`，连跑两遍逐字节一致）
- **PDF 导出改造（admin）**：页头小筑品牌位（table 布局 + base64 内嵌 128px 标记，资产缺失自动降级）+ **中文子集字体** `public/fonts/pet-pdf-cjk.ttf`（文泉驿微米黑 GB2312 子集 6763 字 + ASCII + 业务符号，1,260,352 B，Apache-2.0 附 LICENSE；`@font-face` normal+bold 双注册——dompdf 对同族 bold 不做回退；fontCache 从只读 vendor 移到 `runtime/dompdf/`）；dashboard 统计卡由 flex（dompdf 不支持）改等宽表格横排
- **权限种子补齐**：`get.admin/report`、`post.admin/export/property-excel`、`post.admin/payment-order/create`、`post.admin/payment-order/reconcile`、`get.admin/profile` 共 5 条（此前这些端点在任何角色下 403）；`permission.slug` 加唯一索引 `uk_slug`
- **两端 `InvalidResourceIdException`**：非法/空 hashid → 干净 422（继承 `InvalidArgumentException` 保持既有 catch 语义，零回归）
- **CI**：actions 升级 `checkout@v7` / `setup-node@v7` / `pnpm/action-setup@v6` / `gitleaks-action@v3`（17 处纯版本号，breaking 逐条核过不命中本仓库；滚动 tag 的三项实测已 Node24 未动）
- `docs/migrations/2026-10-04-install-sql-catchup.sql`：存量库补齐迁移（19 表 updated_at + 5 权限种子 + slug 唯一索引，slug 级幂等，`mysql --force`）

### 修复
- **webman 路由参数按名注入（P0，约 90+ 端点）**：控制器形参 `$hashid` 与 `Route::resource()` 展开的 `{id}` 不匹配 → `MissingInputException` → 全部详情/更新/删除 500。admin 改本地 `$resource` 包装（路径落 `{hashid}`，31 处）+ 7 处手写 `{id}` + 6 条同型隐蔽路由；修复前后路由注册表 282 条集合恒等；service 侧零不匹配（全量脚本核过）。14 条 curl 实证 + 真写穿透
- **500 掩盖机制（6 个中间件）**：webman 异常处理器返回 `Webman\Http\Response`，被中间件 `: support\Response` 逐个 TypeError 重演，客户端与日志只见 TypeError。修复后真异常直达（日志计数对照：改前一个请求 3-4 条 ERROR、改后恰好 1 条真异常）
- **`findOrFail()` 未捕获（12 处）**：新增全局 `app/exception/Handler.php`（`RecordsNotFoundException` 一族 → 404「资源不存在」），一条映射覆盖 Vote 9 / Notification 2 / Payment 1 及 firstOrFail/sole 同族
- **admin hashids 空盐（安全）**：`config/hashids.php` 硬编码 `salt=''` 短路 `.env` —— 泄漏的 hashid 无密钥可离线反解。改为 `getenv('HASHIDS_SALT')` 注入；两端 `.env.example` 占位区分（`change-me-admin-hashids-salt` / `change-me-service-hashids-salt`）
- **加密列等值查询恒 false**：`service` 业主登录（phone 为随机 IV 加密列，明文/密文等值查询都不可命中 → 真登录必败，且 JWT 用了不存在的 `create()/createRefresh()`）改 `encode()` + `findOwnerByPhone()` 游标解密比对；admin `OwnerController` 批量导入查重同因恒 false（可静默插重复号）→ 开跑前一次游标解密比对集合（含批内去重）。两端负例/正例 e2e 实证
- **hashid 读写对称性**：筛选用 hashid 被 `(int)` 吞掉恒空（22 + 14 处过滤/写路径）→ `decodeId`/`BaseController::decodeIds()` 统一；8 个端点读响应外键补 `encodeId`（18 字段，0 保持空串语义）；契约守卫测试白名单 9 → 1（仅 JWT 内部 adminId）
- **权限动作端点 403（14 个）**：种子按无参数逻辑路径写，而中间件回退只从右往左砍 → `put.admin/complaint/{hashid}/handle` 落在未种的短前缀。改「剥注册路由模式里的 `{...}` 段再回退」（`$request->route->getPath()`；运行时 path 无字面花括号，是原方案的空操作坑）；超管 14 条全通、构造非超管角色「该拒仍拒」×3、短前缀回退保留
- **服务端 autoload 顺序（隐蔽）**：`webman-scout` 的 `config()` polyfill 排在框架 helpers 前（运行时读的是 `autoload_static.php`）→ `config('bootstrap')` 全空 → **56 个 DB 用例被静默 markTestSkipped**。新增 `scripts/fix-autoload-order.php` + composer `post-autoload-dump` 钩子 + Dockerfile `COPY scripts/`；修后跳过 56 → 0
- **decimal 裸 cast（11 字段）**：`'decimal'` 无 scale → Brick\Math `toScale(null)` / `explode` 取不到 scale。按 install.sql 列定义逐字段改 `decimal:2`（admin 端本就全显式）；`/service/v1/rooms` 由 500 转 200，历史 skip 用例转绿
- **owner 端列表解析少解一层**：service 分页线格式 `data.data`，两端只解到 `data` → `List.from(Map)` 抛错被空 catch 吞掉 → 五条核心路径**静默空列表**。HarmonyOS 6 处（新增 `getList<T>()` 统一解包 + EmptyView 空态）、Flutter owner 14 处（含 visitor 状态枚举按 DB 0-3 与 `expected_start` 字段修正；16 处静默 catch 改 `debugPrint` 可诊断；测试 stub 改真实形状 + 2 条非空列表用例含证伪验证）
- **安装向导**：UI 确认页缺 `admin_password_confirm` 字段 → 「两次密码不一致」→ **向导无法从界面完成安装**（交付阻断）；重灌不幂等（1061/1062 等）→ 导入循环把 1050/1060/1061/1062 降级 skip + 汇总；Monitor 监听 `.env` 导致向导中途改写触发 reload、**worker 被 SIGKILL 留下半灌库** → 从 monitorDir 剔除 `.env`
- **PDF 中文方框**（前述字体）；**测试基建**：MetricsControllerTest 两端状态感知化、ImportControllerTest 去「假定库里有 admin」的 fresh-库必红夹具、CircuitBreakerTest half_open 时序（整数秒粒度 20% 窗口，test 改 timeout=2）、ControllerValidationTest 夹具随 hashid 契约更新、service 安全配置断言改 require 真实配置文件、两端 phpstan baseline 同环境重生成（admin 613 条基线）

### 变更
- `.gitignore` 新增 HarmonyOS `entry/build/`；文档「68 表」口径修正为 **67**（PROJECT_PLAN 中/英/法 + admin/CLAUDE.md）；`docs/MOBILE_GAPS.md` 加 2026-10-04 更新注记；`scripts/backup.sh` 容器模式固定容器内 3306（原沿用宿主映射端口连不上）

### 测试
- **admin 271 用例 / 675 断言 / 0 失败**；**service 200 用例 / 847 断言 / 0 失败**（跳过 0；较 v1.5.1 时代 service 断言 +453、跳过 -1）
- e2e（真库真接口）：分页两页零交集（admin+service）；`/admin/report` 200 真实汇总；派单 hashid 全链（列表 hashid+姓名、无效 422、有效落进度）；**业主真登录**（加密手机号建号 → 验证码 → token → /service/v1/home）；路由 14 条 curl + 真写穿透；14 条动作端点权限；向导全链路（159/161 语句、建号授超管、`.installed`）；PDF 冒烟 `pdffonts`/`pdftotext`/`pdftoppm` 目检
- **fresh 库总复验**（`scripts/verify-fresh-db.sh`，幂等可重跑，退出码即结论）：全绿——fresh 库 5 项不变量（67 表 / `uk_slug` / 0 缺 `updated_at` / 5 条权限种子+超管授权）、向导全链路（字段集校验 → 导入 → 建号 → 真登录 → `/admin/report` 200 → 重装幂等）、派单与分页、业主真登录、`.installed` 终态口径；**参数路由补扫 49 条：403=0 / 5xx=0**（原 12 条 5xx 全部转干净 404）
- 环境态（不入库，供后续会话）：本机 DB/Redis 首次可用（`pmp-mysql` 容器 + `ring-r4-redis`），验证脚本可重复执行并自动还原基准库
- Flutter：admin analyze 0 / 1 例，owner analyze 0 / **11 例**（含非空列表新用例）；入口 `main.dart.js` md5 admin `c8ab243b…`、owner `9c4c6afd…`（Flutter web 整树不可复现，只认入口 md5）

### 边界（如实）
- HarmonyOS 无 DevEco：全部改动**未经编译**（照既有可编译模式静态核对）；iOS/macOS/Windows 打包未验证
- PDF：GB2312 外生僻字/emoji 仍方框；首次导出 ~13s（字体解析）、之后 ~4.5s/次；卡片 ≥7 张折行
- **后续项**：16 处读端裸外键（approval/payment 等有真消费页面，需逐页核消费后再改输出——其中 Approval/Payment「写收 hashid、读吐裸值」最刺眼）；HarmonyOS 访客取消（PUT/DELETE）与列表分页；熔断器冷却 1s 粒度（设计粒度，记录不改）；跨端 hashid 约束（只传 BIGINT）
- 本机环境（不入库）：`pmp-mysql` 容器 3307 + `ring-r4-redis` 使本地 DB/Redis 首次可用（详见仓库记忆）

## v1.6.0 (2026-10-03)

### 新增
- **`scripts/gen-pet-icons.sh` 派生图标生成器**：从唯一真源 `docs/images/favicon.svg`（内置 md5 守卫）生成全仓 57 件派生位图（PNG + ico），三个变体自动适配平台——`tile`（原样圆角瓦片：浏览器 / 桌面 / 启动图 / HarmonyOS rawfile）、`full`（裁到瓦片 + 满铺去 alpha：iOS / Android / HarmonyOS 应用图标）、`maskable`（80% 安全区 + 靛蓝实底：web maskable）。幂等且**逐字节可复现**（独立复跑两遍 md5 清单全等；已显式剔除 ImageMagick 默认写入的 `date:*` 元数据块）

### 宠物接入
- **两端 Flutter（admin + owner）**：新增共享组件 `PetMark` / `PetEmpty`（`lib/*/widgets/pet_mark.dart`，文案可空 + build 内兜底以保 `const`）；29 + 4 处纯文字空态换小筑标记插图（56px，口径对齐 React）；admin 侧栏/抽屉头部 3 处 `Icons.admin_panel_settings` → `PetMark`；owner 首页标题加标记；两端壳层图标全套替换（Android 5 档 / iOS 15 件 / macOS 7 件 / Windows 多帧 ico / web 5 件 ×2 端）；启动图放标记（Android `launch_background` + 5 档 `launch_image`、iOS `LaunchImage` 168/336/504）
- **两端 HarmonyOS（此前零宠物）**：`app_icon` 216² 满铺（AppScope + entry ×4）、`start_icon` 128 tile（admin 被 module.json5 引用，owner 侧同换求一致）、admin `rawfile/logo.png`（登录页品牌位）与 `empty.png`（`EmptyView` 为全端空态公共出口，240² = 120dp 的 2×）；owner 端新建 `rawfile/` 并在登录页加 logo 位（`LoginPage.ets`）
- **React / Angular 补点**：React 下拉无数据空态复用 `EmptyState`；Angular 报表页 6 处 `nz-empty` + 欠费排行表统一挂页内既有宠物模板
- **两个后端**：`admin/public/favicon.ico` 由 2026-05 的旧橙色插画换为多尺寸小筑 ico（16/32/48 三帧），`service/public/` 补齐同款（此前只有 svg）
- **壳层元数据清理**：两端 Flutter web `manifest.json` / `index.html`、admin 的 `AndroidManifest.xml` / iOS `Info.plist` / macOS `PRODUCT_NAME` / Windows 窗口名与 `Runner.rc` / Linux GTK 标题——应用名统一「物业管理平台」，主题色由 Flutter 模板蓝 `#0175C2` 改为靛蓝 `#4F46E5`，描述不再出现 "A new Flutter project."

### 变更
- `.gitignore` 新增 HarmonyOS `entry/build/` 忽略；删除误入库的 admin 端构建缓存 146 文件（DevEco 重新构建时生成）

### 测试
- Flutter 两端 `flutter analyze` 0 issue；`flutter test` admin 1 例、owner 9 例（含空态 `find.text('暂无数据')` 断言）全过；入口 `main.dart.js` md5：admin `dbd9b3c4…`、owner `67690b08…`
- React `pnpm test` 7 文件 47 例、Angular `ng test` 38 例全过；重建锚点（独立复跑逐字节复现）：React `index-D3OBXg3z.js` md5 `ca9f5617…` / 整树 `e8cfe7ee…`（5 文件）；Angular `main-GVCZUKER.js` md5 `9edc1521…` / 整树 `3fd1ac5a…`（58 文件）
- 生成器独立复核：连跑两遍 md5 清单全等；iOS / Android / HarmonyOS 应用图标无 alpha 通道；Windows ico 7 帧、favicon.ico 3 帧且两端逐字节相同；8 处 `favicon.svg` 副本与真源逐字节一致；拼版目检（16px 格帽 + 双点眼可辨）
- **锚点口径修正**：Flutter web 整树 sha256 **天然不可复现**——`build/web/flutter_bootstrap.js` 每次构建写入随机 `serviceWorkerVersion`（admin 连构三次逐字节 diff 仅此一行），Flutter 端一律以入口 `main.dart.js` md5 为主锚点（已同步「字节互认」团队协议）
- 边界（如实）：HarmonyOS 真机构建、iOS / macOS / Windows 打包、App Store 图标校验在本机均不可行——HarmonyOS `app_icon` 取平台规范 216² 但未在 DevEco 验证；macOS `PRODUCT_NAME` 用裸中文、Windows 资源串按工程现状取转义写法（该工程无 `/utf-8` MSVC 开关），均未做构建验证；Android 未做 adaptive icon（8+ 会套白底圆角并缩至 ~72%，标记显小一圈，另开项）；web maskable 的 80% 边缘与瓦片渐变有极淡接缝（记录不判定）；身份头像位（顶栏人像 / HarmonyOS `avatar.png`）与加载态转圈按既定口径不动

## v1.5.1 (2026-10-03)

### 修复
- **CI 两个恒失败作业修复（Service Tests / PHPStan Level 5）**：`Service Tests` —— ① 8 个触库用例补齐 `requireDb()` 跳过守卫（Home / MiddlewareAuth / Parking / Profile / Vote 五文件，沿用各文件既有惯例；无可用 DB 连接时跳过而非报 `connection() on null`）；② `MetricsControllerTest` 的 `db_up` 断言改为随实际可达性（可连=1 / 不可连=0，两条路径都钉死，防指标恒 1/恒 0 僵死）；③ `SecurityFeatureTest` 改为直接 `require` 真实配置文件（`config/plugin/erikwang2013/jwt/jwt.php` 与 `config/encryption.php`，含两者自带的 fail-fast 语义）——原 `config('jwt.secret')` 在 phpunit 引导下恒为空（引导不加载 webman 配置树）。`PHPStan` —— 两端 `phpstan-baseline.neon` 按 composer.lock 锁定版本（2.2.16）同环境重生成：清 10 条死条目、修正计数漂移、补齐 Eloquent 魔术静态方法/动态属性类噪音；两端 `analyse` 均为 No errors。验证：CI run 37101769614 全绿（前端两个作业按路径过滤正确跳过）
- 静态分析暴露的 3 处真问题（未入基线、直接修）：`ExportController` 两处 literal-string `++` 补 `@var string` 标注；`ReportController` 三个 `@param` 补缺失的 `$`（docblock 语法错误）；`RepairController` 两处 `?->name` 改 `->name`（`??` 已含 isset 语义，运行行为不变）

## v1.5.0 (2026-10-03)

### 新增
- **React 管理端（重新设计版）**：React 19 + Vite + Ant Design 6 + TanStack Query 5 + Zustand，13 模块 / 16 路由（登录、值班台、报表中心、小区、房产、业主、账单、缴费、报修、投诉、用户、角色权限、系统配置 / 操作日志 / 个人中心，含 404）
- **Angular 管理端（重新设计版）**：Angular 20（standalone + signals）+ NG-ZORRO + 自封装 ECharts，同样的 13 模块 / 16 路由
- 两端共用「小筑」设计语言（靛蓝 + 琥珀），为重新设计而非 Flutter 版移植；通用列表组件归一后端**三种分页形状**（Laravel 分页器 / `page`+`limit` / 无分页）后喂表格

### 修复
- **后端分页忽略 `?page=N`**：illuminate 的 `Paginator::$currentPageResolver` 全局未注册（`resolveCurrentPage()` 恒返默认 1），7 个业务模块（小区 / 房产 / 业主 / 账单 / 缴费 / 报修 / 投诉）列表恒返回第 1 页（total / 总页数正常）；service 端依赖 resolver 的 4 处同样受影响。新增 `admin/app/common/PaginationBootstrap.php` 与 `service/app/common/PaginationBootstrap.php`，并在两端 `config/bootstrap.php` 注册。验证边界：admin 端新增 `tests/PaginationBootstrapTest.php`（3 例 15 断言）通过、`php start.php restart -d` 启动无 bootstrap 告警；**service 端仅 `php -l` 通过，未做启动验证；两端均未用真实数据端到端验证翻页**
- **`/admin/report` 路由从未注册**：`ReportController` 存在但 `config/route.php` 从未注册该路径（`git log -S` 证实历史上也不存在），Flutter 存量端与 React / Angular 三端同调此路径，报表中心自 v1.2.0 起在真后端恒 404；已在 `/admin` 路由组补注册。验证边界：重启后无 token 请求由 404 HTML 变为 `{"code":401,"message":"未登录"}`（路由与中间件链生效），**带 token 真实取数未验证（DB 不可连）**；全量核对 156 处 `@Apidoc\Url` 注解未发现其他未注册接口，属孤例
- **报修接口员工 ID 对外统一为 hashid**：`staff_id` 编码后返回并新增 `staff_name`（一次 join），`assign` / `update` 改为接收 hashid（无效判 422）。此前该字段混用「原始数字 ID」与「员工列表的 hashid」两个不可互转的 ID 空间，前端无法显示维修人员姓名、派单也拿不到可提交的 ID。验证边界：仅 `php -l` + 重启后路由注册 + 无测试依赖旧契约；join 与编解码未经真实数据端到端验证（本机 DB 不可连）

### 变更
- **移除商业版本档位机制**：项目只保留 main 单一版本；删除 `lite` / `standard` / `full` 三个 git 分支（本地与 origin）、移除 `edition_supports()` 路由门控（admin / service 两侧路由改为无条件注册）、删除 `config/edition.php`、`EditionFeatureTest`、`EDITIONS` 环境变量与 `docs/EDITIONS.md`（含 12 语言镜像）。行为影响：`EDITIONS` 此前未设置、默认 full，故移除后路由注册范围与现状完全一致（非功能变更）
- **双端收尾裁决落地**（2026-10-03，已写入共享规格 `admin/apps/README.md` §1.3）：汇总卡措辞两端统一为「应收合计（元）/实收合计（元）/欠费合计（元）」（React 改齐，重建后产物锚点更新）；图表系列色序写死 8 位（前 5 位语义色 + 第 6–8 位扩展色 `#8B5CF6` / `#0EA5E9` / primary-dark，**不做 5 色循环截断**）；「颜色只走五档语义 token」明确只管页面模板/组件内联，样式表字面量豁免；汇总卡单位后缀、顶栏面包屑、`/reports` DOM 节点数三处差异裁定「记录不判定」

### 宠物接入
- React / Angular 两端各六处接线：`public/favicon.svg`（与 `docs/images/favicon.svg` 同源，MD5 一致）、登录页全身像（160px）+ 问候气泡、侧栏 28px 图标标记、值班台欢迎卡、列表空态插图、404 页
- 浏览器标签图标部署点由四个增至六个（新增 `admin/apps/react/public/`、`admin/apps/angular/public/`）

### 测试
- React：`pnpm build`（tsc -b + vite）零错误，`pnpm test` **7 文件 47/47** 通过（终版当场复跑）；无头浏览器逐页截图核对（登录页走真后端验证码），13 模块 / 16 路由全部渲染，宠物六处齐全；首轮 3 项规格偏差（卡片阴影、登录页大号控件圆角、表格行高）修复后复验通过
- Angular：`pnpm build`（ng build）零错误，`ng test` 38/38 通过；首轮验收 9 页运行时白屏（NG0201）与 4 项样式偏差已修复，15 个页面（13 路由 + 系统三页签 + 404）全部出图；终验中另发现并修复两处独立缺陷（见下条），已修复并经交互级复验通过
- Angular 终验修复的两处独立缺陷（两种成因、两种修法）：① **账单编辑页主线程冻结** —— 直接成因不是 locale，而是模板方法绑定在每次变更检测新建 `Date` 实例，触发 `NgModel` 身份判定变化与 `writeValue()` 内 `markForCheck()` 形成自循环，已用 `DateValueCache` 复用实例断环；② **日期本地化缺陷（NG0701，工程未 `registerLocaleData` zh）** 导致报表日期区间不可用，已注册 locale + `LOCALE_ID` 治根。复验：账单日期面板开 → 选 → 保存（PUT 带 `start_date`，主线程无卡死）、报表按日期区间出数
- 双端验证码点击坐标映射实测通过（点渲染区换算提交与期望坐标误差：Angular 0/0，React ≤1px 容差内）
- 双端新增页面级挂载冒烟测试（逐路由渲染，随 `pnpm test` / `ng test` 常跑）；破坏态复现（React 摘 Provider、Angular 摘 NzModalService 注册）下 `build` 仍 exit 0 —— 此类运行时崩溃 build 拦不住，冒烟测试是必要防线
- 边界：本机 MySQL 不可连，登录后页面截图均基于请求拦截桩数据，图表数据与导出未做端到端验证；后端分页修复仅有 admin 单测级证据（见「修复」）

## v1.4.0 (2026-09-26)

### 新增
- **项目宠物「小筑」**：手绘 SVG 楼宇管家（靛蓝 `#4F46E5` + 暖橙 `#F59E0B`），含全身像与 16px 可辨识的图标标记，语言无关可被 13 种语言共用
- **四类手绘 SVG 设计图（中英双版）**：项目结构 / 架构设计 / 功能设计 / 生命周期，统一视觉体系（`docs/images/design_*.svg` 与 `design_*_en.svg`）

### 宠物接入
- `admin/public/favicon.svg` + `service/public/favicon.svg` + `apps/flutter/web/favicon.svg` + `admin/apps/flutter/web/favicon.svg`（新增，四处同源）+ 安装向导 `<link rel="icon">`
- 安装向导 step1~3 + 已安装页：宠物头像 + 分步引导气泡
- 404 / 504 错误页：新增 `admin/public/{404,504}.html` 与 service 同名副本，全部资源内联（后端宕机仍可显示）
- Flutter Web 登录页（业主端 + 管理端）：`flutter_svg` + `assets/pet_xiaozhu.svg` 替换原 `Icons.apartment` / `Icons.admin_panel_settings`
- 架构图「横切关注点」栏内嵌宠物形象
- 图标标记补全瞳孔：原 `favicon.svg` 只有白色眼球，在 32px 下呈空白眼；补齐深色瞳孔并收小双眼，与架构图内嵌标记一致

### 运维
- `admin/docs/nginx-security.conf` + `service/docs/nginx-security.conf` 增加 `error_page 404 / 500 502 503 504`，并注明后端宕机时改用磁盘 alias 的做法

### 文档
- 根 README / README_EN：新增「项目宠物 · 小筑」章节 + 简介接入宠物说明；原有 Mermaid 缩略图（架构/功能/生命周期）替换为手绘 SVG 图组
- 12 语言 i18n README：接入宠物图 + 本地化简介句，图表替换为共享英文版图（复用各语言既有标题，未新增翻译）
- docs/ARCHITECTURE_DESIGN / FEATURE_DESIGN / ARCHITECTURE_DIAGRAM / FUNCTION_DIAGRAM / LIFECYCLE_DIAGRAM 五篇接入总图与宠物插图
- 12 语言 i18n 文档镜像（`docs/i18n/*/docs/`）同步：ARCHITECTURE_DESIGN / ARCHITECTURE_DIAGRAM / FEATURE_DESIGN / FUNCTION_DIAGRAM / LIFECYCLE_DIAGRAM 五篇 × 12 语言 = 60 篇接入宠物与新图；标题沿用各语言既有译文，图片走共享的 `docs/images/`（无新增翻译、无图片副本）
- admin README（中英）：接入宠物图并说明本端已接入位置
- docs/INSTALL.md：安装向导章节接入宠物；新增品牌错误页 Nginx 接线说明
- apps/flutter/README.md：补充资产说明与「三处副本需同步」提示
- admin/apps/flutter/README.md：新增资产章节（原先仅为脚手架默认内容）

### 测试
- 业主端 Flutter `flutter analyze` 无问题；`flutter test` 9/9 通过（登录页宠物尺寸调至 96px 高以适配 600px 测试视口，修复 22px 溢出）
- 管理端 Flutter `flutter analyze` 无问题；`flutter test` 通过
- 错误页与安装向导经无头浏览器截图核对；全部 SVG 通过 XML 合法性校验，无失效图片引用

## v1.3.0 (2026-09-04)

### 变更
- **API 版本迁入接口路由**：版本号从请求头 `API-Version` 移入 URL（管理端 `/api/v1/*`；业主端 `/api/v1/*`、`/service/v1/*`、`/open/v1/*`），不再读取版本头
- 删除 admin / service 两端 `ApiVersion` 中间件（`config/route.php` 路由组直接绑定版本化控制器）
- 未知版本路径（如 `/api/v9/*`）由 FastRoute 直接返回 404（原版本头方案返回 400）
- CORS 允许头移除 `API-Version`；Redis 限流敏感路径键同步为 `/api/v1/auth/login|register`
- `hg/apidoc` 全局参数与 OpenAPI 文档（DocsController）移除 `API-Version` 安全方案与参数

### 客户端适配
- HarmonyOS `ApiService` 统一在路径首段后插入版本段（`versioned()` 助手，15+ 页面零改动）
- loadtest 脚本（login/smoke）路径与请求头同步更新

### 文档
- 根 docs（API/ARCHITECTURE/ARCHITECTURE_DESIGN/INSTALL/MOBILE_GAPS）+ 12 语言 i18n 镜像 + admin CLAUDE/README（中英）+ admin/docs 全量同步 URL 版本方案

### 测试
- admin 258 / service 198 用例全绿；修复限流测试残留 Redis key（`_api_v1_auth_login`）与遗留 ApiVersion 断言

## v1.2.0 (2026-08-31)

### 新增功能
- **管理端报表中心**：日期范围筛选（近30天/近90天/本年）+ 汇总卡片（应收/实收/欠费/收缴率/入住率）+ 收支趋势柱状图 + 缴费方式分布饼图 + 报修/投诉/访客状态分布 + 欠费排行 TOP10 + PDF 导出（Redis 5m 缓存）
- **业主起始页统计**：新增 待处理投诉 / 进行中活动 / 进行中投票 / 未读消息 统计卡片，Flutter Web 与 HarmonyOS 双端同步
- **一键安装**：根 README 增加 `bash scripts/deploy.sh` 一键部署说明

### 文档
- 根 README / README_EN / admin README（中英）增加 一键安装 + 使用说明 章节
- 功能模块表新增「平台功能」行（报表中心 + 起始页统计）
- 功能图（function_overview / function_admin_tree / readme_modules 中英）重新渲染，加入报表中心节点
- docs/FEATURES.md 新增 报表中心 + 业主端模块 章节
- 12 语言 i18n README 全量同步（一键安装 + 使用说明 + 功能行）

## v1.0.0 (2026-08-04)

### 管理后台 (admin)
- JWT 认证 + RBAC 权限鉴权（method.path 粒度）
- 仪表盘实时统计（Redis 5m 缓存）
- 用户/角色/权限 CRUD + 批量操作 + Excel 导入
- 34 个业务模块：小区/楼栋/单元/房产/业主/租户/费用/报修/公告/停车/设备/投诉/访客/合同/财务/安防/保洁/绿化/活动/能耗/员工/通知/审批/支付/投票/SLA/催缴/巡检/商城/人脸/集团/智能问答
- 57 个 Flutter Web 页面（PC 管理后台风格）
- 操作审计日志（8 平台来源检测 + 敏感字段脱敏）
- 18 层纵深防御：XSS/SQL注入/CSRF/限流/CSP/HSTS/IP黑名单
- Web 安装向导（三步部署）
- Docker Compose 生产编排 + GitHub Actions CI/CD
- Prometheus 监控指标端点

### 业主端 (service)
- JWT 业主认证 + 并发会话限制
- 房产管理/费用查询/在线缴费/报修提交
- 公告查看/投诉建议
- 23 个 Flutter Web 页面
- 7 个 HarmonyOS 页面
- 独立 Docker 编排（端口偏移，与 admin 共存）

### 安全
- 管理员端 90 个测试，业主端 43 个测试
- Dependabot 自动依赖更新
- Docker 非 root 运行 + Redis 密码认证 + ES 安全启用
- Nginx 安全配置参考

### 生态
- 中英文 README + 安装指南 + API 文档
- 架构/功能/安全设计文档
- Mermaid 架构图/流程图/功能图/生命周期图/安全架构图
