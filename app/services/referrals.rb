# Referral lifecycle (top-level — see EarnPoints note on the Loyalty namespace).
module Referrals
  module_function

  # A new member joined via a referrer's code — create a pending referral.
  def attach(referred:, referrer_code:)
    return if referrer_code.blank? || referred.referred_by_id.present?
    referrer = Member.find_by(referral_code: referrer_code.to_s.upcase)
    return if referrer.nil? || referrer.id == referred.id

    referred.update!(referred_by: referrer)
    Referral.find_or_create_by!(referred: referred) do |r|
      r.workspace = referred.workspace
      r.referrer = referrer
      r.state = "pending"
    end
  end

  # Called after a member's purchase: if they were referred and this is their
  # first purchase, complete the referral and reward BOTH sides.
  def on_purchase(member)
    program = member.workspace.program
    return unless program.referral_enabled
    referral = Referral.pending.find_by(referred_id: member.id)
    return unless referral
    return if member.purchases.count > 1 # only on the first

    pts = program.referral_points
    Referral.transaction do
      award(referral.referrer, pts, "Thưởng giới thiệu bạn")
      award(referral.referred, pts, "Thưởng khi được giới thiệu")
      referral.update!(state: "completed", reward_points: pts, completed_at: Time.current)
    end
  rescue => e
    Rails.logger.error("[Referrals] #{e.class}: #{e.message}")
  end

  def award(member, points, note)
    PointTransaction.create!(workspace: member.workspace, member: member, kind: "referral",
                             amount: points, note: note)
    member.recompute_points!
  end
end
