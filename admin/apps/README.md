# 管理端多框架（admin/apps）

本目录是管理端（admin）前端的**多框架实现**集合，共用同一套后端 API 与同一套设计语言。

| 目录 | 框架 | 状态 |
|------|------|------|
| `flutter/` | Flutter Web（Material 3） | 存量，40 模块全量 |
| `harmonyos/` | HarmonyOS App | 存量 |
| `react/` | React 19 + Vite + Ant Design | 本轮新增（重设计） |
| `angular/` | Angular + NG-ZORRO | 本轮新增（重设计） |

React / Angular 两版是**重新设计**的实现，不是 Flutter 版的移植：视觉、信息架构、仪表盘叙事均按本文档的设计语言重做，业务模块按「每域一个样板」交付（见 §5），其余模块按同一模式扩展。

---

## 1. 设计语言：小筑（靛蓝 + 琥珀）

取自项目宠物「小筑」的配色（`docs/images/pet_xiaozhu.svg`）。两个框架必须使用同一组值。

### 1.1 色板

| 语义 | 值 | 说明 |
|------|-----|------|
| 主色 `primary` | `#4F46E5` | 靛蓝 600，按钮/链接/选中 |
| 主色深 `primary-dark` | `#4338CA` | 渐变终点、hover |
| 主色浅 `primary-light` | `#6366F1` | 渐变起点、次级强调 |
| 强调 `accent` | `#F59E0B` | 琥珀，与主色成对出现（徽标、激活条、宠物帽） |
| 成功 `success` | `#10B981` | |
| 警告 `warning` | `#F59E0B` | 同 accent |
| 危险 `error` | `#F43F5E` | |
| 页面底色 `bg-layout` | `#F5F6FA` | 微靛蓝灰，非纯白 |
| 侧栏底色 | `#1E1B4B` | 靛蓝 950（宠物瞳孔色），配 `#FBBF24` 激活项 |
| 正文 `text` | `#1F2937` | |
| 次要文字 | `#6B7280` | |

### 1.2 形状与字体

- 圆角：卡片 `12px`，输入/按钮 `8px`，标签/徽标 `6px`（比 Ant Design 默认更圆，是「重新设计」的一部分）
- 阴影：`0 1px 2px rgba(30,27,75,.06), 0 8px 24px rgba(30,27,75,.06)`（带靛蓝色相的柔和投影，不用纯黑）
- 字体栈：`-apple-system, "PingFang SC", "Microsoft YaHei", "Segoe UI", Roboto, sans-serif`
- 数字（统计卡数值）用 `font-variant-numeric: tabular-nums`

### 1.3 骨架尺寸（与 Flutter 版一致，跨端不跳）

- 侧栏展开 `240px` / 收起 `64px`；顶栏 `56px`；内容区内边距 `24px`；表格行高 `48px`
- 断点：`< 992px` 侧栏自动收起；`< 768px` 侧栏变抽屉
- 例外：卡片内的**次级紧凑表**（如报表页欠费 TOP10）允许用紧凑尺寸（约 `40px` 行高），主数据表必须 `48px`
- 表格**操作列在横向溢出时固定在右侧**（Angular 用 `position:sticky; right:0`，React 用 antd 的 `fixed: 'right'`，语义等价），保证横滚时行操作不被顶出视野 —— 两端同一规则
- 次要文字（含统计卡 label、表格次要说明）一律 `#6B7280`：**antd 的 `Typography.Text type="secondary"` 读的是 `colorTextDescription` 而非 `colorTextSecondary`**，只设后者会回落成 antd 派生色，两端即分叉
- 已接受的**两端允许不同**之处（不是漂移，勿擅自「拉平」）：① 个人中心页的版式（Angular 身份卡 + Descriptions + 弹窗；React 账号摘要 + 内联表单）—— 功能集相同（资料修改/改密码/退出登录），仅版式不同；② 页面内部组件的排布细节，只要用本文档的 token 与骨架即可；③ **声明宽是「下限」不是硬约束**：`table-layout: auto` 下内容更宽时列仍会被撑开，所以声明值必须按**真实数据里最宽的单元格**来定，否则列宽照样随内容抖动、两端照样各撑一套。操作列含 3 个行内按钮（详情 + 派单 + 进度），两端一律声明 **`170`**（实测内容宽 React 156 / Angular 165，声明 170 后两端都恰好等于声明值）。此前的教训：150 是在「仅一个按钮」的行上量出来的，必然装不下三个 —— **遇到列宽对不齐，先问「声明值装得下最宽内容吗」，而不是去压内容或改组件库内边距**
- 已裁定**记录不判定**的两端差异（存在即合规，勿再擅自「拉平」）：④ 汇总卡数值的单位后缀（Angular「3 单 / 5 人」，React 只有数字）；⑤ 顶栏面包屑（React 有、Angular 无）；⑥ `/reports` 页 DOM 节点数（React 多 9 个 `.ant-card` 节点，实测视觉逐像素相同）
- **图表系列色序两端统一**（按位置取色，顺序不同则同一个分类会画出不同颜色）：`[primary #4F46E5 → primary-light #6366F1 → warning #F59E0B → success #10B981 → error #F43F5E → #8B5CF6 → #0EA5E9 → primary-dark #4338CA]` —— 前 5 位为语义色、第 6–8 位为扩展色，两端逐位相同；**不做 5 色循环截断**（超过 5 个系列时保留颜色区分度）；饼图 tooltip 带系列名（如「支付方式」）
- **金额格式：千分位 + 两位小数**（`1,250,000.00`），单位写在标签或表头里（如「应收合计（元）」），**值上不挂 `¥`** —— 与「表头已写单位则值上不重复」同一条
- **颜色只走五档语义 token**（`success / warning / error / processing / default`），**页面里不得内联 antd/NG-ZORRO 的预设色名或十六进制** —— `gold`/`green`/`volcano` 这类预设与我们的 token **既不同名也不同值**（`gold` #FAAD14 vs `warning` #F59E0B、`green` #52C41A vs `success` #10B981），两端各写一种就会真的画出不同颜色。内联字面量（色名、`¥` 这类符号）是字典、组件、测试都管不到的盲区，建议配一条**源码扫描用例**兜住。**本条只管页面模板/组件里的内联**；样式表（`*.scss`/`*.css`）中为对齐组件库而写的字面量不算内联 —— 如 ng-zorro 缺 antd 类时的覆盖值（`styles.scss` 的 `#f6f6f7`）、表头底色与登录页装饰底（`#fafafa`/`#fafaff`）、React `index.css` 的 `#1f2937` —— 但须就近注释出处
- **对齐 ≠ 照抄**：裁定「向对端看齐」时，先判断对端那个做法**本身是否合理**；明显的缺陷（单位重复、冗余后缀、把有意义的取值当空值等）不要镜像过来，先提出来再统一。两端一致不等于两端都对 —— 本轮 `¥` 的教训就是「为了逐字一致」把一个重复单位从一端抄到了另一端。**表头已写单位（如「欠费金额(元)」）时，值上不再挂符号**
- 列表列宽必须**显式声明**，不依赖内容撑开 —— 内容驱动的列宽会随数据抖动，且两端会各撑出一套宽度。需要截断的列用 `max-width: 0` + `ellipsis` 让声明宽成为硬约束，全文挂 `title` 属性。**要让声明宽整体成为硬约束，表格必须是 `table-layout: fixed`** —— `auto` 布局下声明宽只被当作下限、剩余空间会按比例摊回（antd 侧给 `scroll.y` 即自动切 `fixed`，NG-ZORRO 侧补 `[nzScroll]="{ y: ... }"` 同理）；这也是「同一张表补了宽度声明却仍不是声明值」的常见原因。声明值取「内容需要的中等宽度」即可（长文本列用 `ellipsis` 吸收超出，全文挂 `title`）。**表格总宽超过容器时允许横向滚动** —— 两端声明同值即同宽同滚动，且操作列本就固定在右侧，横滚不会藏住动作。**不要为消掉滚动条去压窄列宽**。（早期版本写过「1440 下不得出现横向滚动」，该前提在两端补齐同一套列集后不成立：两端的容器宽度本就不同 —— React 因多一层 Card+Tabs 嵌套为 `1068`、Angular 为 `1120`，而统一列集的声明和达 `1220` —— 故该条作废。）勾选列（`rowSelection` / `nzShowCheckbox`）不是数据列，**不适用本条**，用各自组件库的默认呈现

---

## 2. 宠物「小筑」接线点（两个框架都要有）

源文件以 `docs/images/pet_xiaozhu.svg`（全身）与 `docs/images/favicon.svg`（图标标记）为准，**复制**到各应用的静态目录（构建期无法跨目录引用），沿用仓库既有约定「多处副本需同步」。

| 位置 | 呈现 |
|------|------|
| `public/favicon.svg` | 图标标记，`<link rel="icon">` 指向它 |
| 登录页 | 小筑全身像（高 ≤ 160px）+ 系统名 + 一句管家口吻的问候气泡 |
| 侧栏顶部 | 小筑图标标记 `28px` + 「物业管理平台」 |
| 仪表盘 | 「值班台」欢迎卡：小筑 + 按当前时段的问候（早安/午安/晚安）+ 用户名 + 今日待办计数 |
| 空状态 | 列表无数据的空态插图用图标标记 |
| 404 页 | 小筑全身像 + 返回首页按钮 |
| 加载态 | 全屏 Loading 用小筑图标标记替代默认转圈（可选，不阻塞） |

品牌名：**物业管理平台**（浏览器标题：`<当前页> · 物业管理平台`）。

---

## 3. API 契约（写死，勿猜）

- 后端基址（开发）：`http://localhost:8787`；前端开发服务器需把 `/api` 与 `/admin` 反代到该地址
- 统一响应包：`{ code, message, data }`，`code === 0` 为成功，其余为错误（`message` 可直接展示）
- 认证：`Authorization: Bearer <access_token>`（`/admin/*` 全部需要）
- 主键：所有业务 ID 是 **hashid 字符串**，不是数字
- 分页：**后端混用两种形状，通用列表组件必须同时兼容**（已对全部在范围内控制器逐一核对）：

| 形状 | 入参 | 出参 | 用于 |
|------|------|------|------|
| A：Laravel 分页器 | `page` + `page_size` | `data.data`（行数组）+ `data.current_page / per_page / total / last_page` | 小区 / 房产 / 业主 / 账单 / 缴费 / 报修 / 投诉（全部业务模块） |
| B：自定义 | `page` + `limit` | `data.list` + `data.total / page / limit` | 用户 / 角色 / 系统配置 / 操作日志（系统模块） |
| C：无分页 | — | `data` 直接是数组（权限是**树**） | `/admin/permission` |

  即抽象层不能假定某一种：把两种形状归一成 `{ rows, total, page, pageSize }` 后再喂表格。

### 3.1 认证与验证码

| 接口 | 方法 | 请求 | 响应 `data` |
|------|------|------|-------------|
| `/api/v1/captcha/generate` | POST | `{ difficulty: 'easy'\|'medium'\|'hard' }` | `{ key, image, extra: { texts: [{ text, order }] } }` |
| `/api/v1/auth/login` | POST | `{ username, password, captcha_key, clicks: [{x,y}] }` | `{ access_token, refresh_token, user: {...} }` |
| `/api/v1/auth/refresh` | POST | `{ refresh_token }` | 同上 |
| `/admin/profile/logout` | POST | — | — |

要点：

1. **验证码 `image` 是「整段 data URI 再做 base64」**：即 `image` 解码后得到 `data:image/png;base64,iVBOR...`。前端解码一次后**直接**作为 `<img src>`（`atob(image)`），不要再拼前缀。
2. `extra.texts` 只有 `{ text, order }`，**不含坐标**：界面需按 `order` 依次提示「请点击『<text>』」，用户点图时前端换算成图片原始坐标提交 `clicks`。换算**以图片自身 natural 尺寸为准**（读 `img.naturalWidth/naturalHeight`，不要写死常量）：后端画布当前默认 `300×200`（`AbstractCaptcha::$width/$height`），但可由后端 `size` 选项覆盖。
3. 登录密码规则（后端校验）：8–32 位，且含大写、小写、数字、特殊字符 `@$!%*?&`。
4. 连续 5 次失败锁定 15 分钟（HTTP 语义上仍是 `code: 429`）。
5. 401 时用 `refresh_token` 换新 token 并重放一次原请求；刷新自身 401 直接登出。并发 401 只发一次刷新，其余排队。

### 3.2 本轮用到的业务接口

| 模块 | 列表 | 详情/写操作 |
|------|------|-------------|
| 仪表盘 | `GET /admin/dashboard` → `{stats[], trends[], distribution, recent_logs}` | `GET /admin/dashboard/property` |
| 报表 | `GET /admin/report?start_date&end_date&community_id` | `POST /admin/export/pdf` |
| 小区 | `GET/POST /admin/community` | `GET/PUT/DELETE /admin/community/{hashid}` |
| 房产 | `GET /admin/room`、`GET /admin/room/tree` | `POST/PUT/DELETE /admin/room[/{hashid}]` |
| 业主 | `GET/POST /admin/owner`、`POST /admin/owner/batch/destroy` | `GET/PUT/DELETE /admin/owner/{hashid}` |
| 账单 | `GET/POST /admin/fee-bill`、`POST /admin/fee-bill/batch/generate` | `GET/PUT/DELETE /admin/fee-bill/{hashid}` |
| 缴费 | `GET /admin/fee-payment` | `POST /admin/fee-payment/offline` |
| 报修 | `GET/POST /admin/repair` | `PUT /admin/repair/{hashid}/assign`、`POST /admin/repair/{hashid}/progress` |
| 员工（派单名册） | `GET /admin/staff` | 只读；派单下拉的数据源 |
| 投诉 | `GET /admin/complaint` | `PUT /admin/complaint/{hashid}/handle`、`POST /admin/complaint/{hashid}/visit` |
| 用户 | `GET/POST /admin/user`、`POST /admin/user/batch/status` | `GET/PUT/DELETE /admin/user/{hashid}` |
| 角色/权限 | `GET/POST /admin/role`、`GET /admin/permission` | `PUT/DELETE /admin/role/{hashid}` |
| 配置 | `GET /admin/config` | `POST /admin/config`、`PUT/DELETE /admin/config/{id}` |
| 日志 | `GET /admin/log` | 只读 |
| 个人中心 | `GET /admin/profile` | `PUT /admin/profile`、`PUT /admin/profile/password` |

完整字段以对应控制器 `admin/app/admin/controller/*.php` 的 `index()` / `store()` 为准，实现前先读控制器，**不要臆造字段**。

**报修与员工 ID 契约（2026-10-03 起）**：报修列表与详情返回 `staff_id`（**员工 hashid**，未分配为空串）与 `staff_name`（员工姓名，未分配为空串）；派单 `assign`、编辑 `update` 提交的 `staff_id` 也必须是**员工 hashid**（无效或员工不存在判 422），派单界面用 `GET /admin/staff` 做下拉选人。⚠️ `show()` 里 `progress[].staff_id` 是**操作管理员 id**（非员工 id），不要当员工 hashid 解释。

---

## 4. 信息架构（重设计）

导航按**域**分组，与 Flutter 版的平铺分组不同：

```
总览   仪表盘 · 报表中心
资产   小区 · 房产（楼栋/单元/户型后续并入）· 业主
财务   账单 · 缴费记录
服务   报修 · 投诉
系统   用户 · 角色权限 · 系统配置 · 操作日志 · 个人中心
```

导航项文案一律用**短名**（小区 / 房产 / 业主 / 账单 / **缴费记录** / 报修 / 投诉），不带「管理」后缀 —— 分组标题（资产 / 财务 / 服务）已提供上下文，重复后缀只会让侧栏变长。注意「缴费记录」是完整词（不是「缴费管理」的省略），不按短名规则砍掉「记录」二字。

仪表盘改名「**值班台**」，叙事从「看统计」改成「先干活」：

1. 顶部：小筑欢迎卡（问候 + 今日待办：待处理报修 / 待处理投诉 / 逾期账单）
2. 中段：统计卡（用户总数 / 今日新增 / 今日活跃 / 今日日志，取 `/admin/dashboard` 的 `stats`，数值用 `tabular-nums`）
3. 图表：`trends` 折线、`distribution` 饼图（ECharts）
4. 底栏：`recent_logs` 最近操作时间线

---

## 5. 模块清单（每框架 13 项 / 约 16 条路由）

| # | 路由 | 模块 | 考察点 |
|---|------|------|--------|
| 1 | `/login` | 登录 | 点击验证码、宠物、错误提示 |
| 2 | `/dashboard` | 值班台 | 统计卡 + 双图 + 时间线 |
| 3 | `/reports` | 报表中心 | 日期筛选 + 多图 + 导出 |
| 4 | `/communities` | 小区管理 | 标准 CRUD 样板（搜索/分页/弹窗表单） |
| 5 | `/rooms` | 房产管理 | 树形（`room/tree`）+ CRUD |
| 6 | `/owners` | 业主管理 | CRUD + 批量删除 |
| 7 | `/fee-bills` | 账单管理 | 批量生成（选周期 + 小区） |
| 8 | `/fee-payments` | 缴费记录 | 只读列表 + 线下缴费登记 |
| 9 | `/repairs` | 报修管理 | 建单 + 状态流转（派单 / 进度上报）+ 只读详情抽屉 |
| 10 | `/complaints` | 投诉管理 | 处理 / 回访 |
| 11 | `/users` | 用户管理 | CRUD + 批量启停 |
| 12 | `/roles` | 角色权限 | 角色 CRUD + 权限树勾选 |
| 13 | `/system` | 系统配置 / 操作日志 / 个人中心 | 配置表单 / 只读日志 / 改密登出 |

其余模块（停车、设备、合同、SLA、催缴、巡检、商城、集团、知识库、审批、投票、支付……）本轮不做页面，但 §4 的目录结构与 API 客户端需能直接扩展。

---

## 6. 技术选型与工程约定

| | React | Angular |
|---|---|---|
| 脚手架 | Vite + React 19 + TS | Angular CLI（standalone） |
| 路由 | React Router 7 | Angular Router |
| 数据层 | TanStack Query 5 + Zustand（仅存认证态） | Signals + 轻量 service（`HttpClient`） |
| 组件库 | Ant Design 6（`ConfigProvider` 覆写 token） | NG-ZORRO（CSS 变量版 + `NzConfigService` 设 primaryColor） |
| 图表 | ECharts 6（自封装 `<Chart>` 组件，不引第三方 wrapper） | ECharts 6（同一封装思路） |
| 包管理 | pnpm（registry 已指向 npmmirror）；遇兼容问题退回 npm | 同左 |

共同约定：

- TypeScript strict；禁止 `any` 兜底业务数据
- 目录：`src/api`（客户端与端点常量）/ `src/auth`（token 存取 + 401 刷新）/ `src/layout`（骨架 + 菜单）/ `src/pages/<模块>` / `src/theme`（token 定义）/ `src/components`（共享表格/表单/空态）
- **通用列表页抽成一个共享组件**（搜索区 + 表格 + 分页 + 行操作），各模块只描述列与表单字段；13 个模块不允许出现 13 份复制粘贴的分页逻辑
- 生产构建必须零错误：React `pnpm build`；Angular `ng build`
- 单文件 ≤ 500 行；不新增仓库级文档（各应用 `README.md` 除外）

## 7. 本地联调与验收

```bash
# 后端（已在运行则跳过）
cd admin && php start.php start -d          # http://localhost:8787

# 前端
cd admin/apps/react   && pnpm install && pnpm dev     # 默认 5173
cd admin/apps/angular && pnpm install && pnpm start   # 默认 4200
```

开发服务器把 `/api`、`/admin` 反代到 `http://localhost:8787`。

**产物指纹的算法必须写死**（跨端「字节互认」靠它，配方不一致会算出不可比的哈希）：**以 `index.html` 所在目录为根**（Angular 是 `dist/xiaozhu-admin/browser`、React 是 `dist`），执行

```bash
(cd <根目录> && find . -type f | LC_ALL=C sort | xargs sha256sum | sha256sum | cut -d' ' -f1)
```

三个关键点：**同一个根目录**（以 index.html 所在处为准，不是各自的上层 dist）、**相对路径**（`find .`）、**`LC_ALL=C`**（排序与 locale 无关，否则两机结果不同）。只报入口文件哈希（`index-*.js` 的 md5/sha256）比整树哈希更不容易踩这个坑，建议两者都报、以入口哈希为主。

**桩数据的覆盖要求（验收盲区）**：只放「正常值」的桩会让一整类缺陷隐身 —— 图形类缺陷尤其（图例与坐标轴文字画在 canvas 上，**DOM 与截图都验不到**，只有把 `Chart` 换成捕获 `option` 的桩才能断言）。桩数据至少要覆盖：**不等长序列**（如某月只有支出没有收入）、**枚举外的值**（兜底路径）、**空串与 null**、**空数组**。每加一个兜底分支，就配一条能把它打红的反向验证。

验收：① 两框架 `build` 零错误；② 无头浏览器实测登录页（验证码真实渲染）与登录后各页面截图核对，宠物按 §2 出现；③ 根 README / CHANGELOG / CI 同步。

> 注：本机 MySQL 连接凭据与 `admin/.env` 不一致（`/health` 报 `database: unavailable`），登录后的数据接口无法真实取数；截图核对时用请求拦截注入桩数据，登录页验证码可走真实后端（Redis）。
