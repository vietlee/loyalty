class Badge < ApplicationRecord
  acts_as_tenant(:workspace)

  CRITERIA = %w[first_purchase purchases_count points_total night_owl].freeze

  belongs_to :workspace
  has_many :member_badges, dependent: :destroy

  validates :key, :name, presence: true
  validates :key, uniqueness: { scope: :workspace_id }

  scope :ordered, -> { order(:position, :id) }

  def display_icon = icon.presence || "🏅"

  # Does `member` currently satisfy this badge?
  def earned_by?(member)
    case criteria_type
    when "first_purchase" then member.purchases.any?
    when "purchases_count" then member.purchases.count >= threshold
    when "points_total"    then member.lifetime_points >= threshold
    when "night_owl"       then member.purchases.where("EXTRACT(hour FROM created_at) >= ?", 22).count >= threshold
    else false
    end
  end
end
