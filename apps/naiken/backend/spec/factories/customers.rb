FactoryBot.define do
  factory :customer do
    agent
    name { "山田 太郎" }
    name_kana { "ヤマダ タロウ" }
    sequence(:email) { "customer#{it}@example.com" }
    phone { "090-1234-5678" }
    budget_max { 5000 }
    desired_area { "世田谷区" }

    # 遷移ルールを通さずに、テストの前提となるステータスを直接作る
    %w[viewing_scheduled considering contracted lost].each do |status_name|
      trait status_name.to_sym do
        after(:create) { |customer| customer.update_column(:status, status_name) }
      end
    end
  end
end
