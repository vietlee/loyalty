class Reward < ApplicationRecord
  acts_as_tenant(:workspace)

  KINDS = %w[voucher gift discount].freeze
  VALUE_UNITS = %w[vnd percent item].freeze

  belongs_to :workspace
  # Refuse deletion while the reward is in use — deleting it would wipe issued
  # vouchers from customers' wallets or break a stamp card / campaign. Merchants
  # deactivate (active: false) instead. destroy returns false + adds an error.
  has_many :vouchers,     dependent: :restrict_with_error
  has_many :stamp_cards,  dependent: :restrict_with_error
  has_many :campaigns,    dependent: :restrict_with_error
  has_many :promo_codes,  dependent: :restrict_with_error

  def in_use? = vouchers.exists? || stamp_cards.exists? || campaigns.exists? || promo_codes.exists?

  # Gifts/items don't need a numeric value → default a blank one to 0 so it
  # never hits the NOT NULL column. For voucher/discount a blank value fails
  # the presence check below (clear form error) instead of 500-ing.
  before_validation { self.value = 0 if value.blank? && (kind == "gift" || value_unit == "item") }

  validates :title, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :value_unit, inclusion: { in: VALUE_UNITS }
  validates :value, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :value, numericality: { less_than_or_equal_to: 100 },
                    if: -> { value_unit == "percent" && value.present? }

  scope :active,   -> { where(active: true) }
  scope :listed,   -> { where(archived_at: nil) } # hide archived (soft-deleted) rewards
  scope :ordered,  -> { order(:position, :id) }
  def archived? = archived_at.present?
  # Rewards a member can redeem with points right now.
  scope :redeemable, -> { active.where.not(cost_points: nil) }

  def in_stock?  = stock.nil? || stock > redeemed_count
  def within_window?
    now = Time.current
    return false unless starts_at.nil? || starts_at <= now
    return false unless ends_at.nil?   || ends_at >= now
    sch = schedule || {}
    days = Array(sch["days"]).map(&:to_i)
    return false if days.present? && !days.include?(now.wday)   # 0=CN … 6=T7
    fh, th = sch["from_hour"], sch["to_hour"]
    if fh.present? && th.present?
      return false unless (fh.to_i..th.to_i).cover?(now.hour)
    end
    true
  end
  def available? = active? && in_stock? && within_window?

  WDAYS_VI = %w[CN T2 T3 T4 T5 T6 T7].freeze # index = wday (0=Sun)
  # Human summary of the recurring schedule (nil when always-on within window).
  def schedule_summary
    sch = schedule || {}
    parts = []
    days = Array(sch["days"]).map(&:to_i).sort
    parts << days.map { |d| WDAYS_VI[d] }.join(", ") if days.present?
    parts << "#{format('%02d', sch['from_hour'])}:00–#{format('%02d', sch['to_hour'])}:59" if sch["from_hour"].present? && sch["to_hour"].present?
    parts.join(" · ").presence
  end

  def remaining
    stock.nil? ? nil : [stock - redeemed_count, 0].max
  end

  def value_label
    case value_unit
    when "percent" then "-#{value}%"
    when "item"    then I18n.t("customer.reward.free")
    else "-#{ActiveSupport::NumberHelper.number_to_delimited(value)}đ"
    end
  end

  def display_icon = icon.presence || { "voucher" => "🎟️", "gift" => "🎁", "discount" => "🏷️" }[kind]
end
