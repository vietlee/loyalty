class StampCardMembership < ApplicationRecord
  acts_as_tenant(:workspace)

  belongs_to :workspace
  belongs_to :member
  belongs_to :stamp_card

  validates :member_id, uniqueness: { scope: :stamp_card_id }

  # Add one stamp; on reaching the target, issue the reward voucher and start a
  # fresh card. Returns { completed:, voucher: } when a card was completed.
  def add_stamp!
    result = { completed: false, voucher: nil }
    with_lock do
      self.count += 1
      self.last_stamp_at = Time.current
      if count >= stamp_card.target_count
        self.count = 0
        self.completed_count += 1
        result[:completed] = true
        result[:voucher] = issue_reward! if stamp_card.reward
      end
      save!
    end
    result
  end

  def issue_reward!
    Voucher.create!(
      workspace: workspace, member: member, reward: stamp_card.reward,
      source: "campaign", state: "active", points_spent: 0,
      expires_at: stamp_card.reward.valid_days.days.from_now
    )
  end
end
