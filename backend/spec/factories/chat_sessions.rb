FactoryBot.define do
  factory :chat_session do
    association :company
    status { "active" }
    intent_score { Faker::Number.between(from: 0, to: 100) }
    visitor_id { Faker::Internet.uuid }
    messages { [] }
  end
end
