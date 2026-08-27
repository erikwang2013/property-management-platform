# 機能ドキュメント (Features)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## 機能一覧

| 番号 | モジュール | 所属バッチ | 管理者端 | 所有者端 | データテーブル |
|------|------|---------|---------|--------|--------|
| 1 | コミュニティ管理 | 第1バッチ | CRUD + 検索ページング | バインドしたコミュニティの閲覧 | management_community |
| 2 | 棟管理 | 第1バッチ | CRUD + コミュニティ別フィルタ | - | management_building |
| 3 | 部屋管理 | 第1バッチ | CRUD + 棟別フィルタ | - | management_unit |
| 4 | 間取りタイプ管理 | 第1バッチ | CRUD | - | management_room_type |
| 5 | 不動産管理 | 第1バッチ | CRUD + 建物ツリー + 所有者一括バインド | マイ不動産一覧/詳細 | management_room |
| 6 | 所有者管理 | 第1バッチ | CRUD + 一括インポート/有効・無効化/削除 | 登録/ログイン/個人情報 | management_owner, management_room_owner |
| 7 | テナント管理 | 第1バッチ | CRUD + 不動産別フィルタ | - | management_tenant |
| 8 | 料金管理 | 第1バッチ | 料金タイプ CRUD + 請求書管理 + 一括生成 + オフライン集金 | 請求書照会 + オンライン支払い + 料金統計 | management_fee_type, management_fee_bill, management_fee_payment |
| 9 | 修理依頼管理 | 第1バッチ | 修理依頼一覧 + 手配 + 進捗更新 | 修理依頼提出 + 進捗確認 + 評価 | management_repair_order, management_repair_progress |
| 10 | お知らせ通知 | 第1バッチ | CRUD + 公開/固定表示 | お知らせ一覧/詳細 | management_announcement |
| 11 | 駐車管理 | 第2バッチ | 駐車スペース/車両管理 + 駐車記録 | マイ駐車スペース/車両 + 駐車記録 | management_parking_space, management_parking_vehicle, management_parking_record |
| 12 | 設備管理 | 第2バッチ | 設備台帳 + メンテナンス記録 | - | management_equipment, management_equipment_maintenance |
| 13 | 苦情・提案 | 第2バッチ | 苦情一覧 + 処理 + フォローアップ | 苦情提出 + 進捗確認 + 評価 | management_complaint |
| 14 | 来訪者管理 | 第2バッチ | 来訪者承認 + 記録照会 | 来訪者予約 + 通行コード | management_visitor |
| 15 | 契約管理 | 第2バッチ | CRUD + ステータス管理 | - | management_contract |
| 16 | 財務管理 | 第2バッチ | 収支管理 + 統計レポート | - | management_finance_income, management_finance_expense |
| 17 | 警備巡回 | 第3バッチ | 巡回ルート + 巡回記録 | - | management_security_patrol, management_patrol_record |
| 18 | 清掃管理 | 第3バッチ | 清掃エリア + 清掃記録 | - | management_cleaning_area, management_cleaning_record |
| 19 | 緑化管理 | 第3バッチ | 緑化エリア + 維持管理記録 | - | management_green_area, management_green_maintenance |
| 20 | コミュニティイベント | 第3バッチ | イベント管理 + 申し込み確認 | イベント一覧 + 申し込み | management_community_activity, management_activity_signup |
| 21 | エネルギー管理 | 第3バッチ | 計器管理 + 検針記録 | - | management_energy_meter, management_energy_record |
| 22 | スタッフ管理 | 第3バッチ | CRUD + ステータス管理 | - | management_staff |

## 拡張機能（第4バッチ — 12モジュール）

| 番号 | モジュール | 管理者端 | 所有者端 | データテーブル |
|------|------|---------|--------|--------|
| 23 | メッセージ通知 | テンプレート CRUD + 手動送信 + 一覧 | マイメッセージ + 既読マーク | management_notification_template, management_notification |
| 24 | 承認ワークフロー | 承認タイプ + インスタンス + ステップ遷移 | - | management_approval_type, management_approval, management_approval_record |
| 25 | 決済統合 | 注文管理 + 返金 + WeChat/Alipay コールバック | - | management_payment_order |
| 26 | 所有者投票 | 投票 CRUD + 選択肢 + 面積加重統計 | 投票一覧 + 投票 + 面積加重 | management_vote, management_vote_option, management_vote_record |
| 27 | SLA 自動エスカレーション | ルール設定 + タイムアウトチェック + 罰金 | - | management_sla_rule, management_sla_record |
| 28 | スマート督促 | 戦略設定 + 滞納マッチング + 延滞金 | - | management_collection_strategy, management_collection_record |
| 29 | 巡回点検モバイル | タスク配信 + GPS 打刻 + 写真 | - | management_inspection_task, management_inspection_checkpoint |
| 30 | コミュニティモール | カテゴリ/商品/注文/発送管理 | 商品閲覧 + 注文 + マイ注文 | management_mall_category, management_mall_product, management_mall_order |
| 31 | 顔認証 | 審査管理 | 顔認証登録 + 認証ステータス | management_face_info |
| 32 | グループ管理 | グループ CRUD + コミュニティ関連付け + 跨区集計 | - | management_group, management_group_community |
| 33 | スマートQ&A | ナレッジベース + 対話記録 + 統計 | 質問 + キーワードマッチング | management_knowledge_base, management_chat_record |
| - | データ大画面 | リアルタイム不動産データ可視化の全画面表示 | - | (既存データ API を再利用) |

## 管理画面モジュール（admin 既存）

| モジュール | 機能 |
|------|------|
| ダッシュボード | リアルタイム統計/トレンド/分布/ログ（Redis 5m キャッシュ） |
| ユーザー管理 | 管理者ユーザー CRUD + 一括削除/有効・無効化 + Excel インポート |
| ロール権限 | CRUD + 権限ツリー + RBAC method.path 認可 |
| システム設定 | キーバリュー CRUD |
| 操作監査 | ログ照会 + 8 プラットフォーム送信元の自動検出 |
| ファイル管理 | アップロード + Excel/PDF エクスポート（機密データマスキング） |
| セキュリティ管理 | 18 層多層防御 + security.txt |
| 運用監視 | ヘルスチェック + Prometheus メトリクス + API ドキュメント |
| 国際化 | 中文/英語バイリンガル、PHP symfony/translation + Flutter GetX Translations + HarmonyOS リソース修飾子 |
| API ドキュメント | `hg/apidoc` 自動生成、admin 10 グループ + service 9 グループ、機能モジュール別に編成 |

## 横断機能の特徴

### ID 暗号化転送
全 API インターフェースのリクエストとレスポンスの ID フィールドは `erikwang2013/hashids` でエンコード/デコードされます。クライアントが受け取るのは hashid 文字列（例：`aB3xK9mW2pQ7rT5v`）で、バックエンドが BIGINT にデコードして操作します。

### 機密データ保護
- API 転送層：`erikwang2013/encryption` — AES-256-CBC
- データベース保存層：`erikwang2013/encryptable` — Eloquent Model casts 自動暗号化/復号
- フロント表示層：携帯番号 138****1234、メール a***@e.com

### 操作監査
管理端の全 POST/PUT/DELETE 操作を自動記録。操作ユーザー、IP、パス、パラメータ（マスキング済み）、操作日時、送信元端（web/ios/android/harmonyos/windows/macos/linux/ipados）を含みます。

### 権限制御
- 管理者端：RBAC method.path 粒度認可、スーパー管理者 `*` はチェックをスキップ
- 所有者端：JWT Bearer Token 認証、所有者は自分のデータのみ操作可能

### セキュリティ防御
18 層多層防御：認証コード → パスワード確認 → ランダム認証 → セキュリティスキャン → 攻撃ブロック → 転送暗号化 → JWT → セッション制御 → アカウントロック → RBAC → レート制限 → ID 保護 → リクエスト暗号化 → 保存暗号化 → 表示マスキング → 監査 → CSP → 著作権ウォーターマーク

### エクスポート機能
- Excel：PhpSpreadsheet、青背景白文字のヘッダー + 先頭行固定 + 自動フィルタ + 機密データマスキング
- PDF：Dompdf A4 横向き、ページヘッダー著作権 + フッターに除去不可の著作権ウォーターマーク
- パネル可視化データの PDF エクスポート

### 検索エンジン
- `erikwang2013/webman-scout` が Elasticsearch を駆動
- 自動インデックス同期（追加・削除・変更の自動プッシュ）
- インデックス接頭辞 `management_`、データベーステーブル接頭辞と一致

### 国際化 (i18n)
- **PHP バックエンド**: symfony/translation — `resource/translations/{zh_CN,en}/messages.php`、42 翻訳キー、コントローラは `__()` メソッドで翻訳取得
- **Flutter Web**: GetX `Translations` — `lib/i18n/messages.dart`、101 翻訳キー、ページは `.tr` 拡張で使用
- **HarmonyOS**: `resources/{base,en_US}/element/string.json` リソース修飾子
- **デフォルト言語**: 簡体中文（zh_CN）、フォールバック言語英語（en）
- **リクエストヘッダー**: `Accept-Language` で応答言語を制御可能

### テストカバレッジ
- **テストフレームワーク**: PHPUnit 12.x
- **TDD フロー**: レッド→グリーン→リファクタ、テストファースト
- **管理端**: 60 テスト、164 アサーション、基礎サービス、環境設定、セキュリティ検証をカバー
- **業務端**: 18 テスト、45 アサーション、100% 合格率
- **合計**: 78 テスト、209 アサーション
- **カバレッジ範囲**: Snowflake ID 生成の一意性、Hashids エンコード/デコード往復、統一レスポンス形式、64 テーブル Schema 検証、中英翻訳キー一致性
- **Flutter**: flutter analyze ゼロ問題
- **API ドキュメント**: `hg/apidoc` 自動生成、admin(10 グループ) + service(9 グループ)、機能モジュール別にインターフェースドキュメントを編成
