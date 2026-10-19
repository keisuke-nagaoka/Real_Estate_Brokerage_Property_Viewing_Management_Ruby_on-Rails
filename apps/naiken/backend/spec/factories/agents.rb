FactoryBot.define do
  factory :agent do
    sequence(:name) { "担当者#{it}" }
    sequence(:email) { "agent#{it}@example.com" }
  end
end
