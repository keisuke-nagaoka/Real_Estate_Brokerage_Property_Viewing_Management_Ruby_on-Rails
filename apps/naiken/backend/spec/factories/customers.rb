FactoryBot.define do
  factory :customer do
    agent
    name { "山田 太郎" }
    name_kana { "ヤマダ タロウ" }
    sequence(:email) { "customer#{it}@example.com" }
    phone { "090-1234-5678" }
    budget_max { 5000 }
    desired_area { "世田谷区" }
  end
end
