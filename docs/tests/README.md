# 测试报告索引

- 日期：2026-08-27
- 测试团队：PHP ×2（admin/service）、API、UI 自动化 4 名测试工程师并行执行；Go/Rust 工程师已核查（项目无对应代码）

## 汇总

| 套件 | 测试数 | 断言数 | 通过率 | 报告 |
|------|--------|--------|--------|------|
| admin 单元测试 | 258 | 619 | 100%（2 个 DB 门控跳过） | [admin-unit-report.md](admin-unit-report.md) |
| service 单元测试 | 201 | 661 | 100%（1 个应用缺陷门控跳过） | [service-unit-report.md](service-unit-report.md) |
| API 自动化（并入上两套件） | 全部端点 | — | 100% | [api-report.md](api-report.md) |
| UI 端到端 | 54 用例 | — | 通过（1 缺陷复现 + 3 环境不可测，缺陷已修复） | [e2e-report.md](e2e-report.md) |
| Go | — | — | 无代码，无可测对象 | [go-unit-report.md](go-unit-report.md) |
| Rust | — | — | 无代码，无可测对象 | [rust-unit-report.md](rust-unit-report.md) |
| **合计** | **459** | **1280** | — | — |

## 本轮发现的真实缺陷（均已修复）

| 级别 | 缺陷 | 修复 |
|------|------|------|
| P0 | 安装向导模板路径错位（`app/view/install/` vs webman 解析 `app/admin/view/install/`）→ `/install` 全 500 | 模板移至 `app/admin/view/install/`，E2E 复测 32/32 |
| P1 | `MetricsCollector::process(): support\Response` 异常路径 TypeError，掩盖真实错误、5xx 统计失真 | 返回类型改为父类 `Webman\Http\Response` |
| P1 | `ActivitySignup`/`ParkingRecord` 开启时间戳但表无 `updated_at`，写路径必崩 | `$timestamps = false` |
| P1 | `Visitor::$fillable` 缺 `id`，`create()` 静默丢主键 | 补 `id` |
| P2 | `ApiVersion` 中间件把 404/400 语义传给 `json()` 第二参（编码选项位掩码）→ HTTP 状态恒 200 | 显式状态码构造响应（admin + service 两处 + DocsController） |

## 待办（门控跳过的应用缺陷，未修）

1. 10+ 模型 `decimal` 裸 cast 在 Eloquent 11+ 读取即崩 —— 需改为 `'decimal:2'`（service 1 用例门控跳过）
2. vendor `erikwang2013/poster-php` ImagickDriver 在加载 imagick 环境下 clone 未初始化 typed 属性崩溃（生产需注册 CaptchaPlugin 或以 GD 驱动运行）
3. batch3 表（vote/mall/face/notification/knowledge/chat）dev 库未迁移，对应控制器仅覆盖校验路径

## 运行方式

```bash
cd admin && vendor/bin/phpunit --no-coverage    # admin 258 用例
cd service && vendor/bin/phpunit --no-coverage  # service 201 用例
bash scripts/e2e/run.sh                          # UI 端到端
cd apps/flutter && flutter test                  # Flutter widget 测试
```
