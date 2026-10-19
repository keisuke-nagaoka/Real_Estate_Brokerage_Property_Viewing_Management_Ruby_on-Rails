# デモ用データ。何度実行しても同じ状態になるよう find_or_create_by! で投入する
# 実行: bin/rails db:seed

agents = [
  { name: "佐藤 健太", email: "sato@example.com" },
  { name: "鈴木 美咲", email: "suzuki@example.com" },
  { name: "高橋 翔", email: "takahashi@example.com" }
].map { |attrs| Agent.find_or_create_by!(email: attrs[:email]) { it.name = attrs[:name] } }

customers = [
  { name: "山田 太郎", name_kana: "ヤマダ タロウ", email: "yamada@example.com", phone: "090-1111-2222", budget_max: 6000, desired_area: "世田谷区", note: "小学校区を重視" },
  { name: "田中 花子", name_kana: "タナカ ハナコ", email: "tanaka@example.com", phone: "080-3333-4444", budget_max: 4500, desired_area: "杉並区・中野区" },
  { name: "伊藤 誠", name_kana: "イトウ マコト", phone: "070-5555-6666", budget_max: 8000, desired_area: "港区", note: "駅徒歩5分以内希望" },
  { name: "渡辺 由美", name_kana: "ワタナベ ユミ", email: "watanabe@example.com", budget_max: 5000, desired_area: "川崎市中原区" },
  { name: "中村 大輔", name_kana: "ナカムラ ダイスケ", email: "nakamura@example.com", phone: "090-7777-8888", budget_max: 7000, desired_area: "目黒区" },
  { name: "小林 さくら", name_kana: "コバヤシ サクラ", phone: "080-9999-0000", budget_max: 3800, desired_area: "練馬区", note: "ペット可物件のみ" },
  { name: "加藤 拓也", name_kana: "カトウ タクヤ", email: "kato@example.com", budget_max: 5500, desired_area: "品川区" },
  { name: "吉田 愛", name_kana: "ヨシダ アイ", email: "yoshida@example.com", phone: "090-1212-3434", budget_max: 4200, desired_area: "横浜市港北区" },
  { name: "松本 健", name_kana: "マツモト ケン", email: "matsumoto@example.com", phone: "090-5656-7878", budget_max: 6500, desired_area: "世田谷区" },
  { name: "井上 真理", name_kana: "イノウエ マリ", email: "inoue@example.com", budget_max: 3500, desired_area: "杉並区", note: "他社で購入のため失注" },
  { name: "木村 翔太", name_kana: "キムラ ショウタ", phone: "080-2468-1357", budget_max: 5000, desired_area: "目黒区・品川区", note: "Webから資料請求" }
]

customers.each_with_index do |attrs, i|
  Customer.find_or_create_by!(name: attrs[:name]) do |customer|
    customer.assign_attributes(attrs.merge(agent: agents[i % agents.size]))
  end
end

properties = [
  { name: "パークハウス世田谷桜丘", prefecture: "東京都", city: "世田谷区", address_line: "桜丘3丁目", price: 5980, layout: "3LDK", floor_area: 72.4, built_year: 2015, nearest_station: "千歳船橋", walk_minutes: 8 },
  { name: "ブリリア杉並高井戸", prefecture: "東京都", city: "杉並区", address_line: "高井戸東2丁目", price: 4480, layout: "2LDK", floor_area: 58.1, built_year: 2009, nearest_station: "高井戸", walk_minutes: 6 },
  { name: "プラウド目黒本町", prefecture: "東京都", city: "目黒区", address_line: "目黒本町5丁目", price: 7280, layout: "3LDK", floor_area: 75.6, built_year: 2019, nearest_station: "武蔵小山", walk_minutes: 9 },
  { name: "ザ・パークハウス港南", prefecture: "東京都", city: "港区", address_line: "港南4丁目", price: 8900, layout: "2LDK", floor_area: 68.3, built_year: 2021, nearest_station: "品川", walk_minutes: 12, note: "高層階・眺望良好" },
  { name: "ライオンズ練馬中村橋", prefecture: "東京都", city: "練馬区", address_line: "中村北4丁目", price: 3680, layout: "3LDK", floor_area: 65.0, built_year: 2003, nearest_station: "中村橋", walk_minutes: 4, note: "ペット飼育可(規約あり)" },
  { name: "シティテラス武蔵小杉", prefecture: "神奈川県", city: "川崎市中原区", address_line: "小杉町1丁目", price: 5280, layout: "3LDK", floor_area: 70.2, built_year: 2012, nearest_station: "武蔵小杉", walk_minutes: 7 },
  { name: "クレヴィア品川大井町", prefecture: "東京都", city: "品川区", address_line: "大井1丁目", price: 5480, layout: "2LDK", floor_area: 55.8, built_year: 2017, nearest_station: "大井町", walk_minutes: 5 },
  { name: "パークシティ日吉", prefecture: "神奈川県", city: "横浜市港北区", address_line: "日吉本町1丁目", price: 4180, layout: "3LDK", floor_area: 71.0, built_year: 2006, nearest_station: "日吉", walk_minutes: 10 },
  { name: "グランドメゾン中野", prefecture: "東京都", city: "中野区", address_line: "中野2丁目", price: 6280, layout: "2LDK", floor_area: 60.5, built_year: 2018, nearest_station: "中野", walk_minutes: 6, status: "closed", note: "売主都合により掲載終了" },
  { name: "コスモ三軒茶屋", prefecture: "東京都", city: "世田谷区", address_line: "太子堂4丁目", price: 3980, layout: "1LDK", floor_area: 42.3, built_year: 1998, nearest_station: "三軒茶屋", walk_minutes: 3 },
  { name: "ルネ浦和パークサイド", prefecture: "埼玉県", city: "さいたま市浦和区", address_line: "高砂2丁目", price: 4680, layout: "3LDK", floor_area: 74.8, built_year: 2014, nearest_station: "浦和", walk_minutes: 6 },
  { name: "ザ・レジデンス船橋", prefecture: "千葉県", city: "船橋市", address_line: "本町4丁目", price: 3880, layout: "3LDK", floor_area: 68.9, built_year: 2011, nearest_station: "船橋", walk_minutes: 5 },
  { name: "ブランズ横浜青葉台", prefecture: "神奈川県", city: "横浜市青葉区", address_line: "青葉台1丁目", price: 5680, layout: "3LDK", floor_area: 80.2, built_year: 2017, nearest_station: "青葉台", walk_minutes: 8 }
]

properties.each do |attrs|
  Property.find_or_create_by!(name: attrs[:name]) { it.assign_attributes(attrs) }
end

# 物件写真。scripts/generate_property_images.py で生成したダミー画像(外観・室内・間取り図)を、
# 写真が未登録の物件にだけ添付する(ファイル名の番号は上の properties の順番に対応)
images_dir = Rails.root.join("db/seeds/images")
properties.each.with_index(1) do |attrs, number|
  property = Property.find_by!(name: attrs[:name])
  next if property.photos.attached?

  files = Dir[images_dir.join(format("property-%02d-*.jpg", number))].sort
  property.photos.attach(files.map do |path|
    { io: File.open(path), filename: File.basename(path).sub(/\Aproperty-\d+-\d-/, ""), content_type: "image/jpeg" }
  end)
end

# 内見予定は「今日」を基準に作るため、未登録のときだけ投入する
if Viewing.none?
  today = Time.zone.today
  at = ->(days, hour, minute = 0) { (today + days).in_time_zone.change(hour:, min: minute) }
  customer = ->(name) { Customer.find_by!(name:) }
  property = ->(name) { Property.find_by!(name:) }

  [
    # 過去(実施済み・キャンセル)
    { customer: "山田 太郎", property: "パークハウス世田谷桜丘", starts_at: at.(-7, 10), status: "completed", note: "日当たりを気に入っていた" },
    { customer: "田中 花子", property: "ブリリア杉並高井戸", starts_at: at.(-5, 14), status: "completed" },
    { customer: "伊藤 誠", property: "ザ・パークハウス港南", starts_at: at.(-3, 11), status: "canceled", note: "顧客都合でキャンセル" },
    { customer: "松本 健", property: "パークハウス世田谷桜丘", starts_at: at.(-10, 13), status: "completed", note: "購入申込みへ" },
    # 今後の予定
    { customer: "山田 太郎", property: "コスモ三軒茶屋", starts_at: at.(1, 10) },
    { customer: "中村 大輔", property: "プラウド目黒本町", starts_at: at.(1, 14) },
    { customer: "伊藤 誠", property: "ザ・パークハウス港南", starts_at: at.(2, 11), note: "高層階の眺望を確認したい" },
    { customer: "渡辺 由美", property: "シティテラス武蔵小杉", starts_at: at.(2, 15, 30) },
    { customer: "加藤 拓也", property: "クレヴィア品川大井町", starts_at: at.(3, 13) },
    { customer: "小林 さくら", property: "ライオンズ練馬中村橋", starts_at: at.(4, 10, 30), note: "ペット飼育規約を持参" },
    { customer: "吉田 愛", property: "パークシティ日吉", starts_at: at.(5, 16) }
  ].each do |attrs|
    c = customer.(attrs[:customer])
    Viewing.create!(
      customer: c,
      property: property.(attrs[:property]),
      agent: c.agent,
      starts_at: attrs[:starts_at],
      ends_at: attrs[:starts_at] + 1.hour,
      status: attrs.fetch(:status, "scheduled"),
      note: attrs[:note]
    )
  end

  # 内見予定の登録で「内見予定」に自動で進むため、それ以外のステータスの顧客を遷移ルールに沿って変更する
  {
    "田中 花子" => %w[considering],
    "松本 健" => %w[viewing_scheduled contracted],
    "井上 真理" => %w[lost]
  }.each do |name, statuses|
    c = customer.(name)
    statuses.each { |status| c.change_status(status) || raise("#{name}: #{c.errors.full_messages.join}") }
  end
end

puts "agents: #{Agent.count}, customers: #{Customer.count}, properties: #{Property.count}, " \
     "viewings: #{Viewing.count}, photos: #{ActiveStorage::Attachment.where(record_type: "Property").count}"
