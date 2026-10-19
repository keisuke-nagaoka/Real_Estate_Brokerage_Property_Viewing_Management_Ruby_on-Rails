# rails_docker

Ruby on Rails アプリのローカル開発環境。`go_docker` / `node_docker` と同じ考え方で、
1つのnginxの配下にパス単位 (`/naiken/`, ...) で複数アプリを振り分ける構成。
本番では `rails.keisuke-nagaoka.com` 配下で、EC2上のnginx → 各コンテナ、DBは Amazon RDS for MySQL に接続する想定。

## 構成

```
rails_docker/
├── compose.yml             # ローカル開発用 (MySQLコンテナ込み・ソースをbind mount)
├── compose.prod.yml        # EC2用 (MySQLコンテナなし・RDSへ接続・ソースをイメージに焼き込み)
├── .env.example            # 開発用イメージのビルド引数 (UID/GID)
├── docker/
│   ├── ruby/
│   │   ├── Dockerfile          # 開発用 (Rails)
│   │   └── Dockerfile.prod     # 本番用マルチステージビルド (RDSのCAバンドル同梱)
│   ├── node/
│   │   └── Dockerfile          # 開発用 (React + Vite)
│   ├── nginx/
│   │   ├── default.conf        # ローカル用: /naiken/api/ → Rails, /naiken/ → Vite
│   │   ├── default.prod.conf   # 本番用: /naiken/api/ → Rails, /naiken/ → Reactのビルド成果物
│   │   ├── Dockerfile.prod     # Reactをビルドしてnginxイメージに焼き込む
│   │   ├── server.crt          # 自己署名証明書 (gitignore)
│   │   └── server.key
│   └── mysql/
│       ├── conf.d/my.cnf       # utf8mb4 / UTC
│       └── init/               # 初回起動時に実行 (テストDBの作成・権限付与)
└── apps/
    └── naiken/                 # 不動産仲介向け 顧客・内見管理システム
        ├── backend/            # Rails 8.1 (API mode) + RSpec
        └── frontend/           # React 19 + TypeScript + Vite
```

| 項目 | バージョン |
| --- | --- |
| Ruby / Rails | 3.4 / 8.1 (API mode) |
| Node.js / React / Vite | 24 / 19 / 8 |
| DB | MySQL 8.0 (本番: Amazon RDS for MySQL) |
| テスト | RSpec, FactoryBot |

## 起動

初回のみ、自己署名証明書と `.env` を作成する。

```bash
cd rails_docker
openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout docker/nginx/server.key \
  -out docker/nginx/server.crt \
  -days 365 \
  -subj "/CN=localhost"

# ホストのユーザーと同じUID/GIDでコンテナを動かし、生成ファイルがroot所有にならないようにする
printf "UID=%s\nGID=%s\n" "$(id -u)" "$(id -g)" > .env
cp apps/naiken/backend/.env.example apps/naiken/backend/.env
```

```bash
docker compose up -d
```

- http://localhost:9300/naiken/ (画面 / ViteのHMR有効)
- https://localhost:9743/naiken/ (自己署名証明書)
- http://localhost:9300/naiken/api/v1/health (API・DB疎通確認)
- MySQLはホストから `localhost:3310` でも接続可能

## よく使うコマンド

```bash
# Rails
docker compose exec naiken-api bin/rails db:seed    # デモデータ投入(何度実行しても同じ状態になる)
docker compose exec naiken-api bin/rails g model Customer name:string
docker compose exec naiken-api bin/rails db:migrate
docker compose exec naiken-api bin/rails console
docker compose exec naiken-api bundle exec rspec
docker compose exec naiken-api bin/rubocop
docker compose exec naiken-api bin/brakeman

# React
docker compose exec naiken-web npm install <package>
docker compose exec naiken-web npm run lint
docker compose exec naiken-web npm run build
```

> nginxの設定ファイルを編集した場合は `docker compose up -d --force-recreate nginx` で反映する
> (Docker Desktop(WSL)では、単一ファイルのbind mountがエディタの保存方法によって追従しないことがあるため)。

## ローカルと本番でDBを切り替える構成

コードは `DB_HOST` などの環境変数しか見ないため、ローカル/本番でコード変更は不要。

```
ローカル: docker compose up                        → naiken-api → MySQLコンテナ(db)
本番    : docker compose -f compose.prod.yml up -d → naiken-api → Amazon RDS for MySQL (TLS + 証明書検証)
```

- `compose.prod.yml` は `db` サービスを持たず、`apps/naiken/backend/.env.production` の `DB_HOST` にRDSのエンドポイントを設定する
- `naiken-api` は起動時に `bin/rails db:prepare` を実行し、DB作成・未適用マイグレーションを適用してからPumaを起動する
- Reactはビルド成果物を nginx イメージに焼き込み、nginxが静的配信する (Node.jsは本番で常駐しない)
- 画面とAPIは同一オリジン (`/naiken/` と `/naiken/api/`) のためCORS設定は不要
- 本番のホスト側ポートは `HTTP_PORT` / `HTTPS_PORT` で変更可能 (デフォルト 80 / 443)

RDS側は以下を想定:

- Public access: **No**(EC2と同一VPC内のみ)
- セキュリティグループ: 3306番ポートはEC2のセキュリティグループからのみ許可
- 接続は `DB_SSL_MODE=verify_identity` + イメージ同梱のRDS CAバンドル (`/etc/ssl/certs/rds-global-bundle.pem`) で、TLS暗号化とサーバー証明書の検証を行う
- 本番の接続情報(`.env.production`)はGitHubにコミットしない(`.gitignore`で除外済み)

RDSにはアプリ専用のユーザーとDBを作成する (管理ユーザーでEC2から接続して実行):

```sql
CREATE DATABASE naiken_production CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE USER 'naiken_app'@'%' IDENTIFIED BY '********' REQUIRE SSL;
GRANT ALL PRIVILEGES ON naiken_production.* TO 'naiken_app'@'%';
```

## 新しいアプリを追加する手順

1. `apps/<新アプリ名>/backend` (Rails) と、必要なら `apps/<新アプリ名>/frontend` (React) を作成する
2. `compose.yml` / `compose.prod.yml` にサービスを追加する
3. `docker/nginx/default.conf` / `default.prod.conf` に `upstream` と `location /<新アプリ名>/` ブロックを追加する
4. フロントエンドがある場合は `docker/nginx/Dockerfile.prod` にビルドステージを追加する
5. `docker compose up -d --build` で反映する
