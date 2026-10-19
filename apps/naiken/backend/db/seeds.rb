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
  { name: "吉田 愛", name_kana: "ヨシダ アイ", email: "yoshida@example.com", phone: "090-1212-3434", budget_max: 4200, desired_area: "横浜市港北区" }
]

customers.each_with_index do |attrs, i|
  Customer.find_or_create_by!(name: attrs[:name]) do |customer|
    customer.assign_attributes(attrs.merge(agent: agents[i % agents.size]))
  end
end

properties = [
  { name: "パークハウス世田谷桜丘", address: "東京都世田谷区桜丘3丁目", price: 5980, layout: "3LDK", floor_area: 72.4, built_year: 2015, nearest_station: "千歳船橋", walk_minutes: 8 },
  { name: "ブリリア杉並高井戸", address: "東京都杉並区高井戸東2丁目", price: 4480, layout: "2LDK", floor_area: 58.1, built_year: 2009, nearest_station: "高井戸", walk_minutes: 6 },
  { name: "プラウド目黒本町", address: "東京都目黒区目黒本町5丁目", price: 7280, layout: "3LDK", floor_area: 75.6, built_year: 2019, nearest_station: "武蔵小山", walk_minutes: 9 },
  { name: "ザ・パークハウス港南", address: "東京都港区港南4丁目", price: 8900, layout: "2LDK", floor_area: 68.3, built_year: 2021, nearest_station: "品川", walk_minutes: 12, note: "高層階・眺望良好" },
  { name: "ライオンズ練馬中村橋", address: "東京都練馬区中村北4丁目", price: 3680, layout: "3LDK", floor_area: 65.0, built_year: 2003, nearest_station: "中村橋", walk_minutes: 4, note: "ペット飼育可(規約あり)" },
  { name: "シティテラス武蔵小杉", address: "神奈川県川崎市中原区小杉町1丁目", price: 5280, layout: "3LDK", floor_area: 70.2, built_year: 2012, nearest_station: "武蔵小杉", walk_minutes: 7 },
  { name: "クレヴィア品川大井町", address: "東京都品川区大井1丁目", price: 5480, layout: "2LDK", floor_area: 55.8, built_year: 2017, nearest_station: "大井町", walk_minutes: 5 },
  { name: "パークシティ日吉", address: "神奈川県横浜市港北区日吉本町1丁目", price: 4180, layout: "3LDK", floor_area: 71.0, built_year: 2006, nearest_station: "日吉", walk_minutes: 10 },
  { name: "グランドメゾン中野", address: "東京都中野区中野2丁目", price: 6280, layout: "2LDK", floor_area: 60.5, built_year: 2018, nearest_station: "中野", walk_minutes: 6, status: "closed", note: "売主都合により掲載終了" },
  { name: "コスモ三軒茶屋", address: "東京都世田谷区太子堂4丁目", price: 3980, layout: "1LDK", floor_area: 42.3, built_year: 1998, nearest_station: "三軒茶屋", walk_minutes: 3 }
]

properties.each do |attrs|
  Property.find_or_create_by!(name: attrs[:name]) { it.assign_attributes(attrs) }
end

puts "agents: #{Agent.count}, customers: #{Customer.count}, properties: #{Property.count}"
