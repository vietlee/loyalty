class MissionProgress < ApplicationRecord
  acts_as_tenant(:workspace)

  belongs_to :workspace
  belongs_to :member
  belongs_to :mission

  validates :member_id, uniqueness: { scope: [:mission_id, :period_key] }

  def completed? = completed_at.present?
  def claimed?   = claimed_at.present?
  def pct        = mission.goal.to_i.zero? ? 0 : [(progress.to_f / mission.goal * 100).round, 100].min

  # Advance progress; award points once when the goal is reached.
  def advance!(by = 1)
    return if completed?
    self.progress += by
    if progress >= mission.goal
      self.completed_at = Time.current
      save!
      claim!
    else
      save!
    end
  end

  def claim!
    return if claimed?
    PointTransaction.create!(workspace: workspace, member: member, kind: "mission",
                             amount: mission.reward_points, source: mission, note: mission.title)
    update!(claimed_at: Time.current)
    member.recompute_points!
  end
end
