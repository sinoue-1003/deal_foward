FactoryBot.define do
  factory :company do
    name { Faker::Company.name }
    industry { Faker::Company.industry }
    employee_count { Faker::Number.between(from: 1, to: 10000) }
    annual_revenue { Faker::Number.between(from: 1_000_000, to: 1_000_000_000) }
  end
end
