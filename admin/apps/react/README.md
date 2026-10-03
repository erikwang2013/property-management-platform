<!-- Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz -->

# 物业管理平台 · React 管理端

`admin/apps/react` —— 依据 `admin/apps/README.md`（共享设计规范）全新实现的管理端，**重设计，非 Flutter 版移植**。
技术栈：Vite + React 19 + TypeScript(strict) + React Router 7 + TanStack Query 5 + Zustand + Ant Design 6 + ECharts 6。

## 启动

```bash
cd admin/apps/react
pnpm install          # 依赖源已配置为 npmmirror
pnpm dev              # http://localhost:5173
```

后端需已运行在 `http://localhost:8787`（开发服务器已把 `/api` 与 `/admin` 代理过去）。
其他命令：

| 命令 | 作用 |
|------|------|
| `pnpm dev` | 开发服务器 :5173（HMR） |
| `pnpm build` | `tsc -b && vite build`，产物在 `dist/` |
| `pnpm test` | vitest 单测（响应包解包 / 验证码二次解码 / 401 刷新排队 / 徽标档位 / 报表图表 option 口径） |
| `pnpm typecheck` | 仅类型检查 |

## 目录结构

```
src/
├── api/
│   ├── client.ts        # fetch 封装：Bearer 注入、401 单次刷新+重放、错误包解包、验证码二次解码、坐标换算
│   ├── endpoints.ts     # 全部接口常量（与后端路由一一对应）
│   ├── paging.ts        # 两种分页形态（paginator / flat）统一读页与传参 + useList
│   ├── lookups.ts       # 下拉/树/名册等选项型查询
│   ├── types.ts         # 行类型，字段以后端控制器 index() 实际返回为准
│   └── client.test.ts   # 单测
├── auth/store.ts        # Zustand + persist（localStorage: property-admin-auth），仅存认证态
├── components/
│   ├── ListPage.tsx     # 通用列表页：筛选 + 表格 + 分页 + 行操作 + 批量操作
│   ├── FormModal.tsx    # 通用表单弹窗：声明式字段（含 custom 逃生舱、级联 onValuesChange）
│   ├── PasswordPrompt.tsx  # 敏感操作密码确认（后端删除类接口要求 password）
│   ├── RemoteSelect.tsx # 远程搜索下拉
│   ├── StatusTag.tsx    # 状态枚举集中映射（一处定义，全站复用）
│   ├── Chart.tsx        # 自写 ~40 行 ECharts 包装（init/setOption/resize/dispose）
│   └── PetMark.tsx      # 宠物形象 + 空状态（EmptyState）
├── layout/              # AppLayout（侧栏/顶栏/面包屑/用户菜单）+ menu.tsx（导航分组与页面标题）
├── pages/               # 各业务页面（见下）
├── theme/tokens.ts      # 设计令牌（规范 §1 的色板/圆角/字体 → antd ConfigProvider token；阴影例外，走 index.css，详见「设计令牌落地要点」）
├── App.tsx              # 路由表
├── AppProviders.tsx     # 外层依赖：ConfigProvider(主题/i18n) + AntdApp + QueryClientProvider + Router
├── main.tsx             # StrictMode + AppProviders + App
├── routes.smoke.test.tsx # 逐路由挂载冒烟（见下）
└── index.css
```

## 挂载冒烟测试（页面「能构建但一渲染就崩」的兜底）

`src/routes.smoke.test.tsx` 把 `App.tsx` 里**每条路由**的页面用 jsdom 真挂载一次，断言渲染出该页独有的文案且不抛异常；网络用桩（`vi.stubGlobal('fetch')`），不依赖后端。

- **新增路由时必须在 `ROUTES` 里补一行**（`page`/`path`/`marker`/`authed`），否则该页面没有防护。`marker` 要选该页独有的**可见文本**（placeholder 不在 `textContent` 里，选了会假红）。
- Provider 栈只有一份，在 `AppProviders.tsx`：`main.tsx` 与冒烟测试都用它，避免「测试里补了 Provider、线上没补」的假绿 —— 谁摘掉注入，两边一起红。
- jsdom 按文件声明（`// @vitest-environment jsdom`），全局仍是 node；`vite.config.ts` 的 `include` 已含 `*.test.tsx`。

## 图表口径测试（ECharts 的画布内容查不到 DOM）

`src/pages/ReportsPage.test.tsx` 把 `../components/Chart` 换成**捕获 `option` 的桩**再渲染页面 —— 图例与坐标轴文字画在 canvas 上，`container.querySelector` 永远看不见，脚本截图也只能靠肉眼。断言的是两处「图画得出来、看着正常」的口径：

- **收支趋势横轴取两串月份的并集**：类目轴与系列**按下标对齐**，轴上没有某个月，该系列的这一点就被静默丢弃。桩数据必须让两串月份**不等长**（收入缺 `2026-10`、支出有），等长的桩数据永远测不出这个缺陷。
- **访客状态图例走 `STATUS_MAPS.visitor` 文案**：字典外的值兜底成「状态 N」，不出现裸枚举号。断言里保留了 `{ status: 9 }` 这条，顺带钉住兜底文案。

两处都做过**反向验证**（临时改回旧实现，测试必须红且报出实际值），别在没做这一步的情况下宣称「加了测试就有防护」。

## 路由与模块（13 个模块 / 16 条路由）

| 路由 | 模块 | 关键能力 |
|------|------|----------|
| `/login` | 登录 | 真实点选验证码（点击图 → 原图坐标换算）、宠物全形象、密码规则与后端一致 |
| `/dashboard` | 值班台 | 欢迎卡（宠物 + 问候语）、待办统计（报修/投诉/欠费）、趋势图、状态分布、最近日志 |
| `/reports` | 报表中心 | 日期区间 + 小区筛选、8 项汇总、收支趋势、缴费方式饼图、报修/投诉/访客分布、欠费排行、PDF 导出 |
| `/communities` | 小区管理 | 增删改查 |
| `/rooms` | 房产管理 | 列表 + 小区结构树（四级、支持搜索过滤、级联表单） |
| `/owners` | 业主管理 | 增删改查 + 批量删除 |
| `/fee-bills` | 账单管理 | 增删改查 + 批量生成 |
| `/fee-payments` | 缴费记录 | 只读列表 + 线下缴费登记 |
| `/repairs` | 报修管理 | 详情抽屉（进度时间线）、派单、更新进度 |
| `/complaints` | 投诉管理 | 详情抽屉、处理、回访 |
| `/users` | 用户管理 | 增删改查 + 批量启用/禁用 + 批量删除 |
| `/roles` | 角色权限 | 增删改查 + 权限树勾选 |
| `/system/config` | 系统配置 | 键值对增删改查 |
| `/system/logs` | 操作日志 | 条件查询 + 详情 |
| `/system/profile` | 个人中心 | 资料修改、改密码、退出登录 |
| `*` | 404 | 宠物形象 + 返回值班台；标题「页面不存在 · 物业管理平台」（`PAGE_TITLES` 查不到即落进通配，标题取 `页面不存在`，别只剩光杆系统名） |

`/system/:tab` 由同一个 `SystemPage` 承载 config / logs / profile 三个页签。

## 宠物资产来源与同步提示

`public/favicon.svg`（图标标记）与 `public/pet_xiaozhu.svg`（全身形象）**复制自仓库 `docs/images/` 下同名文件**，本目录内的两份是副本。

> ⚠️ 同一形象在仓库内存在多处副本（`docs/images/`、Flutter 端资产等）。**改动任意一份都必须同步其余副本**，否则各端形象会不一致。同步后请校对 md5：
>
> ```bash
> md5sum docs/images/favicon.svg admin/apps/react/public/favicon.svg
> md5sum docs/images/pet_xiaozhu.svg admin/apps/react/public/pet_xiaozhu.svg
> ```

接线点（规范 §2）：登录页全身形象、侧栏标记、值班台欢迎卡、列表空状态、404 页。

## 设计令牌落地要点（改样式前先看这几条）

- **卡片阴影在 `src/index.css`**（`:root` 的 `--card-shadow` + `.ant-card` 规则）。antd 的 Card 不消费 `boxShadowTertiary` 一类 token，只写 token 不生效；`tokens.ts` 的 `cardShadow` 引用同一个 CSS 变量，避免两处写字面量。
- **表格行高 48px 是两个值配合出来的**：正文行高 24px（`token.lineHeight = 24/14`）+ 单元格上下内边距 11.5px（`Table.cellPaddingBlock` 与 `cellPaddingBlockMD`，`size="middle"` 读 MD 变体）+ 1px 分隔线。只改其中一个会变成 46/49px。报表页的 Top 10 表用 `size="small"`，故意保持紧凑，不受此约束。
- **列宽要真的落地，得配 `Column.ellipsis`**：表格是 auto 布局（操作列 `fixed:'right'` + `scroll.x:'max-content'` 让 rc-table 停在 auto 分支），列上的 `width` 只是提示，内容更宽时列会被顶开 —— 报修「问题描述」曾按内容渲染成 576px（且随数据长短浮动），Angular 同列是恒定 220px。`ellipsis: true` 给单元格加 `max-width: 0`（规则在 `index.css` 的 `.cell-ellipsis`，四条声明与 Angular `data-table.scss` 的 `.ellipsis` 逐字一致，改一端要同步），宽度才成为硬约束；同时把全文挂到 `title` 原生悬浮，对应 Angular 的 `[attr.title]`。带 `ellipsis` 标记的是报修「问题描述」与配置「配置值 / 说明」。
- **全站列宽逐列显式声明（规范 §1.3），取值对齐 Angular**：13 个页面的每一列都在代码里写了 `width`。**比对口径是声明值而非实渲值** —— 表格 auto 布局在容器有余量时会把富余摊给各列，两端同名列实渲可以差几像素（规范 §1.3 已裁定可接受）。**2026-10-03 列集取并集后，11 张列表在两端的列集与声明宽已完全一致**（逐页：报修 140/150/84/84/220/90/100/150/150；小区 180/120/220/90/90/160/100/150；房产 140/150/100/100/80/120/110/90/100/100/150；业主 120/140/180/80/110/90/150；账单 190/150/120/120/120/110/180/120/100/150/150；缴费 190/120/110/90/150/110/200/150；投诉 220/90/110/100/90/150/90/150；用户 140/120/140/180/90/150/150；角色 160/180/200/110/100/150；配置 140/180/240/100/240/150；日志 130/180/90/260/140/110/160）。**操作列宽 170 在 `ListPage` 里声明**（同 Angular `data-table.scss` 的 `.ops-head`）：规范 §1.3 裁定 170 —— `table-layout: auto` 下**声明宽是下限不是上限**，3 个行内按钮的实测内容宽是 React 156 / Angular 165，声明 150 会被撑到 156；声明 170 后两端都恰好等于声明值、不随内容抖动（1 个按钮的行上量出的 150 装不下 3 个按钮，这是上一轮的教训）。
  - 长文本列（Angular 原先不声明、按内容渲染 368/508 那种）两端已收敛到同一组值：小区名称 180 / 地址 220；业主·用户邮箱 180；角色描述 200；缴费备注 200；配置值 240 / 说明 240（均带 `ellipsis`）；日志请求路径 260。
  - 并集补上的 5 列（本端原先没有）：房产 套内(m²) 110；账单 缴费时间 150；缴费 操作员ID 110；角色 创建时间 150；配置 更新时间 150。反向的 4 列（房产 小区/楼栋/单元、账单 房产/费用类型、投诉 满意度、日志 来源端）由 Angular 补齐 —— 缴费页的「账单」列**两端同删**（lead 2026-10-03：那列只显示后端返回的裸 hashid，反查要额外拉账单表且受分页限制，显示裸 hashid 等于没有信息）。至此 `★` 标注只剩报表页的欠费 Top10 —— Angular 已补上该表，现两端同为 5 列且表头逐字一致（排名 60 / 业主 120 / 联系电话 140 / 房号 160 / 欠费金额(元) 120；本端声明了全部五列，Angular 只声明了排名 60，另四列的声明宽已报 lead 让其补齐同值；导出 PDF 的表头与 Angular `arrearsColumns` 同文案，均不含排名列）。增删列前先两端各跑一次 `/tmp/declared_diff.py` 式的声明值比对 —— 注意比对脚本要能吃下**多行对象**（`{` 与 `title:` 之间夹注释的列，早先的窄正则会把「费用周期」整列漏掉，漏检比错检更危险）。
  - **横向滚动是接受项，不要为消滚动条压窄列宽**（lead 2026-10-03 作废了早先「1440 下不出现横向滚动」的口径）：两端容器本就不同宽（React 因多一层 Card+Tabs 嵌套为 `1068`、Angular 为 `1120`），而统一列集的声明和已达 1220（配置页）—— 无论如何都装不下，两端同值即同宽同滚动，且操作列固定在右侧，横滚不藏动作。1440 视口下本端实测溢出：小区 162、房产 292、业主 0、账单 562、缴费 2（删掉「账单」列后从 192 降下来）、报修 220、投诉 52、用户 54、角色 0、配置 152、日志 172（同表 Angular 侧差 ≤2px，差的就是容器宽度；房产页例外 —— 它的树面板让 Angular 容器只有 828，溢出 582，同样接受）。勾选列（`rowSelection`）不是数据列，**不适用列宽规则**，用 antd 默认呈现（实渲 32~33px，Angular 的 nzShowCheckbox 在有余量的表上会被摊到 80px，同属豁免项）。
- **`message` 一律用 `App.useApp()` 取，不许静态导入**：静态 `message.success()` 不消费 `ConfigProvider`（antd 只在 dev 打一条 `[antd: message] Static function can not consume context...` 告警），toast 会回落成 antd 默认观感 —— 实测正文色 `rgba(0,0,0,.88)`、图标 `#52C41A`；改用 `App.useApp()` 后是正文色 `#1F2937`、图标 `#10B981`（本地 token）、圆角 12px（卡片 token）。`<App>` 已在 `AppProviders` 里包好，页面/组件里加一行 `const { message } = App.useApp()` 即可。⚠️ Angular 端同一 toast 的正文色与图标与我们一致，但**圆角是 NG-ZORRO 的默认 2px**（未接 token），要拉平得在他们那边设 message 的圆角。
- **空值符统一用全角破折号 `—`**：表格（`ListPage` 的 `renderCell`、`StatusTag`/`statusText`）与抽屉里的日期、描述、人员等空值都渲染 `—`，与 Angular 同口径；别再用半角 `-`。⚠️ 这条只管**空值**：`0` 是有意义的取值，别渲染成破折号 —— 投诉「匿名」列就是 `0=实名 / 1=匿名` 两个都挂标（`STATUS_MAPS.anonymous`，同 Angular `ANONYMOUS_TAGS`），早先实名渲染 `—` 是信息丢失。**自定义 `render` 的返回值同样吃这条兜底**（`ListPage` 单元格：`null`/`undefined`/`''` → `—`）：`nameOf(id) || id` 这类「查名字、查不到退回原值」的写法在 id 是空串时返回空串，单元格会白掉、而 Angular 显示「—」。注意**不能**把自定义 render 的结果直接喂给 `renderCell` —— 它末尾是 `String(value)`，传 React 元素进去会渲染成 `[object Object]`。
- **表单提交：可选字段为空时不要发这个键**（与 Angular 同口径，2026-10-03）：后端 `store()` 是 `only([...])` 之后直接 `create()`，空串会被当值写库 —— 落进 `datetime` / `number` 列就是类型错。报修建单的 `onSubmit` 显式重建提交体（`const optional = (k) => values[k] || undefined`），`undefined` 的键由 `JSON.stringify` 丢弃，后端即用列默认值。同时**去掉了类别/紧急度的预选**：类别是派单依据，预选等于替提交人做判断，容易整批错单。
- **颜色只用五档语义 token，页面里不许内联 antd 预设色名**（`gold` / `green` / `volcano` / `lime` … 一律别用）：**预设名走的是 antd 自己的色板，不经过我们的 token**，与语义 token 不是同一个值 —— `gold` #FAAD14 ≠ `warning` #F59E0B、`green` #52C41A ≠ `success` #10B981，所以「看着都是黄/绿」但两端各自画出了不同颜色。登录页验证码提示 chip 的三态原写 `gold`/`green`/`default`（实测 `rgb(212,136,6)`），Angular `hintTone()` 是 `warning`/`success`/`default`（`rgb(245,158,11)`，即 §1.1 的琥珀）；2026-10-03 改成三档语义 token 后两端逐值同色（fg `rgb(245,158,11)` / `rgb(16,185,129)`，bg `rgb(255,250,230)` / `rgb(225,250,237)`）。`default` 可保留（它是语义名不是色相预设）。防线：`StatusTag.test.tsx` 的源码扫描用例（改前先跑红，恰好命中这两条、无假阳性）。同类坑还有「**三态/多态表达式只改被量到的那一态**」—— 三元的另外两臂同样是分叉源，整条链一起看。姊妹坑：`Typography.Text type="secondary"` 读的是 `colorTextDescription` 而非 `colorTextSecondary`（§1.3）—— 都是「以为走了 token、实际走了组件库自己的默认」。
- **图表色序是按位置的契约**（规范 §1.3）：`chartColors` 前五位定死 `primary → primary-light → warning → success → error`，ECharts 按**序列下标**取色，所以顺序一改、同一个分类在两端的饼图里就画出不同颜色。**图内若有语义取色，必须显式写颜色**（收支趋势就是 `colors.primary` / `colors.error`），不要写 `chartColors[3]` —— 调序时按下标取色的系列会静默换色。**饼图 series 必须带 `name`**（支付方式 / 报修状态 / 投诉状态 / 访客状态，与卡片标题同文案），tooltip 标题才两端一致。三条都有断言钉住（`ReportsPage.test.tsx`：色序前五位、趋势双色、系列名）。
- **路由级错误边界 `RouteErrorBoundary`（`src/components/`）**：挂在 `AppLayout` 的 `<Outlet />` 外层（**不是** `main.tsx` 最外层 —— 那样一崩整壳消失），某个页面渲染抛错时只把内容区换成回退界面（小筑 + 一句说明 + 「重试」），侧栏/顶栏照常可用、能直接切走。复位两路：换路由（`resetKey` = pathname）或点「重试」。**「重试」用 `refetchQueries({ type: 'all' })` 而不是 `invalidateQueries`**：崩掉的子树渲染期就抛错、没走到提交，React Query 的订阅在 effect 里也就没建立，此时 `invalidateQueries` 只标脏不发请求，重建子树仍是同一份坏数据；`type: 'all'` 才包含已无订阅者的查询。实测（畸形桩 `/admin/room/tree` 返回对象）：回退界面而非白屏、侧栏 14 个菜单项仍可点、点重试该接口请求数 1→2、切路由复位。⚠️ 单测里每个用例后必须 `cleanup()`：用例 1 的回退界面里也有「重试」按钮，不卸载则下一个用例的 `getByRole` 会命中遗留树里那个按钮（点到别的 QueryClient 上），表现为「点了没反应」——这是测试隔离问题，不是组件问题。
- **表头文案跟 Angular 的显式版**：配置页「配置键 / 配置值」、日志页「请求路径 / 操作时间」（筛选区 label 一并对齐，别再出现「路径包含」这类自造词）。日志页的「详情」行操作是看**请求参数**（`input` 字段，后端 `toArray()` 返回的 JSON 字符串，抽屉里格式化展示；与 Angular logs.ts 同一动作），加上操作列后日志表两端都是 8 列。⚠️ Angular 侧这两列表头仍写「路径 / 时间」（其筛选区与抽屉已是显式版），已报 lead 由其同步。
- **数值枚举的文案以 `docs/install.sql` 的列 COMMENT 为准**（后端控制器只透传数值、不给文案），全部集中在 `src/components/StatusTag.tsx` 的 `STATUS_MAPS`。2026-10-03 修掉三处错值：① 投诉「类型」本端写成 `1=建议 2=投诉`（SQL 是 `1=投诉 2=建议 3=表扬`，两端反了，还多出一个不存在的 `4=报修`）；② 投诉「分类」本端没有映射，表格里直接显示裸数字（SQL：`1=服务态度 … 7=其他`）；③ 用户/角色状态本端用了「停用/正常」，而 `management_admin_user` / `management_admin_role` 是「禁用/启用」（「停用/正常」是小区/租户那张表的），故拆成 `STATUS_MAPS.normal`（小区用）与 `STATUS_MAPS.enable`（用户/角色用）。投诉「状态」五值都留映射，免得出现裸数字（编号见本节末 2026-10-03 裁定）。`Complaint.category` 的类型也从 `string` 改成 `number`（model 里 `casts` 成 integer）。2026-10-03 又做了一轮**全量普查**（16 个数值字典 + 2 个字符串枚举，逐个对到 `docs/install.sql` 的列行号），新修两处：④ 配置「值类型」原是文本框、占位符写 `string / number / boolean / json` —— `number`/`boolean` 不是 `management_system_config.type`（install.sql:112）认的关键字，还漏了 `array`，改成与 SQL 及 Angular 一致的 5 值下拉（`CONFIG_TYPES`）；⑤ 账单「违约金」按 install.sql:764 的 COMMENT 改回「滞纳金」（Angular 已先改，两端同口径）。普查结论与逐条行号见当轮报文；前期**唯一与 SQL 注释不同**的投诉「状态」已由 lead 2026-10-03 裁定收口：**改的是后端守卫、不是编号** —— `handle` 收 0（待处理）置 1（处理中）、`visit` 收 1 置 3（已回访），编号回到 install.sql:974 的 `0=待处理 1=处理中 2=已处理 3=已回访 4=已关闭`，本端 `STATUS_MAPS.complaint` 随之改回（`StatusTag.test.tsx` 已把五值钉死）。**编号一变要全量找消费者**：除状态列/筛选/详情/报表饼图外，值班台「待处理投诉」待办计数（`DashboardPage` 的 `countOf(EP.complaint, { status: 0 })`）也吃这个编号，漏改就会把「处理中」算成「待处理」；行操作可见性同步为「受理」= 0、「回访」= 1（真正的准入仍以后端守卫为准，不符回 422）。
- **徽标一律「浅底彩字」，色相按语义档位**（lead 2026-10-03 裁定，两端同口径）：`StatusTag` 只用 antd 预设名 `success / warning / error / processing / default`，**不用实色白字、不用 `purple` 这类自定义色相、也不按值轮换**。① **状态类字典**（小区/用户角色启停、房产、业主、账单、报修、投诉、紧急度、投诉类型）逐值挂五档语义色，**同一状态两端同档位**（如 自住=processing、豁免=default、已评价=success、处理中=processing、逾期=error）；② **分类类字典**（无褒贬含义：报修分类/用途/装修/性别/支付方式/支付渠道/投诉分类/实名匿名/权限类型）**一律不挂色**、落到 `default` 中性 —— 彩色轮换无信息量，且是两端分叉的主要来源，归零最省。字典里没有的值兜底成「裸值 + 中性」（不是彩色）。回归测试在 `src/components/StatusTag.test.tsx`（锁档位与八值来源端，另有源码扫描用例禁止页面内联五档以外的预设色名 —— `gold`/`green` 与 token `warning`/`success` **不同名也不同值**，登录页验证码提示条的三态色 2026-10-03 据此对齐）。实测（浏览器 computed style，产物 `index-BBCQYy31.js` / md5 `903b76e5…` / 2026-10-03 03:25）：投诉 error 底 `rgb(255,240,240)` 字 `rgb(244,63,94)`；服务态度（分类类）default 底 `rgb(246,246,247)`；处理中 processing 底 `rgb(243,240,255)` 字 `rgb(79,70,229)`。
- **日志「来源端」列要映射后再显示**：`source` 是字符串枚举（`docs/install.sql:560` 八值），后端 `OperationLog::detectSource()` 透传小写标识；列上 `LOG_SOURCES[row.source] ?? row.source` 翻成展示名（网页端 / 安卓 / 鸿蒙 / macOS …，与 Angular `LOG_SOURCES` 逐字一致，改一端要同步），**不要把裸 `harmonyos` 直接给用户看**。
- **正文色必须显式锁 `colorText`**：antd 由 `colorTextBase` 派生出的 `colorText` 带 **0.88 alpha**（白底合成 ≈ `#3A434F`），而组件正文走的是 `colorText`、只有 `body` 吃 `colorTextBase` —— 只设 Base 会得到「body 实心、组件内发虚」的分叉（表头/数据格/统计卡数值全是浅一档的）。`tokens.ts` 里 `colorText: colors.text` 锁实心；派生档（placeholder/禁用 0.25、次要 `#6B7280`）不受影响，已实测。
- **输入/按钮一律 8px**：antd 会按 `size` 取 `borderRadiusLG`(12)/`borderRadiusSM`(6)，故在 `Button`/`Input` 的组件 token 里把 LG、SM 都锁成 8；卡片仍是 12px（`Card.borderRadiusLG`），标签/徽标仍是全局 SM 的 6px。
- **值班台统计卡的图标/配色来自后端**：`/admin/dashboard` 的 `stats[].icon` 是给 Flutter 版写的 Material 名（`people`/`person_add`/`bolt`/`description`…），`DashboardPage.tsx` 的 `STAT_ICONS` 只负责把名字翻成 Ant 图标组件、认不出走 `AppstoreOutlined`；**颜色一律用后端下发的 `color`**，前端不得另配色，否则与 Angular 版分叉（Angular 用同名映射表翻成 NG-ZORRO 图标名）。
- **antd 6 弃用改名清单（都是逐字等价，不是近似替换，改名时别照猜）**：`Drawer width`→`size`（**`size` 收数值**，`size={520}` 与 `width={520}` 同值；`size` 的 `'default'/'large'` 预设是另一回事，拿它替像素值会丢宽度）、`Empty imageStyle`→`styles.image`、`Modal maskClosable`→`mask.closable`、`Space direction`→`orientation`、`Statistic valueStyle`→`styles.content`、`Timeline items[].children`→`items[].content`、`Alert message`→`title`（antd 6.6.5 的 `Alert.js` 里 `['message','title']` 映射，dev 会打 `[antd: Alert] \`message\` is deprecated`；4 处已改：`ListPage`/`PasswordPrompt`/`LoginPage`/`RolesPage`）。等价性以装到的 antd 6 源码为准（如 `Statistic`：`style={{...valueStyle, ...mergedStyles.content}}`；`Timeline`：`content: content ?? children`）。改完在浏览器 console 里应零弃用告警 —— 冒烟测试只挂载不点击，弹窗/抽屉里的告警要手点才现形。**DOM 类名也换了几处**（写端到端脚本选元素时会踩）：`.ant-modal-content`→`.ant-modal-container`、`.ant-drawer-content`→`.ant-drawer-section`、`.ant-select-selection-item`→`.ant-select-content`；toast 只剩 `.ant-message-notice`（已无 `-content` 子节点）。类名以装到的 antd 6 DOM 为准，别按 5.x 的记忆写选择器。

## 已知后端契约缺口（前端已按现状适配，后端修复后需同步调整）

1. **形状 A 的 `page` 参数曾不生效（后端已修，前端无需改动）**：原应用未注册 `Paginator::currentPageResolver`，`AbstractPaginator::resolveCurrentPage()`（`vendor/illuminate/pagination/AbstractPaginator.php:523`）直接返回默认值 1，故 7 个业务模块列表恒返回第 1 页、`current_page` 恒为 1。**2026-10-02 后端已注册 resolver**（`app/common/PaginationBootstrap.php`，见 `admin/apps/README.md` §3），该问题应已消除——但**尚未用真实数据端到端验证**（本机 DB 不可连）。前端两种形状都照常传 `page`，且**仍不把响应里的 `current_page`/`page` 回灌表格**：页码本就是调用方状态，回灌会让形状 A 的翻页 UI 依赖后端恒为 1 的字段。
2. **角色权限回显缺口**：权限树返回 hashid、角色列表不返回已分配权限、而更新走 `sync()` 收原始 id，编辑角色时权限项需重新勾选。
3. **验证码画布实际 300×200**（后端 `AbstractCaptcha::$width/$height` 默认值，可被 `size` 选项覆盖）。前端在图片 `onLoad` 后按真实 natural 尺寸换算点击坐标，与规范 §3.1「以 natural 尺寸为准、不要写死常量」一致，画布尺寸变化也不会失效。
