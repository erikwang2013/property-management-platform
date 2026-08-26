# データベース復旧訓練マニュアル（Recovery Runbook）

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> 適用: property-management-platform（admin 端 + service 端、MySQL 8.0）
> [OPS_RUNBOOK.md](OPS_RUNBOOK.md) 第 1 節と併せて読んでください：バックアップ生成、crontab、RPO/RTO は OPS_RUNBOOK を参照、本文書は「どう復旧するか、どう検証するか」のみを扱います。

## 0. 目標

- **訓練目標：30 分で完全な復旧訓練を 1 回完了**（復旧 + 検証）、四半期に少なくとも 1 回。
- いつでも直近のバックアップを手に、本文書に従って空 DB または指定時点へ復旧できる。

前提条件：

- バックアップファイルが利用可能：`scripts/backup.sh` が cron で実行済み（OPS_RUNBOOK 1.2 参照）。
- 復旧対象環境（訓練機または本番機）が本番と同型：同一 docker-compose、同一バージョンの MySQL 8.0。
- 復旧前に確認：`gzip -t バックアップファイル` が通過；ディスク空き容量 ≥ バックアップ容量の 2 倍。

## 1. シナリオ A：空 DB への復旧（最も一般的、訓練のデフォルトシナリオ）

目標：バックアップを真新しい空 DB にインポートし、データが使えることを検証する。

```bash
cd /path/to/property-management-platform

# 1) 直近のバックアップを選択
ls -lt backups/backup_*.sql.gz | head

# 2) 完全性チェック（不合格ならより古いバックアップへ）
gzip -t backups/backup_20260816_020000.sql.gz && echo OK

# 3) 対象コンテナが稼働中であることを確認
docker compose -f admin/docker-compose.yml ps mysql

# 4) 空 DB を作成（訓練 DB 名に _drill 接尾辞を付け、本番データの誤上書きを回避）
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot -e "CREATE DATABASE IF NOT EXISTS property_management_drill DEFAULT CHARACTER SET utf8mb4;"'

# 5) インポート（-T で TTY を無効化、非対話を保証；実測約 1-5 分）
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot --default-character-set=utf8mb4 property_management_drill' \
  < backups/backup_20260816_020000.sql.gz
```

> 資格情報の注意：`MYSQL_PWD` は `admin/.env` の `DB_PASSWORD` から取得；本番でシェル履歴に平文を残すのは禁止、`--env-file admin/.env` または環境変数注入を推奨。本マニュアルの例は訓練環境の合意値。

## 2. シナリオ B：指定時点への復旧（binlog リプレイ）

前提：MySQL 8 はデフォルトで binlog 有効（`log_bin=ON`）、バックアップ時点以降の増分は全て binlog 内にあります。データ損失 ≤ 直近バックアップ + binlog 保持期間（デフォルト `binlog_expire_logs_seconds=2592000`、30 日）。

考え方：フル復旧 → binlog 起点を特定 → `mysqlbinlog` で対象時点までリプレイ。

```bash
# 1) binlog 有効を確認し、ログファイルを一覧表示
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot -e "SHOW VARIABLES LIKE \"log_bin\"; SHOW BINARY LOGS;"'

# 2) フル復旧（シナリオ A の手順 4-5 と同様、空 DB へ復旧）

# 3) バックアップに対応する binlog 起点を特定：バックアップファイルに記録された位置（--master-data=2 の場合）
#    本スクリプトは --master-data なしのため、起点は「バックアップ開始時刻」、誤差はバックアップ所要時間内。
#    binlog を対象時点までリプレイ（例：2026-08-16 10:30:00 へ復旧）
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysqlbinlog --stop-datetime="2026-08-16 10:30:00" /var/lib/mysql/binlog.000012 | mysql -uroot property_management_drill'
```

要点：

- binlog はコンテナ内パス `/var/lib/mysql/binlog.0000NN`、`SHOW BINARY LOGS` の出力と照合。
- 「バックアップ開始時刻より後」の binlog のみリプレイ；リプレイ後すぐ検証（第 3 節参照）、`max(updated_at)` が期待通りであることを確認。
- 秒単位の誤操作復旧：まず誤操作文を特定 `mysqlbinlog /var/lib/mysql/binlog.0000NN | grep -n "誤操作キーワード"`、その後 `--stop-datetime` または `--stop-position` を決定。

## 3. データ一致性検証（復旧後は必ず実施）

| チェック項目 | コマンド | 合格基準 |
|---|---|---|
| バックアップファイル完全性 | `gzip -t <バックアップ>` | エラーなし |
| 主要テーブル行数 | `SELECT COUNT(*) FROM erik_admin_user;` | バックアップ前の記録と行数一致 |
| 業務テーブル抽查 | `SELECT COUNT(*) FROM erik_owner;`、`erik_tenant`、`erik_fee_bill`、`erik_repair_order` | 3 つ以上が数量レベル的に妥当（非 0 かつバックアップ前と一致） |
| 暗号化フィールドの復号 | encryptable フィールドを含むレコードを 1 件参照（例：`erik_owner` の身分証/携帯番号） | 値が正しく、アプリログに decrypt エラーなし |
| 業務スモーク | ログイン、一覧取得 API を各 1 回 | 200 / 正常応答 |

抽查スクリプト例（訓練環境）：

```bash
docker compose -f admin/docker-compose.yml exec -T -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot property_management_drill -e "
    SELECT (SELECT COUNT(*) FROM erik_admin_user) AS users,
           (SELECT COUNT(*) FROM erik_owner) AS owners,
           (SELECT COUNT(*) FROM erik_tenant) AS tenants,
           (SELECT COUNT(*) FROM erik_fee_bill) AS fee_bills,
           (SELECT COUNT(*) FROM erik_repair_order) AS repair_orders;"'
```

> 行数一致性：バックアップ前に同じ SQL でベースラインを記録し、復旧後に比較；訓練時はベースラインを訓練記録に書き込む。

## 4. 30 分訓練タイムテーブル

| 時間 | アクション | 担当 |
|---|---|---|
| 0-5 min | バックアップ選択、`gzip -t`、空 DB 作成、ベースライン行数記録 | 運用 |
| 5-15 min | シナリオ A の復旧インポート | 運用 |
| 15-25 min | 第 3 節の一致性検証 + 業務スモーク | 運用 + 業務 |
| 25-30 min | 結果記録、訓練 DB クリーンアップ（`DROP DATABASE property_management_drill`）、OPS_RUNBOOK 1.4 の実測 RTO 更新 | 運用 |

## 5. 失敗処理

| 症状 | 処理 |
|---|---|
| `gzip -t` 失敗 | バックアップ破損、より古いバックアップへ切替、大きめの RPO を受け入れ、バックアップ cron が正常か確認 |
| インポートエラー（文字セット/権限） | `--default-character-set=utf8mb4` と空 DB の文字セット一致を確認；ユーザーにテーブル作成権限があることを確認 |
| 行数がベースラインと不一致 | 訓練を直ちに停止、誤った DB/ファイルにインポートしていないか確認；本番復旧の場合は継続調査してアプリをロールバック |
| binlog リプレイ後もデータが不足 | `--stop-datetime` がバックアップ開始時刻より後か確認；バックアップ後の最初の binlog からリプレイを開始しているか確認 |

## 6. 訓練記録テンプレート

```text
日付: 2026-08-16
復旧目標: 空 DB（シナリオ A）/ 時点（シナリオ B）
バックアップファイル: backups/backup_20260816_020000.sql.gz
ベースライン行数: erik_admin_user=1, erik_owner=42, erik_fee_bill=128
復旧所要時間: XX 分    検証所要時間: XX 分    合計: XX 分（目標 ≤ 30）
結果: 合格 / 不合格（失敗理由と対応を添付）
```
