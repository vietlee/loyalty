require "test_helper"

class EarnPointsTest < ActiveSupport::TestCase
  setup do
    @ws = create(:workspace)
    ActsAsTenant.with_tenant(@ws) do
      create(:loyalty_program, workspace: @ws, earn_points: 1, earn_per_amount: 1000, tiers_enabled: false)
      @member = create(:member, workspace: @ws)
    end
  end

  test "earning creates a purchase + ledger entry and updates the cached balance" do
    ActsAsTenant.with_tenant(@ws) do
      result = EarnPoints.new(member: @member, amount: 10_000).call
      assert_equal 10, result.points
      assert_equal 10, @member.reload.points_balance
      assert_equal 1, @member.purchases.count
      assert_equal 1, @member.point_transactions.where(kind: "earn").count
    end
  end

  test "earned points get an expiry when the program configures one" do
    ActsAsTenant.with_tenant(@ws) do
      @ws.program.update!(points_expiry_months: 12)
      EarnPoints.new(member: @member, amount: 10_000).call
      tx = @member.point_transactions.where(kind: "earn").last
      assert_not_nil tx.expires_at
    end
  end
end
