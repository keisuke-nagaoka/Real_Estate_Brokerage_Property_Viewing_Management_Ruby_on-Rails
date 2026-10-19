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

puts "agents: #{Agent.count}, customers: #{Customer.count}"
