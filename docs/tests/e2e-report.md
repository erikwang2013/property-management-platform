# E2E 测试报告 — 物业管理系统

- 测试日期：2026-08-27
- 测试方式：Playwright（chromium headless）+ Node.js 22，脚本位于 `scripts/e2e/`
- 服务环境：webman 2.2.3（workerman 5.2.2）本地启动于 `http://127.0.0.1:8787`，复用现有 `.env`（未连真实生产 DB；`/health` 显示 database:unavailable、redis:ok）
- 移动端：Flutter widget 测试（`flutter test`，flutter tester 无头运行）；HarmonyOS 无可执行环境（详见下文）

## 一、页面清单与测试范围

| 页面 | 模板 | 可测性 | 说明 |
|------|------|--------|------|
| 安装向导 step1（环境检查/DB 配置） | `admin/app/view/install/step1.html` | 可测（临时修复模板路径后） | 当前 git 状态下该页 500（见缺陷 #1） |
| 安装向导 step2（管理员账户） | `admin/app/view/install/step2.html` | 可测（同上） | 含可选配置折叠区 |
| 安装向导 step3（确认安装） | `admin/app/view/install/step3.html` | 部分可测 | 确认页可测；**执行安装（_confirm=1）禁测** |
| 安装锁定页 | `admin/app/view/install/installed.html` | 可测 | 临时创建 `public/.installed` 后验证，立即删除 |
| 首页/登录入口 | `admin/app/view/index/view.html` | 不可达 | 无路由渲染（见"环境不可测" #2） |
| 移动端 Flutter | `apps/flutter/` | 可测 | 9 个 widget 测试全部通过 |
| 移动端 HarmonyOS | `apps/harmonyos/` | 环境不可测 | 无 hdc/模拟器/真机（见"环境不可测" #3） |

测试模式说明：当前 git 状态下向导模板位于 `app/view/install/`，而 webman 实际解析 `app/admin/view/install/`（app 名取自 `app\admin\controller` 命名空间），导致全部向导页 500。E2E 分两阶段：

- **broken 模式**：直接测试当前 git 状态，如实记录 500 缺陷现象；
- **fixed 模式**：临时把模板移动到 webman 实际解析路径，完整验证向导 4 页功能与校验，结束后移动回原位置并重启服务恢复原状。

## 二、用例与结果

### 2.1 安装向导 — broken 模式（当前 git 状态，`wizard-e2e.js` E2E_MODE=broken）

| # | 用例 | 结果 | 说明 |
|---|------|------|------|
| 1 | GET /install 状态码 | 通过（如实 500） | 实际 500，暴露缺陷 #1 |
| 2 | 500 响应体为被掩盖的 TypeError | 通过 | `MetricsCollector` 返回类型过窄，掩盖真实错误（缺陷 #2） |
| 3 | 页面渲染出安装向导标题 | 失败 | 500 错误页，无向导内容（缺陷 #1 的直接后果） |
| 4 | POST _step=2 | 通过（如实 500） | 实际 500 |
| 5 | POST _step=3 | 通过（如实 500） | 实际 500 |

小计：4 通过 / 1 失败（失败即缺陷复现）。

### 2.2 安装向导 — fixed 模式（模板临时移到正确路径后，`wizard-e2e.js` E2E_MODE=fixed）

**step1（DB 配置）**

| # | 用例 | 结果 |
|---|------|------|
| 6 | step1 渲染成功(200) | 通过 |
| 7 | 页面标题「安装向导 — 物业管理系统」 | 通过 |
| 8 | 进度条第 1 步 active | 通过 |
| 9 | 存在字段 #host/#port/#database/#username/#password | 通过（5 项） |
| 10 | 默认值 host=127.0.0.1 / port=3306 / database=property_management | 通过（3 项） |
| 11 | 隐藏域 _step=2 | 通过 |
| 12 | 提交按钮文案「下一步」 | 通过 |
| 13 | 页脚版权 erik.xyz | 通过 |
| 14 | 空表单被 HTML5 required 拦截（未提交） | 通过 |
| 15 | 服务端校验：错误返回 200 + 错误文案（绕过 HTML5 直测 API） | 通过 |
| 16 | 服务端校验：端口提示「请输入有效的端口号」 | 通过 |
| 17 | 服务端校验：库名/用户名提示 | 通过 |
| 18 | 合法输入 → step2 渲染 | 通过 |

**step2（管理员账户）**

| # | 用例 | 结果 |
|---|------|------|
| 19 | step2 渲染「步骤 2/3 · 管理员账户」 | 通过 |
| 20 | 进度条第 1 步 done、第 2 步 active | 通过 |
| 21 | DB 摘要显示 127.0.0.1:3306 | 通过 |
| 22 | 隐藏域携带 DB 配置 | 通过 |
| 23 | 可选配置折叠区（details/summary）存在 | 通过 |
| 24 | 用户名 <3 字符提示「管理员用户名至少3个字符」 | 通过 |
| 25 | 密码强度提示（8-32 位 + 大小写/数字/特殊字符） | 通过 |
| 26 | 两次密码不一致提示 | 通过 |
| 27 | 服务端错误回显在页面（form.submit() 绕过 HTML5 直测） | 通过 |
| 28 | 合法管理员（Admin@12345）→ step3 确认页 | 通过 |

**step3（确认安装）**

| # | 用例 | 结果 |
|---|------|------|
| 29 | step3 渲染「步骤 3/3 · 确认安装」 | 通过 |
| 30 | 显示确认安装表单（未执行） | 通过 |
| 31 | 密码掩码（••）显示 | 通过 |
| 32 | 隐藏域 _confirm=1 | 通过 |
| 33 | 隐藏域保留管理员账户 | 通过 |
| 34 | **执行安装（_confirm=1）** | 环境不可测 | 会改写 .env、导入 install.sql、创建 public/.installed，按约束禁测 |

小计：32 通过 / 1 环境不可测（#34，有意记录，非缺陷）。

### 2.3 安装锁定页（`installed-page.js`，临时创建 public/.installed 后验证）

| # | 用例 | 结果 |
|---|------|------|
| 35 | 标题「已安装 — 物业管理系统」 | 通过 |
| 36 | h1「系统已安装」 | 通过 |
| 37 | 提示删除 public/.installed 重新安装 | 通过 |
| 38 | 存在「前往管理后台」按钮（href=/admin） | 通过 |

小计：4 通过 / 0 失败。验证后已删除临时锁文件并重启服务。

### 2.4 首页 / 健康检查（`index-page.js`）

| # | 用例 | 结果 |
|---|------|------|
| 39 | GET / 状态码 | 通过（如实 404） | `Route::disableDefaultRoute()`，无 / 路由 |
| 40 | 首页不渲染 index/view.html 模板内容 | 通过 | 模板存在但无路由可达 |
| 41 | GET /index/view.html | 通过（如实 404） | 无路由渲染该模板 |
| 42 | GET /health 状态码 200 | 通过 | |
| 43 | /health 返回 JSON 结构 | 通过 | {code:0, message:success, data:{app:open-admin, version:1.0, database:unavailable, redis:ok, elasticsearch:unavailable}} |
| 44 | GET /install（交叉验证缺陷 #1） | 通过（如实 500） | |

小计：5 通过 / 1 通过（如实记录 500 缺陷交叉验证）。

### 2.5 移动端 Flutter（`flutter test`，9 个用例全部通过）

| 测试文件 | 用例 | 结果 |
|---------|------|------|
| widget_test.dart | App 渲染登录页 | 通过 |
| login_page_test.dart | 空表单点登录触发校验提示 | 通过 |
| login_page_test.dart | 点击验证码后登录成功跳转首页 | 通过 |
| home_page_test.dart | 首页渲染统计卡片、功能入口与公告 | 通过 |
| home_page_test.dart | 接口失败时首页回退默认值 | 通过 |
| fee_bills_page_test.dart | 账单列表渲染账单卡片 | 通过 |
| fee_bills_page_test.dart | 状态筛选切换后重新加载 | 通过 |

小计：9 通过 / 0 失败。

## 三、发现的真实 Bug

### Bug #1（P0，当前 git 状态生效）：安装向导全部页面 500

- **现象**：`GET/POST /install` 全部返回 500，安装向导 4 页均无法访问。
- **根因**：向导模板位于 `admin/app/view/install/`，但 webman 的 Raw 视图解析器按控制器命名空间 `app\admin\controller` 解析 app 名为 `admin`，实际加载路径为 `admin/app/admin/view/install/`（不存在）→ 模板 include 失败 → 500。该错位由提交 66f90c6 引入。
- **验证**：将模板移动到 `app/admin/view/install/` 后全部向导页恢复 200，完整流程可跑通（32 项断言通过）。
- **修复建议**：将 `admin/app/view/install/` 移至 `admin/app/admin/view/install/`（git mv），或将 InstallController 注册为无 app 前缀路由。

### Bug #2（P1）：MetricsCollector 返回类型过窄，掩盖真实错误

- **现象**：500 响应体是 `TypeError: Return value must be of type support\Response, Webman\Http\Response returned`，而非真实错误（模板 include 失败），错误排查被误导。
- **根因**：`app/middleware/MetricsCollector.php` 的 `process(): support\Response` 声明了返回类型 `support\Response`（Response 子类），而中间件链在异常路径（`exceptionResponse`）返回裸 `Webman\Http\Response`，导致 TypeError。Cors/SecurityFilter/RateLimit 等其他中间件均声明宽类型，不受影响。
- **影响**：所有 500 的响应体都被该类型错误掩盖，/metrics 的 5xx 统计也失真。
- **修复建议**：`MetricsCollector::process()` 返回类型改为 `Webman\Http\Response`（与其余中间件一致）。

## 四、环境不可测项（如实记录，未伪造结果）

1. **安装向导 step3「执行安装」（_confirm=1）**：会真实改写 `.env`、导入 `install.sql`、创建管理员与 `public/.installed` 锁，按用户约束「不修改生产配置/不连真实生产 DB」禁测。确认页渲染与隐藏域已全部验证（用例 29-33）。
2. **首页/登录入口（index/view.html）**：模板为 webman 默认 hello 模板，`Route::disableDefaultRoute()` 后无任何路由渲染它（/ 与 /index/view.html 均 404）。实际前端登录入口是 Flutter Web 应用（apps/flutter，独立构建产物），其登录页 widget 测试已通过（见 2.5）。
3. **HarmonyOS 移动端（apps/harmonyos）**：环境中无 DevEco Studio 模拟器、无 hdc 设备桥、无真机连接，且工程内无测试目录，ArkTS UI 测试无可执行环境，故如实标记为不可测（Flutter 侧同源功能已覆盖）。

## 五、截图证据

目录：`scripts/e2e/screenshots/`

| 文件 | 内容 |
|------|------|
| broken-step1-500.png | 当前 git 状态 /install 500 错误页 |
| index-root-404.png | GET / 404 页面 |
| health-200.png | /health 健康检查 JSON |
| fixed-step1-render.png | step1 渲染（修复后） |
| fixed-step1-html5-required.png | step1 空表单 HTML5 校验拦截 |
| fixed-step2-render.png | step2 渲染 |
| fixed-step2-validation-error.png | step2 服务端错误回显 |
| fixed-step3-confirm.png | step3 确认页 |
| fixed-installed-page.png | 安装锁定页 |

## 六、最终统计

| 范围 | 通过 | 失败 | 环境不可测 |
|------|------|------|-----------|
| 安装向导 broken（缺陷复现） | 4 | 1（即缺陷） | 0 |
| 安装向导 fixed（完整功能） | 32 | 0 | 1 |
| 安装锁定页 | 4 | 0 | 0 |
| 首页/健康检查 | 5 | 0 | 1（交叉验证项如实记 500，算入 broken 口径） |
| Flutter widget 测试 | 9 | 0 | 0 |
| HarmonyOS | 0 | 0 | 1（整端不可测） |
| **合计** | **54** | **1**（缺陷复现断言） | **3** |

- 真实缺陷：2 个（Bug #1 模板路径错位 P0、Bug #2 MetricsCollector 返回类型过窄 P1）
- 全部 E2E 脚本实际运行通过；所有失败项均有明确原因（缺陷复现或环境不可测），无伪造结果
- 测试后已还原：模板回到 `app/view/install/`、`public/.installed` 已删除、服务以 git HEAD 代码重启（`/install` 恢复 500 缺陷原状，与提交前一致）；本任务未提交任何 git 变更

## 七、复现与修复验证命令

```bash
# 缺陷复现（当前 git 状态）
cd scripts/e2e && E2E_MODE=broken node wizard-e2e.js

# 完整验证（run.sh 自动：broken → index → 移动模板 → fixed → installed 页 → 还原）
bash scripts/e2e/run.sh

# Flutter
cd apps/flutter && flutter test
```

## 八、缺陷修复确认（2026-08-27 主线修复后复测）

| Bug | 修复内容 | 复测结果 |
|-----|----------|----------|
| #1 P0 模板路径错位 | `git mv` 将 4 个安装页模板从 `app/view/install/` 移至 webman 实际解析路径 `app/admin/view/install/` | `E2E_MODE=fixed` 重跑：**32 通过 / 0 失败**（唯一非通过项为按约束禁测的 `_confirm=1` 执行安装） |
| #2 P1 MetricsCollector 返回类型过窄 | `process(): support\Response` → `Webman\Http\Response`（父类，与 Cors/SecurityFilter/RateLimit 一致），异常路径不再被 TypeError 掩盖 | admin phpunit 复跑全绿（258/619） |

修复后安装向导整体可用，向导流程验证截图见 `scripts/e2e/screenshots/fixed-*.png`。
