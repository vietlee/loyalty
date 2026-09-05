# Progresses gamification state after a purchase: stamps, spend/visit missions,
# and badges. Defensive — never let a gamification error break earning.
module Gamification
  module_function

  def after_purchase(purchase)
    member = purchase.member
    ws = purchase.workspace
    return unless ws.program.gamification_enabled

    advance_stamps(member, ws)
    advance_missions(member, ws, purchase)
    evaluate_badges(member, ws)
  rescue => e
    Rails.logger.error("[Gamification] #{e.class}: #{e.message}")
  end

  def advance_stamps(member, ws)
    ws.stamp_cards.active.each do |card|
      next unless card.running?
      result = card.membership_for(member).add_stamp!
      notify_stamp_reward(member, ws, card, result[:voucher]) if result[:completed] && result[:voucher]
    end
  end

  # Let the customer know a stamp card completed and a reward landed in their
  # wallet (in-app inbox + push) — otherwise the voucher appears silently.
  def notify_stamp_reward(member, ws, card, voucher)
    reward_name = voucher.reward&.title
    title = "Bạn vừa nhận quà! 🎁"
    body  = "Thẻ tem “#{card.title}” đã hoàn thành — #{reward_name} đã vào ví của bạn."
    Notification.create!(workspace: ws, member: member, kind: "reward",
                         title: title, body: body, icon: "🎁",
                         deep_link: "/vouchers/#{voucher.id}")
    PushJob.perform_later(ws.id, [member.id], title, body, "/vouchers/#{voucher.id}") if PushSender.configured?
  rescue => e
    Rails.logger.error("[Gamification] notify_stamp_reward: #{e.class} #{e.message}")
  end

  def advance_missions(member, ws, purchase)
    ws.missions.active.each do |mission|
      case mission.mission_type
      when "spend" then mission.progress_for(member).tap { |mp| mp.save! if mp.new_record? }.advance!(purchase.amount)
      when "visit" then mission.progress_for(member).tap { |mp| mp.save! if mp.new_record? }.advance!(1)
      end
    end
  end

  def evaluate_badges(member, ws)
    earned_ids = member.member_badges.pluck(:badge_id)
    ws.badges.where.not(id: earned_ids).each do |badge|
      next unless badge.earned_by?(member)
      mb = MemberBadge.create!(workspace: ws, member: member, badge: badge, earned_at: Time.current)
      # Bonus points for earning the badge (once), if the merchant set any.
      if badge.reward_points.to_i.positive?
        PointTransaction.create!(workspace: ws, member: member, kind: "mission",
                                 amount: badge.reward_points, source: mb,
                                 note: "🏅 #{badge.name}")
        member.recompute_points!
      end
    end
  end
end
