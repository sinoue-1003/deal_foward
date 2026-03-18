FactoryBot.define do
  factory :contact do
    association :company
    name { Faker::Name.full_name }
    email { Faker::Internet.unique.email }
    position { Faker::Job.title }
  end
end
