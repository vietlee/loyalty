class PointTransaction < ApplicationRecord
  acts_as_tenant(:workspace)

  KINDS = %w[earn redeem adjust expire referral mission game birthday].freeze

  belongs_to :workspace
  belongs_to :member
  belongs_to :outlet, optional: true
  belongs_to :staff, class_name: "User", optional: true
  belongs_to :source, polymorphic: true, optional: true

  validates :kind, inclusion: { in: KINDS }
  validates :amount, numericality: { other_than: 0 }

  scope :recent, -> { order(created_at: :desc) }
  scope :credits, -> { where("amount > 0") }
  scope :debits,  -> { where("amount < 0") }
  # Points that count toward tier standing (earned, not spent).
  scope :tier_qualifying, -> { where(kind: %w[earn referral mission game birthday adjust]).where("amount > 0") }

  def credit? = amount.positive?

  ICONS = {
    "earn" => "☕", "redeem" => "🎁", "referral" => "🤝", "mission" => "✅",
    "game" => "🎡", "birthday" => "🎂", "adjust" => "⚙", "expire" => "⌛"
  }.freeze
  def icon = ICONS[kind] || "•"

  def title
    return note if note.present? && kind == "adjust"
    I18n.t("customer.tx.#{kind}", default: I18n.t("customer.tx.adjust"))
  end
end
