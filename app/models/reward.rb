class Reward < ApplicationRecord
  acts_as_tenant(:workspace)

  KINDS = %w[voucher gift discount].freeze

  belongs_to :workspace
  has_many :vouchers, dependent: :destroy

  validates :title, presence: true
  validates :kind, inclusion: { in: KINDS }

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
    when "item"    then "Miễn phí"
    else "-#{ActiveSupport::NumberHelper.number_to_delimited(value)}đ"
    end
  end

  def display_icon = icon.presence || { "voucher" => "🎟️", "gift" => "🎁", "discount" => "🏷️" }[kind]
end
