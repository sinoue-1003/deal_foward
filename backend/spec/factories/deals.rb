FactoryBot.define do
  factory :deal do
    association :company
    title { Faker::Commerce.product_name + " Deal" }
    stage { "prospect" }
    amount { Faker::Number.decimal(l_digits: 6, r_digits: 2).to_f }
    probability { Faker::Number.between(from: 0, to: 100) }
    owner { Faker::Name.full_name }
    close_date { Faker::Date.forward(days: 90) }
  end
end
