class Tier < ApplicationRecord
  acts_as_tenant(:workspace)

  belongs_to :workspace

  validates :key, :name, presence: true
  validates :key, uniqueness: { scope: :workspace_id }

  scope :ordered, -> { order(:position) }

  def gradient_css
    from = gradient_from.presence || "#B08D57"
    to   = gradient_to.presence   || "#7A5C3A"
    "linear-gradient(135deg, #{from} 0%, #{to} 100%)"
  end

  def next_tier
    workspace.tiers.ordered.detect { |t| t.threshold_points > threshold_points }
  end
end
