# An item in the shop's own inbox. Unlike Notification (which belongs to one
# customer), an alert belongs to the WORKSPACE — every owner/manager of the shop
# sees the same list, and reading it clears it for the shop.
class MerchantAlert < ApplicationRecord
  acts_as_tenant(:workspace)

  LEVELS = %w[info warn danger].freeze
  KINDS  = %w[rating reward_stock mission_submission].freeze

  belongs_to :workspace

  validates :kind, :title, presence: true
  validates :level, inclusion: { in: LEVELS }

  scope :recent, -> { order(created_at: :desc) }
  scope :unread, -> { where(read_at: nil) }

  def read? = read_at.present?

  def colour
    case level
    when "danger" then "var(--bad, #C0392B)"
    when "warn"   then "var(--warn, #E08A3C)"
    else "var(--primary)"
    end
  end
end
