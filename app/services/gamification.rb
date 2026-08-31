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
      card.membership_for(member).add_stamp!
    end
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
      MemberBadge.create!(workspace: ws, member: member, badge: badge, earned_at: Time.current)
    end
  end
end
