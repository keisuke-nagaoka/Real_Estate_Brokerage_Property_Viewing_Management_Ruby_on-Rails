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
- [x] 物件情報の登録・管理（物件名・住所・最寄り駅での検索、掲載状況・価格帯での絞り込み）
- [x] 顧客と物件を紐づけた内見予定の管理（日付ごとの一覧、実施済み・キャンセルの操作、顧客・物件ごとの履歴表示）
- [x] 対応ステータスの更新（問い合わせ → 内見予定 → 検討中 → 成約 / 失注）、ステータス別のボード表示

```
問い合わせ ─→ 内見予定 ⇄ 検討中 ─→ 成約（以降は変更不可）
   │            │         │
   └────────────┴─────────┴──→ 失注 ─→ 問い合わせ（再開）
```
- [ ] APIのテスト、入力値検証、エラーハンドリング

### 業務ルール (予定)

- [x] 同じ担当者に、時間帯が重複する内見予定は登録できない（同時リクエストでも二重登録されないよう担当者の行をロックする）
- [x] 掲載終了の物件には内見予定を登録できない
- [x] 実施済み・キャンセル済みの内見予定は変更できない
- [x] 開始時刻前の内見予定は実施済みにできない
- [x] 内見予定のある顧客・物件・担当者は削除できない（履歴の保護）
- [x] 対応ステータスは決められた順序でしか変更できない（例: 問い合わせから直接成約にはできない、成約後は変更できない）
- [x] 成約・失注の顧客には内見予定を登録できない
- [x] 成約・失注になったら、予定中の内見予定を自動でキャンセルする
- [x] 成約済みの顧客は削除できない
- [x] 内見予定を登録すると「内見予定」に、予定中の内見がすべて実施済みになると「検討中」に自動で進む

## API

| メソッド | パス | 説明 |
| --- | --- | --- |
| GET | `/naiken/api/v1/health` | API・DBの疎通確認 |
| GET | `/naiken/api/v1/agents` | 担当者一覧 |
| GET | `/naiken/api/v1/customers?q=&agent_id=&status=&page=&per_page=` | 顧客一覧・検索（`status` はカンマ区切りで複数指定可） |
| GET | `/naiken/api/v1/customers/:id` | 顧客詳細 |
| POST | `/naiken/api/v1/customers` | 顧客登録 |
| PATCH | `/naiken/api/v1/customers/:id` | 顧客更新 |
| DELETE | `/naiken/api/v1/customers/:id` | 顧客削除 |
| PATCH | `/naiken/api/v1/customers/:id/status` | 対応ステータスの変更（キャンセルした内見予定の件数を返す） |
| GET | `/naiken/api/v1/properties?q=&status=&price_min=&price_max=&page=` | 物件一覧・検索 |
| GET | `/naiken/api/v1/properties/:id` | 物件詳細 |
| POST | `/naiken/api/v1/properties` | 物件登録 |
| PATCH | `/naiken/api/v1/properties/:id` | 物件更新（掲載状況の変更を含む） |
| DELETE | `/naiken/api/v1/properties/:id` | 物件削除 |
| GET | `/naiken/api/v1/viewings?from=&to=&agent_id=&customer_id=&property_id=&status=&order=&page=` | 内見予定一覧 |
| GET | `/naiken/api/v1/viewings/:id` | 内見予定詳細 |
| POST | `/naiken/api/v1/viewings` | 内見予定登録 |
| PATCH | `/naiken/api/v1/viewings/:id` | 内見予定の変更（予定のもののみ） |
| PATCH | `/naiken/api/v1/viewings/:id/complete` | 実施済みにする |
| PATCH | `/naiken/api/v1/viewings/:id/cancel` | キャンセルする |

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
- 価格は「万円」単位の整数で保存し、小数の誤差が出ないようにした。専有面積は `decimal` で保存し、JSONでは文字列にならないよう数値に変換して返す
- 内見予定のステータスは通常の更新APIでは変更できないようにし、`complete` / `cancel` という専用のエンドポイントでのみ遷移させた。どの状態からどの状態に変われるかをモデルのメソッドに閉じ込め、不正な遷移をAPIの入口で防いでいる
- 顧客の対応ステータスの遷移ルールは `STATUS_TRANSITIONS` という表(Hash)で定義し、ルールの全体像が1か所で読めるようにした。テストもこの表を元に「許可される遷移」「許可されない遷移」を全パターン生成している
- APIは顧客ごとに「次に変更できるステータス(`next_statuses`)」を返し、画面はそれをボタンとして表示するだけにした。遷移ルールをフロントエンドに重複して持たないため、ルールを変えてもサーバー側の修正だけで済む
- 成約・失注時の「内見予定の一括キャンセル」は、ステータス変更と同じトランザクションで行い、どちらか一方だけが反映されることがないようにした
- 担当者の予定の重複チェックは「チェックしてから保存する」までの間に別のリクエストが割り込むと二重登録になる。そこで保存前に担当者の行を `SELECT ... FOR UPDATE` でロックし、同じ担当者への登録を直列化した（別の担当者への登録は並行して処理できる）
- 業務ルール違反（重複など）は特定の項目ではなく `base` のエラーとして返し、画面上部にメッセージを表示するようにした
- 内見の日時は日本時間のオフセット付き（`+09:00`）で送信し、ブラウザのタイムゾーンに左右されないようにした
- 掲載状況は文字列の `enum` で保存し、DBを直接見ても値の意味が分かるようにした。`validate: true` を指定し、未定義の値が送られても例外ではなくバリデーションエラー(422)になるようにした

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
| 列挙型 | PHPの `enum` + `$casts` | `enum :status, { ... }`（`available?` などのメソッドも自動で生える） |
| 悲観的ロック | `lockForUpdate()` | `lock`（`SELECT ... FOR UPDATE`） |
| 関連先がある場合の削除禁止 | 外部キー制約の例外を捕まえる / 自前でチェック | `dependent: :restrict_with_error`（バリデーションエラーとして扱える） |
| RESTに当てはまらない操作 | `Route::patch('viewings/{id}/complete')` | `member do patch :complete end` |
| モデルのコールバック | Observer / `booted()` 内のイベント | `after_create` / `before_destroy` など（`prepend: true` で実行順を制御） |
| テスト | PHPUnit / Pest | RSpec + FactoryBot |

## 実装中に調べたこと・解決したこと

<!-- 詰まったこと、調べたこと、どう解決したかを記録する -->

- **`customer` キーのないJSONも受け付けられた**：Rails の API モードでは ParamsWrapper が有効で、`{ "name": "..." }` のようなJSONを自動で `{ "customer": { "name": "..." } }` に包む。そのため「`customer` キーがなければ400」というテストが失敗した。Laravel にはない挙動なので、テストを「JSONは自動で包まれる」「JSON以外でキーがなければ400」の2つに分けた
- **テストが development 環境で動いてしまった**：`.env` に `RAILS_ENV=development` を書いていたため、RSpec が test 環境ではなく development 環境で動き、Host 制限で403になった。Rails は未指定なら development になるので、`.env` から削除した
- **未入力の価格に2つのエラーが出た**：`validates :price, presence: true, numericality: {...}` と書くと、未入力のときに「入力してください」と「数値で入力してください」の両方が出た。`numericality` に `allow_nil: true` を付けて別の行に分け、未入力のときは「入力してください」だけになるようにした
- **enumの値の翻訳が効かなかった**：`human_attribute_name("status.completed")` では翻訳されず「Completed」になった。Railsでは `status/completed` のようにスラッシュでつなぐキーで探すため、`human_attribute_name("status/completed")` に直した
- **削除できないときのメッセージが英語の関連名になった**：`restrict_with_error` のメッセージが「viewingsが存在しているので削除できません」になった。関連名(`viewings`)は「親モデルの属性名」として翻訳を探すため、顧客・物件・担当者それぞれの属性に `viewings: 内見予定` を追加した
- **マイグレーション後に500エラーになった**：顧客に `status` 列を追加した後、起動中の開発サーバーで「Undeclared attribute type for enum 'status'」というエラーになった。サーバーが列情報を起動時に読み込んで保持していたためで、再起動で解消した
- **削除できない理由が意図と違った**：成約済みかつ内見予定のある顧客を削除しようとすると、「内見予定が存在しているので削除できません」が先に返った。`has_many ... dependent: :restrict_with_error` のチェックが `before_destroy` より先に動くためで、`before_destroy ..., prepend: true` にして成約済みのチェックを先に行うようにした
- **新しいディレクトリが読み込まれなかった**：`app/serializers` を追加した直後は `uninitialized constant` になった。Rails の自動読み込みの対象ディレクトリは起動時に決まるため、サーバーの再起動が必要だった
