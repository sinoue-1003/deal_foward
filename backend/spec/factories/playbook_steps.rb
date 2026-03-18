FactoryBot.define do
  factory :playbook_step do
    association :playbook
    sequence(:step_index) { |n| n }
    action_type { "send_email" }
    executor_type { "ai" }
    status { "pending" }
    channel { "email" }
    template { Faker::Lorem.sentence }
    due_in_hours { 24 }
  end
end
