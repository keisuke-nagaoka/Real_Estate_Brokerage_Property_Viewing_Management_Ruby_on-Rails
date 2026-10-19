# API リファレンス

すべてのエンドポイントは `/naiken/api/v1` 配下にあります（nginx が `/naiken/api/*` を Rails の `/api/*` に転送します）。

- リクエスト・レスポンスはすべて JSON
- 一覧は `{ "data": [...], "meta": { "page", "per_page", "total_count", "total_pages" } }`、単体は `{ "data": {...} }` の形式
- 日時は日本時間のオフセット付き ISO 8601（例: `2026-10-20T10:00:00+09:00`）

## エンドポイント

### 共通

| メソッド | パス | 説明 |
| --- | --- | --- |
| GET | `/health` | API・DBの疎通確認 |
| GET | `/agents` | 担当者一覧 |

### 顧客

| メソッド | パス | 説明 |
| --- | --- | --- |
| GET | `/customers?q=&agent_id=&status=&page=&per_page=` | 一覧・検索（`q` は氏名・フリガナ・メール・電話番号の部分一致、`status` はカンマ区切りで複数指定可） |
| GET | `/customers/:id` | 詳細（変更可能なステータス `next_statuses` を含む） |
| POST | `/customers` | 登録（ステータスは常に「問い合わせ」） |
| PATCH | `/customers/:id` | 更新（ステータスは変更できない） |
| DELETE | `/customers/:id` | 削除（成約済み・内見予定がある場合は不可） |
| PATCH | `/customers/:id/status` | 対応ステータスの変更（`{ "status": "considering" }`。キャンセルした内見予定の件数を `meta.canceled_viewings_count` で返す） |

### 物件

| メソッド | パス | 説明 |
| --- | --- | --- |
| GET | `/properties?q=&prefecture=&city=&status=&price_min=&price_max=&page=&per_page=` | 一覧・検索（`q` は物件名・住所・最寄り駅の部分一致、価格は万円単位） |
| GET | `/properties/areas` | 物件があるエリア（都道府県・市区町村）と件数。絞り込みの選択肢に使う |
| GET | `/properties/:id` | 詳細 |
| POST | `/properties` | 登録 |
| PATCH | `/properties/:id` | 更新（掲載状況の変更を含む） |
| DELETE | `/properties/:id` | 削除（内見予定がある場合は不可） |
| POST | `/properties/:id/photos` | 写真の追加（`multipart/form-data` で `photos[]` を送る。JPEG・PNG・WebP、1枚5MBまで、1物件10枚まで） |
| DELETE | `/properties/:id/photos/:photo_id` | 写真の削除 |

### 内見予定

| メソッド | パス | 説明 |
| --- | --- | --- |
| GET | `/viewings?from=&to=&agent_id=&customer_id=&property_id=&status=&order=&page=&per_page=` | 一覧（`from` / `to` は `YYYY-MM-DD`、`order=desc` で新しい順） |
| GET | `/viewings/:id` | 詳細 |
| POST | `/viewings` | 登録（ステータスは常に「予定」） |
| PATCH | `/viewings/:id` | 変更（「予定」のもののみ） |
| PATCH | `/viewings/:id/complete` | 実施済みにする（開始時刻を過ぎたもののみ） |
| PATCH | `/viewings/:id/cancel` | キャンセルする |

物件の住所は `prefecture`（都道府県）・`city`（市区町村。政令指定都市は区まで）・`address_line`（町名・番地）に分けて登録し、レスポンスにはそれらをつなげた `address` も含めます。

```json
{ "prefecture": "神奈川県", "city": "川崎市中原区", "address_line": "小杉町1丁目", "address": "神奈川県川崎市中原区小杉町1丁目" }
```

物件のレスポンスには写真の一覧を含めます（1枚目を一覧のカバー写真として使います）。`url` は詳細表示用（最大1600×1200）、`thumbnail_url` は一覧用（640×427）の画像で、初回アクセス時に生成されます。

```json
{ "photos": [ { "id": 1, "filename": "exterior.jpg", "url": "/naiken/api/files/representations/proxy/...", "thumbnail_url": "/naiken/api/files/representations/proxy/..." } ] }
```

## エラーレスポンス

エラーは常に次の形式で返します。

```json
{
  "error": {
    "code": "validation_failed",
    "message": "氏名を入力してください",
    "details": { "name": ["氏名を入力してください"] }
  }
}
```

| ステータス | `code` | 発生する場面 |
| --- | --- | --- |
| 400 | `bad_request` | 必須のキーがない、JSONとして解釈できない、日付の形式が不正 |
| 404 | `not_found` / `route_not_found` | データが存在しない / URLが存在しない |
| 422 | `validation_failed` | 入力値の誤り、業務ルール違反（`details` に項目ごとのメッセージ。特定の項目に属さない業務ルール違反は `base`） |
| 500 | `internal_server_error` | 想定外のエラー（内部情報は返さず、ログと突き合わせるための `request_id` だけを返す） |

業務ルール違反の例（担当者の予定の重複）:

```json
{
  "error": {
    "code": "validation_failed",
    "message": "担当者の別の内見予定（10/20 10:00〜11:00）と時間が重複しています",
    "details": { "base": ["担当者の別の内見予定（10/20 10:00〜11:00）と時間が重複しています"] }
  }
}
```
