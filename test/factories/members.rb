FactoryBot.define do
  factory :member do
    workspace
    sequence(:email) { |n| "cust#{n}@example.com" }
  end
end
