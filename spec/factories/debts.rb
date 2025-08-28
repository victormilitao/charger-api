FactoryBot.define do
  factory :debt do
    name { Faker::Name.name }
    government_id { Faker::Number.number(digits: 11) }
    email { Faker::Internet.email }
    debt_amount { rand(100.0..10000.0).round(2) }
    debt_due_date { rand(Date.current..Date.current + 1.year) }
    debt_id { Faker::Alphanumeric.alphanumeric(number: 10) }
    status { 'pending' }
    
    trait :paid do
      status { 'paid' }
      paid_at { rand(Time.current - 1.month..Time.current) }
      paid_amount { debt_amount }
      paid_by { Faker::Name.name }
    end
    
    trait :overdue do
      debt_due_date { rand(Date.current - 1.year..Date.current - 1.day) }
      status { 'pending' }
    end
  end
end
