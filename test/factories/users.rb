FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "owner#{n}@example.com" }
    sequence(:name)  { |n| "Owner #{n}" }
    password { "secret123" }
    locale { "vi" }
  end
end
