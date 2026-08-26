# モバイル端ギャップ一覧

> 生成日：2026-08-16 · 出典：pmp-team ci-agent（P3-③ 現状棚卸し、読み取り専用）
> 対応ロードマップ：docs/PROJECT_PLAN.md P3 — "HarmonyOS 7 ページをコアパス（支払い/修理依頼/お知らせ/来訪者/駐車）に拡張、Flutter 所有者端のモバイル対応"

## 一、HarmonyOS 所有者端の現状（apps/harmonyos、7 ページ）

| ページ | ルート（main_pages.json 登録済み） | 呼び出し API |
|------|------------------------------|---------|
| LoginPage | pages/LoginPage | ログイン（AuthService） |
| HomePage | pages/HomePage | GET /service/home（ダッシュボード：未払い/工単/不動産数 + お知らせ一覧） |
| FeeBillsPage | pages/FeeBillsPage | GET /service/fees/bills?page=1&per_page=50 |
| RepairListPage | pages/RepairListPage | GET /service/repairs |
| RepairSubmitPage | pages/RepairSubmitPage | POST /service/repair |
| AnnouncementPage | pages/AnnouncementPage | GET /service/announcements?page=1&per_page=50 |
| ProfilePage | pages/ProfilePage | GET /service/profile、POST /service/profile/logout |

**ナビゲーション現状**（全アプリで遷移は 4 つだけ）：Login→Home、Home→Login（ログアウト）、Profile→Login、RepairList→RepairSubmit。HomePage は統計カード + お知らせ一覧のみで、機能エントリグリッドなし；FeeBills/Announcement/Profile ページは存在するが**エントリがなく、到達不可**。

## 二、HarmonyOS コアパス対照

| コアパス | 現状 | ギャップタイプ |
|---------|------|---------|
| 支払い | ページあり、API 疎通 | 純フロント：Home にエントリなし（到達不可） |
| 修理依頼 | 一覧+提出ページあり、API 疎通 | 純フロント：Home にエントリなし（到達不可） |
| お知らせ | ページあり、API 疎通 | 純フロント：Home にエントリなし（到達不可） |
| 来訪者 | ページなし | 新規ページが必要（API は既存：GET/POST/PUT/DELETE /visitor*） |
| 駐車 | ページなし | 新規ページが必要（API は既存：/parking/vehicles、/parking/spaces、/parking/records） |

バックエンドにギャップなし：5 つのコアパスの service API は全て準備完了（fees/repairs/announcements は常駐ルート；parking/visitors は standard 版のゲート内）。ApiService.ets に汎用の get/post/put/delete が既にあり、新ページはそのまま再利用可能。

## 三、Flutter 所有者端の現状（apps/flutter、13 モジュール）

**ページ一覧**：login、home、fee、repair、parking×3、visitor×2、activity、notification、vote、mall×3、chat、face、profile — 全てルート登録済み（app.dart getPages）、5 つのコアパスは全て実装済み。

**モバイル対応の問題**：home_page / login_page のみ LayoutBuilder/MediaQuery のレスポンシブブレークポイントを使用；**10 ページがデスクトップ幅をハードコード**しており、スマホ幅（<400px）では RenderFlex オーバーフローが必発：

| ページ | ハードコード |
|------|--------|
| chat_page | SizedBox(width: 600) |
| mall_products_page | width: 800 |
| mall_product_detail / mall_orders | SizedBox(width: 600) |
| notification_list | width: 480 + SizedBox(width: 600) |
| vote_list / vote_detail | SizedBox(width: 600) |
| activity_detail、parking_records/vehicles、visitor_list、face_register | ブレークポイント処理なし（同種の問題と想定、行単位の検証は未実施） |

また：ボトムナビゲーションバー（BottomNavigationBar）なし、エントリは AppBar + グリッド；ページ padding 24 はデスクトップ寄り。i18n バイリンガルは準備済み。

## 四、ギャップ一覧（分類 + 工数）

### バックエンド依存（なし）

### 純フロント

| # | 項目 | 工数 |
|---|----|--------|
| 1 | HarmonyOS HomePage に機能エントリグリッドを追加（Flutter 版 12 エントリに対照）、支払い/修理依頼/お知らせ/来訪者/駐車/マイページに接続 | M |
| 2 | HarmonyOS に VisitorPage を新規追加（一覧 + 新規作成、VisitorController 再利用） | M |
| 3 | HarmonyOS に ParkingPage を新規追加（車両/駐車スペース/記録、ParkingController 再利用） | M |
| 4 | Flutter 所有者端のハードコード幅を解消（600/800/480 → maxWidth 内に制約または ConstrainedBox 化） | S |
| 5 | Flutter 所有者端にボトムナビゲーションバー + コンパクト padding を追加（スマホ端が検収対象の場合） | M |

### 要連携

| # | 項目 | 工数 |
|---|----|--------|
| 6 | HarmonyOS 実機/エミュレータで支払い→決済、修理依頼提出、来訪者登録の全チェーンを検証 | S（テストデバイス制約あり、PROJECT_PLAN に本リスク記載済み） |

## 五、実装順序の提案

1. ギャップ 1（費用対効果最高：既存 3 ページを再利用、新ページゼロ）
2. ギャップ 4（Flutter オーバーフローは致命傷、スマホで必ずクラッシュ）
3. ギャップ 2、3（新ページ）
4. ギャップ 5（UX 最適化）
5. ギャップ 6（デバイス要、独立実施）
