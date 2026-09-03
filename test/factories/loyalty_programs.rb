FactoryBot.define do
  factory :loyalty_program do
    workspace
    points_enabled { true }
    earn_points { 1 }
    earn_per_amount { 1000 }
    currency { "VND" }
    scan_mode { "staff_scans_member" }
  end
end
