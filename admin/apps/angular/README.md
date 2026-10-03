# 物业管理平台 · Angular 管理端（重新设计版）

按 `admin/apps/README.md`（下称「共享规格」）实现的 Angular 管理端。**不是 Flutter 版的移植**：
视觉与信息架构按共享规格重做，与同目录的 React 版共用同一组设计 token。

## 启动

```bash
cd admin/apps/angular
pnpm install
pnpm start          # http://localhost:4200
```

开发服务器通过 `proxy.conf.json` 把 `/api` 与 `/admin` 反代到后端 `http://localhost:8787`，
因此浏览器视角是同源请求，不需要后端额外开 CORS。

```bash
pnpm build          # 生产构建，产物在 dist/xiaozhu-admin
pnpm exec ng test --watch=false --browsers=ChromeHeadless   # 单元测试
```

`pnpm build` 与上面的测试命令都必须零错误。测试依赖本机 Chrome（`karma-chrome-launcher`
会自动找到 `/usr/bin/google-chrome`；找不到时用 `CHROME_BIN=/path/to/chrome` 指定）。

### 后端未连通时

`admin/.env` 的 MySQL 未连通时，`/admin/*` 取数会失败（属预期），页面会弹出后端返回的错误提示；
**验证码接口 `/api/v1/captcha/generate` 不依赖数据库**，登录页可以真实渲染验证码。

## 目录结构

```
src/
├── api/            # API 客户端与端点常量
│   ├── api.config.ts   # 所有端点（与 config/route.php 核对过）
│   ├── api.service.ts  # unwrap/toParams/分页归一化/download
│   ├── types.ts        # Envelope / Paginator / ManualList / PageResult
│   ├── room-tree.ts    # /admin/room/tree → 四层 id→名 映射（报修/房产/账单共用）
│   └── dict.ts         # 枚举字典 + 徽标配色（以后端为准，非 Flutter 版内联值）
├── auth/           # token 存取、401 刷新、路由守卫、验证码解码
├── components/     # 通用列表页 / 通用表单弹窗 / 自封装 ECharts / 密码确认
├── layout/         # 骨架（侧栏 + 顶栏）与菜单定义
├── pages/<模块>/    # 13 个模块，每个目录只描述「列、筛选项、表单字段、行操作」
├── theme/          # 设计 token（CSS 变量 + TS 常量两份，值同源）
└── core.spec.ts    # 唯一的测试文件（38 例），含 16 条路由的渲染冒烟
```

### 13 个模块 / 16 条路由（共享规格 §5）

| # | 路由 | 模块 |
|---|------|------|
| 1 | `/login` | 登录（点击验证码 + 小筑） |
| 2 | `/dashboard` | 值班台（欢迎卡 + 统计卡 + 双图 + 时间线） |
| 3 | `/reports` | 报表中心（日期区间 + 小区筛选 + 多图 + 欠费 TOP10 + PDF 导出） |
| 4 | `/communities` | 小区管理（标准 CRUD 样板） |
| 5 | `/rooms` | 房产管理（左侧层级树 + CRUD） |
| 6 | `/owners` | 业主管理（CRUD + 批量删除） |
| 7 | `/fee-bills` | 账单管理（CRUD + 批量生成） |
| 8 | `/fee-payments` | 缴费记录（只读 + 线下缴费登记） |
| 9 | `/repairs` | 报修管理（新建 / 详情抽屉 / 派单 / 进度上报） |
| 10 | `/complaints` | 投诉管理（详情抽屉 / 受理 / 回访） |
| 11 | `/users` | 用户管理（CRUD + 批量启停） |
| 12 | `/roles` | 角色权限（CRUD + 权限树勾选） |
| 13 | `/system`、`/system/logs`、`/system/profile` | 系统配置 / 操作日志 / 个人中心 |
| — | `**` | 404（小筑 + 返回首页） |

分开计：`/system` 下的三条按共享规格算同一项的三种视图。

## 关键实现说明

- **分页逻辑只有一份**：`components/data-table` 承担搜索区 + 表格 + 分页 + 行操作，
  其余 12 个模块只提供 `columns` / `filters` / `rowActions` / `load` 四个描述符。
  两种后端分页形状由 `ApiService.getPage`（Laravel 分页器）与 `getManualPage`
  （`page`+`limit`）归一成同一个 `PageResult<T>`。
- **表单弹窗只有一份**：`components/form-modal` 按 `FormField[]` 生成响应式表单，
  `immutable` 字段在编辑态自动锁定。
- **空值统一「—」（team-lead 2026-10-03 裁定）**：表格与详情抽屉里日期/描述/人员等**所有**空值
  一律「—」。表格侧的唯一出口是 `data-table` 的 `cellText`
  （`col.lookup?.(raw) || raw || '—'`），文本与 `datetime` 等 kind 都经它，所以不用给每个可空列
  各配一个 lookup；抽屉侧各字段写 `|| '—'`。
- **`Column.lookup`**：展示「只回 hashid 的关联字段」时把值换成可读文案，无命中则回落显示
  hashid（与 React 侧 `roomName(id) || id` 同语义）。用在四处：报修/账单的「房产」（`room_id`
  → 房号）、房产页的「小区 / 楼栋 / 单元」（末两层无命中给「—」，因为「—」是空值出口而 hashid 不是）。
  「维修人员」直接显示后端 join 的 `staff_name`，空串走上面那条「—」出口。
  **数据源统一在 `src/api/room-tree.ts`**（`indexRoomTree` → 四个 `Map`，报修/房产/账单三页共用；
  与 React 的 `tree.roomName` 同一份 `/admin/room/tree`，不是 `/admin/room` 名册）。
  早期各页自己写的 `collectRoomNames` 只收 `type === 'room'` 叶子，要上三层就得再抄一遍，
  故提成一个函数；`type → 桶名` 用显式 `BUCKET` 表（`'community' + 's'` 拼不出 `'communities'`）。
- **`Column.render`**：组合单元格，从整行取值、无视 `key`（与 React 侧列定义里的 `render` 同义）。
  目前只有账单的「费用周期」`${start_date} ~ ${end_date}`；它的「—」由 `render` 内部逐段给，
  所以 `cellText` 对它**不套**末尾那个空值出口（否则整段为空时会出现「— ~ —」之外的双重兜底）。
- **报修列集两端统一**（team-lead 裁定，10 列）：工单号 · 房产 · 类别 · 紧急度 · 问题描述 ·
  状态 · 维修人员 · 完成时间 · 创建时间 · 操作；**不含「联系电话」**（全文在详情抽屉里）。
  「维修人员」直接显示后端 join 出的 `staff_name`，未分配（空串）显示「—」。
  筛选区文案与列标题同词：**工单号 / 状态 / 类别**（曾一处叫「报修编号」、一处叫「分类」）。
- **列集两端取并集**（team-lead 2026-10-03 裁定）：各自的独有列都保留，不删任何一方。本端补进
  React 的独有列 —— 房产页「小区 / 楼栋 / 单元」、账单页「房产 / 费用类型 / 费用周期」、
  投诉页「满意度」、日志页「来源端」；本端原有的独有列一律保留 —— 房产「套内(m²)」、
  账单「缴费时间」、缴费「操作员ID」、角色「创建时间」、配置「更新时间」。
  **例外：缴费页「账单」列两端同删**（team-lead 2026-10-03 二次裁定）：该列只能显示后端返回的
  裸 hashid（反查账单编号要额外拉 `/admin/fee-bill`，且受分页限制只能覆盖首页；后端 join 又超出本轮范围），
  显示裸 hashid 等于没有信息 —— 同理由，该列的筛选项「账单 hashid」也一并删掉，
  两端筛选项同为 支付单号 / 支付方式 / 渠道 三项。
  两端现在 11 个列表页的列集**逐列同集同序**。
- **同义列名对齐 React**：用户「姓名 / 手机号（脱敏）/ 邮箱（脱敏）/ 最近登录」、
  角色「角色名 / 用户数」、小区「楼栋数 / 房屋套数」（并挪到「物业公司」之前）、
  业主「手机号（脱敏）/ 邮箱（脱敏）」+「入住日期」移到「状态」前、日志「请求路径 / 操作时间」
  （表头改回显式版：早先是简写的「路径 / 时间」，与本端筛选区 label、详情抽屉及 React 端不同词）。
  「脱敏」二字是核对过后端掩码代码才跟的：`UserController::index()` 与 `OwnerController::index()`
  都对手机号/邮箱做了掩码（`139****0001` / `a***@x.com`），React 的列名属实。
- **报修详情是只读抽屉**（`nz-drawer` + `nz-descriptions` + `nz-timeline`，宽 520）：编号 · 房产
  （tree 反查）· 联系电话 · 类别 · 紧急度 · 状态 · 维修人员 · 问题描述（全文，列表里是 220px 截断）
  · 图片 · 预约时间 · 完成时间 · 评价 · 进度时间线。**不引入新动作** —— 派单/进度仍走原来那两个弹窗。
  空值统一「—」；评价取 `feedback || (rating ? 'N 星' : '—')`（与 React 同句）。
  进度记录的 `staff_id` 是**操作管理员 id**（后端 `addProgress` 写的是 adminId），不是员工 hashid，
  因此**不展示**。抽屉打开时才请求 `GET /admin/repair/{hashid}`，取数失败只显示「暂无详情」。
  时间线紧跟 Descriptions，中间不加小标题（与 React 抽屉同构）。
- **投诉详情同样是只读抽屉**（宽 520，字段与 React 的 `ComplaintsPage.tsx` 逐项对齐）：标题 · 内容 ·
  状态 · 受理说明 · 回访记录 · 满意度 + 提交/受理/回访三节点时间线（没有的时间点不列）。
  **不渲染 `images`**：`Complaint` 没有 json cast，该列是**字符串或 null**，直接 `@for` 会逐字符渲染 ——
  `ComplaintDetail` 因此故意不声明该字段（React 侧同样不渲染）。
  两处曾报 lead 裁定的列集差异**均已定案**（2026-10-03）：① 补「满意度」列（声明 90 + 右对齐，
  后端 `ComplaintController::index()` 确实返回 `satisfaction`，React 保留该列）；② 「匿名」列的
  实名行渲染字典里的「实名」徽标，**不跟随 React 的裸「—」** —— `is_anonymous = 0` 是**有意义的取值**
  而非空值，本轮「空值一律 —」的裁定不覆盖它（React 同桌改成同款徽标）。
  列名（受理时间/创建时间）与列宽已按 React 对齐。
- **派单的人员下拉**来自 `GET /admin/staff`（取前 200 名建下拉），提交的是**员工 hashid**
  （`staff_id` 自 2026-10-03 起由后端按 hashid 解析，无效值判 422）。员工规模更大时应换成远程搜索。
  **过滤掉离职（`status === 0`）**，休假（`2`）仍可派；选项文案 `姓名（职位）`，无职位时不带括号 ——
  与 React 的 `staffOptions` 同句。列表行的 `staff_id` 与这个下拉是同一个值域，所以列表直接显示
  `staff_name` 即可，不需要再查表。
- **两个投诉弹窗的标题带投诉标题**（`受理投诉 · <标题>` / `回访投诉 · <标题>`，React 同格式）；
  「回访记录」的字段名与抽屉里的同名字段保持一致（后端收的是 `visitor_remark`），两个说明都必填。
- **报修三个弹窗共用一个 FormModal**：新建报修单（`create`）/ 派单（`assign`）/ 进度上报（`progress`），
  模式在打开前落定。派单与进度弹窗**标题带工单号**（`派单 · <工单号>`、`进度上报 · <工单号>`，React 同格式），
  同时开多单时能对上号；进度说明必填（React 同）。
  措辞**以共享规格 §5 原文为准 =「进度上报」**（team-lead 2026-10-03 裁定，React 侧同桌跟改；
  本端原先写的「上报进度」已改回）。
- **新建报修单**（`POST /admin/repair`，规范 §5 行 165）：字段与 React 的 `createFields` 同集同序 ——
  报修房产(必填) · 报修人 · 联系电话(必填) · 分类 · 紧急程度 · 预约上门 · 问题描述。
  房产下拉**复用已拉的 `/admin/room/tree`**（Map 保序 = 小区→楼栋→单元→房号），不额外发请求；
  React 那边走 `/admin/room` 远程搜索，值域同为房间 hashid、只是文案不同（tree 节点名 vs `room_number`）。
  报修人下拉取 `/admin/owner`（前 200 名，`姓名 手机号`，与 React 的 `useOwners` 同格式）。
  **空的可选字段一律不发**（`|| undefined`）——后端把空串当值写库，空串写 datetime/number 列会报类型错。
  两处与 React 的差异已记、未擅自跟随：React 表单有 `initial={{category:1,urgency:1}}` 预选
  （本端 FormModal 「预填即编辑态」会连带把成功提示改成「更新成功」，要跟随得先给 `FormField` 加 default），
  且 React 直接 `post(EP.repair, values)`，不做空值剔除。
- **ECharts 自封装**：`components/chart` 只做 init / setOption / resize / dispose，
  不引第三方 Angular wrapper；按需注册图表模块。
- **路由页面冒烟（`core.spec.ts`）**：遍历**真实路由表**逐个 `TestBed.createComponent` +
  `detectChanges`，断言不抛异常且渲染出正文。抓的是「构建通过、一渲染就崩」这类只在运行期
  暴露的问题 —— NG0201 那次编译期零提示、`pnpm build` 与既有单测全绿，却让 9 个页面正文空白。
  页面清单取自 `app.routes.ts`，**新增路由自动纳入覆盖**，不用维护一份会过期的数组。
  测试用 `app.config` 的真实 providers（配套 testing backend 挡请求），所以它验证的正是
  「根注入器提供的东西够不够页面构造期用」。
  **做过「测试的测试」**：摘掉 `app.config.ts` 的 `NzModalService` 后
  `TOTAL: 11 FAILED, 24 SUCCESS`，失败的 9 条精确点名
  `/communities`、`/fee-bills`、`/owners`、`/roles`、`/rooms`、`/system`、`/system/logs`、
  `/system/profile`、`/users`（与当年 9 个空白页面完全吻合），报错信息给出完整注入链
  `ConfirmService -> NzModalService`；恢复后 35 SUCCESS。
- **401 刷新排队**：`auth/auth.interceptor.ts`。并发 401 共享同一个在途刷新
  （`shareReplay` + `finalize`），刷新成功后统一重放；刷新自身 401、或重放后仍 401 → 直接登出。
  注意后端 `AdminAuth` 中间件的 401 是 **HTTP 200 + body `code: 401`**，不是 HTTP 401，
  所以响应体也要过一道检测（原始请求与重放请求都过）。
- **`registerLocaleData(localeZh)` 必须留**，位置在 **`app.config.ts`**（2026-10-03 从 `main.ts` 挪过来）：
  NG-ZORRO 的 `zh_CN` 语言包 `locale` 是 `'zh-cn'`，日期控件经 `DateHelperByDatePipe` →
  Angular `formatDate(date, fmt, 'zh-cn')` 取数；Angular 只认**已注册**的语言数据，缺了抛 **NG0701**，
  表现是日期面板整个渲染不出来（输入框空白、日历 0 格）。注册 `zh` 后 Angular 按父语言回落到 `zh-cn`。
  挪动的原因：测试（`core.spec.ts`）直接用 `appConfig.providers`、**不走 `main.ts`**，
  注册留在 `main.ts` 就等于测试路径上根本没有这份语言数据 —— 交互冒烟也就没法「摘掉就变红」。
  另配 `{ provide: LOCALE_ID, useValue: 'zh-CN' }`，让应用自己的 `date` 管道也走中文。
  **做过「测试的测试」**：注释掉 `registerLocaleData(localeZh)` → 日期交互用例立刻变红，
  报 `Error: NG0701: Missing locale data for the locale "zh-cn"`（精确指向 locale/日期控件）；恢复后全绿。
- **依赖 locale 的组件逐一实操过**（不是「看有没有报错」，探针 `ngdates-all.mjs` +
  `nglocale-census.mjs`，跑在**当前产物** `dist/xiaozhu-admin` 新起的 4351 端口上）：
  本端**每一个**日期控件都真开面板 + 真点一天 + 断言输入框变值，逐处结果
  （面板格数 / 表头 / 星期行 / 点选后的值 / CDP 存活耗时）：

  | 位置 | 初值 | 面板 | 表头 | 点选后 | 存活 |
  |------|------|------|------|--------|------|
  | `/fee-bills` 编辑弹窗（P0 现场） | `2026-10-01 / 10-31 / 10-15` | 42 格 | `2026年10月` | `2026-10-07` | 1ms |
  | `/owners` 新建弹窗（生日） | 空 | 42 格 | `2026年10月` | `2026-10-08` | 2ms |
  | `/fee-payments` 线下缴费（收款时间） | 空 | 42 格 | `2026年10月` | `2026-10-08` | 2ms |
  | `/repairs` 新建报修（预约上门） | 空 | 42 格 | `2026年10月` | `2026-10-08` | 1ms |
  | `/system/logs` 筛选 开始/结束日期 | 空 | 各 42 格 | `2026年10月` | `2026-10-08` | 1ms |
  | `/reports` 区间选择器 | `2026-09-04` | 两联 84 格 | `2026年9月` | `2026-09-07 ~ 09-21` | 1ms |

  星期行一律「一 二 三 四 五 六 日」；分页文案 `共 25 条` / `20 条/页`，且实测**真翻页**
  （点了第 2 页与换成 50 条/页，两条请求 `/admin/community?page=2&page_size=20`、
  `?page=1&page_size=50` 都发了出去）；空态 `暂无数据`，次要色 `rgb(107,114,128)`。
  控制台零错误。
  未被用到的 locale 组件**无实例可测**：`nz-calendar`、`nz-time-picker` 全工程 grep 零命中
  （Transfer / Upload / Popconfirm / QRCode / CheckList / CronExpression 等同理），
  本端会用到的 locale 组件只有上表这 4 类（日期选择器、区间选择器、分页、空态），全都实操过了。
- **日期控件的 `ngModel` 取值必须走 `DateValueCache`**（`components/date-value.ts`，P0 根因）：
  模板里 `[ngModel]="dateValue(key)"` 是**方法绑定**，每次变更检测都重新求值；若每次
  `new Date(raw)` 就返回**新对象**，NgModel 按身份判定「值变了」→ 推送进控件 →
  控件的 `writeValue()` 里 `cdr.markForCheck()` → 调度下一轮 CD → 又一个新对象 →
  **自循环**，主线程被饿死（页面冻死、CDP `Runtime.evaluate` 8×4s 全超时）。
  触发条件是**日期字段有初值**：空串走 `null` 分支、`null === null` 身份稳定，环起不来 ——
  所以「日期为空」的用例全绿，只有编辑带日期的账单才冻死。
  同一个原始字符串复用同一个 `Date` 实例即断环（`data-table` 的筛选区日期同理，一并改过）。
  守卫分两层：`DateValueCache` 的**不变量单测**（同一原始值必须返回同一实例；摘掉缓存这条立刻红）
  ＋浏览器探针（实测由「冻死」变 1–2ms 响应）。TestBed 里没有 zone 持续驱动 CD，
  自循环**复现不出来**，所以不变量单测是唯一能在单测层守住的形态。
- **枚举字典逐条核过 `docs/install.sql` 的列 COMMENT（2026-10-03 全量普查，不是抽查）**：
  `src/api/dict.ts`（19 张「值 → 文案」表、17 张徽标表、`LOG_SOURCES` 来源端映射、2 个守卫常量。
  第 19 张是后补的 `VISITOR_STATUS` —— 报表页访客饼图要用，见下「/reports 整页栅格」）
  ＋页内 1 张（`system.ts` 的 `CONFIG_TYPES`；`logs.ts` 的 `METHOD_TAGS` 已随「胶囊改纯文本」删掉）
  = **逐条对上 SQL 行号，取值无一处不一致**。页内那张 `usageTags` 已并进 `dict.ts`
  成为 `USAGE_TYPE_TAGS`（原先在 `rooms.ts` 里按值轮换四位十六进制）。几处最容易踩的：
  - **同名不同表**：`status` 在 `management_community` 是「0=停用 1=正常」（SQL 585），
    在 `management_admin_user` / `management_admin_role` 是「0=禁用 1=启用」（SQL 21 / 57）。
    本端因此有 `NORMAL` 与 `ENABLE` 两张表：小区走前者，用户/角色/个人中心走后者。
    `payment_method` 同理 —— `management_finance_income`（SQL 1050）只有 4 值、没有「刷卡」，
    本端渲染的是 `management_fee_payment`（SQL 789，5 值），两张表不能混用。
    报表页那处已反向核实（只读 `ReportController.php:137-148`）：后端聚合的正是 `management_fee_payment`，
    图例文案取自控制器常量 `PAY_METHOD_NAMES`（5 值，与 :789 一致），前端只消费 `payment_methods[].name`、不经字典
    —— 所谓 789 vs 1050「口径冲突」是两张不同的表，无冲突。
  - 投诉「类型」曾把 1/2 写反（SQL 968：1=投诉 2=建议 3=表扬），已修；
    「分类」曾整列没有映射（SQL 969：1=服务态度 … 7=其他），已补。
  - 投诉「状态」**曾是有意偏离，现已归位**（team-lead 2026-10-03）：SQL 974 是
    `0=待处理 1=处理中 2=已处理 3=已回访 4=已关闭`，旧守卫却是「非 1 不可受理、非 2 可回访」，
    本端一度按守卫显示（0/1 都叫「待处理」）。**后端这次改的是守卫**（`handle` 收 0 置 1、
    `visit` 收 1 置 3），编号回到 SQL，前端字典与按钮可见性随之一致改回
    （受理 `status===0`、回访 `status===1`）—— 前端 / SQL / 守卫三者现在同一套编号，
    筛选下拉里那个重复的「待处理」也随之消失。
  - 两处**已按裁定改掉**（team-lead 2026-10-03）：① `late_fee` 文案统一为 SQL 列注释的
    「滞纳金」（原写「违约金」）；② `source`（SQL 560，八值枚举）在 `dict.ts` 加 `LOG_SOURCES`
    映射成展示名，日志页「来源端」列走 `Column.lookup`（不再是裸小写英文）：
    `web→网页端`、`ios→iOS`、`ipados→iPadOS`、`android→安卓`、`harmonyos→鸿蒙`、
    `windows→Windows`、`macos→macOS`、`linux→Linux`
    （品牌名保留官方拼写 —— macOS/Windows/Linux 无通用中文名；其余用通行中文名）。
    实测八个值渲染为 iPadOS / macOS / Windows / Linux / iOS / 安卓 / 鸿蒙 / 网页端。
  - 顺手清掉一个死导入：投诉页 import 了 `COMPLAINT_CATEGORY` 却从未使用（列走 `_TAGS` 那张表）。
    `PERMISSION_TYPE_TAGS` 全工程零引用（权限树只用值表）—— 保留未删；
    `USAGE_TYPE_TAGS` / `REPAIR_CATEGORY_TAGS` / `GENDER_TAGS` 本轮改纯文本后也加入零引用名单（同先例保留）。
  - `tsconfig` 没开 `noUnusedLocals`，上面这类死导入**构建不会报**，只能靠人核。
- **toast 圆角走真实 CSS**（`styles.scss`）：vendor 里 `.ant-message-notice-content{border-radius:2px}`
  是**字面值**（不在变量化范围内），故在 styles.scss 写一条同选择器规则接到 `--xz-radius-card`（12px）。
  字色与图标色不用管：`.ant-message` 已在正文色列表里，图标色 vendor 走 `--ant-success-color` 等，
  已由 `theme/_tokens.scss` 映射到 `--xz-success`。实测：圆角 `12px`、图标 `rgb(16,185,129)` = `#10B981`、
  正文 `rgb(31,41,55)` = `#1F2937`。
- **NG-ZORRO 主题（踩过坑，改样式前必读）**：`ng-zorro-antd.variable.min.css` **只变量化了颜色**。
  实测该文件（669,184 字节）：`--ant-primary-color` 出现 293 次，而
  `--ant-border-radius*` / `--ant-text-color` / `--ant-font-family` / `--ant-box-shadow` 均出现 **0 次**，
  文件内 `border-radius:var(` 是 0 次、字面 `border-radius:2px` 是 140 次。
  所以**只覆写这些变量是死代码**，圆角/文字色/字体/阴影必须在 `src/styles.scss` 里写真实 CSS 规则
  （该文件在 `angular.json` 的 styles 中排在变量样式表之后，同特异性下后者胜出）。
  vendor 里字面量 `rgba(0,0,0,.85)` 出现 **185 次**，就是 §1.1 正文色的泄漏源。
  覆盖时**必须避开有配色语义的变体**：它们与基础类同为 `(0,1,0)`，一条 `.ant-btn{color:…}`
  会把 `.ant-btn-primary` 的白字压成深色。本项目的处理是：
  - 默认按钮 —— vendor 里**没有 `.ant-btn-default` 这个类**（默认态就是裸 `.ant-btn`），
    只能排除法：`.ant-btn:not(.ant-btn-primary):not(.ant-btn-link):not(.ant-btn-text):not(.ant-btn-dangerous):not(.ant-btn-background-ghost)`；
  - 文本按钮 `.ant-btn-text`、无配色标签 `.ant-tag:not([class*='ant-tag-'])` 单独放行；
  - `.ant-alert` 仍然不碰。
  另有两条**继承救不了**的坑：
  - **标题元素**：vendor 重置 `h1,h2,…{color:rgba(0,0,0,.85)}` 是元素选择器、直接命中，
    从父元素继承来的颜色会被它盖掉 —— 值班台问候语本应继承 `.welcome` 的白字，
    实测在深靛蓝渐变上渲染成近黑色（已改），`.welcome h2` 现在显式写 `color:#fff`。
  - **卡片标题**：`.ant-card-head` 自带 `color` 声明，只覆盖 `.ant-card` 够不着标题，
    必须把 `.ant-card-head` 也写进覆盖列表。
  - **抽屉/弹窗标题**：同理，`.ant-drawer-title`、`.ant-modal-title` 各有一条直接命中的
    `color: rgba(0,0,0,.85)`，元素级 `h1..h6` 规则压不住（标题元素恰好是 `h4`，同特异性下
    元素选择器输给类选择器）。依据：antd 抽屉在**根节点**上取 `colorText`（标题继承之），
    弹窗标题取 `colorTextHeading`，而 antd `theme/util/alias.js` 里
    `colorTextHeading: mergedToken.colorText` —— React 侧 `colorText` 被锁成 `#1F2937`，
    故两端都应是正文色。**已实测**：React 产物里 `.ant-drawer-title` 与 `.ant-modal-title`
    都是 `rgb(31,41,55)`。
  - **次要色不能顺手一起扫**：`.ant-empty-description`、`.ant-descriptions-item-label`
    是「描述色」而非正文色（前者 antd 取 `colorTextDescription`；后者**在 bordered 变体下**
    取 `colorTextSecondary`，两端用的都是 bordered）。vendor 里这两个类**没有自己的 color 声明**：
    祖先(如 `.ant-empty`)染成正文色它们就继承正文色，祖先不写也还是继承外面的正文色 ——
    结论是必须各写一条 `color: var(--xz-text-secondary)`，同时 `.ant-empty` **不要**留在正文色列表里。
    实测两端一致取到 `rgb(107,114,128)`。
    对照（**确认是正文色、不需要次要色规则**）：`.ant-timeline`、`.ant-drawer-body`、`.ant-drawer`
    取的是 `colorText`，`.ant-message` 在 antd 6 里干脆不设色、随 body 继承 —— 都归正文色列表。
  自检手段：把所有路由的叶子节点颜色做一次普查，除了规格 token 与元素自身语义色
  （白/靛蓝/玫红/琥珀/翠绿、disabled 的 `rgba(0,0,0,.25)`、placeholder 的 `#BFBFBF`），
  不应再出现任何 antd 派生色。当前 14 条路由**已清零**。
- **`NzModalService` 必须在根注入器提供**（`app.config.ts`）：它的 `ɵprov` **没有 `providedIn`**，
  只由 `NzModalModule` 提供；而 `ConfirmService` 是 `providedIn:'root'` 且在根作用域 `inject` 它。
  页面自己 `imports:[NzModalModule]` 注册到的是路由级注入器，救不了根级解析 ——
  漏了会让**按需加载的 9 个页面在构造期抛 NG0201、正文空白且一个接口都不发**，编译期毫无提示。
  `core.spec.ts` 里有一条回归守卫（已验证去掉该 provider 会失败）。
- **表格行高 48px 的配方**：`padding 11.5px` + `line-height 24px` + `1px` 分隔线 = 48。
  不能用 `height`（那是「最小高度」语义，padding 撑开后声明不生效）。
  行操作按钮必须 `nzSize="small"`（24px）：默认按钮高 32px，会把有操作的行撑到 56px。
- **宽表**：表格用 `nzScroll x:max-content`（与 React 版的 `scroll={{x:'max-content'}}` 一致），
  列宽不够时横向滚动，而不是把无宽列挤成竖排。操作列 `position:sticky; right:0`，
  保证滚动时行操作始终可见。
  操作列**声明宽 170**（共享规格 §1.3 指定的值）：`table-layout:auto` 下声明宽是**下限**，
  声明 150 时反而被三个行内按钮的内容（实测 React 156 / Angular 165）撑开，两端各撑一套；
  声明 170 后两端都恰好等于 170。
  声明和**小于**容器时反向也一样：auto 布局会把余量摊回各列 —— 角色权限声明和 1070 < 容器 1120，
  实测每列各涨 2~5px（160→164、180→185 …）。两端同为 antd，行为一致。
- **列宽全部显式声明**（规范 §1.3 行 51）：11 个列表页的数据列无一缺声明 —— 2026-10-03 在真产物上
  逐页数 `th`（`/tmp/verify/pw/thcount.mjs`）：**共 100 个 = 88 数据列 + 10 操作列 + 2 勾选列**
  （缴费页删掉「账单」列后由 101 降下来）。未声明宽的只有 10 个操作列
  （走 `.ops-head { width:170px }` 类而不是行内 style；缴费页是只读页、无行操作）
  与 2 个勾选列（ng-zorro 内部生成，规范 §1.3 明确它不算数据列）。
  `/system` 的「配置值」「说明」声明 **240** 并加 `ellipsis`：`ellipsis`（`max-width:0` + 省略号）
  让声明宽从下限变成**硬约束**，否则长文本会把列撑开、声明形同虚设。
- **欠费 TOP10（`/reports`）的列宽要两件事一起做才生效**（2026-10-03）：
  ① 四个数据列补声明宽 120/140/160/120（排名 60 原有）；
  ② 这张表**必须带 `nzScroll`** —— React 同名表是 `scroll={{ y: 220 }}`，antd 据此把 `table-layout`
  切成 `fixed`、列宽按声明值生效；本端缺 `nzScroll` 时仍是 auto 布局，声明宽退化成「下限」
  被摊到整个容器（实测 110/221/258/294/221，声明和才 600）。补上后本端同为 `fixed`、表体 220px 可滚。
  此前「React 半栏 600 / 本端整宽 1104、fixed 下富余宽度按比例摊回」的残留差异，**已随整页栅格对齐消解**
  （见下一节）：现在卡的容器两端同为 `568`、表 600、表体 520、横向溢出量也同为 80px。
- **`/reports` 整页栅格与画法已对齐 React**（team-lead 2026-10-03 裁定「页面对齐」）：
  图表区三行 **14+10 / 8+8+8 / 12+12**（矮屏一律 24 堆叠），补齐 React 有而本端缺的
  **「访客状态」饼图** —— 后端 `report` 一直返回 `visitor_status`，此前本端没渲染，是功能缺口而非版式差异。
  同时把**画法**也对齐（原本一页三种饼形）：四张状态饼共用一个 `pie()`（环形 42%~68%、白描边、
  图例贴底可滚动，同 React 的 `pie()`），收支趋势改为**收入柱 + 支出线**（主色/错误色，同 React 的
  `chartColors[0]/[3]`），报修分类柱去掉圆角与限宽，卡片标题改为 React 的用词
  （支付方式分布 / 报修分类；「缴费方式占比」「报修分类分布」作废），图表高度 320/280 同 React。
  实测两端逐项相等（`/tmp/verify/pw/reports-grid-2ends.mjs`，同一份桩）：
  卡宽 `665 / 471 / 373 / 373 / 373 / 568 / 568`、图高 `320 / 320 / 280 ×4`、
  TOP10 表 600 + 列宽 `60/120/140/160/120` —— 两端全等。
  两处**刻意不镜像**（规范 §1.3「对齐 ≠ 照抄」；2026-10-03 已由 team-lead 裁定**对端跟本端改**，非本端改回）：
  ① 访客饼图图例本端按 `install.sql:1010`（`0=已预约 1=已到访 2=已离开 3=已取消`）渲染文案，
  React 那侧是裸 `状态0..3` —— 裸枚举号是缺陷，本端带了 `VISITOR_STATUS` 字典（`dict.ts` 值表 18 → 19 张）；
  ② 收支趋势横轴本端取收入/支出两串月份的**并集**，React 只用收入月份（支出多出一月时那月会丢）。
- **导航项一律短名**（规格 §4，2026-10-03）：`layout/menu.ts` 的小区 / 房产 / 业主 / 账单 /
  报修 / 投诉 / 用户 去掉了「管理」后缀（缴费记录 / 角色权限 / 系统配置 / 操作日志 / 个人中心
  本来就没有后缀）。`app.routes.ts` 的浏览器标题同步换成同一批短名 —— React 的标题由菜单 label
  派生（`PAGE_TITLES`），两端的 `<title>` 必须同词；实测 `/complaints` 为「投诉 · 物业管理平台」。
- **§1.3 行 51 于 2026-10-03 02:35 修订**，此前「1440 下不得出现横向滚动」的规则**作废**：
  现在写明「表格总宽超过容器时允许横向滚动 —— 两端声明同值即同宽同滚动；**不要为消掉滚动条去压窄列宽**」。
  （team-lead 的 message 里仍是作废版的口径，**以规范文件为准**，已报 lead。）
  按此口径，1440 视口下本端的横向滚动量（实测，容器 → 滚动宽）：
  业主 1120→1120（0）· 角色权限 1120→1120（0）· 投诉 1120→1170（50）· 用户 1120→1172（52）·
  配置 1120→1220（100）· 日志 1120→1240（120）· 小区 1120→1280（160）· 缴费 1120→1310（190）·
  报修 1120→1340（220）· 账单 1120→1680（560）· 房产 828→1410（582，左侧层级树占了宽）。
  容器差异同样不是本端独有：React 的 `/system` 多一层 Card + Tabs 嵌套、实测 1068，
  两端该页声明和同为 1220 → 两端都滚动。

## 宠物「小筑」素材

`public/favicon.svg`（图标标记）与 `public/pet_xiaozhu.svg`（全身）是
`docs/images/` 下同名文件的**副本**（构建期无法跨目录引用），当前与本仓库源文件逐字节一致。

> 同步约定：`docs/images/` 是唯一真源。改宠物形象时，必须同步复制到
> `admin/apps/angular/public/`、React 版与 Flutter 版各自的静态目录。
> 可用 `diff docs/images/favicon.svg admin/apps/angular/public/favicon.svg` 快速校验。

接线点（共享规格 §2）：登录页全身像 + 问候气泡、侧栏顶部 28px 图标标记、
值班台欢迎卡、列表空态插图、404 页、`<link rel="icon">`。

## 工程约定与已知偏差

- **Angular 20 而非最新版**：本机 Node v22.17.0 不满足 Angular 21+ 的
  `^22.22.3` 下限；Angular 20 声明 `^20.19.0 || ^22.12.0 || >=24.0.0`，22.17.0 满足。
  用法仍是 standalone + signals + 新控制流语法（`@if` / `@for` / `@switch`）。
- **`@angular/cdk` 不是直接依赖**：它是 `ng-zorro-antd` 的 dependency，pnpm 严格布局下
  不在根 `node_modules`，构建能正常解析。`ng serve` 启动时会打印一条
  `Failed to resolve dependency: @angular/cdk/bidi` 的 Vite 预打包提示，不影响构建与运行。
- **徽标（`nz-tag`）配色：已按裁定统一为「浅底彩字」，两端实测同值**（team-lead 2026-10-03 裁定 1/2）：
  本端 `dict.ts` 的 `_TAGS` 由**十六进制**改成 **ng-zorro 预设名**（`success` / `warning` / `error` /
  `processing` / `default`），档位与 React 的 `STATUS_MAPS` 一一对齐。同一份桩数据在两端量
  `.ant-tag` 计算样式（本端 4351 新产物 / React 4352 新产物，`/tmp/verify/pw/preset-2ends.mjs`），
  账单五档 + 房产两档**逐值全等**（前景 / 背景 / 描边）：
  `default`（未缴·空置·豁免）`rgb(31,41,55)` / `rgb(246,246,247)` / 透明；
  `warning`（部分缴）`rgb(245,158,11)` / `rgb(255,250,230)` / 透明；
  `success`（已缴）`rgb(16,185,129)` / `rgb(225,250,237)` / 透明；
  `error`（逾期）`rgb(244,63,94)` / `rgb(255,240,240)` / 透明；
  `processing`（出租·自住）`rgb(79,70,229)` / `rgb(243,240,255)` / 透明。
  两处 ng-zorro 侧的实现细节值得记下来：① 预设类靠 `theme/_tokens.scss` 把
  `--ant-*-color-deprecated-bg` / `-border` 映射到本设计色板 —— `--ant-info-color` 默认是 antd 蓝，
  不映射的话 `processing` 档会跑成 `#1890ff`；② **ng-zorro 没有 `.ant-tag-default` 规则**
  （它加了类却不给样式），不补就落到基础 `.ant-tag`（`#fafafa` + 灰描边），故 `styles.scss` 里显式给了值。
- **分类类字典一律中性 `default`、不再按值轮换色板**（裁定 2）：用途 / 类别 / 装修 / 性别 /
  投诉分类 / 支付方式 / 渠道 / 权限类型 / 匿名等无褒贬含义的字典都不传色
  （其中用途 / 类别 / 性别三列随后又按下一节裁定改成了纯文本，表格里已不再出现徽标）。
  轮换（原 `['#4F46E5','#F59E0B','#10B981','#6B7280'][i]`）没有信息量，且是两端分叉的主要来源。
  有褒贬的少数保留语义色：投诉类型（1 投诉 `error` / 2 建议 `warning` / 3 表扬 `success`）、
  紧急度（普通 `default` / 紧急 `warning` / 非常紧急 `error`）。
- **四列「胶囊 → 纯文本」已按裁定落地**（team-lead 2026-10-03，跟 React）：`/rooms` 用途、`/repairs`
  类别、`/owners` 性别、`/system/logs` 方法由中性徽标改成纯文本 —— 前三个 `kind:'tag'` 换成
  `Column.lookup`（查不到回落原值、空值才落到「—」），方法列是裸字符串直接透传、连 lookup 都不用。
  `logs.ts` 的 `METHOD_TAGS` 随之删除。实测（按表头文字定位列，`/tmp/verify/pw/round5.mjs`）：
  四处单元格内 `.ant-tag` 计数 0（用途「商业」/ 性别「女」/ 类别「墙面地面」/ 方法 DELETE），
  对照 `/rooms` 状态列仍是 1（有褒贬的语义色保留）——判定依据是「有没有褒贬含义」，不是「是不是枚举」。
- **金额格式：千分位 + 两位小数，值上不挂符号**（规范 §1.3 line 52，2026-10-03）：唯一实现是
  `src/components/money.ts` 的 `formatMoney()`（`toLocaleString('en-US', {minimumFractionDigits:2,
  maximumFractionDigits:2})`，非数值出「—」不吐 `NaN`），三个消费点：`data-table` 的 `moneyOf`
  （13 个模块所有 `kind: 'money'` 列）、报表汇总卡（`money: true` 的三张卡）、TOP10 单元格与导出 PDF 行。
  单位一律写在标签/表头：卡片标签是「**应收合计（元）**」，表头是「欠费金额(元)」。
  实测 `1250000 / 980000 / 270000.5` 渲染为 `1,250,000.00 / 980,000.00 / 270,000.50`（账单表 + 卡片 + TOP10 三处），
  整页无 `¥`、无 `NaN`。**React 侧 `money()` 仍是裸 `toFixed(2)`**（三个页面各一份）：它的汇总卡带千分位
  只是因为 antd `Statistic` 自己会分组，表格与导出不会 —— 两端要一致需对方把三处 `money()` 换成同一格式。
- **图表系列色序按位置对齐**（规范 §1.3 line 51，2026-10-03）：`theme/tokens.ts` 的 `CHART_PALETTE` 改为
  `[primary #4F46E5 → primaryLight #6366F1 → warning #F59E0B → success #10B981 → error #F43F5E]`，
  第 6 位起补上 `#8B5CF6 / #0EA5E9 / primaryDark`，与 React 的 `chartColors` **逐位同长同序**。
  顺序不是审美：ECharts 按位置取色，顺序不同 → 同一个分类两端画出不同颜色（改动前访客饼「已取消」
  本端 `#6366F1`、React `#F43F5E`；缴费方式饼 5 个值同样在第 4、5 片互换）。
  实测（在切片中角 55% 半径处采样 canvas 像素，`/tmp/verify/pw/piepx-ng.mjs`）：
  支付方式 5 片 = `#4f46e5 / #6366f1 / #f59e0b / #10b981 / #f43f5e`，
  访客 4 片 = `#4f46e5 / #6366f1 / #f59e0b / #10b981` —— 与规范序列逐位相同。
  另：规范 line 53「页面里不得内联预设色名/十六进制」本端来源已扫过，`nzColor` 一律走字典里的
  五档语义名，页面内无 `gold`/`green`/`volcano` 或十六进制字面量（色板定义在 `theme/tokens.ts`，不在页面）。
- **畸形响应的兜底在共享归一化函数里**（2026-10-03）：`fromPaginator` / `fromManualList` 在 `data` /
  `list` 不是数组（且非 null）时抛 `TypeError`。之前不拦的话 `{}` 会一路进表格、**到渲染期**才炸成
  压缩后的 `t is not iterable` —— 那时错误已脱离 Observable，订阅方的 `errorText` 够不着，
  用户只看到空表 + 控制台报错。拦在管道内则走 `DataTableComponent` 的 error 回调 → `errorText`
  把 `TypeError`/`RangeError`/`ReferenceError` 翻成「数据格式异常，请刷新重试」并 `console.error` 原错误。
  实测（桩把 `/admin/community` 的 `data` 给成 `{}`）：toast 文案就是这句人话，表格走空态，
  控制台只剩那条有意打印的未压缩 `TypeError`。注意**不能一刀切成「所有 Error」** ——
  本项目有意抛的 `new Error('两次输入的新密码不一致')` 要原样透传。
  同一轮还补了第二处同族根因：`indexRoomTree`（`api/room-tree.ts`）对非数组响应改为**回落空索引**
  而不是抛错。它被三个调用点放在 `subscribe(next:)` 里调，**next 里抛出的异常越过该订阅自己的 `error`
  回调直达全局错误处理**（实测 `/fee-bills` 的 console 只剩压缩后的 `t is not iterable`，页面看着正常、
  问题被吞掉）；三处调用本来就有「树拉不到只回落显示 hashid、不打断列表」的约定，故此处不抛才对。
- **登录页验证码提示改「编号全列」**（team-lead 2026-10-03 裁定，跟 React）：标题下一排
  `nz-tag` 依次列出 `1. 山` `2. 云` `3. 风`，行首文案统一为「请依次点击验证码上的文字」。
  本端在两处比 React 多的加分项按裁定保留：**已点进度**（点过的下标染 `success`、当前待点染 `warning`、
  未到染 `default`，色彩即进度）与**「撤销一次」**。实测点击前后：`[warning, default]` → `[success, warning]`，
  色值 `rgb(245,158,11)` / `rgb(31,41,55)`，行尾「已点：风 · 撤销一次」。
- **问候语只有三档**（规格 §2）：`h<12 早安` / `h<18 午安` / 其余 `晚安`。本端曾多出未申报的第四档
  「夜深了（h<6）」，已删；要加档得两侧一起动。
- **包管理用 pnpm**，registry 已是 npmmirror。
- **不使用 NgRx**：状态全部用 signal + service。
- 所有 `*.ts|html|scss` 均带版权头注释，单文件均 ≤ 500 行。

## 后端契约上的已知缺口

实现时按控制器 `index()` 的实际返回写字段，以下是**后端侧**的问题（前端已按现状处理，
但功能会受影响，详见交付报告）：

- `/admin/role`：无 `show()`，`index()` 不返回 `permissions`，故权限树无法回显已授权限；
  `permission_ids` 被 `sync()` 时未做 hashid 解码。
- `/admin/report`：`ReportController` 未在 `config/route.php` 注册，报表页会提示取数失败。
- ~~五个 `paginate()` 端点的 `page` 参数不生效~~：**后端已于 2026-10-02 修复**
  （`app/common/PaginationBootstrap.php` 注册了 `Paginator::currentPageResolver`，
  由 `admin/config/bootstrap.php` 引入；`admin/tests/PaginationBootstrapTest.php`
  3 tests / 15 assertions 通过）。该验证**只到单测级，端到端未验**（本机 DB 不可连）。
  前端两种形状都照常传 `page`，
  且**不把响应里的 `current_page` / `page` 回灌表格**——页码是调用方状态，
  回灌会让形状 A 的翻页 UI 依赖后端字段（React 版同此处理）。
- `OwnerController::index` 对加密列做 `like`，手机号搜索永远匹配不到。
- 空串写入会触发 NOT NULL / 类型转换错误（`gender`、`birthday`、`user.status` 等）。
- `DashboardController` 的统计卡 `icon` 是 **Material 名**（`people` / `person_add` / `bolt` /
  `description`，为 Flutter 版写的），Angular 端 `APP_ICONS` 无法注册这类名字。
  `pages/dashboard/dashboard.ts` 的 `STAT_ICONS` 做了一层名字映射 + `appstore` 兜底，
  **颜色仍用后端下发值**，以保证与 React 版同 payload 同视觉。映射词表与 React 版
  `DashboardPage.tsx` 的 `STAT_ICONS` **逐键对齐**（含 `person_add → user-add`），
  认不出的都走 `appstore` / `AppstoreOutlined` 兜底。
- **验证码画布实际 300×200**（后端 `AbstractCaptcha::$width/$height` 默认值，可被 `size` 选项覆盖）。
  `auth/captcha.ts` 的 `toImageCoords` 按图片 natural 尺寸换算，`login.ts` 的 `canvasSize`
  在 `(load)` 时记录同一尺寸供标记定位，全链路无写死常量（规范 §3.1 要求）。
  实测：图片 300×200 被渲染成 322×215（等比缩放的整数像素取整，横纵比例一致），
  点渲染中心 → 提交 (150,100)（画布正中）。
  关键是**这个 300×200 会被后端 `size` 选项改掉**，所以任何写死的画布常量都是错的；
  原先写死 400×250 时点画布正中会提交 (200,125)，而正确值是 (150,100)。
  更隐蔽的是标记显示当年用 `hit.x/400` 定位、算出来恰好还是 50%，界面看着正常、提交的坐标全错。
