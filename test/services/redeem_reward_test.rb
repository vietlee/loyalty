require "test_helper"

class RedeemRewardTest < ActiveSupport::TestCase
  setup do
    @ws = create(:workspace)
    ActsAsTenant.with_tenant(@ws) do
      create(:loyalty_program, workspace: @ws, tiers_enabled: false)
      @member = create(:member, workspace: @ws)
      @reward = create(:reward, workspace: @ws, cost_points: 100)
    end
  end

  def credit!(amount)
    ActsAsTenant.with_tenant(@ws) do
      PointTransaction.create!(workspace: @ws, member: @member, kind: "adjust", amount: amount)
      @member.recompute_points!
    end
  end

  test "redeeming issues a voucher and debits the ledger" do
    credit!(150)
    ActsAsTenant.with_tenant(@ws) do
      result = RedeemReward.new(member: @member, reward: @reward).call
      assert_not_nil result.voucher
      assert_equal 50, @member.reload.points_balance
      assert_equal 1, @reward.reload.redeemed_count
    end
  end

  test "a second redemption on the same balance is refused, not overdrawn" do
    credit!(100) # exactly enough for ONE
    ActsAsTenant.with_tenant(@ws) do
      first  = RedeemReward.new(member: @member, reward: @reward).call
      second = RedeemReward.new(member: @member.reload, reward: @reward).call

      assert_not_nil first.voucher
      assert_nil second.voucher, "balance was overdrawn by a repeat submit"
      assert_equal 0, @member.reload.points_balance
      assert_equal 1, Voucher.where(member: @member).count
      assert_equal 1, @reward.reload.redeemed_count, "stock moved on a failed redemption"
    end
  end

  test "a stale cached balance cannot overdraw the ledger" do
    credit!(100)
    ActsAsTenant.with_tenant(@ws) do
      RedeemReward.new(member: @member, reward: @reward).call
      # Simulate a second request holding a pre-redemption copy of the member.
      stale = Member.find(@member.id)
      stale.update_columns(points_balance: 100)
      result = RedeemReward.new(member: stale, reward: @reward).call
      assert_nil result.voucher
      assert_equal 1, Voucher.where(member: @member).count
    end
  end

  test "limited stock cannot be exceeded" do
    credit!(1000)
    ActsAsTenant.with_tenant(@ws) do
      @reward.update!(stock: 2)
      3.times { RedeemReward.new(member: @member.reload, reward: @reward.reload).call }
      assert_equal 2, @reward.reload.redeemed_count
      assert_equal 2, Voucher.where(member: @member).count
    end
  end

  test "running out of stock raises a merchant alert" do
    credit!(1000)
    ActsAsTenant.with_tenant(@ws) do
      @reward.update!(stock: 1)
      RedeemReward.new(member: @member, reward: @reward).call
      assert MerchantAlert.where(kind: "reward_stock").exists?
    end
  end
end
