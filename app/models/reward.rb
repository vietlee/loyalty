class Reward < ApplicationRecord
  acts_as_tenant(:workspace)

  KINDS = %w[voucher gift discount].freeze
  VALUE_UNITS = %w[vnd percent item].freeze

  belongs_to :workspace
  has_many :vouchers, dependent: :destroy

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
  scope :ordered,  -> { order(:position, :id) }
  # Rewards a member can redeem with points right now.
  scope :redeemable, -> { active.where.not(cost_points: nil) }

  def in_stock?  = stock.nil? || stock > redeemed_count
  def within_window?
    now = Time.current
    (starts_at.nil? || starts_at <= now) && (ends_at.nil? || ends_at >= now)
  end
  def available? = active? && in_stock? && within_window?

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
