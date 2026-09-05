# Redeems a catalog reward with points: validates availability + balance, then
# atomically issues a Voucher, debits the ledger, decrements stock, and
# recomputes the member's cached points. (Top-level — see EarnPoints note.)
class RedeemReward
  Result = Struct.new(:voucher, :error, keyword_init: true)

  def initialize(member:, reward:)
    @member = member
    @reward = reward
  end

  def call
    return err("Ưu đãi không còn khả dụng.") unless @reward.available?
    return err("Ưu đãi này không đổi bằng điểm.") if @reward.cost_points.nil?
    return err("Bạn chưa đủ điểm để đổi.") if @member.points_balance < @reward.cost_points

    voucher = nil
    Voucher.transaction do
      voucher = Voucher.create!(
        workspace: @member.workspace, member: @member, reward: @reward,
        source: "redeem", state: "active", points_spent: @reward.cost_points,
        expires_at: @reward.voucher_expiry_from
      )
      PointTransaction.create!(
        workspace: @member.workspace, member: @member, kind: "redeem",
        amount: -@reward.cost_points, source: voucher, note: @reward.title
      )
      Reward.where(id: @reward.id).update_all("redeemed_count = redeemed_count + 1")
      @member.recompute_points!
    end
    Result.new(voucher: voucher)
  end

  private

  def err(msg) = Result.new(error: msg)
end
