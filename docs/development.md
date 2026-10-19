# 開発環境

Docker Compose で、nginx・Rails API・React(Vite)・MySQL を起動します。
1つの nginx の配下にパス単位（`/naiken/`, ...）でアプリを振り分ける構成で、本番（`rails.keisuke-nagaoka.com`）と同じURL構造で開発できます。

## ディレクトリ構成

```
.
├── compose.yml             # ローカル開発用 (MySQLコンテナ込み・ソースをbind mount)
├── compose.prod.yml        # EC2用 (MySQLコンテナなし・RDSへ接続・ソースをイメージに焼き込み)
├── .env.example            # 開発用イメージのビルド引数 (UID/GID)
├── .github/workflows/      # CI (GitHub Actions)
├── docs/                   # ドキュメント・スクリーンショット
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
    └── naiken/
        ├── backend/            # Rails 8.1 (API mode)
        │   ├── app/
        │   │   ├── controllers/api/v1/   # APIのエンドポイント
        │   │   ├── models/               # バリデーション・業務ルール
        │   │   └── serializers/          # JSONの組み立て
        │   ├── config/locales/ja.yml     # 項目名・エラーメッセージの日本語化
        │   ├── db/                       # マイグレーション・シード
        │   └── spec/                     # RSpec (models / requests)
        └── frontend/           # React 19 + TypeScript + Vite
            └── src/
                ├── api/                  # APIクライアント (リソースごと)
                ├── components/           # 共通コンポーネント
                ├── lib/                  # 通信・表示変換・日時の扱い
                └── pages/                # 画面 (customers / properties / viewings)
```

## 初回セットアップ

```bash
# 自己署名証明書 (HTTPSでの動作確認用)
openssl req -x509 -nodes -newkey rsa:2048 \
  -keyout docker/nginx/server.key \
  -out docker/nginx/server.crt \
  -days 365 \
  -subj "/CN=localhost"

# ホストのユーザーと同じUID/GIDでコンテナを動かし、生成ファイルがroot所有にならないようにする
printf "UID=%s\nGID=%s\n" "$(id -u)" "$(id -g)" > .env
cp apps/naiken/backend/.env.example apps/naiken/backend/.env

docker compose up -d
docker compose exec naiken-api bin/rails db:seed
```

| URL | 内容 |
| --- | --- |
| http://localhost:9300/naiken/ | 画面（Vite の HMR 有効） |
| https://localhost:9743/naiken/ | 画面（自己署名証明書） |
| http://localhost:9300/naiken/api/v1/health | API・DBの疎通確認 |
| `localhost:3310` | MySQL（ホストから接続する場合） |

## よく使うコマンド

```bash
# Rails
docker compose exec naiken-api bin/rails db:seed           # デモデータ投入(何度実行しても同じ状態になる)
docker compose exec naiken-api bin/rails db:seed:replant   # データを消してデモデータを入れ直す
docker compose exec naiken-api bin/rails db:migrate
docker compose exec naiken-api bin/rails console
docker compose exec naiken-api bundle exec rspec
docker compose exec naiken-api bin/rubocop
docker compose exec naiken-api bin/brakeman
docker compose exec naiken-api bin/ci                      # RuboCop・セキュリティチェック・RSpecをまとめて実行

# React
docker compose exec naiken-web npm install <package>
docker compose exec naiken-web npm run lint
docker compose exec naiken-web npm test                    # Vitest
docker compose exec naiken-web npm run build
```

> nginx の設定ファイルを編集した場合は `docker compose up -d --force-recreate nginx` で反映します
> （Docker Desktop(WSL) では、単一ファイルの bind mount がエディタの保存方法によって追従しないことがあるため）。

## CI (GitHub Actions)

`.github/workflows/ci.yml` で、push・プルリクエストごとに以下を並行して実行します。

| ジョブ | 内容 |
| --- | --- |
| Backend (Rails) | RuboCop / Brakeman / bundler-audit / RSpec（MySQL 8.0 をサービスコンテナで起動） |
| Frontend (React) | oxlint / Vitest / 型チェック・ビルド |
| Production images | 本番用の Rails API イメージ・nginx イメージがビルドできることを確認（プッシュはしない） |

## 新しいアプリを追加する手順

1. `apps/<新アプリ名>/backend` (Rails) と、必要なら `apps/<新アプリ名>/frontend` (React) を作成する
2. `compose.yml` / `compose.prod.yml` にサービスを追加する
3. `docker/nginx/default.conf` / `default.prod.conf` に `upstream` と `location /<新アプリ名>/` ブロックを追加する
4. フロントエンドがある場合は `docker/nginx/Dockerfile.prod` にビルドステージを追加する
5. `docker compose up -d --build` で反映する
