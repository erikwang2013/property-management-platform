# property_portal

物业管理系统 · 业主端 Flutter Web 客户端。

## 资产 (Assets)

| 文件 | 用途 |
|------|------|
| `assets/pet_xiaozhu.svg` | 项目宠物「小筑」— 登录页主视觉 |
| `assets/favicon.svg` | 小筑图标标记 — 空态插图 / 首页标记 / 壳层图标源 |
| `web/favicon.svg` | 浏览器标签图标（PNG 作为后备） |

> 两份 `assets/` 副本是 `docs/images/` 真源的**副本**：Flutter 资源必须位于包目录内，
> 无法引用仓库外的路径。`.svg` 副本共 8 处（两端 `assets/` + 两端 `web/` + `admin/public/`、
> `service/public/`、`admin/apps/react/public/`、`admin/apps/angular/public/`），改动源文件需全量同步；
> 各平台**派生位图**（launcher / 启动图 / favicon.ico 等 68 件）统一由
> `bash scripts/gen-pet-icons.sh` 重新生成（tile / full / maskable 三变体）。
> 加载依赖 `flutter_svg`，见 `pubspec.yaml` 中 `flutter_svg: ^2.3.0`。

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
