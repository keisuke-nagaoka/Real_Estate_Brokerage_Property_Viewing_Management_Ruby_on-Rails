# 本番環境（AWS）

本番は AWS の EC2 1台で、既存の個人サイト（`keisuke-nagaoka.com`・`go.`・`node.`）と同居させています。DB は Amazon RDS for MySQL です。
デプロイの流れは他のサイトと同じく、EC2 上で `docker build` → `docker run` し、入口の nginx に設定を追加します。

```
Browser ──HTTPS──> Route 53 (rails.keisuke-nagaoka.com → EC2)
                     │
                     ▼
                   EC2 (Amazon Linux 2023)
                   └─ 入口の nginx コンテナ「nginx」（80/443・Let's Encrypt。node・go と共用）
                       │  web-network
                       ▼
                     naiken-nginx コンテナ
                       ├─ /naiken/      → React のビルド成果物（静的配信）
                       └─ /naiken/api/  → naiken-api コンテナ（Rails / Puma） ──TLS──> RDS for MySQL
```

## 構成のポイント

| 項目 | 内容 |
| --- | --- |
| HTTPS | 既存の入口の nginx が受ける。証明書は他のサイトと同じく certbot（Docker）で取得し、cron の `~/renew-cert.sh` で自動更新される |
| 入口の nginx との接続 | `naiken-nginx`・`naiken-api` を既存の `web-network` に参加させ、コンテナ名で転送する |
| 入口の nginx の安全性 | 転送先を Docker の DNS でリクエストのたびに引く設定にし、Rails のコンテナが止まっていても入口の nginx（node・go のサイト）が起動できるようにした |
| メモリ | EC2 のメモリは 1GB。Rails の gem のビルドは空きメモリ（約400MB）だけでは足りず強制終了されるため、スワップ（1GB）を追加する。動作中の Rails にはメモリの上限（400MB）を付け、他のサイトのメモリを奪わないようにする |
| DB | RDS にアプリ専用のデータベース・ユーザーを作り、他のアプリのデータベースには触れられない権限にする。通信は TLS 必須・証明書検証あり |
| 物件写真 | Docker ボリューム `naiken_storage` に保存（コンテナを作り直しても消えない） |
| 初回起動 | `db:prepare` がテーブルを作り、デモデータ（物件写真を含む）も投入する。2回目以降は未適用のマイグレーションだけを実行する |

## ローカルと本番の違い

| 項目 | ローカル (`compose.yml`) | 本番（EC2） |
| --- | --- | --- |
| DB | MySQL コンテナ | Amazon RDS for MySQL |
| Rails | ソースを bind mount、変更を即反映 | `docker/ruby/Dockerfile.prod` でビルドしたイメージ（ソース・gem を焼き込み） |
| React | Vite の開発サーバー（HMR） | ビルド成果物を nginx イメージに焼き込み、nginx が静的配信（Node.js は常駐しない） |
| HTTPS | 自己署名証明書 | 入口の nginx（Let's Encrypt） |
| 物件写真 | `apps/naiken/backend/storage/`（bind mount） | Docker ボリューム `naiken_storage` |
| 設定 | `apps/naiken/backend/.env` | `apps/naiken/backend/.env.production`（GitHub にはコミットしない） |

本番と同じ構成は、手元でも `compose.prod.yml` で起動して確認できます。

## 初回デプロイの手順

### 1. Route 53

ホストゾーン `keisuke-nagaoka.com` にレコードを作成する。

| 項目 | 値 |
| --- | --- |
| レコード名 | `rails` |
| タイプ | A |
| 値 | EC2 の IP アドレス（他のサイトと同じ） |
| TTL | 300 |

### 2. EC2 の準備

ディスク（8GB）の空きが少ないため、EBS を 16GB に増やしておくと安心です（AWS コンソール：EC2 → インスタンス → ストレージ → ボリュームID → ボリュームを変更 → サイズを 16 に）。その後、EC2 で次を実行します。

```bash
# EBS を増やした場合: ディスクの拡張をOSに反映する
lsblk
sudo growpart /dev/nvme0n1 1
sudo xfs_growfs -d /

# 不要な Docker のビルドキャッシュ・タグのないイメージを削除する(動いているサイトには影響しない)
docker builder prune -f
docker image prune -f

# スワップ(1GB)を追加する(Rails の gem のビルドに必要)
sudo dd if=/dev/zero of=/swapfile bs=1M count=1024
sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab

free -h
df -h /
```

### 3. ソースの取得と設定

```bash
sudo dnf install -y git
cd ~/apps
git clone https://github.com/keisuke-nagaoka/Ruby-on-Rails_App.git rails_docker
cd rails_docker

cp apps/naiken/backend/.env.production.example apps/naiken/backend/.env.production
chmod 600 apps/naiken/backend/.env.production
openssl rand -hex 64                     # → SECRET_KEY_BASE に設定する
openssl rand -base64 24 | tr -d '/+='    # → DB_PASSWORD に設定する
nano apps/naiken/backend/.env.production # SECRET_KEY_BASE・DB_HOST(RDSのエンドポイント)・DB_PASSWORD を設定
```

### 4. RDS にデータベースとユーザーを作る

```bash
mariadb -h <RDSのエンドポイント> -P 3306 -u admin -p
```

```sql
CREATE DATABASE naiken_production CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
-- パスワードは .env.production の DB_PASSWORD と同じにする。通信は TLS を必須にする
CREATE USER 'naiken_app'@'%' IDENTIFIED BY '<DB_PASSWORD>' REQUIRE SSL;
-- 起動時にテーブルの作成・変更(マイグレーション)を行うため、このデータベースに対する全権限を付ける(他のデータベースには触れない)
GRANT ALL PRIVILEGES ON naiken_production.* TO 'naiken_app'@'%';
SHOW GRANTS FOR 'naiken_app'@'%';
exit
```

### 5. イメージを作る

```bash
cd ~/apps/rails_docker
docker build -f docker/ruby/Dockerfile.prod -t naiken-api:latest .
docker build -f docker/nginx/Dockerfile.prod -t naiken-nginx:latest .

# ビルドの途中で作られた不要なデータを削除してディスクを空ける
docker builder prune -f
docker image prune -f
```

### 6. コンテナを起動する

```bash
# Rails API。初回はテーブルの作成とデモデータの投入を行う(30秒ほどかかる)
docker run -d \
  --name naiken-api \
  --restart unless-stopped \
  --network web-network \
  --memory 400m \
  --env-file /home/ec2-user/apps/rails_docker/apps/naiken/backend/.env.production \
  -v naiken_storage:/rails/storage \
  --health-cmd "curl -fsS http://localhost:3000/up" \
  --health-interval 30s \
  naiken-api:latest

docker logs -f naiken-api   # 「Listening on http://0.0.0.0:3000」が出たら Ctrl+C

# 画面(React)と API への振り分け
docker run -d \
  --name naiken-nginx \
  --restart unless-stopped \
  --network web-network \
  -p 127.0.0.1:8300:80 \
  naiken-nginx:latest

docker ps
# 入口の nginx を通さずに確認する(Host ヘッダーは本番のドメインにする)
curl -s -H "Host: rails.keisuke-nagaoka.com" http://127.0.0.1:8300/naiken/api/v1/health
```

### 7. 入口の nginx に追加し、証明書を取得する

設定ファイルは [`deploy/front-nginx/`](../deploy/front-nginx/) にあります。反映する前に、必ず `nginx -t` で確認します。

```bash
# (1) 証明書を取得するための一時的な設定(HTTPのみ)を置いて反映する
cp ~/apps/rails_docker/deploy/front-nginx/rails.http-only.conf ~/nginx/conf.d/rails.conf
docker exec nginx nginx -t
docker exec nginx nginx -s reload

# (2) 証明書を取得する(以降は ~/renew-cert.sh で自動更新される)
docker run --rm \
  -v /home/ec2-user/certbot/www:/var/www/certbot \
  -v /home/ec2-user/certbot/conf:/etc/letsencrypt \
  certbot/certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  -d rails.keisuke-nagaoka.com

# (3) 本番の設定(HTTPS・転送)に置き換えて反映する
cp ~/apps/rails_docker/deploy/front-nginx/rails.conf ~/nginx/conf.d/rails.conf
docker exec nginx nginx -t
docker exec nginx nginx -s reload

curl -I https://rails.keisuke-nagaoka.com/naiken/
```

## 更新（2回目以降のデプロイ）

```bash
cd ~/apps/rails_docker
git pull
docker build -f docker/ruby/Dockerfile.prod -t naiken-api:latest .
docker build -f docker/nginx/Dockerfile.prod -t naiken-nginx:latest .

# 古いコンテナを削除し、手順6と同じ docker run で起動し直す(物件写真・DBのデータは残る)
docker rm -f naiken-api naiken-nginx
# (手順6の docker run を2つ実行)

docker builder prune -f
docker image prune -f
```

マイグレーションは、コンテナの起動時に `db:prepare` が未適用のものを自動で実行します。
