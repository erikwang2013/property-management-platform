# インターフェースドキュメント（API リファレンス）

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## 概要

- 管理画面 API は `http://localhost:8787` で稼働
- 業務端 API は `http://localhost:8788` で稼働
- 統一レスポンス形式: `{"code": 0, "message": "success", "data": {...}}`
- 全 ID フィールドは hashids エンコードで転送
- API バージョンはリクエストヘッダー `API-Version` で制御（デフォルト `v1`）
- 言語はリクエストヘッダー `Accept-Language` で制御（`zh-CN` / `en-US`、デフォルト `zh-CN`）

### オンライン API ドキュメント

サービス起動後、`hg/apidoc` が自動生成するインタラクティブドキュメントにアクセス：

| 端 | アドレス | グループ数 |
|----|------|--------|
| 管理画面 | `http://localhost:8787/apidoc` | 10 グループ（common/dashboard/system/property-core/property-aux/property-adv/extensions/export/import/upload） |
| 所有者ポータル | `http://localhost:8788/apidoc` | 9 グループ（公開インターフェース/ホーム/料金/修理依頼/フィードバック/駐車/イベント/個人/拡張） |

---

## 管理画面 API (admin :8787)

### 公開インターフェース — 認証不要

#### POST /api/captcha/generate
クリック認証コードを取得します。

リクエストパラメータ: なし

レスポンス:
```json
{
  "code": 0,
  "data": {
    "key": "captcha_key_string",
    "image": "base64_encoded_png",
    "extra": { "targets": ["树", "鸟", "花"] }
  }
}
```

#### POST /api/captcha/verify
クリック認証コードを検証します。

リクエストパラメータ:
| パラメータ | 型 | 説明 |
|------|------|------|
| key | string | 認証コード key。generate が返却 |
| clicks | array | クリック座標 [{x, y}, ...] |

レスポンス:
```json
{
  "code": 0,
  "data": { "valid": true }
}
```

検証失敗時は `code` が 422、`data.valid` が `false` になります。

#### POST /api/auth/login
管理者ログイン。

リクエストパラメータ:
| パラメータ | 型 | 説明 |
|------|------|------|
| username | string | ユーザー名 |
| password | string | パスワード |
| captcha_key | string | 認証コード key |
| clicks | array | クリック座標 [{x, y}, ...] |

レスポンス:
```json
{
  "code": 0,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "user": { "id": "aB3xK9mW...", "username": "admin", "real_name": "管理员" }
  }
}
```

#### POST /api/auth/refresh
Token を更新します。

リクエストパラメータ:
| パラメータ | 型 | 説明 |
|------|------|------|
| refresh_token | string | リフレッシュトークン |

レスポンス:
```json
{
  "code": 0,
  "data": { "access_token": "eyJ..." }
}
```

#### GET /health
ヘルスチェック。

#### GET /metrics
Prometheus 監視メトリクス。

#### GET /api/docs
OpenAPI ドキュメント。

---

### 管理画面インターフェース — 認証必須（Bearer Token）

全インターフェースのプレフィックスは `/admin`、`Authorization: Bearer {access_token}` の携帯が必要です。

#### ダッシュボード

**GET /admin/dashboard**
ダッシュボードの統計データを取得。

#### 管理者ユーザー管理

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/user | ユーザーリスト (?keyword=&status=&page=&page_size=) |
| POST | /admin/user | ユーザー作成 |
| GET | /admin/user/{hashid} | ユーザー詳細 |
| PUT | /admin/user/{hashid} | ユーザー更新 |
| DELETE | /admin/user/{hashid} | ユーザー削除（パスワード確認が必要） |
| POST | /admin/user/batch/destroy | 一括削除 |
| POST | /admin/user/batch/status | 一括有効・無効化 |
| POST | /admin/import/users | Excel ユーザーインポート |

#### ロール権限管理

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/role | ロールリスト |
| POST | /admin/role | ロール作成 |
| GET | /admin/role/{hashid} | ロール詳細 |
| PUT | /admin/role/{hashid} | ロール更新 |
| DELETE | /admin/role/{hashid} | ロール削除 |
| GET | /admin/permission | 権限リスト（ツリー型） |
| POST | /admin/permission | 権限作成 |
| PUT | /admin/permission/{hashid} | 権限更新 |
| DELETE | /admin/permission/{hashid} | 権限削除 |

#### システム設定

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/config | 設定リスト (?group=) |
| POST | /admin/config | 設定作成 |
| PUT | /admin/config/{hashid} | 設定更新 |
| DELETE | /admin/config/{hashid} | 設定削除 |

#### 操作ログ

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/log | ログリスト (?user_id=&action=&method=&source=&start_date=&end_date=) |

#### 個人センター

| メソッド | パス | 説明 |
|------|------|------|
| PUT | /admin/profile | 個人情報の変更 |
| PUT | /admin/profile/password | パスワード変更 |
| POST | /admin/profile/logout | ログアウト |

#### エクスポート

| メソッド | パス | 説明 |
|------|------|------|
| POST | /admin/export/excel | Excel エクスポート ({ table, columns, conditions, title }) |
| POST | /admin/export/pdf | PDF エクスポート ({ type, title, data }) |

---

### 不動産管理 — 管理画面インターフェース

#### コミュニティ管理

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/community | リスト (?keyword=&status=) |
| POST | /admin/community | 作成 |
| GET | /admin/community/{hashid} | 詳細 |
| PUT | /admin/community/{hashid} | 更新 |
| DELETE | /admin/community/{hashid} | 削除（パスワードが必要） |

#### 棟管理

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/building | リスト (?community_id=&keyword=) |
| POST | /admin/building | 作成 |
| GET | /admin/building/{hashid} | 詳細 |
| PUT | /admin/building/{hashid} | 更新 |
| DELETE | /admin/building/{hashid} | 削除 |

#### 部屋管理

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/unit | リスト (?building_id=) |
| POST | /admin/unit | 作成 |
| GET | /admin/unit/{hashid} | 詳細 |
| PUT | /admin/unit/{hashid} | 更新 |
| DELETE | /admin/unit/{hashid} | 削除 |

#### 間取りタイプ管理

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/room-type | リスト |
| POST | /admin/room-type | 作成 |
| GET | /admin/room-type/{hashid} | 詳細 |
| PUT | /admin/room-type/{hashid} | 更新 |
| DELETE | /admin/room-type/{hashid} | 削除 |

#### 不動産管理

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/room | リスト (?community_id=&building_id=&unit_id=&status=) |
| POST | /admin/room | 作成 |
| GET | /admin/room/{hashid} | 詳細 |
| PUT | /admin/room/{hashid} | 更新 |
| DELETE | /admin/room/{hashid} | 削除 |
| GET | /admin/room/tree | 建物ツリー（コミュニティ→棟→部屋→不動産） |

#### 所有者管理

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/owner | リスト (?keyword=&status=) |
| POST | /admin/owner | 作成 |
| GET | /admin/owner/{hashid} | 詳細（バインド不動産含む） |
| PUT | /admin/owner/{hashid} | 更新 |
| DELETE | /admin/owner/{hashid} | 削除（パスワードが必要） |
| POST | /admin/owner/batch/import | Excel 一括インポート |
| POST | /admin/owner/batch/destroy | 一括削除 |

#### テナント管理

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/tenant | リスト (?room_id=&status=) |
| POST | /admin/tenant | 作成 |
| GET | /admin/tenant/{hashid} | 詳細 |
| PUT | /admin/tenant/{hashid} | 更新 |
| DELETE | /admin/tenant/{hashid} | 削除 |

#### 料金タイプ

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/fee-type | リスト |
| POST | /admin/fee-type | 作成 |
| GET | /admin/fee-type/{hashid} | 詳細 |
| PUT | /admin/fee-type/{hashid} | 更新 |
| DELETE | /admin/fee-type/{hashid} | 削除 |

#### 請求書管理

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/fee-bill | リスト (?community_id=&status=&due_date_start=&due_date_end=) |
| POST | /admin/fee-bill | 請求書作成 |
| GET | /admin/fee-bill/{hashid} | 詳細 |
| PUT | /admin/fee-bill/{hashid} | 更新 |
| DELETE | /admin/fee-bill/{hashid} | 削除 |
| POST | /admin/fee-bill/batch/generate | 請求書の一括生成 |

#### 支払い記録

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/fee-payment | リスト (?bill_id=&payment_method=&date_start=&date_end=) |
| POST | /admin/fee-payment/offline | オフライン集金の登録 |

#### 修理依頼管理

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/repair | リスト (?status=&category=) |
| POST | /admin/repair | 作成 |
| GET | /admin/repair/{hashid} | 詳細（進捗記録含む） |
| PUT | /admin/repair/{hashid} | 更新 |
| DELETE | /admin/repair/{hashid} | 削除 |
| PUT | /admin/repair/{id}/assign | 手配（{ staff_id }） |
| POST | /admin/repair/{id}/progress | 進捗更新（{ status_to, remark }） |

#### お知らせ管理

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/announcement | リスト (?community_id=&category=&is_published=) |
| POST | /admin/announcement | 作成 |
| GET | /admin/announcement/{hashid} | 詳細 |
| PUT | /admin/announcement/{hashid} | 更新 |
| DELETE | /admin/announcement/{hashid} | 削除 |

#### 駐車管理

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/parking-space | リスト (?community_id=) |
| POST | /admin/parking-space | 駐車スペース作成 |
| PUT | /admin/parking-space/{hashid} | 更新 |
| DELETE | /admin/parking-space/{hashid} | 削除 |
| GET | /admin/parking-vehicle | リスト (?owner_id=&space_id=) |
| POST | /admin/parking-vehicle | 車両作成 |
| PUT | /admin/parking-vehicle/{hashid} | 更新 |
| DELETE | /admin/parking-vehicle/{hashid} | 削除 |
| GET | /admin/parking-record | 駐車記録 (?vehicle_id=&date_start=&date_end=) |

#### 設備管理

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/equipment | リスト (?community_id=&category=&status=) |
| POST | /admin/equipment | 作成 |
| PUT | /admin/equipment/{hashid} | 更新 |
| DELETE | /admin/equipment/{hashid} | 削除 |
| GET | /admin/equipment-maintenance | メンテナンス記録 (?equipment_id=) |
| POST | /admin/equipment-maintenance | メンテナンス作成 |

#### 苦情処理

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/complaint | リスト (?type=&status=) |
| GET | /admin/complaint/{hashid} | 詳細 |
| PUT | /admin/complaint/{id}/handle | 処理（{ handler_remark }） |
| POST | /admin/complaint/{id}/visit | フォローアップ（{ visitor_remark }） |

#### 来訪者承認

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/visitor | リスト (?status=) |
| PUT | /admin/visitor/{id}/approve | 承認 |

#### 契約管理

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/contract | リスト (?contract_type=&status=) |
| POST | /admin/contract | 作成 |
| PUT | /admin/contract/{hashid} | 更新 |
| DELETE | /admin/contract/{hashid} | 削除 |

#### 財務管理

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/finance-income | 収入リスト (?income_type=&date_start=&date_end=) |
| POST | /admin/finance-income | 収入登録 |
| GET | /admin/finance-expense | 支出リスト |
| POST | /admin/finance-expense | 支出登録 |
| GET | /admin/finance/statistics | 月次収支統計 (?year=) |

#### 不動産パネル

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/dashboard/property | 不動産統計（未収金/入居率/修理依頼/苦情/収支トレンド） |
| POST | /admin/export/property-excel | 不動産データ Excel エクスポート（{ type: owners|bills }） |

#### 警備巡回

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/security-patrol | リスト (?community_id=) |
| POST | /admin/security-patrol | 巡回ルート作成 |
| GET | /admin/patrol-record | 記録 (?patrol_id=&staff_id=) |
| POST | /admin/patrol-record | 記録作成 |

#### 清掃管理

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/cleaning-area | エリアリスト |
| POST | /admin/cleaning-area | エリア作成 |
| GET | /admin/cleaning-record | 記録 (?area_id=) |
| POST | /admin/cleaning-record | 記録作成 |

#### 緑化管理

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/green-area | エリアリスト |
| POST | /admin/green-area | エリア作成 |
| GET | /admin/green-maintenance | 維持管理記録 (?area_id=) |
| POST | /admin/green-maintenance | 記録作成 |

#### コミュニティイベント

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/activity | リスト (?status=) |
| POST | /admin/activity | イベント作成 |
| PUT | /admin/activity/{hashid} | 更新 |
| DELETE | /admin/activity/{hashid} | 削除 |
| GET | /admin/activity-signup | 申し込みリスト (?activity_id=) |
| PUT | /admin/activity-signup/{id}/checkin | チェックイン |

#### エネルギー管理

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/energy-meter | 計器リスト (?room_id=&meter_type=) |
| POST | /admin/energy-meter | 計器作成 |
| GET | /admin/energy-record | 検針記録 (?meter_id=&date_start=&date_end=) |
| POST | /admin/energy-record | 記録作成 |

#### スタッフ管理

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/staff | リスト (?community_id=&status=) |
| POST | /admin/staff | 作成 |
| PUT | /admin/staff/{hashid} | 更新 |
| DELETE | /admin/staff/{hashid} | 削除 |
| POST | /admin/staff/batch/status | 一括有効・無効化 |

#### メッセージ通知

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/notification-template | テンプレートリスト |
| POST | /admin/notification-template | テンプレート作成 |
| PUT | /admin/notification-template/{hashid} | テンプレート更新 |
| DELETE | /admin/notification-template/{hashid} | テンプレート削除 |
| GET | /admin/notification | メッセージリスト (?type=&is_read=) |
| POST | /admin/notification/send | 手動通知送信 |

#### 承認ワークフロー

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/approval-type | 承認タイプリスト |
| POST | /admin/approval-type | 承認タイプ作成 |
| GET | /admin/approval | 承認リスト (?status=) |
| GET | /admin/approval/{hashid} | 承認詳細 |
| POST | /admin/approval | 承認提出 |
| PUT | /admin/approval/{hashid}/approve | 承認（承認/却下） |

#### 決済管理

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/payment-order | 注文リスト |
| GET | /admin/payment-order/{hashid} | 注文詳細 |
| POST | /admin/payment-order/{hashid}/refund | 返金 |
| GET | /admin/payment/statistics | 決済統計 |

#### 所有者投票

| メソッド | パス | 説明 |
|------|------|------|
| GET | /admin/vote | 投票リスト (?status=) |
| POST | /admin/vote | 投票作成 |
| GET | /admin/vote/{hashid}/statistics | 開票統計 |
| PUT | /admin/vote/{hashid}/publish | 投票公開 |
| PUT | /admin/vote/{hashid}/end | 投票終了 |

#### SLA 管理・スマート督促・巡回点検管理・モール管理・顔認証管理・グループ管理・ナレッジベース

（完全なエンドポイントは `docs/API.md` ファイルを参照）

---

## 業務端 API (service :8788)

### 公開インターフェース — 認証不要

#### POST /api/captcha/generate
クリック認証コードを取得します。（管理画面と同じ）

#### POST /api/captcha/verify
クリック認証コードを検証します。（リクエスト/レスポンスは管理画面と同じ）

#### POST /api/auth/login
所有者ログイン。

リクエストパラメータ:
| パラメータ | 型 | 説明 |
|------|------|------|
| phone | string | 携帯番号 |
| password | string | パスワード |
| captcha_key | string | 認証コード key |
| clicks | array | クリック座標 |

レスポンス:
```json
{
  "code": 0,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "owner": { "id": "xB9k...", "name": "张三", "phone": "138****1234" }
  }
}
```

#### POST /api/auth/register
所有者登録。

リクエストパラメータ:
| パラメータ | 型 | 説明 |
|------|------|------|
| phone | string | 携帯番号 |
| password | string | パスワード（最低 6 桁） |
| name | string | 氏名 |
| captcha_key | string | 認証コード key |
| clicks | array | クリック座標 |
| room_id | string | （任意）バインドする部屋番号 hashid |
| id_card_last4 | string | （任意）身分証の下 4 桁 |

#### POST /api/auth/refresh
Token を更新します。

---

### 所有者端インターフェース — 認証必須（Bearer Token）

全インターフェースのプレフィックスは `/service`、`Authorization: Bearer {access_token}` の携帯が必要です。

#### ホーム

**GET /service/home**

レスポンス:
```json
{
  "code": 0,
  "data": {
    "room_count": 2,
    "pending_amount": "1250.00",
    "pending_bill_count": 3,
    "repairing_count": 1,
    "announcements": [{ "id": "xB9k...", "title": "停水通知", "published_at": "2026-05-20 09:00" }]
  }
}
```

#### マイ不動産

| メソッド | パス | 説明 |
|------|------|------|
| GET | /service/rooms | マイ不動産リスト |
| GET | /service/room/{hashid} | 不動産詳細（面積、向き、権利、コミュニティ情報含む） |

#### 料金管理

| メソッド | パス | 説明 |
|------|------|------|
| GET | /service/fees/bills | 請求書リスト (?status=0未缴/1部分缴/2已缴/3逾期) |
| GET | /service/fees/bill/{hashid} | 請求書詳細（料金タイプ、支払い記録含む） |
| GET | /service/fees/payments | 支払い記録 |
| POST | /service/fees/pay | オンライン支払い（{ bill_id, payment_method, password }） |
| GET | /service/fees/statistics | 料金統計 (?year=2026) |

#### 修理依頼

| メソッド | パス | 説明 |
|------|------|------|
| GET | /service/repairs | 修理依頼リスト (?status=) |
| GET | /service/repair/{hashid} | 修理依頼詳細（進捗タイムライン含む） |
| POST | /service/repair | 修理依頼提出（{ room_id, category, urgency, description, images[], scheduled_at }） |
| DELETE | /service/repair/{hashid} | キャンセル（パスワードが必要、{ password }） |
| POST | /service/repair/{hashid}/rate | 評価（{ rating: 1-5, feedback }） |

#### 苦情・提案

| メソッド | パス | 説明 |
|------|------|------|
| GET | /service/complaints | 苦情リスト |
| GET | /service/complaint/{hashid} | 苦情詳細（処理進捗含む） |
| POST | /service/complaint | 苦情提出（{ type, category, title, content, is_anonymous, images[] }） |
| POST | /service/complaint/{hashid}/satisfaction | 満足度評価（{ satisfaction: 1-5 }） |

#### お知らせ

| メソッド | パス | 説明 |
|------|------|------|
| GET | /service/announcements | お知らせリスト (?category=) |
| GET | /service/announcement/{hashid} | お知らせ詳細 |

#### 駐車

| メソッド | パス | 説明 |
|------|------|------|
| GET | /service/parking/vehicles | マイ車両 |
| GET | /service/parking/spaces | マイ駐車スペース |
| GET | /service/parking/records | 駐車記録 |

#### 来訪者

| メソッド | パス | 説明 |
|------|------|------|
| GET | /service/visitors | マイ来訪者予約 |
| POST | /service/visitor | 予約作成（通行コード生成） |
| PUT | /service/visitor/{hashid} | 予約変更 |
| DELETE | /service/visitor/{hashid} | 予約キャンセル |

#### コミュニティイベント

| メソッド | パス | 説明 |
|------|------|------|
| GET | /service/activities | イベントリスト (?status=) |
| GET | /service/activity/{hashid} | イベント詳細 |
| POST | /service/activity/{hashid}/signup | 申し込み |
| POST | /service/activity/{hashid}/cancel | 申し込みキャンセル |

#### 個人情報

| メソッド | パス | 説明 |
|------|------|------|
| GET | /service/profile | 個人情報 |
| PUT | /service/profile | 変更（{ name, email, gender, birthday }） |
| PUT | /service/profile/password | パスワード変更（{ old_password, new_password }） |
| POST | /service/profile/logout | ログアウト |

---

## オープン API — API Key 認証

インバウンド対外向け読み取り専用インターフェース。第三者システム（不動産プラットフォーム連携、データ大画面など）向け。プレフィックスは `/open`、全て読み取り専用。

### 認証方式

各リクエストにリクエストヘッダー `X-API-Key` を携帯します。値は `scripts/gen_api_key.php` が生成する Key（64 桁 hex、DB には SHA-256 ダイジェストのみ保存）：

```bash
curl -H "X-API-Key: <你的Key>" http://localhost:8788/open/announcements
```

- 欠落または誤った Key は `401` を返します（`{"code":401,"message":"无效的API Key","data":[]}`）
- Key 管理：`php scripts/gen_api_key.php [--name=用途]` で生成；無効化/削除は `erik_api_key` テーブルを直接操作（`status=0` で即無効、キーは即時失効）

### エンドポイント

#### GET /open/announcements — お知らせリスト

パラメータ：`page`（デフォルト 1）、`category`（任意）。レスポンス構造は `/service/announcements` と同じ。

```bash
curl -H "X-API-Key: <你的Key>" "http://localhost:8788/open/announcements?page=1"
```

#### GET /open/bills — 請求書照会

パラメータ：`bill_number`（必須、請求書番号）。単一の請求書詳細を返します（料金タイプ、部屋番号、未払い金額含む）。存在しない場合は 404 を返します。

```bash
curl -H "X-API-Key: <你的Key>" "http://localhost:8788/open/bills?bill_number=B202608160001"
```

#### GET /open/repairs — 修理依頼ステータス照会

パラメータ：`order_number`（必須、修理依頼番号）。修理依頼の現在のステータスと進捗タイムライン（`progress` 配列）を返します。存在しない場合は 404 を返します。

```bash
curl -H "X-API-Key: <你的Key>" "http://localhost:8788/open/repairs?order_number=R202608160001"
```

---

## エラーコード

| code | 意味 | 説明 |
|------|------|------|
| 0 | 成功 | 正常なレスポンス |
| 400 | リクエストエラー | パラメータ形式が不正 |
| 401 | 未認証 | Token 欠落/期限切れ/無効/ブラックリスト登録 |
| 403 | 権限なし | ユーザーロールが必要権限を含まない / アカウントが無効化 |
| 404 | 存在しない | リソースが見つからない |
| 405 | メソッド不許可 | GET/POST/PUT/DELETE/OPTIONS 以外の HTTP メソッド |
| 413 | リクエストボディ過大 | 10MB 超過 |
| 415 | サポート外のメディアタイプ | Content-Type が JSON または form-urlencoded でない |
| 422 | 検証失敗 | フォームパラメータが規則に合わない / パスワード確認失敗 / 認証コードエラー |
| 429 | リクエスト過多 | レート制限発動 / アカウントロック |
| 500 | サーバーエラー | 予期しない例外 |

## レート制限レスポンスヘッダー

レート制限発動時は 429 を返し、レスポンスヘッダーに以下を含みます：

| レスポンスヘッダー | 説明 |
|--------|------|
| X-RateLimit-Limit | 制限回数 |
| X-RateLimit-Remaining | 残り回数 |
| X-RateLimit-Reset | リセット時間（Unix タイムスタンプ） |
| Retry-After | 推奨リトライ待機秒数 |
