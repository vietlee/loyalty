FactoryBot.define do
  factory :workspace do
    sequence(:name) { |n| "Test Shop #{n}" }
    sequence(:subdomain) { |n| "shop#{n}" }
    industry { "fnb" }
    status { "active" }
  end
end
