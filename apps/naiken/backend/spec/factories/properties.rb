FactoryBot.define do
  factory :property do
    sequence(:name) { "テストマンション#{it}" }
    address { "東京都世田谷区桜丘3丁目" }
    price { 5000 }
    layout { "3LDK" }
    floor_area { 70.5 }
    built_year { 2015 }
    nearest_station { "千歳船橋" }
    walk_minutes { 8 }

    trait :closed do
      status { "closed" }
    end
  end
end
