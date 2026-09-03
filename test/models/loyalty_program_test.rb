require "test_helper"

class LoyaltyProgramTest < ActiveSupport::TestCase
  test "points_for floors amount / rate * points" do
    p = LoyaltyProgram.new(points_enabled: true, earn_points: 1, earn_per_amount: 1000)
    assert_equal 10, p.points_for(10_500)
    assert_equal 0,  p.points_for(500)
  end

  test "points_for is zero when points disabled" do
    p = LoyaltyProgram.new(points_enabled: false, earn_points: 1, earn_per_amount: 1000)
    assert_equal 0, p.points_for(10_000)
  end

  test "points_expire? reflects expiry months" do
    assert LoyaltyProgram.new(points_expiry_months: 12).points_expire?
    assert_not LoyaltyProgram.new(points_expiry_months: 0).points_expire?
  end
end
