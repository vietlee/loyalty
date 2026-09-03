FactoryBot.define do
  factory :reward do
    workspace
    sequence(:title) { |n| "Reward #{n}" }
    kind { "voucher" }
    value_unit { "vnd" }
    value { 10_000 }
    cost_points { 100 }
    valid_days { 30 }
    active { true }
  end
end
