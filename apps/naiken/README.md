# Naiken — 不動産仲介向け 顧客・内見管理システム

不動産仲介の営業担当者が、顧客・物件・内見予定・対応状況を一元管理する小規模なWebアプリケーションです。
PHP / Laravel で業務システムを開発してきた経験を、Ruby on Rails に応用することを目的に開発しています。

- 公開URL: https://rails.keisuke-nagaoka.com/naiken/ (準備中)
- 環境構築・起動方法: [rails_docker/README.md](../../README.md)

## 技術構成

| 領域 | 技術 |
| --- | --- |
| バックエンド | Ruby 3.4 / Ruby on Rails 8.1 (API mode) |
| フロントエンド | React 19 / TypeScript / Vite |
| DB | MySQL 8.0 (本番: Amazon RDS for MySQL) |
| テスト・静的解析 | RSpec / FactoryBot / RuboCop / Brakeman |
| インフラ | Docker / nginx / AWS (EC2, RDS, Route 53) |

```
Browser ──HTTPS──> nginx (EC2)
                    ├─ /naiken/      → Reactのビルド成果物 (静的配信)
                    └─ /naiken/api/  → Rails API (Puma) ──TLS──> RDS for MySQL
```

## 機能 (予定)

- [x] 顧客情報の登録・編集・一覧・検索（氏名・フリガナ・メール・電話番号の部分一致、担当者での絞り込み、ページネーション）
- [ ] 物件情報の登録・管理
- [ ] 顧客と物件を紐づけた内見予定の管理
- [ ] 対応ステータスの更新 (問い合わせ → 内見予定 → 検討中 → 成約 など)
- [ ] APIのテスト、入力値検証、エラーハンドリング

### 業務ルール (予定)

- [ ] 同じ担当者に、時間帯が重複する内見予定は登録できない
- [ ] 成約済みの案件は、特定の操作 (内見予定の追加など) を制限する

## API

| メソッド | パス | 説明 |
| --- | --- | --- |
| GET | `/naiken/api/v1/health` | API・DBの疎通確認 |
| GET | `/naiken/api/v1/agents` | 担当者一覧 |
| GET | `/naiken/api/v1/customers?q=&agent_id=&page=&per_page=` | 顧客一覧・検索 |
| GET | `/naiken/api/v1/customers/:id` | 顧客詳細 |
| POST | `/naiken/api/v1/customers` | 顧客登録 |
| PATCH | `/naiken/api/v1/customers/:id` | 顧客更新 |
| DELETE | `/naiken/api/v1/customers/:id` | 顧客削除 |

エラーは常に次の形式で返す（バリデーションエラーは422、存在しない場合は404）。

```json
{ "error": { "code": "validation_failed", "message": "氏名を入力してください", "details": { "name": ["氏名を入力してください"] } } }
```

## 設計で意識したこと

<!-- なぜその設計にしたか (例: APIのバージョニング、業務ルールをどこに書くか、など) -->

- APIは `/api/v1` でバージョニングし、レスポンスは `{ data, meta }`、エラーは `{ error: { code, message, details } }` に統一した。フロントエンドは `details` を使って項目ごとにエラーを表示する
- JSONの組み立ては `app/serializers` のクラスに分け、モデルの全カラムをそのまま返さないようにした
- 一覧取得では `includes(:agent)` で担当者をまとめて読み込み、N+1問題を防いでいる
- 検索の `LIKE` では `sanitize_sql_like` で `%` `_` をエスケープし、ユーザー入力がワイルドカードとして解釈されないようにした
- 入力値の表記ゆれ（全角の電話番号、前後の空白、空文字）は `normalizes` で保存前に正規化した
- 一覧の検索条件はURLのクエリに持たせ、リロードやブラウザバックでも条件が保持されるようにした

## Laravel と Rails の違い

<!-- 実装しながら気づいた違いを、Laravelでの書き方と対比して記録する -->

| 観点 | Laravel | Rails |
| --- | --- | --- |
| ORM | Eloquent | Active Record |
| マイグレーション | `up()` / `down()` を書くことが多い | `change` だけで、ロールバック時の処理を自動で推測してくれる |
| バリデーション | FormRequest (コントローラーの手前で検証) | モデルの `validates` (保存時に検証) |
| 許可する入力項目 | `$fillable` / `$request->validated()` | Strong Parameters (`params.expect`) |
| 値の整形 | Mutator / `Attribute::make(set:)` | `normalizes` |
| 検索条件の再利用 | ローカルスコープ (`scopeXxx`) | `scope` |
| APIリソース | API Resource (`JsonResource`) | 今回はシリアライザークラスを自作 |
| ルーティング | `Route::apiResource` | `resources ... only:` |
| テスト | PHPUnit / Pest | RSpec + FactoryBot |

## 実装中に調べたこと・解決したこと

<!-- 詰まったこと、調べたこと、どう解決したかを記録する -->

- **`customer` キーのないJSONも受け付けられた**：Rails の API モードでは ParamsWrapper が有効で、`{ "name": "..." }` のようなJSONを自動で `{ "customer": { "name": "..." } }` に包む。そのため「`customer` キーがなければ400」というテストが失敗した。Laravel にはない挙動なので、テストを「JSONは自動で包まれる」「JSON以外でキーがなければ400」の2つに分けた
- **テストが development 環境で動いてしまった**：`.env` に `RAILS_ENV=development` を書いていたため、RSpec が test 環境ではなく development 環境で動き、Host 制限で403になった。Rails は未指定なら development になるので、`.env` から削除した
- **新しいディレクトリが読み込まれなかった**：`app/serializers` を追加した直後は `uninitialized constant` になった。Rails の自動読み込みの対象ディレクトリは起動時に決まるため、サーバーの再起動が必要だった
