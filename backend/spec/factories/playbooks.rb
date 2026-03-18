FactoryBot.define do
  factory :playbook do
    association :company
    title { "#{Faker::Company.bs.capitalize} Playbook" }
    status { "active" }
    objective { Faker::Lorem.sentence }
    situation_summary { Faker::Lorem.paragraph }
    created_by { "ai_agent" }
  end
end
