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

- [ ] 顧客情報の登録・編集・一覧・検索
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

## 設計で意識したこと

<!-- なぜその設計にしたか (例: APIのバージョニング、業務ルールをどこに書くか、など) -->

## Laravel と Rails の違い

<!-- 実装しながら気づいた違いを、Laravelでの書き方と対比して記録する -->

| 観点 | Laravel | Rails |
| --- | --- | --- |
| ORM | Eloquent | Active Record |
| マイグレーション | | |
| バリデーション | FormRequest | |
| ルーティング | | |
| テスト | PHPUnit / Pest | RSpec |

## 実装中に調べたこと・解決したこと

<!-- 詰まったこと、調べたこと、どう解決したかを記録する -->
