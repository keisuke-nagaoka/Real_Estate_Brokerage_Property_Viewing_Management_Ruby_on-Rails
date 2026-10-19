# 本番環境（AWS）

本番は AWS の EC2 上で Docker Compose（`compose.prod.yml`）を動かし、DB は Amazon RDS for MySQL に接続する構成です。

```
Browser ──HTTPS──> Route 53 (rails.keisuke-nagaoka.com)
                     │
                     ▼
                   EC2
                   └─ nginx コンテナ
                       ├─ /naiken/      → React のビルド成果物（静的配信）
                       └─ /naiken/api/  → Rails API コンテナ（Puma） ──TLS──> RDS for MySQL
```

## ローカルと本番の違い

コードは `DB_HOST` などの環境変数しか見ないため、ローカルと本番でコードの変更は不要です。

```
ローカル: docker compose up                        → naiken-api → MySQLコンテナ(db)
本番    : docker compose -f compose.prod.yml up -d → naiken-api → Amazon RDS for MySQL (TLS + 証明書検証)
```

| 項目 | ローカル (`compose.yml`) | 本番 (`compose.prod.yml`) |
| --- | --- | --- |
| DB | MySQL コンテナ | Amazon RDS for MySQL |
| Rails | ソースを bind mount、変更を即反映 | ソース・gem をイメージに焼き込み（`docker/ruby/Dockerfile.prod`） |
| React | Vite の開発サーバー（HMR） | ビルド成果物を nginx イメージに焼き込み、nginx が静的配信（Node.js は常駐しない） |
| 物件写真 | `apps/naiken/backend/storage/`（bind mount） | Docker ボリューム `naiken_storage` |
| 設定 | `apps/naiken/backend/.env` | `apps/naiken/backend/.env.production`（GitHub にはコミットしない） |

- `naiken-api` は起動時に `bin/rails db:prepare` を実行し、DB 作成・未適用マイグレーションを適用してから Puma を起動する
- 画面と API は同一オリジン（`/naiken/` と `/naiken/api/`）のため CORS 設定は不要
- 本番のホスト側ポートは `HTTP_PORT` / `HTTPS_PORT` で変更可能（デフォルト 80 / 443）
- `APP_HOSTS` で Host ヘッダーを制限し、DNS リバインディング攻撃を防ぐ
- 物件写真（Active Storage）は Docker ボリューム `naiken_storage` に保存し、コンテナを作り直しても消えないようにする。写真のURLの先頭には `PUBLIC_PATH_PREFIX`（`/naiken`）を付ける
- 初回起動時（DB を新規作成したとき）は `db:prepare` がデモデータ（物件写真を含む）も投入する
- 起動・設定のテンプレートは [`apps/naiken/backend/.env.production.example`](../apps/naiken/backend/.env.production.example)

## RDS

- Public access: **No**（EC2 と同一 VPC 内からのみ接続）
- セキュリティグループ: 3306 番ポートは EC2 のセキュリティグループからのみ許可
- 接続は `DB_SSL_MODE=verify_identity` + イメージに同梱した RDS の CA バンドル（`/etc/ssl/certs/rds-global-bundle.pem`）で、TLS 暗号化とサーバー証明書の検証を行う

アプリ専用のユーザーと DB を作成します（管理ユーザーで EC2 から接続して実行）。

```sql
CREATE DATABASE naiken_production CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE USER 'naiken_app'@'%' IDENTIFIED BY '********' REQUIRE SSL;
GRANT ALL PRIVILEGES ON naiken_production.* TO 'naiken_app'@'%';
```

## デプロイ

```bash
cp apps/naiken/backend/.env.production.example apps/naiken/backend/.env.production
# .env.production に SECRET_KEY_BASE・RDS の接続情報を設定する

docker compose -f compose.prod.yml up -d --build
```
