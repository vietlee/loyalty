require "test_helper"

class VoidPurchaseTest < ActiveSupport::TestCase
  setup do
    @ws = create(:workspace)
    @staff = create(:user)
    ActsAsTenant.with_tenant(@ws) do
      create(:loyalty_program, workspace: @ws, earn_points: 1, earn_per_amount: 1000, tiers_enabled: false)
      @ws.memberships.create!(user: @staff, role: "manager")
      @member = create(:member, workspace: @ws)
      @result = EarnPoints.new(member: @member, amount: 100_000, staff: @staff).call
    end
  end

  test "voiding reverses the points and drops the bill out of revenue" do
    ActsAsTenant.with_tenant(@ws) do
      assert_equal 100, @member.reload.points_balance

      r = VoidPurchase.new(purchase: @result.purchase, staff: @staff, reason: "gõ nhầm").call

      assert r.ok
      assert_equal 100, r.points_reversed
      assert_equal 0, @member.reload.points_balance
      assert_equal 0, @member.lifetime_points
      assert @result.purchase.reload.voided?
      assert_equal 0, Purchase.not_voided.sum(:amount), "voided bill still counted as revenue"
      # The ledger stays append-only: earn + void, nothing deleted.
      assert_equal 1, @member.point_transactions.where(kind: "earn").count
      assert_equal 1, @member.point_transactions.where(kind: "void").count
    end
  end

  test "a void is netted off points issued, not counted as a redemption" do
    ActsAsTenant.with_tenant(@ws) do
      VoidPurchase.new(purchase: @result.purchase, staff: @staff).call
      assert_equal 0, PointTransaction.net_credits.sum(:amount), "issued points ignore the reversal"
      assert_equal 0, PointTransaction.redemptions.sum(:amount).abs,
                   "a reversal was counted as points the customer redeemed"
    end
  end

  test "voiding tells the customer what happened" do
    ActsAsTenant.with_tenant(@ws) do
      assert_difference -> { @member.notifications.count }, 1 do
        VoidPurchase.new(purchase: @result.purchase, staff: @staff).call
      end
    end
  end

  test "voiding twice is refused" do
    ActsAsTenant.with_tenant(@ws) do
      VoidPurchase.new(purchase: @result.purchase, staff: @staff).call
      second = VoidPurchase.new(purchase: @result.purchase.reload, staff: @staff).call
      assert_not second.ok
      assert_equal 0, @member.reload.points_balance, "points were reversed twice"
    end
  end

  test "voiding rolls an in-progress stamp card back" do
    ActsAsTenant.with_tenant(@ws) do
      @ws.program.update!(gamification_enabled: true)
      reward = create(:reward, workspace: @ws)
      card = StampCard.create!(workspace: @ws, title: "Card", target_count: 5, reward: reward, active: true)
      res = EarnPoints.new(member: @member, amount: 50_000, staff: @staff).call
      sm = StampCardMembership.find_by(member: @member, stamp_card: card)
      assert_equal 1, sm.count

      VoidPurchase.new(purchase: res.purchase, staff: @staff).call
      assert_equal 0, sm.reload.count
    end
  end

  test "a cashier may undo their own fresh bill but not an old one" do
    ActsAsTenant.with_tenant(@ws) do
      cashier = create(:user)
      membership = @ws.memberships.create!(user: cashier, role: "cashier")
      purchase = EarnPoints.new(member: @member, amount: 10_000, staff: cashier).call.purchase

      assert purchase.voidable_by?(cashier, membership)
      purchase.update_columns(created_at: 2.hours.ago)
      assert_not purchase.reload.voidable_by?(cashier, membership)
      # A manager is never locked out.
      assert purchase.voidable_by?(@staff, @ws.memberships.find_by(user: @staff))
    end
  end
end
