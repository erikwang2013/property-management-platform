# インストールガイド

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

本書は不動産管理システムをゼロからデプロイする手順を案内します。

---

## 目次

1. [Web インストールウィザード（推奨）](#web-安装向导推荐)
2. [手動インストール](#手动安装)
3. [Docker デプロイ](#docker-部署)
4. [デフォルトアカウント](#默认账户)
5. [インストールの検証](#验证安装)
6. [よくある質問](#常见问题)

---

## Web インストールウィザード（推奨）

プロジェクトには Web インストールウィザードが組み込まれており、管理画面を起動後、ブラウザだけで全設定を完了できます。

### 使用手順

```bash
# 1. 管理画面ディレクトリへ
cd admin

# 2. 環境変数ファイルを作成（テンプレートからコピー）
cp .env.example .env

# 3. 依存関係をインストール
composer install --no-dev --optimize-autoloader

# 4. サービスを起動
php start.php start -d
```

### 5. インストールウィザードを開く

ブラウザで **`http://localhost:8787/install`** にアクセスし、案内に従って 3 ステップの設定を完了します：

| ステップ | 内容 | 説明 |
|------|------|------|
| 第 1 步 | 数据库配置 | ホスト、ポート、DB 名、ユーザー名、パスワードを入力 |
| 第 2 步 | 管理员账户 | 管理画面のログインユーザー名とパスワードを設定（最低 6 桁） |
| 第 3 步 | 确认安装 | 設定情報を確認し、確認クリックでインストールを自動実行 |

インストールプロセスで自動的に完了する処理：
1. データベース接続のテスト
2. `.env` 設定ファイルの書き込み
3. 全 65 テーブル + 権限シードデータのインポート
4. 管理者アカウントの作成とスーパー管理者ロールの付与
5. インストールロックファイル `public/.installed` の作成

### インストール完了後

- 管理画面アドレス：`http://localhost:8787/admin`
- インストールウィザードにログインアドレスとアカウント情報が表示されます
- 設定を反映するためサービスの再起動を推奨：`php start.php restart -d`
- 再インストールする場合は `public/.installed` ファイルを削除するだけ

---

## 手動インストール

### 環境要件

| コンポーネント | バージョン要件 | 説明 |
|------|---------|------|
| PHP | 8.1+（推奨 8.3） | pcntl、pdo_mysql、redis、gd、mbstring 拡張が必要 |
| MySQL | 8.0+ | utf8mb4 文字セット |
| Redis | 6.0+ | キャッシュ、レート制限、Session |
| Composer | 2.x | PHP 依存関係管理 |
| Elasticsearch | 8.x | 全文検索（任意、無効時はデータベースクエリを使用） |
| Flutter SDK | 3.x | フロントエンド開発にのみ必要 |

### PHP 拡張の確認

```bash
php -m | grep -E "pcntl|pdo_mysql|redis|gd|mbstring|curl|json|xml|dom"
```

---

## データベース初期化

### 1. データベースの作成

```bash
mysql -u root -p <<SQL
CREATE DATABASE IF NOT EXISTS management
  DEFAULT CHARSET utf8mb4
  COLLATE utf8mb4_unicode_ci;
SQL
```

### 2. 統合インストールスクリプトのインポート

```bash
mysql -u root -p management < docs/install.sql
```

`docs/install.sql` には全 65 テーブル + RBAC 権限シードデータが含まれ、`CREATE TABLE IF NOT EXISTS` により再実行可能です。

実行後の検証：

```bash
mysql -u root -p management -e "SHOW TABLES;" | wc -l
# 出力: 66（65 テーブル + 1 行のヘッダー）
```

---

## 管理画面のデプロイ

管理画面は `http://localhost:8787` で稼働し、管理者バックエンド API を提供します。

```bash
cd admin

# 1. 環境変数の設定
cp .env.example .env
# .env を編集し、データベースパスワード、JWT 鍵などを変更

# 2. 依存関係のインストール
composer install --no-dev --optimize-autoloader

# 3. サービスの起動
php start.php start -d
# -d はバックグラウンド実行、-d なしでフォアグラウンド実行しログ確認可

# 4. 検証
curl http://localhost:8787/health
```

### 主要設定項目（admin/.env）

| 設定項目 | 説明 | 本番環境の要件 |
|--------|------|-------------|
| `JWT_SECRET_KEY` | JWT 署名鍵 | 64 桁以上のランダム文字列 |
| `HASHIDS_SALT` | ID 暗号化のソルト | ランダム文字列、service と一致させる |
| `SNOWFLAKE_DATACENTER_ID` | データセンター ID (0-31) | マルチデータセンター時は区別が必要 |
| `SNOWFLAKE_WORKER_ID` | ワーカーノード ID (0-31) | 同一データセンター内でマシン毎に異なる値 |
| `ENCRYPTION_KEY` | API 転送暗号化鍵 | 32 バイトのランダム文字列 |
| `ENCRYPTABLE_KEY` | データベースフィールド暗号化鍵 | 32 バイトのランダム文字列 |
| `DB_PASSWORD` | データベースパスワード | 強力なパスワード |

---

## 業務端のデプロイ

業務端は `http://localhost:8788` で稼働し、所有者端 API を提供します。

```bash
cd service

# 1. 環境変数の設定
cp .env.example .env
# .env を編集し、データベースパスワード、JWT 鍵などを変更

# 2. 依存関係のインストール
composer install --no-dev --optimize-autoloader

# 3. サービスの起動
php start.php start -d

# 4. 検証
curl http://localhost:8788/health
```

> **注意：** admin と service は同一のデータベースを共有します。`HASHIDS_SALT` は admin と一致させる必要があります。一致しない場合、admin が生成した暗号化 ID を service 端で復号できません。

---

## Docker デプロイ

### 管理画面

```bash
cd admin
cp .env.docker .env
# .env を編集し本番鍵を変更

docker compose up -d
# 含まれる: Nginx + PHP + MySQL + Redis + Elasticsearch
```

### 業務端

```bash
cd service
cp .env.docker .env
# .env を編集し本番鍵を変更

docker compose up -d
```

### サービスポート計画

| サービス | admin | service | 説明 |
|------|-------|---------|------|
| アプリ | 8787 | 8788 | webman HTTP |
| MySQL | 3306 | 3307 | コンテナポートマッピング |
| Redis | 6379 | 6380 | コンテナポートマッピング |
| Elasticsearch | 9200 | 9201 | コンテナポートマッピング |
| Nginx | 80/443 | 80/443 | ずらしてデプロイが必要 |

> 同一ホストに 2 つの docker-compose をデプロイする場合、service のポートはオフセット済みで競合しません。

---

## デフォルトアカウント

| ユーザー名 | パスワード | ロール | 説明 |
|--------|------|------|------|
| admin | admin123 | スーパー管理者 | 全権限を持つ |

> **本番環境では直ちにデフォルトパスワードを変更してください。**

---

## インストールの検証

### 1. ヘルスチェック

```bash
# 管理画面
curl http://localhost:8787/health

# 業務端
curl http://localhost:8788/health
```

### 2. API ドキュメント

全 API エンドポイントとパラメータの説明は独立ドキュメント [API.md](API.md) を参照。起動後は自動生成のインタラクティブなインターフェースドキュメントにもアクセスできます：

| 端 | アドレス |
|----|------|
| 管理画面 | http://localhost:8787/apidoc |
| 業務端 | http://localhost:8788/apidoc |

### 3. ログインテスト

```bash
curl -X POST http://localhost:8787/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

### 4. テスト実行

```bash
# 管理画面
cd admin && php vendor/bin/phpunit

# 業務端
cd service && php vendor/bin/phpunit
```

---

## よくある質問

### Q: 起動エラー `Call to undefined function pcntl_fork()`

PHP に pcntl 拡張がありません。

```bash
# Ubuntu/Debian
apt install php-pcntl

# Docker
docker-php-ext-install pcntl
```

### Q: ログイン後に Token 無効と表示される

admin と service の `.env` で以下の設定が一致しているか確認してください：
- `JWT_SECRET_KEY`
- `JWT_ALGORITHM`

### Q: 暗号化 ID が両端で一致しない

admin と service の `HASHIDS_SALT` の値が完全に同一であることを確認してください。

### Q: Docker コンテナ間でネットワーク不通

IP ではなくコンテナ名で接続してください（例：`DB_HOST=mysql`）。

### Q: データベースをリセットする方法

```bash
mysql -u root -p -e "DROP DATABASE IF EXISTS management;"
mysql -u root -p -e "CREATE DATABASE management DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -p management < docs/install.sql
```

### Q: HTTPS の設定方法

本番環境では Nginx リバースプロキシでの TLS 終端を推奨します。参考設定は `admin/docs/nginx-security.conf` を参照してください。

---

## 次のステップ

- [アーキテクチャ設計ドキュメント](ARCHITECTURE_DESIGN.md) — システムの階層アーキテクチャとミドルウェア実行チェーン
- [API ドキュメント](API.md) — 完全なインターフェースリファレンス
- [機能設計ドキュメント](FEATURE_DESIGN.md) — 34 モジュールの機能仕様
- [バージョン比較](EDITIONS.md) — Lite / Standard / Full バージョンの差異
