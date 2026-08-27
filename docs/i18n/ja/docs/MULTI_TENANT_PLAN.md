# マルチテナント SaaS 方案評審 (Multi-Tenant Plan)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> ステータス: 評審稿 (P3-① 先行タスク) | 日付: 2026-08-16

## 1. 現状棚卸し

### 1.1 テーブル構造分類（65 テーブル、docs/install.sql で検証）

| カテゴリ | テーブル | 説明 |
|------|-----|------|
| グローバル/プラットフォーム表 | management_admin_user / admin_role / admin_permission / admin_user_role / admin_role_permission、management_system_config、management_operation_log | 認可、設定、監査。本来プラットフォームレベルで、テナントを付けない |
| コミュニティ次元の表 | management_community および community_id で帰属する 40+ の業務テーブル（building/unit/room/owner/fee_*/repair_order/parking_*/announcement 等） | community_id 経由で間接的にテナントへ帰属 |
| グループ関連表 | management_group（グループ）、management_group_community（グループ↔コミュニティ） | 現状は**任意関連**でテナント意味論なし、跨区集計は join に依存 |
| プラットフォーム拡張表 | management_notification_template、management_knowledge_base、management_mall_*、management_face_info 等 | 一部はプラットフォームレベル、一部はコミュニティレベル、個別確認が必要 |
| 紛らわしい表 | **management_tenant（賃借人テーブル）** | ⚠️ 意味論の衝突：「建物の賃借人」（room_id/owner_id 次元）であって、**SaaS テナントではない** |

### 1.2 認可チェーン（admin 端、コード検証）

```
グローバルミドルウェア: Cors → SecurityFilter → RateLimit
ルートグループミドルウェア: AdminAuth(JWT → $request->adminId) → AdminPermission(RBAC method.path) → OperationLog → Controller
```

- `AdminAuth` はリクエスト注入パターンを確立済み（`$request->adminId`）、テナントコンテキストは完全に踏襲可能
- `AdminPermission` はプラットフォームレベル RBAC で、テナント分離とは**直交**し、重ね掛け可能
- service 所有者端：JWT が owner_id を保持し、データは room_owner → room.community_id 経由で自然に制限され、テナント横断リスクは低い

### 1.3 主要結論

- 既存の SaaS テナントモデルはなし；`management_tenant` の名称は賃借人が占有済みのため、新概念は名称を避ける必要がある
- 全コントローラが直接 Eloquent クエリで、repository 層もグローバルスコープもない —— 分離改造はモデル層で行う必要がある
- config/database.php は単一接続だが、illuminate/database は複数 connection をネイティブサポート（独立 DB への進化を予約）

## 2. 方案比較と推奨

| 方案 | メカニズム | 改造量 | 運用コスト | 適用 |
|------|------|--------|----------|------|
| **A. 共有 DB + tenant_id 行分離（推奨）** | テナントテーブル + 業務テーブル tenant_id 列 + Eloquent グローバルスコープフィルタ | 中（2 テーブルに列追加 + ミドルウェア + グローバルスコープ + 既存データ回填） | 低（単一 DB のバックアップ/移行は不変） | 中小不動産、単テナント <500 万行 |
| B. 独立 DB（テナント毎に 1 DB） | 接続ルーティング + 跨 DB 集計 | 高（接続管理/跨 DB レポート/移行×N/バックアップ×N） | 高 | 大型グループ、コンプライアンス分離要件 |
| C. ハイブリッド（機密 DB 独立 + 共有） | A+B の組み合わせ | 高 | 高 | 決済/顔認証など強分離シナリオ |

**A を推奨、B は進化方向。** 理由：

1. 既存 65 テーブルは単一 DB に統一。A の tenant_id データモデルは将来の DB 分割を妨げない（フィルタ粒度を行から DB に変えるだけでよく、A 方案ではテナント ID がグローバルにモデル化済み）
2. 業務データは全て community_id 経由で帰属するため、tenant_id は**最上位テーブル**に追加するだけでよく、中間の 40 業務テーブルはアクセスパスで保証され、テーブル毎の列追加を回避
3. 両端（admin/service）が同一データモデルを共有し、A の改造は admin 端の実行層に集中
4. 単機デプロイの現状では B のバックアップ/移行の複雑さは許容不可

## 3. 分離ポイント設計

### 3.1 データモデル（最小セット）

- `management_platform_tenant` を新規作成（賃借人テーブル management_tenant との衝突を回避）：id/name/status/created_at 等
- `management_community` に `tenant_id BIGINT NOT NULL DEFAULT 0` を追加、インデックス `(tenant_id, community_id)`
- `management_admin_user` に `tenant_id BIGINT NOT NULL DEFAULT 0` を追加（0 = プラットフォームスーパー管理者）
- 業務中間テーブル（building/room/fee_bill 等 40 テーブル）は**列を追加せず**、community_id 経由で帰属

### 3.2 実行層の三種の神器

1. **TenantContext ミドルウェア**：JWT payload に `tenant_id` クレームを追加 → `$request->tenantId`（AdminAuth の注入パターンを踏襲）；ログイン/インストール/プラットフォームレベルルート（user/role/permission/config）の通過リスト
2. **TenantScope グローバルスコープ**：Community およびプラットフォームレベル業務モデルに Eloquent グローバルスコープを適用し、`$request->tenantId` で自動フィルタ；`find()` もスコープの制約を受け、テナント横断の単一レコード直接参照を自然に防止
3. **Tenant::for() 明示コンテキスト**：スケジューラ/キュー/インポートは HTTP リクエストがないため、クロージャで囲んで明示的にテナントを指定；コンテキスト欠落時は **fail-closed**（クエリ拒否）、フィルタなしの黙認通過を許可しない

### 3.3 越権防御テスト要点（検収マトリクス）

| テストケース | 期待値 |
|------|------|
| テナント A 管理者がテナント B の community/building/fee_bill を list | 空または A のデータのみ返却 |
| テナント A 管理者がテナント B の単一レコードを find/update/delete（id 直接参照） | 403 / 空データ / 拒否 |
| プラットフォーム管理者（tenant_id=0）のテナント横断操作 | 通過（プラットフォームレベル能力） |
| service 所有者のコミュニティ横断操作（支払い/修理依頼） | 拒否（community 帰属検証） |
| スケジューラ/キューがテナントコンテキスト未指定 | フィルタなしではなく fail-closed エラー |

## 4. 進化パス（段階的移行）

| ステップ | 内容 | 検収 |
|------|------|------|
| 1. データ層 | platform_tenant テーブル作成 + community/admin_user に列追加 + 冪等マイグレーション + デフォルトテナント初期化と既存データ回填 | 全 community が必ずテナントに紐付き、孤立データレポートがゼロ |
| 2. 実行層 | TenantContext ミドルウェア + TenantScope + Tenant::for() ツール + ルート通過リスト | 単テナント回帰：全 133 テスト合格 |
| 3. パイロットモジュール | グループ管理 → コミュニティ → 所有者 → 料金（請求書）の 4 モジュールから分離を有効化 | 越権テストマトリクス合格 |
| 4. 全量展開 | バッチ毎（第1バッチコア → 第2バッチ補助 → 拡張モジュール）にモジュールを有効化 | 全モジュールの越権マトリクス合格 |
| 5. 進化 | 単テナントデータ >500 万行またはコンプライアンス要件時に DB 分割（B 方案）を評価、A のデータモデルは阻害しない | DB 分割方案評審 |

データ移行戦略：既存データは全て「デフォルトテナント」に帰属（移行スクリプトが作成）、業務データは削除も変更もしない；移行スクリプトは冪等で繰り返し実行可能。

## 5. リスク一覧

| リスク | 影響範囲 | 緩和 / ロールバック |
|------|--------|-------------|
| 58+17 コントローラのクエリパス改造量大 | 全量業務 API | グローバルスコープで ~80% の一覧/詳細をカバー；raw query と一括インポートは Tenant::for() を使用；バッチ毎にグレースケール |
| グローバルスコープがプラットフォームレベルクエリを誤傷（ダッシュボードの跨区集計） | ダッシュボード/レポート | プラットフォームレベル API は明示的に Tenant::without() または tenant_id=0 バイパス |
| スケジューラ/キューにリクエストコンテキストなし | 督促/SLA/通知などのバックグラウンドタスク | Tenant::for() で明示ラップ + fail-closed |
| 既存データ回填ミス | 全既存データ | 冪等スクリプト + 回填検証 + ドライラン |
| インデックス/パフォーマンス影響 | 高頻度テーブル（fee_bill/room/owner） | (tenant_id, community_id) 複合インデックス；スロークエリログで再確認 |
| 133 テスト回帰 | 全量 | スコープ注入後に全量回帰を先に実行してからパイロット開始 |
| 命名混乱（management_tenant 賃借人 vs SaaS テナント） | 開発者の認知 | 新テーブルは platform_tenant と命名し、ドキュメントで明示宣言 |
| **ロールバック方案** | — | グローバルスコープは設定スイッチでワンクリック無効化可能（単テナント意味論に復帰）、データ列は保持し削除しない、破壊的変更なし |

## 6. 評審結論

**今すぐ実施を推奨**：
- 共有 DB + tenant_id 行分離（方案 A）、`management_platform_tenant` テーブルを新規作成、community/admin_user に列追加
- TenantContext ミドルウェア + TenantScope グローバルスコープ + Tenant::for() ツール
- パイロット順序：グループ → コミュニティ → 所有者 → 料金
- 前置依存：完了済み — マルチテナントのテーブル/列/回填は docs/install.sql にインライン化済み（2026-08-16 統合、単一の DB 作成エントリ）

**保留を推奨**：
- 独立 DB 分離（B）：単テナント >500 万行またはコンプライアンス要件時のみ起動、データモデルは予約済み
- ハイブリッド方案（C）：決済/顔認証など強分離シナリオで顧客が明示的に要求した場合に再評価

**実施非推奨**：
- Schema レベル分離（MySQL に独立 schema 意味論なし、コストは独立 DB と同等）
- 動的多 DB ルーティング（単機デプロイではメリットなし）
- テナントレベル個別 schema/フィールド（YAGNI）
- management_tenant 賃借人テーブルの流用/改造で SaaS テナント化（意味論衝突、賃借人業務を破壊）
