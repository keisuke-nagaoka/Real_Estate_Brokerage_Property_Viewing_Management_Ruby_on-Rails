FactoryBot.define do
  factory :viewing do
    customer
    property
    agent { customer.agent }
    starts_at { 1.day.from_now.change(hour: 10) }
    ends_at { starts_at + 1.hour }

    trait :completed do
      starts_at { 1.day.ago.change(hour: 10) }
      status { "completed" }
    end

    trait :canceled do
      status { "canceled" }
    end
  end
end
