class SpinWheel < ApplicationRecord
  acts_as_tenant(:workspace)

  belongs_to :workspace

  DEFAULT_SEGMENTS = [
    { "label" => "+10 điểm",  "kind" => "points",  "value" => 10,  "weight" => 30, "color" => "#E08A3C" },
    { "label" => "Chúc may mắn", "kind" => "none", "value" => 0,   "weight" => 25, "color" => "#C9CDD4" },
    { "label" => "+50 điểm",  "kind" => "points",  "value" => 50,  "weight" => 20, "color" => "#3F7A57" },
    { "label" => "+20 điểm",  "kind" => "points",  "value" => 20,  "weight" => 15, "color" => "#4B9FE1" },
    { "label" => "+100 điểm", "kind" => "points",  "value" => 100, "weight" => 8,  "color" => "#C64B8C" },
    { "label" => "+200 điểm", "kind" => "points",  "value" => 200, "weight" => 2,  "color" => "#E0B54A" }
  ].freeze

  def resolved_segments
    segments.presence || DEFAULT_SEGMENTS
  end

  def free_spin_available?(member)
    return false unless daily_free
    !SpinLog.where(workspace_id: workspace_id, member_id: member.id, cost: 0)
            .where("created_at >= ?", Time.current.beginning_of_day).exists?
  end

  # Weighted-random pick; returns [index, segment].
  def pick
    segs = resolved_segments
    total = segs.sum { |s| s["weight"].to_i }
    roll = SecureRandom.random_number(total)
    acc = 0
    segs.each_with_index do |s, i|
      acc += s["weight"].to_i
      return [i, s] if roll < acc
    end
    [segs.size - 1, segs.last]
  end

  # Perform a spin. Returns { index:, segment:, points:, error: }.
  def spin!(member)
    free = free_spin_available?(member)
    cost = free ? 0 : cost_points
    return { error: :not_enough } if !free && member.points_balance < cost

    index, seg = pick
    points = seg["kind"] == "points" ? seg["value"].to_i : 0
    reward = (seg["kind"] == "reward" && seg["reward_id"].present?) ?
             Reward.find_by(id: seg["reward_id"], workspace_id: workspace_id) : nil

    voucher = nil
    SpinWheel.transaction do
      SpinLog.create!(workspace: workspace, member: member, segment_index: index,
                      result_kind: seg["kind"], result_value: (reward ? reward.id : points), cost: cost)
      PointTransaction.create!(workspace: workspace, member: member, kind: "adjust",
                               amount: -cost, note: "Lượt quay") if cost.positive?
      PointTransaction.create!(workspace: workspace, member: member, kind: "game",
                               amount: points, note: "Vòng quay may mắn") if points.positive?
      if reward
        voucher = Voucher.create!(workspace: workspace, member: member, reward: reward,
                                  source: "spin", state: "active", points_spent: 0,
                                  expires_at: reward.valid_days.present? ? reward.valid_days.days.from_now : nil)
      end
      member.recompute_points!
    end
    { index: index, segment: seg, points: points, reward: reward, voucher: voucher, free: free, cost: cost }
  end
end
