# 運用マニュアル（OPS Runbook）

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> 適用: property-management-platform（admin 端 + service 端、PHP 8.3 webman）

## 1. データベースのバックアップと復旧

admin 端と service 端は同一 MySQL インスタンスと DB `property_management` を共有しており、バックアップは 1 回で済みます。統一エントリ：

| DB 名 | バックアップスクリプト | 説明 |
|---|---|---|
| `property_management` | `scripts/backup.sh` | `admin/.env` から接続情報を読み取る（`--container=` でコンテナ名を上書き可）、デフォルトはコンテナ内 mysqldump |

出力 `backups/backup_YYYYMMDD_HHMMSS.sql.gz`、デフォルトで直近 7 日間保持（`--keep-days=` で調整可）。

### 1.1 フルバックアップ

```bash
cd /path/to/property-management-platform
bash scripts/backup.sh
```

### 1.2 定期タスク（crontab）

```cron
# 毎日 02:00 フルバックアップ
0 2 * * * cd /path/to/property-management-platform && bash scripts/backup.sh >> /var/log/pmp-backup.log 2>&1
```

本番の提案：バックアップディレクトリを独立ディスク/リモートストレージにマウントし、バックアップファイルの完全性を定期抽查（`gzip -t` 検証）。

### 1.3 復旧訓練フロー（四半期に少なくとも 1 回）

1. 直近のバックアップを選択：`ls -t backups/backup_*.sql.gz`
2. **独立環境**（または一時 DB）で復旧を実行：詳細は [RECOVERY_RUNBOOK.md](RECOVERY_RUNBOOK.md) のシナリオ A（空 DB 復旧）とシナリオ B（時点復旧）を参照。
3. 検証：
   - 行数比較：`SELECT COUNT(*) FROM erik_user;` がバックアップ前の記録と一致
   - 暗号化フィールドが正常に復号できる：encryptable フィールドを含むレコードを 1 件参照し、値が正しく、ログに decrypt エラーなし
   - 業務スモーク：ログイン、一覧取得 API が正常
4. 訓練の所要時間と結果を記録（RTO 評価用）。

> 完全な訓練マニュアル（空 DB 復旧 / 時点復旧 / 一致性検証 / 30 分訓練タイムテーブル）は [RECOVERY_RUNBOOK.md](RECOVERY_RUNBOOK.md) を参照してください。

### 1.4 RPO / RTO の説明

- **RPO（許容データ損失量）**：バックアップ頻度で決まる。毎日フルバックアップ → RPO ≤ 24 時間、つまり最大で直近 1 日分のデータを失う。より小さい RPO が必要ならバックアップ頻度を上げる（例：1 日 2 回）か binlog 増分バックアップを有効化。
- **RTO（復旧所要時間）**：DB サイズと復旧速度による。目標 ≤ 1 時間（復旧 + 検証 + サービス再起動）。毎回の訓練後に実測値を更新。
- 復旧失敗時の緊急対応：まずアプリコードをロールバックし、直近の利用可能なバックアップで再試行；バックアップが破損していれば、より古いバックアップを使い大きめの RPO を受け入れる。

## 2. 鍵管理

プロジェクトは 5 つの鍵に依存し、全て `.env` 内（admin と service はそれぞれ独立、同一セットを共用しない）：

| 変数 | 長さ | 用途 |
|---|---|---|
| `ENCRYPTION_KEY` | 32 バイト | API 転送暗号化（config/encryption.php） |
| `ENCRYPTABLE_KEY` | 32 バイト | データベース機密フィールド暗号化（encryptable プラグイン、**ENCRYPTION_KEY と共用しない**） |
| `JWT_SECRET_KEY` | 64 桁以上 | JWT 署名 |
| `HASHIDS_SALT` | — | ID 暗号化/復号 |
| `HASHIDS_ALT_SALT` | — | ID 暗号化/復号の予備 |

### 2.1 鍵の生成

```bash
# 5 つの KEY=VALUE を stdout に出力、そのまま .env に追記可能
php scripts/gen_env_keys.php

# .env に直接書き込み：既存の鍵は上書きせず、不足分のみ追記
php scripts/gen_env_keys.php --file=.env
```

> .env 内の鍵がまだ `change-me` プレースホルダーの場合は、先にその行を削除してから実行（プレースホルダーは「既存」とみなされ、上書きされない）。

### 2.2 鍵ローテーション（encryptable）

```bash
bash scripts/rotate_keys.sh            # デフォルトはカレントディレクトリの .env を操作
bash scripts/rotate_keys.sh /path/to/service/.env
```

スクリプトが自動実行：.env のバックアップ → 新しい `ENCRYPTABLE_KEY` を生成 → 旧キーを `ENCRYPTION_PREVIOUS_KEYS` に追記（カンマ区切り、直近ローテーションが先頭）→ 新キーを書き込み。その後プロンプトに従い手動で：サービス再起動 → 復号検証 → 確認後にバックアップ削除。

**`ENCRYPTION_PREVIOUS_KEYS` の説明**：encryptable は復号時、まず現在の `ENCRYPTABLE_KEY` を試し、失敗したらリスト順に過去のキーを 1 つずつ試します。したがって**ローテーション時、旧キーは新キーが有効になる前にこのリストへ追加する必要があります**。そうしないと再起動後に旧データを復号できません（データは失われず、.env のロールバックで復旧可能）。リストは増やす一方で、過去キーの削除前に全旧データの再暗号化完了を必ず確認してください。

**自動データ移行はしない**：ローテーション後も旧データは旧キーで暗号化されたまま、読み書きは正常です。新キーで既存データを書き直す必要がある場合は、別途データ移行タスクを実行（テーブル毎に読み取り → 書き込みで再暗号化トリガー）。

### 2.3 Fail-fast 起動検証

以下の設定はサービス起動時に検証され、鍵が**欠落または依然 `change-me` プレースホルダー**の場合は直接 `RuntimeException` を投げて起動を拒否します（プレースホルダー鍵のまま本番稼働を防止）：

| 設定 | 検証する鍵 |
|---|---|
| `service/config/encryption.php` | `ENCRYPTION_KEY` |
| `service/config/encryptable.php`、`service/config/plugin/erikwang2013/encryptable/app.php` | `ENCRYPTABLE_KEY` |
| `service/config/jwt.php`、`service/config/plugin/erikwang2013/jwt/jwt.php` | `JWT_SECRET_KEY` |

起動エラー例：`ENCRYPTABLE_KEY 未配置或仍为占位符，请在 .env 中配置 32 字节随机密钥`（= ENCRYPTABLE_KEY が未設定またはプレースホルダーのままです。.env に 32 バイトのランダム鍵を設定してください）。

**日常操作チェックリスト**：

1. 新環境デプロイ：`cp .env.example .env` → `change-me` プレースホルダー行を削除 → `php scripts/gen_env_keys.php --file=.env` → サービス起動で鍵エラーなしを確認。
2. 定期ローテーション：2.2 に従い、四半期に 1 回で十分（強制周期なし、漏洩時は即ローテーション）。
3. バックアップの `.env.bak.*` は平文鍵を含むため、データベースバックアップと同等に扱う（権限 600、リモート保管）。

## 3. 監視アラート（Prometheus + Grafana）

オーケストレーションは `admin/docker-compose.yml`（prometheus / grafana / redis-exporter の 3 サービスを追加）、設定は全て `admin/deploy/monitoring/`：

```bash
cd admin
docker compose up -d prometheus grafana redis-exporter
# Prometheus: http://host:9090   Grafana: http://host:3000
# Grafana 初回ログイン: admin / ${GRAFANA_ADMIN_PASSWORD}（デフォルト change-me-grafana-password）
```

- **データソース**：Grafana 起動時に Prometheus データソースを自動設定（provisioning）、パネルは UI で作成。
- **アラートルール**：`deploy/monitoring/alerts.yml`、カバー範囲：
  - `AppDown`（アプリ到達不可、全站 5xx 相当）— critical
  - `MysqlDown` / `RedisDown`（アプリ側のプローブ失敗）— critical
  - `ElasticsearchDown`（ES ネイティブ `/_prometheus/metrics` スクレイプ失敗）+ `ElasticsearchHealthYellow`（クラスターが緑以外）— critical/warning
  - `QueueBacklog`（scout 検索キュー `queues:scout_*` が >100 件滞留 10 分継続）— warning
- **ES パスワード注入**：prometheus は compose `secrets` 経由で `ELASTIC_PASSWORD` を読み取る（Docker Compose ≥ 2.24 が必要）、設定ファイルにパスワードをハードコードしない；未設定時は change-me プレースホルダーで、ES スクレイプ 401 で ElasticsearchDown が発動。
- **ルール再読み込み**：alerts.yml 変更後 `curl -X POST localhost:9090/-/reload`（prometheus に `--web.enable-lifecycle` が必要、デフォルト未追加ならコンテナ再起動）。
- **ローカル検証**：`bash scripts/verify_monitoring.sh` — admin/service 両側のアラートルール YAML 構文、両端 `/metrics`（admin:8787 / service:8788）のメトリクス出力、Prometheus（9090/9091）のルールロードを検証；アプリ/Prometheus 未稼働時は該当項目が SKIP 表示で exit 0。

**ステータス**：admin と service の両方に `/metrics` エンドポイントあり（MetricsController、認証不要）。MetricsCollector ミドルウェアが `code="all"|"5xx"` で実際に累積カウント（admin は `open_admin_http_requests_total`、service は `property_service_http_requests_total` を出力）、両側 alerts.yml の `Http5xxRatio` ルール（5xx 比率 >5% が 10 分継続）は直接有効化可能。**アラート実測はデプロイ待ち**：ルールは準備済みだが、実デプロイ環境でのトリガー検証は未実施（`verify_monitoring.sh` と Prometheus の本番稼働に依存）。

## 4. ログローテーション

- **コンテナログ**：compose の全サービスに `json-file` + `max-size 10m / max-file 3` を設定済み、追加対応不要。
- **ホスト機アプリログ**（`runtime/*.log`、`service/workerman.log`）：`admin/deploy/logrotate/pmp-app` を使用：

```bash
sudo cp admin/deploy/logrotate/pmp-app /etc/logrotate.d/pmp-app
# 実際のデプロイパスに合わせてファイル内のパスを修正してから有効化；copytruncate により webman 再起動不要でローテーション
sudo logrotate -d /etc/logrotate.d/pmp-app   # 試実行チェック
```

デフォルト毎日ローテーション、30 日保持、gzip 圧縮。

## 5. デプロイ後の負荷試験スモーク

デプロイ完了後、k6 スモークでログインチェーンと主要業務 API の到達性を検証（低レート、性能負荷試験ではない）。スクリプト：`scripts/loadtest/smoke.js`（デフォルト 2 VU、30s、ログイン + dashboard、いずれも `BASE_URL`/`VUS`/`DURATION`/`TOKEN` 環境変数で上書き可）。

### 5.1 ローカルスモーク

```bash
cd /path/to/property-management-platform/scripts/loadtest

# ログインチェーンのみ探索（token 不要；422 認証コードエラー/429 レート制限は防御の発動で、到達性ありとみなす）
k6 run -e BASE_URL=http://127.0.0.1:8790 smoke.js

# 認証付き業務 API：デプロイサーバー上で負荷試験用 JWT を発行（admin/.env と vendor に依存）してから渡す
TOKEN=$(php mint-token.php)
k6 run -e BASE_URL=https://admin.example.com -e TOKEN="$TOKEN" smoke.js

# 並列数/時間のカスタム
k6 run -e BASE_URL=https://admin.example.com -e TOKEN="$TOKEN" -e VUS=5 -e DURATION=60s smoke.js
```

フル負荷試験（login + dashboard + fee の 3 スクリプト）は引き続き `bash scripts/loadtest/run.sh [BASE_URL] [VUS] [DURATION]` を使用。

### 5.2 CI スモーク（GitHub Actions 手動トリガー）

リポジトリの Actions ページ → **Loadtest Smoke** → **Run workflow**：

| 入力 | 必須 | 説明 |
|---|---|---|
| `target_url` | はい | 被験環境のアドレス、例：`https://admin.example.com` |
| `duration` | いいえ | スモーク時間、デフォルト `30s` |
| `token` | いいえ | 負荷試験 JWT；空欄ならログインチェーンのみ探索 |

token 取得（デプロイサーバーのリポジトリルートで実行、`admin/.env` と `admin/vendor/` が必要）：

```bash
php scripts/loadtest/mint-token.php
```

> 注意：token は負荷試験専用 JWT（デフォルトは erik 管理者アカウント）で、workflow ログに平文で出現します。負荷試験専用アカウントで発行してください；本番で露出させたくない場合は 5.1 のローカルスモークに切り替えてください。
