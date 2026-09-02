# Awards points for a purchase: computes base points from the program's earn
# rate, applies the member's tier multiplier, writes a Purchase + ledger entry
# atomically, and refreshes the member's cached balance/tier.
class EarnPoints
  Result = Struct.new(:purchase, :points, :multiplier, :tier_before, :tier_after,
                      :leveled_up, keyword_init: true)

    def initialize(member:, amount:, outlet: nil, staff: nil, source: "staff_scan")
      @member = member
      @amount = amount.to_i
      @outlet = outlet
      @staff  = staff
      @source = source
      @program = member.workspace.program
    end

    def call
      base = @program.points_for(@amount)
      mult = (@program.tiers_enabled ? (@member.tier&.multiplier || 1) : 1).to_f
      points = (base * mult).floor
      tier_before = @member.tier

      purchase = nil
      Purchase.transaction do
        purchase = Purchase.create!(
          workspace: @member.workspace, member: @member, outlet: @outlet,
          staff: @staff, amount: @amount, points_earned: points, source: @source
        )
        if points.positive?
          PointTransaction.create!(
            workspace: @member.workspace, member: @member, kind: "earn",
            amount: points, source: purchase, outlet: @outlet, staff: @staff,
            expires_at: @program.points_expire_at(purchase.created_at)
          )
        end
        @member.recompute_points!
      end

      Gamification.after_purchase(purchase)
      Referrals.on_purchase(@member)

      tier_after = @member.reload.tier
      Result.new(purchase: purchase, points: points, multiplier: mult,
                 tier_before: tier_before, tier_after: tier_after,
                 leveled_up: tier_before&.key != tier_after&.key)
    end
  end
