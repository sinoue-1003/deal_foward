FactoryBot.define do
  factory :communication do
    association :company
    channel { "slack" }
    content { Faker::Lorem.paragraph }
    recorded_at { Time.current }
    direction { "inbound" }
  end
end
